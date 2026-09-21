import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/offline/offline_models.dart';
import '../../../core/utils/uuid_v4.dart';
import '../../accounts/domain/account_entity.dart';
import '../../accounts/domain/account_repository.dart';
import '../../categories/domain/category_entity.dart';
import '../../categories/domain/category_repository.dart';
import '../domain/movement_entity.dart';
import '../domain/movement_repository.dart';

class ApiMovementRepository implements MovementRepository {
  final ApiClient _api;
  final CategoryRepository _categories;
  final AccountRepository _accounts;
  final Map<String, int> _versions = {};
  final Map<String, Map<String, dynamic>> _raw = {};

  ApiMovementRepository(this._api, this._categories, this._accounts);

  @override
  Future<List<MovementEntity>> getMovements({String? accountId}) async {
    final context = await _loadContext();
    final result = <MovementEntity>[];
    String? cursor;
    do {
      final query = <String, String>{'limite': '100'};
      if (accountId != null) query['cuentaId'] = accountId;
      if (cursor != null) query['cursor'] = cursor;
      final path = Uri(path: '/movimientos', queryParameters: query).toString();
      final data = (await _api.get(path)).object;
      for (final item in data['elementos'] as List<dynamic>? ?? const []) {
        final json = item as Map<String, dynamic>;
        if (json['estado'] == 'anulado') continue;
        result.add(_fromJson(json, context.$1, context.$2));
      }
      cursor = data['cursorSiguiente'] as String?;
    } while (cursor != null);
    return result;
  }

  @override
  Future<MovementEntity> getMovementById(String id) async {
    final context = await _loadContext();
    final movement = _fromJson(
      (await _api.get('/movimientos/$id')).object,
      context.$1,
      context.$2,
    );
    return _attachDocument(movement);
  }

  @override
  Future<MovementEntity> addMovement(MovementEntity movement) async {
    final id = uuidOrNew(movement.id);
    final body = {
      'id': id,
      'ambito': 'privado',
      'cuentaId': movement.account.id,
      if (movement.creditCardId != null)
        'tarjetaCreditoId': movement.creditCardId,
      if (movement.cardOperation != null)
        'operacionTarjeta': cardOperationToString(movement.cardOperation),
      'tipo': movement.type == MovementType.income ? 'ingreso' : 'gasto',
      'monto': movement.amount.round(),
      'descripcion': movement.description,
      'fecha': _date(movement.date),
      'hora': _time(movement.date),
      'categoriaIds': movement.categories.map((item) => item.id).toList(),
      if (movement.documentId != null) 'documentoId': movement.documentId,
      if (movement.recurringSourceId != null)
        'movimientoRecurrenteId': movement.recurringSourceId,
    };
    final optimistic = {...body, 'version': 1, 'estado': 'confirmado'};
    final response = await _api.post(
      '/movimientos',
      body: body,
      offline: OfflineMutation(
        entityType: 'movimiento',
        entityId: id,
        optimisticResponse: optimistic,
        collectionPath: '/movimientos',
      ),
    );
    return _fromJson(response.object, movement.categories, [movement.account]);
  }

  @override
  Future<MovementEntity> updateMovement(MovementEntity movement) async {
    final existing = _raw[movement.id];
    if (existing == null) await getMovementById(movement.id);
    final original = _raw[movement.id]!;
    if (original['tarjetaCreditoId'] != movement.creditCardId) {
      throw const AppFailure(
        'No se puede cambiar la tarjeta de un movimiento existente.',
        code: 'movement_card_immutable',
      );
    }
    final version = _versions[movement.id]!;
    final changes = <String, dynamic>{
      'descripcion': movement.description,
      'categoriaIds': movement.categories.map((item) => item.id).toList(),
      if (movement.documentId != null) 'documentoId': movement.documentId,
      if ((original['monto'] as num).toDouble() != movement.amount)
        'monto': movement.amount.round(),
      if (original['tipo'] !=
          (movement.type == MovementType.income ? 'ingreso' : 'gasto'))
        'tipo': movement.type == MovementType.income ? 'ingreso' : 'gasto',
      if (original['cuentaId'] != movement.account.id)
        'cuentaId': movement.account.id,
      if (original['fecha'] != _date(movement.date))
        'fecha': _date(movement.date),
      if (original['hora'] != _time(movement.date))
        'hora': _time(movement.date),
    };
    final response = await _api.patch(
      '/movimientos/${movement.id}',
      body: changes,
      headers: {'If-Match': '"$version"'},
      offline: OfflineMutation(
        entityType: 'movimiento',
        entityId: movement.id,
        optimisticResponse: {...original, ...changes, 'version': version + 1},
        collectionPath: '/movimientos',
      ),
    );
    return _fromJson(response.object, movement.categories, [movement.account]);
  }

