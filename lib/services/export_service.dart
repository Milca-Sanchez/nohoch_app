import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // Para detectar si corre en Web
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;

import '../models/treasury_record.dart';
import '../models/inventory_item.dart';
import '../models/inventory_category.dart';

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

    final bytes = await doc.save();
    final filename = 'Reporte_Financiero_Nohoch_${DateFormat('yyyyMMdd').format(now)}.pdf';

    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", filename)
        ..click();
      html.Url.revokeObjectUrl(url);
      return;
    }

    // Use printing to display/share PDF
    await Printing.sharePdf(
      bytes: bytes,
      filename: filename,
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
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", filename)
        ..click();
      html.Url.revokeObjectUrl(url);
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
      if (kIsWeb) {
        // Fallback redundante por seguridad
        await Share.share(csvData, subject: 'Reporte CSV de Tesorería - Nohoch');
      }
    }
  }

  Future<void> exportInventoryToPdf({
    required List<InventoryItem> items,
    required List<InventoryCategory> categories,
    required bool onlyLowStock,
  }) async {
    final doc = pw.Document();
    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(now);

    // Filter items based on criteria
    final filteredItems = onlyLowStock
        ? items.where((item) {
            final cat = categories.firstWhere((c) => c.id == item.categoryId, orElse: () => categories.first);
            return item.quantity < cat.lowStockThreshold;
          }).toList()
        : items;

    // Sort items by name
    filteredItems.sort((a, b) => a.name.compareTo(b.name));

    // Group items by category
    final Map<String, List<InventoryItem>> groupedItems = {};
    for (var cat in categories) {
      final catItems = filteredItems.where((i) => i.categoryId == cat.id).toList();
      if (catItems.isNotEmpty) {
        groupedItems[cat.id] = catItems;
      }
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          final content = <pw.Widget>[];

          // Header
          content.add(
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
                    pw.Text(
                      onlyLowStock
                          ? 'Reporte de Inventario - Materiales en Bajo Stock'
                          : 'Reporte de Inventario - Todos los Materiales',
                      style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Fecha de emisión:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text(dateStr, style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
          );

          content.add(pw.Divider(color: PdfColors.grey400, thickness: 1, height: 24));

          // Summary stats
          content.add(
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildInventoryStatBox('Total Categorías', '${groupedItems.keys.length}', PdfColors.blueGrey800),
                _buildInventoryStatBox('Total Artículos Diferentes', '${filteredItems.length}', PdfColors.blue800),
                _buildInventoryStatBox(
                  'Cantidad Total de Stock',
                  '${filteredItems.fold<int>(0, (sum, i) => sum + i.quantity)}',
                  onlyLowStock ? PdfColors.orange800 : PdfColors.green800,
                ),
              ],
            ),
          );

          content.add(pw.SizedBox(height: 24));

          if (groupedItems.isEmpty) {
            content.add(
              pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 40),
                  child: pw.Text(
                    'No hay materiales que coincidan con los filtros seleccionados.',
                    style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600),
                  ),
                ),
              ),
            );
          } else {
            // Group sections
            for (var entry in groupedItems.entries) {
              final catId = entry.key;
              final catItems = entry.value;
              final category = categories.firstWhere((c) => c.id == catId);

              // Sub-header for Category
              content.add(
                pw.Container(
                  margin: const pw.EdgeInsets.only(top: 16, bottom: 8),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        category.name.toUpperCase(),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                      pw.Text(
                        'Artículos: ${catItems.length}',
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ),
              );

              // Category items table
              content.add(
                pw.TableHelper.fromTextArray(
                  context: context,
                  cellAlignment: pw.Alignment.centerLeft,
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3), // Nombre
                    1: const pw.FlexColumnWidth(1), // Cantidad
                    2: const pw.FlexColumnWidth(1.2), // Estado
                    3: const pw.FlexColumnWidth(1.8), // Ubicación
                    4: const pw.FlexColumnWidth(2), // Actualizado
                  },
                  headers: ['Nombre del Material', 'Cantidad', 'Estado', 'Ubicación', 'Último Movimiento'],
                  data: catItems.map((item) {
                    final isLow = item.quantity < category.lowStockThreshold;
                    return [
                      item.name,
                      '${item.quantity}${isLow ? ' (Bajo Stock)' : ''}',
                      item.status,
                      item.location.isNotEmpty ? item.location : 'Sin ubicación',
                      dateFormat.format(item.lastUpdateDate),
                    ];
                  }).toList(),
                ),
              );
              
              content.add(pw.SizedBox(height: 12));
            }
          }

          return content;
        },
      ),
    );

    // Save and share
    final prefix = onlyLowStock ? 'Reporte_BajoStock_Nohoch_' : 'Reporte_Inventario_Nohoch_';
    final bytes = await doc.save();
    final filename = '$prefix${DateFormat('yyyyMMdd').format(now)}.pdf';

    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", filename)
        ..click();
      html.Url.revokeObjectUrl(url);
      return;
    }

    await Printing.sharePdf(
      bytes: bytes,
      filename: filename,
    );
  }

  pw.Widget _buildInventoryStatBox(String title, String value, PdfColor color) {
    return pw.Container(
      width: 160,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Future<void> exportInventoryToCsv({
    required List<InventoryItem> items,
    required List<InventoryCategory> categories,
    required bool onlyLowStock,
  }) async {
    // Filter items based on criteria
    final filteredItems = onlyLowStock
        ? items.where((item) {
            final cat = categories.firstWhere((c) => c.id == item.categoryId, orElse: () => categories.first);
            return item.quantity < cat.lowStockThreshold;
          }).toList()
        : items;

    // Sort items by name
    filteredItems.sort((a, b) => a.name.compareTo(b.name));

    List<List<dynamic>> rows = [];

    // Headers
    rows.add([
      'Categoría',
      'Nombre del Material',
      'Cantidad',
      'Estado',
      'Ubicación',
      'Descripción',
      'Fecha de Registro',
      'Último Movimiento',
    ]);

    // Data
    for (var item in filteredItems) {
      final category = categories.firstWhere((c) => c.id == item.categoryId, orElse: () => categories.first);
      rows.add([
        category.name,
        item.name,
        item.quantity,
        item.status,
        item.location,
        item.description,
        dateFormat.format(item.registrationDate),
        dateFormat.format(item.lastUpdateDate),
      ]);
    }

    String csvData = csv.encode(rows);

    final now = DateTime.now();
    final prefix = onlyLowStock ? 'Inventario_BajoStock_' : 'Inventario_Completo_';
    final filename = '$prefix${DateFormat('yyyyMMdd').format(now)}.csv';
    final bytes = [0xEF, 0xBB, 0xBF] + utf8.encode(csvData);

    // Control seguro si estás probando en Microsoft Edge / Web
    if (kIsWeb) {
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", filename)
        ..click();
      html.Url.revokeObjectUrl(url);
      return;
    }

    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(bytes);
      
      await Share.shareXFiles(
        [XFile(file.path)], 
        text: 'Reporte CSV de Inventario - Nohoch',
      );
    } catch (e) {
      if (kIsWeb) {
        await Share.share(csvData, subject: 'Reporte CSV de Inventario - Nohoch');
      }
    }
  }
}