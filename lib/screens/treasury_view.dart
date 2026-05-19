import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../providers/treasury_provider.dart';
import '../services/export_service.dart';
import 'incomes_screen.dart';
import 'expenses_screen.dart';

class TreasuryView extends StatelessWidget {
  const TreasuryView({super.key});

  @override
  Widget build(BuildContext context) {
    final treasury = Provider.of<TreasuryProvider>(context);
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      body: treasury.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dashboard Financiero',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Row(
                        children: [
                          FilledButton.icon(
                            onPressed: () async {
                              final exportService = ExportService();
                              await exportService.exportToPdf(
                                records: treasury.records,
                                totalIncome: treasury.totalIncome,
                                totalExpenses: treasury.totalExpenses,
                                balance: treasury.balance,
                              );
                            },
                            icon: const Icon(Icons.picture_as_pdf, size: 18),
                            label: const Text('Exportar PDF'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.redAccent.shade700,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: () async {
                              final exportService = ExportService();
                              await exportService.exportToCsv(records: treasury.records);
                            },
                            icon: const Icon(Icons.table_chart, size: 18),
                            label: const Text('Exportar CSV'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _buildSummaryCard(
                        context,
                        'Balance actual',
                        currencyFormat.format(treasury.balance),
                        Icons.account_balance,
                        theme.colorScheme.primary,
                        null,
                      ),
                      const SizedBox(width: 16),
                      _buildSummaryCard(
                        context,
                        'Total ingresos',
                        currencyFormat.format(treasury.totalIncome),
                        Icons.arrow_upward,
                        Colors.green,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IncomesScreen())),
                      ),
                      const SizedBox(width: 16),
                      _buildSummaryCard(
                        context,
                        'Total egresos',
                        currencyFormat.format(treasury.totalExpenses),
                        Icons.arrow_downward,
                        Colors.redAccent,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpensesScreen())),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildRecentMovements(context, treasury, currencyFormat),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 1,
                          child: _buildChart(context, treasury),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String amount, IconData icon, Color color, VoidCallback? onTapLabel) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(128)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(180),
                    ),
                  ),
                  Icon(icon, color: color),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (onTapLabel != null)
                    InkWell(
                      onTap: onTapLabel,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          'Ver total',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: color,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentMovements(BuildContext context, TreasuryProvider treasury, NumberFormat format) {
    final theme = Theme.of(context);
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
    
    final sortedRecords = List.from(treasury.records)
      ..sort((a, b) => b.date.compareTo(a.date));

    final recentRecords = sortedRecords.take(10).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(128)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Movimientos Recientes',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: recentRecords.isEmpty
                ? const Center(child: Text('No hay movimientos recientes.'))
                : ListView.separated(
                    itemCount: recentRecords.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final record = recentRecords[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: record.isIncome ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30),
                          child: Icon(
                            record.isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                            color: record.isIncome ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(record.concept, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${dateFormat.format(record.date)} • ${record.responsible}'),
                        trailing: Text(
                          '${record.isIncome ? '+' : '-'}${format.format(record.amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: record.isIncome ? Colors.green : Colors.red,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, TreasuryProvider treasury) {
    final theme = Theme.of(context);
    final double income = treasury.totalIncome;
    final double expenses = treasury.totalExpenses;
    
    if (income == 0 && expenses == 0) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(128)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('No hay datos suficientes para graficar')),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(128)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Distribución Histórica',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      color: Colors.green.shade400,
                      value: income,
                      title: 'Ingresos',
                      radius: 50,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    PieChartSectionData(
                      color: Colors.redAccent.shade200,
                      value: expenses,
                      title: 'Egresos',
                      radius: 50,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
