import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../providers/treasury_provider.dart';
import '../models/treasury_record.dart';
import '../models/financial_history.dart';
import '../services/export_service.dart';
import 'incomes_screen.dart';
import 'expenses_screen.dart';

class TreasuryView extends StatefulWidget {
  const TreasuryView({super.key});

  @override
  State<TreasuryView> createState() => _TreasuryViewState();
}

class _TreasuryViewState extends State<TreasuryView> {
  int _selectedChartTab = 0; // 0 = Ingresos, 1 = Egresos

  @override
  Widget build(BuildContext context) {
    final treasury = Provider.of<TreasuryProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      body: treasury.isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = MediaQuery.of(context).size.width;
                final isMobile = screenWidth < 700;

                final header = Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  alignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Tesorería',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onBackground,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildExportButton(
                          label: 'Exportar PDF',
                          icon: Icons.picture_as_pdf,
                          color: Colors.redAccent.shade700,
                          onTap: () async {
                            // Show a loading indicator
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Row(
                                    children: [
                                      CircularProgressIndicator(color: Colors.white),
                                      SizedBox(width: 16),
                                      Text('Generando documento...'),
                                    ],
                                  ),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }

                            final exportService = ExportService();
                            await exportService.exportToPdf(
                              records: treasury.records,
                              totalIncome: treasury.totalIncome,
                              totalExpenses: treasury.totalExpenses,
                              balance: treasury.balance,
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildExportButton(
                          label: 'Exportar CSV',
                          icon: Icons.table_chart,
                          color: Colors.green.shade700,
                          onTap: () async {
                            // Show a loading indicator
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Row(
                                    children: [
                                      CircularProgressIndicator(color: Colors.white),
                                      SizedBox(width: 16),
                                      Text('Generando documento...'),
                                    ],
                                  ),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }

                            final exportService = ExportService();
                            await exportService.exportToCsv(records: treasury.records);
                          },
                        ),
                      ],
                    ),
                  ],
                );

                // Tarjeta de Balance General (Centrada y Destacada en la parte superior)
                final balanceCard = Center(
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Card(
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            colors: isDark
                                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                                : [Colors.white, const Color(0xFFF1F5F9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.03),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Balance actual',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                currencyFormat.format(treasury.balance),
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.onSurface,
                                  letterSpacing: -1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.account_balance, size: 14, color: theme.colorScheme.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Fondo total disponible',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );

                // Tarjetas de Ingresos y Egresos Lado a Lado
                final incomeExpenseRow = isMobile
                    ? Column(
                        children: [
                          _buildFinancialCard(
                            context,
                            title: 'Ingresos',
                            amount: currencyFormat.format(treasury.totalIncome),
                            icon: Icons.arrow_upward_rounded,
                            color: Colors.green,
                            isIncome: true,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IncomesScreen())),
                          ),
                          const SizedBox(height: 12),
                          _buildFinancialCard(
                            context,
                            title: 'Egresos',
                            amount: currencyFormat.format(treasury.totalExpenses),
                            icon: Icons.arrow_downward_rounded,
                            color: Colors.redAccent,
                            isIncome: false,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpensesScreen())),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _buildFinancialCard(
                              context,
                              title: 'Ingresos',
                              amount: currencyFormat.format(treasury.totalIncome),
                              icon: Icons.arrow_upward_rounded,
                              color: Colors.green,
                              isIncome: true,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IncomesScreen())),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildFinancialCard(
                              context,
                              title: 'Egresos',
                              amount: currencyFormat.format(treasury.totalExpenses),
                              icon: Icons.arrow_downward_rounded,
                              color: Colors.redAccent,
                              isIncome: false,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpensesScreen())),
                            ),
                          ),
                        ],
                      );

                // Panel Analítico: Dos Gráficas Premium y Lista de Movimientos
                final bodyContent = isMobile
                    ? Column(
                        children: [
                          _buildChartCard1(context, treasury),
                          const SizedBox(height: 16),
                          _buildChartCard2(context, treasury),
                          const SizedBox(height: 24),
                          _buildRecentMovements(context, treasury, currencyFormat, isMobile: true),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 11,
                            child: Column(
                              children: [
                                _buildChartCard1(context, treasury),
                                const SizedBox(height: 16),
                                _buildChartCard2(context, treasury),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 10,
                            child: _buildRecentMovements(context, treasury, currencyFormat, isMobile: false),
                          ),
                        ],
                      );

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        header,
                        const SizedBox(height: 24),
                        balanceCard,
                        const SizedBox(height: 16),
                        incomeExpenseRow,
                        const SizedBox(height: 28),
                        bodyContent,
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // Tarjeta Financiera para Ingresos y Egresos (Premium minimalista con HSL)
  Widget _buildFinancialCard(
    BuildContext context, {
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
    required bool isIncome,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final softColor = isIncome
        ? (isDark ? const Color(0xFF1B3B2B) : const Color(0xFFE8F5E9))
        : (isDark ? const Color(0xFF4C2222) : const Color(0xFFFFEBEE));
    final contentColor = isIncome ? Colors.green.shade700 : Colors.red.shade700;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.02),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isIncome
              ? Colors.green.withOpacity(0.15)
              : Colors.red.withOpacity(0.15),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          color: softColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isIncome
                          ? Colors.green.withOpacity(0.2)
                          : Colors.redAccent.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: isIncome ? Colors.green : Colors.redAccent, size: 16),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 10, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  amount,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : contentColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Gráfica 1 — Filtrable (Selector Ingresos/Egresos) en Card Premium
  Widget _buildChartCard1(BuildContext context, TreasuryProvider treasury) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final displayRecords = _selectedChartTab == 0 ? treasury.incomes : treasury.expenses;
    final sortedSelected = List<TreasuryRecord>.from(displayRecords)
      ..sort((a, b) => a.date.compareTo(b.date)); // Orden cronológico (más antiguo a más nuevo)
    
    final lastSix = sortedSelected.length > 6
        ? sortedSelected.sublist(sortedSelected.length - 6)
        : sortedSelected;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.02),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Detalle de Movimientos',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildChartTabButton(0, 'Ingresos'),
                    const SizedBox(width: 8),
                    _buildChartTabButton(1, 'Egresos'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildChart1(context, lastSix, _selectedChartTab == 0),
          ],
        ),
      ),
    );
  }

  Widget _buildChartTabButton(int index, String label) {
    final theme = Theme.of(context);
    final isSelected = _selectedChartTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedChartTab = index;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (index == 0 ? Colors.green.withOpacity(0.15) : Colors.redAccent.withOpacity(0.15))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (index == 0 ? Colors.green : Colors.redAccent)
                : theme.colorScheme.outlineVariant.withAlpha(80),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? (index == 0 ? Colors.green.shade700 : Colors.redAccent.shade700)
                : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildChart1(BuildContext context, List<TreasuryRecord> displayRecords, bool isIncome) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (displayRecords.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        child: Text(
          'Sin movimientos de ${isIncome ? "ingresos" : "egresos"} para graficar',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    double maxVal = 0.0;
    for (final r in displayRecords) {
      if (r.amount > maxVal) maxVal = r.amount;
    }
    final maxY = maxVal > 0 ? maxVal * 1.15 : 100.0;

    final barGroups = List.generate(displayRecords.length, (index) {
      final r = displayRecords[index];
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: r.amount,
            color: isIncome ? Colors.green.shade400 : Colors.redAccent.shade200,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY,
              color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
            ),
          ),
        ],
      );
    });

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => isDark ? const Color(0xFF1E293B) : Colors.white,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final record = displayRecords[group.x];
                return BarTooltipItem(
                  '${record.concept}\n\$${NumberFormat("#,##0.00").format(rod.toY)}',
                  TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < displayRecords.length) {
                    final r = displayRecords[index];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('dd/MM').format(r.date),
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                getTitlesWidget: (value, meta) {
                  if (value == maxY || value == 0) return const SizedBox();
                  return Text(
                    '\$${NumberFormat.compact().format(value)}',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
        ),
      ),
    );
  }

  // Gráfica 2 — Balance General (Tendencia en formato LineChart con puntos coloreados dinámicamente)
  Widget _buildChartCard2(BuildContext context, TreasuryProvider treasury) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    if (treasury.records.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04)),
        ),
        child: const SizedBox(
          height: 260,
          child: Center(
            child: Text(
              'No hay datos suficientes para graficar el balance general',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }

    // Ordenar cronológicamente (antiguo a nuevo)
    final sortedRecords = List<TreasuryRecord>.from(treasury.records)
      ..sort((a, b) => a.date.compareTo(b.date));

    double runningBalance = 0.0;
    final List<Map<String, dynamic>> points = [];
    for (final r in sortedRecords) {
      if (r.isIncome) {
        runningBalance += r.amount;
      } else {
        runningBalance -= r.amount;
      }
      points.add({
        'date': r.date,
        'balance': runningBalance,
        'record': r,
      });
    }

    // Tomar los últimos 8 puntos para evitar saturación y conservar legibilidad
    final displayPoints = points.length > 8
        ? points.sublist(points.length - 8)
        : points;

    final spots = List.generate(displayPoints.length, (index) {
      return FlSpot(index.toDouble(), displayPoints[index]['balance'] as double);
    });

    double minY = double.infinity;
    double maxY = -double.infinity;
    for (final pt in displayPoints) {
      final bal = pt['balance'] as double;
      if (bal < minY) minY = bal;
      if (bal > maxY) maxY = bal;
    }
    
    final margin = (maxY - minY).abs() * 0.15;
    final chartMinY = minY - (margin > 0 ? margin : 10.0);
    final chartMaxY = maxY + (margin > 0 ? margin : 10.0);
    final primaryColor = theme.colorScheme.primary;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.02),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balance General (Tendencia)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Evolución del balance acumulado con indicador de transacciones',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (displayPoints.length - 1).toDouble(),
                  minY: chartMinY,
                  maxY: chartMaxY,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => isDark ? const Color(0xFF1E293B) : Colors.white,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((touchedSpot) {
                          final index = touchedSpot.spotIndex;
                          final point = displayPoints[index];
                          final record = point['record'] as TreasuryRecord;
                          final formattedBalance = currencyFormat.format(point['balance']);
                          final formattedAmount = currencyFormat.format(record.amount);
                          final sign = record.isIncome ? '+' : '-';
                          
                          return LineTooltipItem(
                            '${record.concept}\n${record.isIncome ? "Ingreso" : "Egreso"}: $sign$formattedAmount\nBalance: $formattedBalance',
                            TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < displayPoints.length) {
                            final date = displayPoints[index]['date'] as DateTime;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('dd/MM').format(date),
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 55,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              '\$${NumberFormat.compact().format(value)}',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.end,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 3.5,
                      color: primaryColor,
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withOpacity(0.2),
                            primaryColor.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          final record = displayPoints[index]['record'] as TreasuryRecord;
                          final isIncome = record.isIncome;
                          final Color dotColor = isIncome ? Colors.green : Colors.redAccent;
                          
                          return FlDotCirclePainter(
                            radius: 5,
                            color: dotColor,
                            strokeColor: isDark ? const Color(0xFF1F2937) : Colors.white,
                            strokeWidth: 2,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.green, 'Ingresos'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.redAccent, 'Egresos'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  // Lista Premium de Movimientos Recientes en Contenedor Unificado (Igual a Actividad Reciente en Admin)
  Widget _buildRecentMovements(BuildContext context, TreasuryProvider treasury, NumberFormat format, {required bool isMobile}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sortedHistory = List<FinancialHistory>.from(treasury.financialHistory)
      ..sort((a, b) => b.date.compareTo(a.date));
    final recentHistory = sortedHistory.take(10).toList();

    Widget listViewContent;

    if (recentHistory.isEmpty) {
      listViewContent = Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 40,
              color: isDark ? Colors.white30 : Colors.black38,
            ),
            const SizedBox(height: 12),
            Text(
              'No hay movimientos recientes',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else {
      listViewContent = Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2C) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
          ),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          physics: isMobile ? const NeverScrollableScrollPhysics() : null,
          itemCount: recentHistory.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
          ),
          itemBuilder: (context, index) {
            final fh = recentHistory[index];
            final isIncome = fh.action.toLowerCase().contains('ingreso');

            // Extraer concepto y monto del detalle
            String concept = '';
            double amount = 0.0;

            final conceptMatch = RegExp(r'Concepto:\s*(.*)$').firstMatch(fh.details);
            if (conceptMatch != null) {
              concept = conceptMatch.group(1)?.trim() ?? '';
            }
            if (concept.isEmpty) {
              concept = fh.action;
            }

            final amountMatch = RegExp(r'Monto:\s*\$?([\d\.,]+)').firstMatch(fh.details);
            if (amountMatch != null) {
              final cleanedAmount = amountMatch.group(1)?.replaceAll(',', '') ?? '0';
              amount = double.tryParse(cleanedAmount) ?? 0.0;
            }

            // Generar título descriptivo dinámico
            String displayTitle = '';
            if (fh.action.toLowerCase().contains('modificado')) {
              displayTitle = '${isIncome ? 'Ingreso' : 'Egreso'} modificado: $concept';
            } else if (fh.action.toLowerCase().contains('eliminado')) {
              displayTitle = '${isIncome ? 'Ingreso' : 'Egreso'} eliminado: $concept';
            } else {
              displayTitle = concept;
            }

            final Color themeColor = isIncome ? Colors.green : Colors.redAccent;
            final IconData icon = isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

            final iconBgColor = isDark
                ? themeColor.withOpacity(0.15)
                : themeColor.withOpacity(0.1);

            // Buscar registro activo en tiempo real
            final recordsMatching = treasury.records.where((r) => r.id == fh.recordId);
            final TreasuryRecord? activeRecord = recordsMatching.isNotEmpty ? recordsMatching.first : null;

            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: themeColor,
                  size: 18,
                ),
              ),
              title: Text(
                displayTitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onBackground,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  '${DateFormat('dd/MM/yyyy').format(fh.date)} • ${_capitalize(fh.responsible)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              trailing: Text(
                '${isIncome ? '+' : '-'}${format.format(amount)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: themeColor,
                ),
              ),
              onTap: () {
                if (activeRecord != null) {
                  _showTreasuryDetailDialog(context, activeRecord);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Este movimiento ha sido eliminado y no se puede visualizar el detalle.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            );
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Movimientos Recientes',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 16),
        isMobile ? listViewContent : Expanded(child: listViewContent),
      ],
    );
  }

  void _showTreasuryDetailDialog(BuildContext context, TreasuryRecord record) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: record.isIncome
                          ? Colors.green.withOpacity(0.12)
                          : Colors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          record.isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                          color: record.isIncome ? Colors.green : Colors.red,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          record.isIncome ? 'Ingreso' : 'Egreso',
                          style: TextStyle(
                            color: record.isIncome ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Detalle de Transacción',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
              const Divider(height: 24),
              _buildDetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Fecha:',
                value: dateFormat.format(record.date),
                theme: theme,
              ),
              const SizedBox(height: 14),
              _buildDetailRow(
                icon: Icons.text_fields,
                label: 'Concepto:',
                value: record.concept,
                theme: theme,
              ),
              const SizedBox(height: 14),
              _buildDetailRow(
                icon: Icons.attach_money,
                label: 'Monto:',
                value: currencyFormat.format(record.amount),
                theme: theme,
                textColor: record.isIncome ? Colors.green.shade700 : Colors.red.shade700,
              ),
              const SizedBox(height: 14),
              _buildDetailRow(
                icon: Icons.description_outlined,
                label: 'Descripción:',
                value: record.description.isNotEmpty ? record.description : 'Sin descripción',
                theme: theme,
              ),
              const SizedBox(height: 14),
              _buildDetailRow(
                icon: Icons.person_outline,
                label: 'Responsable:',
                value: record.responsible,
                theme: theme,
              ),
              const SizedBox(height: 14),
              _buildDetailRow(
                icon: Icons.info_outline,
                label: 'Nota:',
                value: record.notes != null && record.notes!.isNotEmpty ? record.notes! : 'Sin nota',
                theme: theme,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: record.isIncome ? Colors.green : Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
    Color? textColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor ?? theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExportButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: isMobile ? 16 : 18),
      label: Text(
        label,
        style: TextStyle(
          fontSize: isMobile ? 13 : 14,
        ),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        padding: isMobile
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
