import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/treasury_provider.dart';
import '../providers/auth_provider.dart';
import '../models/treasury_record.dart';
import 'package:uuid/uuid.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final treasury = Provider.of<TreasuryProvider>(context);
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Egresos'),
        backgroundColor: Colors.red.shade50,
      ),
      body: treasury.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: Colors.red.shade100,
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Text('Total Egresos', style: theme.textTheme.titleMedium?.copyWith(color: Colors.red.shade900)),
                          Text(currencyFormat.format(treasury.totalExpenses), style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.red.shade900)),
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
                              DataColumn(label: Text('Fecha')),
                              DataColumn(label: Text('Concepto')),
                              DataColumn(label: Text('Monto')),
                              DataColumn(label: Text('Descripción / Motivo')),
                              DataColumn(label: Text('Responsable')),
                              DataColumn(label: Text('Nota')),
                              DataColumn(label: Text('Acciones')),
                            ],
                            rows: treasury.expenses.map((expense) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(dateFormat.format(expense.date))),
                                  DataCell(Text(expense.concept)),
                                  DataCell(Text(currencyFormat.format(expense.amount), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                                  DataCell(Text(expense.description)),
                                  DataCell(Text(expense.responsible)),
                                  DataCell(Text(expense.notes ?? '-')),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () {
                                        final auth = Provider.of<AuthProvider>(context, listen: false);
                                        treasury.deleteRecord(expense.id, auth.currentUser?.name ?? 'Desconocido');
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
        onPressed: () => _showAddExpenseDialog(context),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Registrar Egreso'),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final conceptCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController();
    final responsibleCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Registrar Egreso'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: conceptCtrl, decoration: const InputDecoration(labelText: 'Concepto')),
                TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Monto'), keyboardType: TextInputType.number),
                TextField(controller: descriptionCtrl, decoration: const InputDecoration(labelText: 'Descripción y motivo del gasto')),
                TextField(controller: responsibleCtrl, decoration: const InputDecoration(labelText: 'Responsable (Opcional)')),
                TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Nota (Opcional)')),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Fecha: '),
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
                      child: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
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
                    notes: noteCtrl.text.isEmpty ? null : noteCtrl.text,
                    isIncome: false,
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
