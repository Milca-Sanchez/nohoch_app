import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/treasury_provider.dart';
import '../providers/auth_provider.dart';
import '../models/treasury_record.dart';
import 'package:uuid/uuid.dart';

class IncomesScreen extends StatelessWidget {
  const IncomesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final treasury = Provider.of<TreasuryProvider>(context);
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final monthFormat = DateFormat('MMMM', 'es'); // Requiere locale 'es' si está configurado, o por defecto

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingresos'),
        backgroundColor: Colors.green.shade50,
      ),
      body: treasury.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: Colors.green.shade100,
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Text('Total Ingresos', style: theme.textTheme.titleMedium?.copyWith(color: Colors.green.shade900)),
                          Text(currencyFormat.format(treasury.totalIncome), style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.green.shade900)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(128)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView(
                        children: [
                          DataTable(
                            headingTextStyle: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            columns: const [
                              DataColumn(label: Text('Mes')),
                              DataColumn(label: Text('Concepto')),
                              DataColumn(label: Text('Monto')),
                              DataColumn(label: Text('Descripción')),
                              DataColumn(label: Text('Responsable')),
                              DataColumn(label: Text('Acciones')),
                            ],
                            rows: treasury.incomes.map((income) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(monthFormat.format(income.date).toUpperCase())),
                                  DataCell(Text(income.concept)),
                                  DataCell(Text(currencyFormat.format(income.amount), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                                  DataCell(Text(income.description)),
                                  DataCell(Text(income.responsible)),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () {
                                        final auth = Provider.of<AuthProvider>(context, listen: false);
                                        treasury.deleteRecord(income.id, auth.currentUser?.name ?? 'Desconocido');
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddIncomeDialog(context),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Registrar Ingreso'),
      ),
    );
  }

  void _showAddIncomeDialog(BuildContext context) {
    final conceptCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController();
    final responsibleCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Registrar Ingreso'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: conceptCtrl, decoration: const InputDecoration(labelText: 'Concepto')),
                TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Monto'), keyboardType: TextInputType.number),
                TextField(controller: descriptionCtrl, decoration: const InputDecoration(labelText: 'Descripción')),
                TextField(controller: responsibleCtrl, decoration: const InputDecoration(labelText: 'Responsable (Opcional)')),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Mes: '),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setState(() => selectedDate = date);
                        }
                      },
                      child: Text(DateFormat('MMMM yyyy', 'es').format(selectedDate)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountCtrl.text);
                if (amount != null && amount > 0 && conceptCtrl.text.isNotEmpty) {
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  final responsibleName = responsibleCtrl.text.isEmpty 
                      ? (auth.currentUser?.name ?? 'Admin') 
                      : responsibleCtrl.text;
                  
                  final record = TreasuryRecord(
                    id: const Uuid().v4(),
                    concept: conceptCtrl.text,
                    amount: amount,
                    date: selectedDate,
                    description: descriptionCtrl.text,
                    responsible: responsibleName,
                    isIncome: true,
                  );
                  Provider.of<TreasuryProvider>(context, listen: false).addRecord(record, auth.currentUser?.name ?? 'Admin');
                  Navigator.pop(context);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
