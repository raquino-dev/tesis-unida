import 'package:flutter/material.dart' show DateTimeRange;
import 'dart:convert';
import 'dart:io';
import '../../../core/errors/app_failure.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../mock/mock_data.dart';
import '../../movements/domain/movement_entity.dart';
import '../../movements/domain/movement_repository.dart';
import '../../movements/presentation/viewmodels/movement_list_viewmodel.dart';
import '../../transfers/domain/transfer_repository.dart';
import '../domain/export_entity.dart';
import '../domain/export_repository.dart';

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
    final file = File(
      '${Directory.systemTemp.path}/extracto_${DateTime.now().millisecondsSinceEpoch}.xls',
    );
    await file.writeAsString(content);
    return file.path;
  }

  String _xmlEscape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  Future<String> _writePdf({
    required double totalIncome,
    required double totalExpense,
    required int movementCount,
  }) async {
    final lines = [
      'Extracto financiero',
      'Ingresos: ${totalIncome.toStringAsFixed(0)} PYG',
      'Gastos: ${totalExpense.toStringAsFixed(0)} PYG',
      'Movimientos incluidos: $movementCount',
    ];
    final stream = StringBuffer('BT /F1 18 Tf 50 770 Td ');
    for (var index = 0; index < lines.length; index++) {
      if (index > 0) stream.write('0 -28 Td ');
      stream.write(
        '(${lines[index].replaceAll('(', r'\(').replaceAll(')', r'\)')}) Tj ',
      );
    }
    stream.write('ET');
    final objects = <String>[
      '<< /Type /Catalog /Pages 2 0 R >>',
      '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>',
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
      '<< /Length ${latin1.encode(stream.toString()).length} >>\nstream\n$stream\nendstream',
    ];
    final buffer = StringBuffer('%PDF-1.4\n');
    final offsets = <int>[];
    for (var index = 0; index < objects.length; index++) {
      offsets.add(latin1.encode(buffer.toString()).length);
      buffer.write('${index + 1} 0 obj\n${objects[index]}\nendobj\n');
    }
    final xref = latin1.encode(buffer.toString()).length;
    buffer.write('xref\n0 ${objects.length + 1}\n0000000000 65535 f \n');
    for (final offset in offsets) {
      buffer.write('${offset.toString().padLeft(10, '0')} 00000 n \n');
    }
    buffer.write(
      'trailer << /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n$xref\n%%EOF',
    );
    final file = File(
      '${Directory.systemTemp.path}/extracto_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(latin1.encode(buffer.toString()));
    return file.path;
  }
}
