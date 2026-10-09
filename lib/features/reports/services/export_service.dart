import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/utils/formatters.dart';
import '../../transactions/domain/transaction_model.dart';

class ExportFilters {
  final Set<String> types; // 'income' | 'expense'
  final Set<String> categoryNames;
  final Set<String> memberNames;

  const ExportFilters({
    this.types = const {'income', 'expense'},
    this.categoryNames = const {},
    this.memberNames = const {},
  });

  List<TransactionModel> apply(List<TransactionModel> list) {
    return list.where((t) {
      if (!types.contains(t.type.name)) return false;
      if (categoryNames.isNotEmpty &&
          !categoryNames.contains(t.categoryName)) {
        return false;
      }
      if (memberNames.isNotEmpty &&
          !memberNames.contains(t.createdByName)) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
}

class ExportService {
  // ============================================================
  //  PDF - MENSAL
  // ============================================================
  Future<void> exportPdfMonthly({
    required String familyName,
    required int year,
    required int month,
    required List<TransactionModel> all,
    required ExportFilters filters,
  }) async {
    final monthly = all
        .where((t) => t.date.year == year && t.date.month == month)
        .toList();
    final list = filters.apply(monthly);

    final pdf = await _buildPdf(
      familyName: familyName,
      title: 'Relatório Mensal',
      period: _monthLabel(month, year),
      list: list,
    );

    final bytes = await pdf.save();
    final filename =
        'casa_prime_${year}_${month.toString().padLeft(2, '0')}.pdf';
    await _shareOrSave(
      bytes: bytes,
      filename: filename,
      mime: 'application/pdf',
    );
  }

  // ============================================================
  //  PDF - ANUAL
  // ============================================================
  Future<void> exportPdfYearly({
    required String familyName,
    required int year,
    required List<TransactionModel> all,
    required ExportFilters filters,
  }) async {
    final yearly =
        all.where((t) => t.date.year == year).toList();
    final list = filters.apply(yearly);

    final pdf = await _buildPdf(
      familyName: familyName,
      title: 'Relatório Anual',
      period: 'Ano $year',
      list: list,
    );

    final bytes = await pdf.save();
    final filename = 'casa_prime_$year.pdf';
    await _shareOrSave(
      bytes: bytes,
      filename: filename,
      mime: 'application/pdf',
    );
  }

  // ============================================================
  //  CSV - MENSAL
  // ============================================================
  Future<void> exportCsvMonthly({
    required int year,
    required int month,
    required List<TransactionModel> all,
    required ExportFilters filters,
  }) async {
    final monthly = all
        .where((t) => t.date.year == year && t.date.month == month)
        .toList();
    final list = filters.apply(monthly);

    final csv = _buildCsv(list);
    final bytes = Uint8List.fromList(_encodeCsv(csv));
    final filename =
        'casa_prime_${year}_${month.toString().padLeft(2, '0')}.csv';
    await _shareOrSave(
      bytes: bytes,
      filename: filename,
      mime: 'text/csv',
    );
  }

  // ============================================================
  //  CSV - ANUAL
  // ============================================================
  Future<void> exportCsvYearly({
    required int year,
    required List<TransactionModel> all,
    required ExportFilters filters,
  }) async {
    final yearly =
        all.where((t) => t.date.year == year).toList();
    final list = filters.apply(yearly);

    final csv = _buildCsv(list);
    final bytes = Uint8List.fromList(_encodeCsv(csv));
    final filename = 'casa_prime_$year.csv';
    await _shareOrSave(
      bytes: bytes,
      filename: filename,
      mime: 'text/csv',
    );
  }

  // ============================================================
  //  PDF builder
  // ============================================================
  Future<pw.Document> _buildPdf({
    required String familyName,
    required String title,
    required String period,
    required List<TransactionModel> list,
  }) async {
    // Fonte padrão do PDF (Helvetica já vem embutida)
    final doc = pw.Document();

    // Totais
    double totalIncome = 0, totalExpense = 0;
    for (final t in list) {
      if (t.isIncome) {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }
    }
    final balance = totalIncome - totalExpense;

    final now = DateTime.now();
    final generatedAt =
        'Gerado em ${DateFormat('dd/MM/yyyy \'às\' HH:mm', 'pt_BR').format(now)}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => _pdfHeader(title, familyName, period),
        footer: (ctx) => _pdfFooter(generatedAt, ctx),
        build: (ctx) => [
          _pdfSummary(totalIncome, totalExpense, balance),
          pw.SizedBox(height: 16),
          _pdfTable(list),
        ],
      ),
    );