  @override
  Future<void> deleteMovement(String id) async {
    if (!_versions.containsKey(id)) await getMovementById(id);
    await _api.delete(
      '/movimientos/$id',
      headers: {'If-Match': '"${_versions[id]}"'},
      offline: OfflineMutation(
        entityType: 'movimiento',
        entityId: id,
        optimisticResponse: const <String, dynamic>{},
        collectionPath: '/movimientos',
      ),
    );
    _versions.remove(id);
    _raw.remove(id);
  }

  @override
  Future<MovementEntity> reprocessOcr(String id) async {
    final movement = await getMovementById(id);
    if (movement.documentId == null) {
      throw const AppFailure(
        'El movimiento no tiene un comprobante asociado.',
        code: 'document_not_found',
      );
    }
    final response = await _api.post(
      '/documentos-financieros/${movement.documentId}/procesamientos-documentales',
      headers: {
        'Idempotency-Key': 'reprocess-${DateTime.now().microsecondsSinceEpoch}',
      },
      body: {
        'tipo': movement.attachmentType == AttachmentType.xml ? 'sifen' : 'ocr',
      },
    );
    final processingId = response.object['id'] as String;
    for (var attempt = 0; attempt < 24; attempt++) {
      final process = (await _api.get(
        '/procesamientos-documentales/$processingId',
      )).object;
      final state = process['estado'] as String;
      if (state != 'pendiente' && state != 'procesando') {
        return getMovementById(id);
      }
      await Future<void>.delayed(const Duration(milliseconds: 750));
    }
    throw const AppFailure(
      'El comprobante continúa procesándose.',
      code: 'document_processing_timeout',
    );
  }

  Future<MovementEntity> _attachDocument(MovementEntity movement) async {
    final documentId = movement.documentId;
    if (documentId == null) return movement;
    final document = (await _api.get(
      '/documentos-financieros/$documentId',
    )).object;
    final type = switch (document['tipo']) {
      'xml-sifen' => AttachmentType.xml,
      'pdf' => AttachmentType.pdf,
      _ => AttachmentType.image,
    };
    final status = switch (document['estadoProcesamiento']) {
      'pendiente' => OcrStatus.pending,
      'procesando' => OcrStatus.processing,
      'completado' => OcrStatus.success,
      'incompleto' => OcrStatus.incomplete,
      _ => OcrStatus.failed,
    };
    var enriched = movement.copyWith(
      attachmentType: type,
      attachmentName: document['nombreOriginal'] as String,
      ocrStatus: status,
    );
    try {
      final download = (await _api.post(
        '/documentos-financieros/$documentId/descargas',
      )).object;
      final bytes = await _api.downloadBytes(download['url'] as String);
      final path = '${Directory.systemTemp.path}/${document['nombreOriginal']}';
      await File(path).writeAsBytes(bytes, flush: true);
      enriched = enriched.copyWith(attachmentPath: path);
    } catch (_) {
      // Los metadatos siguen siendo útiles aunque la descarga temporal falle.
    }
    return enriched;
  }

  Future<(List<CategoryEntity>, List<AccountEntity>)> _loadContext() async =>
      (await _categories.getCategories(), await _accounts.getAccounts());

  MovementEntity _fromJson(
    Map<String, dynamic> json,
    List<CategoryEntity> categories,
    List<AccountEntity> accounts,
  ) {
    final id = json['id'] as String;
    _versions[id] = (json['version'] as num).toInt();
    _raw[id] = json;
    final categoryIds = (json['categoriaIds'] as List<dynamic>? ?? const [])
        .cast<String>();
    final selected = categories
        .where((item) => categoryIds.contains(item.id))
        .toList();
    final type = json['tipo'] == 'ingreso'
        ? MovementType.income
        : MovementType.expense;
    final effectiveCategories = selected.isNotEmpty
        ? selected
        : [
            CategoryEntity(
              id: 'api-sin-categoria',
              name: 'Sin categoría',
              icon: Icons.category_outlined,
              color: Colors.blueGrey,
              type: type == MovementType.income
                  ? CategoryType.income
                  : CategoryType.expense,
              inUse: true,
            ),
          ];
    final accountId = json['cuentaId'] as String;
    final account = accounts.where((item) => item.id == accountId).firstOrNull;
    return MovementEntity(
      id: id,
      type: type,
      amount: (json['monto'] as num).toDouble(),
      date: DateTime.parse(
        '${json['fecha']}T${json['hora'] as String? ?? '00:00:00'}',
      ),
      categories: effectiveCategories,
      description: json['descripcion'] as String,
      account:
          account ??
          AccountEntity(
            id: accountId,
            name: 'Cuenta',
            type: AccountType.other,
            icon: Icons.wallet_outlined,
            initialBalance: 0,
          ),
      creditCardId: json['tarjetaCreditoId'] as String?,
      cardOperation: cardOperationFromString(
        json['operacionTarjeta'] as String?,
      ),
      transferId: json['transferenciaId'] as String?,
      hasAttachment: json['documentoId'] != null,
      documentId: json['documentoId'] as String?,
      recurringSourceId: json['movimientoRecurrenteId'] as String?,
    );
  }

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}:00';
}
