import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // Para detectar si corre en Web
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/treasury_record.dart';

class ExportService {
  final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final dateFormat = DateFormat('dd/MM/yyyy');

  Future<void> exportToPdf({
    required List<TreasuryRecord> records,
    required double totalIncome,
    required double totalExpenses,
    required double balance,
  }) async {
    final doc = pw.Document();

    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(now);

    // Order records by date descending
    final sortedRecords = List<TreasuryRecord>.from(records)
      ..sort((a, b) => b.date.compareTo(a.date));

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Nohoch App',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Reporte Financiero de Tesorería', style: const pw.TextStyle(fontSize: 14)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Fecha de emisión:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(dateStr),
                  ],
                ),
              ],
            ),
            pw.Divider(color: PdfColors.grey400, thickness: 1, height: 32),

            // Summary
            pw.Text(
              'Resumen Financiero',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
            ),
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryBox('Balance General', balance, PdfColors.blue800),
                _buildSummaryBox('Ingresos', totalIncome, PdfColors.green700),
                _buildSummaryBox('Egresos', totalExpenses, PdfColors.red700),
              ],
            ),
            pw.SizedBox(height: 32),

            // Table
            pw.Text(
              'Detalle de Movimientos',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
            ),
            pw.SizedBox(height: 16),
            
            pw.TableHelper.fromTextArray(
              context: context,
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headers: ['Fecha', 'Tipo', 'Concepto', 'Responsable', 'Monto'],
              data: sortedRecords.map((record) {
                return [
                  dateFormat.format(record.date),
                  record.isIncome ? 'Ingreso' : 'Egreso',
                  record.concept,
                  record.responsible,
                  '${record.isIncome ? '+' : '-'}${currencyFormat.format(record.amount)}',
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    // Use printing to display/share PDF
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'Reporte_Financiero_Nohoch_${DateFormat('yyyyMMdd').format(now)}.pdf',
    );
  }

  pw.Widget _buildSummaryBox(String title, double amount, PdfColor color) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(
            currencyFormat.format(amount),
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Future<void> exportToCsv({
    required List<TreasuryRecord> records,
  }) async {
    final sortedRecords = List<TreasuryRecord>.from(records)
      ..sort((a, b) => b.date.compareTo(a.date));

    List<List<dynamic>> rows = [];
    
    // Headers
    rows.add([
      'Fecha',
      'Tipo',
      'Concepto',
      'Monto',
      'Responsable',
      'Descripción/Notas',
    ]);

    // Data
    for (var record in sortedRecords) {
      rows.add([
        dateFormat.format(record.date),
        record.isIncome ? 'Ingreso' : 'Egreso',
        record.concept,
        record.amount,
        record.responsible,
        record.description,
      ]);
    }

    String csvData = csv.encode(rows);

    final now = DateTime.now();
    final filename = 'Reporte_Tesoreria_${DateFormat('yyyyMMdd').format(now)}.csv';
    final bytes = [0xEF, 0xBB, 0xBF] + utf8.encode(csvData);

    // Control seguro si estás probando en Microsoft Edge / Web
    if (kIsWeb) {
      await Share.share(csvData, subject: 'Reporte CSV de Tesorería - Nohoch');
      return;
    }

    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(bytes);
      
      await Share.shareXFiles(
        [XFile(file.path)], 
        text: 'Reporte CSV de Tesorería - Nohoch',
      );
    } catch (e) {
      await Share.share(csvData, subject: 'Reporte CSV de Tesorería - Nohoch');
    }
  }
}