    return doc;
  }

  pw.Widget _pdfHeader(String title, String familyName, String period) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Casa Prime',
                    style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800)),
                pw.SizedBox(height: 2),
                pw.Text('Gerenciamento Financeiro Familiar',
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey700)),
              ],
            ),
            pw.Text(period,
                style: pw.TextStyle(
                    fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text('Criado por Anderson Scantamburlo',
            style: const pw.TextStyle(
                fontSize: 8, color: PdfColors.grey600)),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey400),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(title,
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text('Família: $familyName',
                  style: const pw.TextStyle(fontSize: 11)),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
      ],
    );
  }

  pw.Widget _pdfFooter(String generatedAt, pw.Context ctx) {
    return pw.Container(
      alignment: pw.Alignment.centerLeft,
      margin: const pw.EdgeInsets.only(top: 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(generatedAt,
              style: const pw.TextStyle(
                  fontSize: 8, color: PdfColors.grey600)),
          pw.Text('Página ${ctx.pageNumber} / ${ctx.pagesCount}',
              style: const pw.TextStyle(
                  fontSize: 8, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  pw.Widget _pdfSummary(double inc, double exp, double bal) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('Entradas', Formatters.money(inc), PdfColors.green700),
          _summaryItem('Saídas', Formatters.money(exp), PdfColors.red700),
          _summaryItem(
            'Saldo',
            Formatters.money(bal),
            bal >= 0 ? PdfColors.blue700 : PdfColors.red700,
          ),
        ],
      ),
    );
  }

  pw.Widget _summaryItem(String label, String value, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(label,
            style: const pw.TextStyle(
                fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 4),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: color)),
      ],
    );
  }

  pw.Widget _pdfTable(List<TransactionModel> list) {
    if (list.isEmpty) {
      return pw.Center(
        child: pw.Text('Nenhum lançamento no período.',
            style: const pw.TextStyle(color: PdfColors.grey700)),
      );
    }

    return pw.TableHelper.fromTextArray(
      headers: const ['Data', 'Descrição', 'Categoria', 'Membro', 'Valor'],
      data: list.map((t) {
        final sign = t.isIncome ? '+' : '-';
        return [
          DateFormat('dd/MM/yyyy').format(t.date),
          t.description,
          t.subcategoryName != null
              ? '${t.categoryName} / ${t.subcategoryName}'
              : t.categoryName,
          t.createdByName,
          '$sign ${Formatters.money(t.amount)}',
        ];
      }).toList(),
      headerStyle: pw.TextStyle(
          fontWeight: pw.FontWeight.bold, fontSize: 10),
      headerDecoration:
          const pw.BoxDecoration(color: PdfColors.grey200),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellHeight: 22,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerLeft,
        4: pw.Alignment.centerRight,
      },
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
    );
  }

  // ============================================================
  //  CSV
  // ============================================================
  String _buildCsv(List<TransactionModel> list) {
    final buf = StringBuffer();
    // BOM UTF-8 para Excel reconhecer acentuação
    buf.write('\uFEFF');
    buf.writeln(
        'Data;Tipo;Descrição;Categoria;Subcategoria;Forma de Pagamento;Membro;Valor');
    for (final t in list) {
      buf.writeln([
        DateFormat('dd/MM/yyyy').format(t.date),
        t.isIncome ? 'Entrada' : 'Saída',
        _esc(t.description),
        _esc(t.categoryName),
        _esc(t.subcategoryName ?? ''),
        _esc(t.paymentMethod ?? ''),
        _esc(t.createdByName),
        t.amount.toStringAsFixed(2).replaceAll('.', ','),
      ].join(';'));
    }
    return buf.toString();
  }

  String _esc(String v) {
    if (v.contains(';') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }

  // Precisamos codificar como UTF-8 (o _buildCsv já colocou BOM)
  List<int> _encodeCsv(String s) {
    // O BOM já foi inserido no início da string em _buildCsv; aqui
    // apenas retornamos a string como bytes UTF-8 (o dart cuida disso).
    return s.codeUnits;
  }

  // ============================================================
  //  Compartilhar ou salvar
  // ============================================================
  Future<void> _shareOrSave({
    required Uint8List bytes,
    required String filename,
    required String mime,
  }) async {
    // Salva em pasta temporária e compartilha
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);

    // share_plus cuida de abrir a folha de compartilhamento do Android.
    // O parâmetro `files` (lista) é obrigatório na versão 12+.
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(file.path, mimeType: mime, name: filename),
        ],
        subject: 'Casa Prime — $filename',
      ),
    );
  }

  // ============================================================
  //  Impressão direta (opcional, se quiser imprimir em vez de compartilhar)
  // ============================================================
  Future<void> printPdf({
    required String familyName,
    required String title,
    required String period,
    required List<TransactionModel> list,
  }) async {
    final pdf = await _buildPdf(
      familyName: familyName,
      title: title,
      period: period,
      list: list,
    );
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  String _monthLabel(int month, int year) {
    const names = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
    ];
    return '${names[month - 1]} / $year';
  }
}
