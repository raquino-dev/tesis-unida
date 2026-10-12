import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../movements/domain/movement_entity.dart';

class StatementPdfBuilder {
  StatementPdfBuilder._();

  static final _navy = PdfColor.fromHex('#102A43');
  static final _green = PdfColor.fromHex('#009B68');
  static final _red = PdfColor.fromHex('#F04464');
  static final _muted = PdfColor.fromHex('#6B829A');
  static final _border = PdfColor.fromHex('#D7E4DF');
  static final _paleGreen = PdfColor.fromHex('#EFF8F4');
  static final _alternateRow = PdfColor.fromHex('#F7FAF9');

  static Future<Uint8List> build({
    required String period,
    required String account,
    required DateTime generatedAt,
    required double totalIncome,
    required double totalExpense,
    required int movementCount,
    required List<MovementEntity> movements,
  }) async {
    final regularFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
    );
    final boldFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
    );
    final document = pw.Document(
      title: 'Extracto financiero - Finanza',
      author: 'Finanza',
      subject: 'Resumen de movimientos financieros',
      creator: 'Finanza',
    );
    final categories = _categoryTotals(movements, totalExpense);
    final sortedMovements = [...movements]
      ..sort((a, b) => b.date.compareTo(a.date));

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(42, 32, 42, 36),
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        header: (context) => _header(generatedAt),
        footer: _footer,
        build: (context) => [
          pw.SizedBox(height: 22),
          pw.Text(
            'Extracto financiero',
            style: pw.TextStyle(
              color: _navy,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Un resumen claro de tus movimientos durante el período seleccionado.',
            style: pw.TextStyle(color: _navy, fontSize: 11),
          ),
          pw.SizedBox(height: 22),
          _informationBand(period: period, account: account),
          pw.SizedBox(height: 22),
          _summary(
            totalIncome: totalIncome,
            totalExpense: totalExpense,
            movementCount: movementCount,
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Principales categorías de gasto',
            style: pw.TextStyle(
              color: _navy,
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          if (categories.isEmpty)
            _emptyMessage('No hay gastos para el período seleccionado.')
          else
            ...categories.map(_categoryBar),
          pw.SizedBox(height: 24),
          pw.Text(
            'Detalle de movimientos',
            style: pw.TextStyle(
              color: _navy,
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'Los movimientos se muestran del más reciente al más antiguo.',
            style: pw.TextStyle(color: _muted, fontSize: 9),
          ),
          pw.SizedBox(height: 12),
          if (sortedMovements.isEmpty)
            _emptyMessage('No hay movimientos para mostrar.')
          else
            _movementTable(sortedMovements),
        ],
      ),
    );

    return document.save();
  }

  static pw.Widget _header(DateTime generatedAt) => pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(
        width: 34,
        height: 30,
        child: pw.SvgImage(
          svg:
              '<svg viewBox="0 0 34 30" xmlns="http://www.w3.org/2000/svg"><path d="M3 27C2 13 10 3 29 2c1 17-8 26-26 25Z" fill="#009B68"/><path d="M4 26C12 18 19 12 28 4" stroke="#21C98C" stroke-width="2" fill="none"/></svg>',
        ),
      ),
      pw.SizedBox(width: 8),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Finanza',
            style: pw.TextStyle(
              color: _navy,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            'Pequeños hábitos, grandes logros.',
            style: pw.TextStyle(color: _muted, fontSize: 8.5),
          ),
        ],
      ),
      pw.Spacer(),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            'Generado el',
            style: pw.TextStyle(color: _muted, fontSize: 8.5),
          ),
          pw.Text(
            DateFormatter.short(generatedAt),
            style: pw.TextStyle(color: _muted, fontSize: 8.5),
          ),
        ],
      ),
    ],
  );

  static pw.Widget _footer(pw.Context context) => pw.Container(
    padding: const pw.EdgeInsets.only(top: 8),
    decoration: pw.BoxDecoration(
      border: pw.Border(top: pw.BorderSide(color: _border, width: 0.6)),
    ),
    child: pw.Row(
      children: [
        pw.Text(
          'Documento generado por Finanza - Uso informativo',
          style: pw.TextStyle(color: _muted, fontSize: 8),
        ),
        pw.Spacer(),
        pw.Text(
          'Página ${context.pageNumber} de ${context.pagesCount}',
          style: pw.TextStyle(color: _muted, fontSize: 8),
        ),
      ],
    ),
  );

  static pw.Widget _informationBand({
    required String period,
    required String account,
  }) => pw.Container(
    decoration: pw.BoxDecoration(
      color: _paleGreen,
      border: pw.Border.all(color: _border, width: 0.6),
    ),
    child: pw.Row(
      children: [
        _infoCell('Período', period),
        _divider(),
        _infoCell('Cuenta', account),
        _divider(),
        _infoCell('Moneda', 'Guaraníes (PYG)'),
      ],
    ),
  );

  static pw.Widget _infoCell(String label, String value) => pw.Expanded(
    child: pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(color: _navy, fontSize: 10)),
          pw.SizedBox(height: 2),
          pw.Text(value, style: pw.TextStyle(color: _navy, fontSize: 9.5)),
        ],
      ),
    ),
  );

  static pw.Widget _divider() =>
      pw.Container(width: 0.6, height: 46, color: _border);

  static pw.Widget _summary({
    required double totalIncome,
    required double totalExpense,
    required int movementCount,
  }) => pw.Row(
    children: [
      _summaryCell('Ingresos', CurrencyFormatter.format(totalIncome), _green),
      _summaryCell('Gastos', CurrencyFormatter.format(totalExpense), _red),
      _summaryCell(
        'Balance',
        CurrencyFormatter.format(totalIncome - totalExpense),
        totalIncome - totalExpense >= 0 ? _green : _red,
      ),
      _summaryCell('Movimientos', '$movementCount', _navy),
    ],
  );

  static pw.Widget _summaryCell(String label, String value, PdfColor color) =>
      pw.Expanded(
        child: pw.Container(
          height: 52,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _border, width: 0.6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(label, style: pw.TextStyle(color: _muted, fontSize: 8.5)),
              pw.SizedBox(height: 2),
              pw.Text(
                value,
                maxLines: 1,
                style: pw.TextStyle(color: color, fontSize: 13.5),
              ),
            ],
          ),
        ),
      );

  static List<_CategoryTotal> _categoryTotals(
    List<MovementEntity> movements,
    double totalExpense,
  ) {
    final totals = <String, double>{};
    for (final movement in movements) {
      final amount = movement.analyticalExpenseAmount;
      if (amount == 0) continue;
      final name = movement.primaryCategory.name;
      totals[name] = (totals[name] ?? 0) + amount;
    }
    final positiveTotal = totalExpense > 0
        ? totalExpense
        : totals.values
              .where((value) => value > 0)
              .fold<double>(0, (a, b) => a + b);
    final result =
        totals.entries
            .where((entry) => entry.value > 0)
            .map(
              (entry) => _CategoryTotal(
                name: entry.key,
                amount: entry.value,
                share: positiveTotal == 0 ? 0 : entry.value / positiveTotal,
              ),
            )
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));
    return result.take(5).toList();
  }

  static pw.Widget _categoryBar(_CategoryTotal category) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Row(
      children: [
        pw.SizedBox(
          width: 112,
          child: pw.Text(
            category.name,
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
            style: pw.TextStyle(color: _navy, fontSize: 8.5),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Container(
            height: 10,
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: (category.share * 100).round().clamp(3, 100),
                  child: pw.Container(color: _green),
                ),
                if (category.share < 1)
                  pw.Expanded(
                    flex: (100 - category.share * 100).round().clamp(1, 97),
                    child: pw.SizedBox(),
                  ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 12),
        pw.SizedBox(
          width: 76,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                CurrencyFormatter.format(category.amount),
                style: pw.TextStyle(color: _muted, fontSize: 8),
              ),
              pw.Text(
                '${(category.share * 100).round()}%',
                style: pw.TextStyle(color: _muted, fontSize: 8),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  static pw.Widget _movementTable(List<MovementEntity> movements) {
    final rows = movements.map((movement) {
      final isIncome = movement.analyticalIncomeAmount > 0;
      final isRefund = movement.isCardRefund;
      final positive = isIncome || isRefund;
      final sign = positive ? '+' : '-';
      final type = movement.isCardPayment
          ? 'Pago tarjeta'
          : isRefund
          ? 'Reintegro'
          : movement.type == MovementType.income
          ? 'Ingreso'
          : 'Gasto';
      return <dynamic>[
        DateFormatter.short(movement.date),
        movement.description,
        movement.categories.map((category) => category.name).join(', '),
        movement.account.name,
        type,
        pw.Text(
          '$sign${CurrencyFormatter.format(movement.amount)}',
          textAlign: pw.TextAlign.right,
          style: pw.TextStyle(
            color: positive ? _green : _red,
            fontSize: 7.4,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: const [
        'Fecha',
        'Concepto',
        'Categoría',
        'Cuenta / método',
        'Tipo',
        'Monto',
      ],
      data: rows,
      headerCount: 1,
      headerDecoration: pw.BoxDecoration(color: _paleGreen),
      headerStyle: pw.TextStyle(
        color: _navy,
        fontSize: 7.5,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(color: _muted, fontSize: 7.4),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 7),
      cellAlignments: const {5: pw.Alignment.centerRight},
      headerAlignments: const {5: pw.Alignment.centerRight},
      columnWidths: const {
        0: pw.FlexColumnWidth(0.85),
        1: pw.FlexColumnWidth(1.9),
        2: pw.FlexColumnWidth(1.3),
        3: pw.FlexColumnWidth(1.6),
        4: pw.FlexColumnWidth(0.9),
        5: pw.FlexColumnWidth(1.25),
      },
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _border, width: 0.5),
        bottom: pw.BorderSide(color: _border, width: 0.5),
      ),
      oddRowDecoration: pw.BoxDecoration(color: _alternateRow),
    );
  }

  static pw.Widget _emptyMessage(String message) => pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(color: _alternateRow),
    child: pw.Text(message, style: pw.TextStyle(color: _muted, fontSize: 9)),
  );
}

class _CategoryTotal {
  final String name;
  final double amount;
  final double share;

  const _CategoryTotal({
    required this.name,
    required this.amount,
    required this.share,
  });
}
