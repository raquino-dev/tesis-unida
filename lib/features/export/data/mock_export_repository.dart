import 'package:flutter/material.dart' show DateTimeRange;
import 'dart:io';
import '../../../core/errors/app_failure.dart';
import '../../../core/utils/date_formatter.dart';
import 'package:path_provider/path_provider.dart';
import '../../../mock/mock_data.dart';
import '../../movements/domain/movement_entity.dart';
import '../../movements/domain/movement_repository.dart';
import '../../movements/presentation/viewmodels/movement_list_viewmodel.dart';
import '../../transfers/domain/transfer_repository.dart';
import '../domain/export_entity.dart';
import '../domain/export_repository.dart';
import 'statement_pdf_builder.dart';

class MockExportRepository implements ExportRepository {
  final MovementRepository _movementRepository;
  final TransferRepository _transferRepository;

  final List<ExportRecord> _history = MockData.exportHistory
      .map(
        (e) => ExportRecord(
          id: e['id'] as String,
          format: (e['format'] as String) == 'PDF'
              ? ExportFormat.pdf
              : ExportFormat.excel,
          range: e['range'] as String,
          date: e['date'] as DateTime,
          success: e['status'] == 'success',
        ),
      )
      .toList();

  MockExportRepository(this._movementRepository, this._transferRepository);

  @override
  Future<List<ExportRecord>> getHistory() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.unmodifiable(_history.reversed);
  }

  @override
  Future<String> downloadExport(ExportRecord record) async {
    final path = record.artifactPath;
    if (path != null && await File(path).exists()) return path;
    return record.format == ExportFormat.pdf
        ? _writePdf(
            movements: const [],
            period: record.range,
            account: 'Todas las cuentas',
            generatedAt: record.date,
            totalIncome: record.totalIncome,
            totalExpense: record.totalExpense,
            movementCount: record.movementCount,
          )
        : _writeExcel(const []);
  }

  @override
  Future<ExportRecord> requestExport({
    required ExportFormat format,
    required DateTimeRange range,
    required MovementFilters filters,
    required String filtersSummary,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1600));
    if (range.start.isAfter(range.end)) {
      throw const AppFailure('El rango de fechas seleccionado no es válido.');
    }

    final rangeFilters = filters.copyWith(dateRange: range);
    final allMovements = await _movementRepository.getMovements();
    final movements = allMovements.where(rangeFilters.matches).toList();

    final allTransfers = await _transferRepository.getTransfers();
    final start = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final end = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23,
      59,
      59,
    );
    final transfers = allTransfers
        .where((t) => !t.date.isBefore(start) && !t.date.isAfter(end))
        .toList();

    final totalIncome = movements.fold<double>(
      0,
      (sum, movement) => sum + movement.analyticalIncomeAmount,
    );
    final totalExpense = movements.fold<double>(
      0,
      (sum, movement) => sum + movement.analyticalExpenseAmount,
    );
    final totalTransferred = transfers.fold<double>(
      0,
      (sum, t) => sum + t.amount,
    );

    final subtotalsByCategory = <String, StatementCategorySubtotal>{};
    for (final m in movements) {
      for (final c in m.categories) {
        final existing = subtotalsByCategory[c.id];
        subtotalsByCategory[c.id] = StatementCategorySubtotal(
          category: c,
          amount:
              (existing?.amount ?? 0) +
              m.analyticalIncomeAmount +
              m.analyticalExpenseAmount,
        );
      }
    }

    final artifactPath = format == ExportFormat.pdf
        ? await _writePdf(
            movements: movements,
            period:
                '${DateFormatter.short(range.start)} - ${DateFormatter.short(range.end)}',
            account: filters.accountId == null
                ? 'Todas las cuentas'
                : movements
                          .where(
                            (movement) =>
                                movement.account.id == filters.accountId,
                          )
                          .firstOrNull
                          ?.account
                          .name ??
                      'Cuenta seleccionada',
            generatedAt: DateTime.now(),
            totalIncome: totalIncome,
            totalExpense: totalExpense,
            movementCount: movements.length,
          )
        : await _writeExcel(movements);
    final record = ExportRecord(
      id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
      format: format,
      range:
          '${DateFormatter.short(range.start)} - ${DateFormatter.short(range.end)}',
      date: DateTime.now(),
      success: true,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      totalTransferred: totalTransferred,
      movementCount: movements.length,
      filtersSummary: filtersSummary,
      categorySubtotals: subtotalsByCategory.values.toList(),
      artifactPath: artifactPath,
    );
    _history.add(record);
    return record;
  }

  Future<String> _writeExcel(List<MovementEntity> movements) async {
    final rows = movements.map((movement) {
      final values = [
        DateFormatter.short(movement.date),
        movement.description,
        movement.type.name,
        movement.amount.toStringAsFixed(0),
      ];
      return '<Row>${values.map((value) => '<Cell><Data ss:Type="String">${_xmlEscape(value)}</Data></Cell>').join()}</Row>';
    }).join();
    final content =
        '''<?xml version="1.0"?>
<?mso-application progid="Excel.Sheet"?>
<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">
<Worksheet ss:Name="Movimientos"><Table>
<Row><Cell><Data ss:Type="String">Fecha</Data></Cell><Cell><Data ss:Type="String">Descripción</Data></Cell><Cell><Data ss:Type="String">Tipo</Data></Cell><Cell><Data ss:Type="String">Monto</Data></Cell></Row>
$rows
</Table></Worksheet></Workbook>''';
    final file = await _newArtifactFile('xlsx');
    await file.writeAsString(content);
    return file.path;
  }

  String _xmlEscape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  Future<String> _writePdf({
    required List<MovementEntity> movements,
    required String period,
    required String account,
    required DateTime generatedAt,
    required double totalIncome,
    required double totalExpense,
    required int movementCount,
  }) async {
    final bytes = await StatementPdfBuilder.build(
      period: period,
      account: account,
      generatedAt: generatedAt,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      movementCount: movementCount,
      movements: movements,
    );
    final file = await _newArtifactFile('pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<File> _newArtifactFile(String extension) async {
    Directory root;
    try {
      root = await getApplicationDocumentsDirectory();
    } catch (_) {
      root = Directory.systemTemp;
    }
    final directory = Directory('${root.path}/extractos');
    await directory.create(recursive: true);
    return File(
      '${directory.path}/extracto_${DateTime.now().millisecondsSinceEpoch}.$extension',
    );
  }
}
