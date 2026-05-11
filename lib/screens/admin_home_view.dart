import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/inventory_provider.dart';
import '../providers/treasury_provider.dart';

class AdminHomeView extends StatelessWidget {
  final Function(int) onNavigate;

  const AdminHomeView({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context);
    final treasury = Provider.of<TreasuryProvider>(context);
    final theme = Theme.of(context);

    // Calculate metrics
    final totalProducts = inventory.items.fold<int>(0, (sum, item) => sum + item.quantity);
    final lowStockProducts = inventory.items.where((i) => i.quantity <= 5).length;
    final currentBalance = treasury.balance;
    
    final now = DateTime.now();
    final todaysMovements = treasury.records.where((r) => 
      r.date.year == now.year && r.date.month == now.month && r.date.day == now.day
    ).length;

    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Centro de Control',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Resumen general del sistema',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // 1. RESUMEN RÁPIDO (PARTE SUPERIOR)
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 600;
              final crossAxisCount = isSmallScreen ? 2 : 4;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.5,
                children: [
                  _buildSummaryCard(
                    context,
                    title: 'Productos',
                    value: totalProducts.toString(),
                    icon: Icons.inventory_2_outlined,
                    color: Colors.blue,
                  ),
                  _buildSummaryCard(
                    context,
                    title: 'Bajo stock',
                    value: lowStockProducts.toString(),
                    icon: Icons.warning_amber_rounded,
                    color: Colors.orange,
                  ),
                  _buildSummaryCard(
                    context,
                    title: 'Balance',
                    value: currencyFormat.format(currentBalance),
                    icon: Icons.account_balance_wallet_outlined,
                    color: Colors.green,
                  ),
                  _buildSummaryCard(
                    context,
                    title: 'Movimientos hoy',
                    value: todaysMovements.toString(),
                    icon: Icons.trending_up,
                    color: Colors.purple,
                  ),
                ],
              );
            }
          ),
          
          const SizedBox(height: 40),

          // 2. CONTENIDO CENTRAL PRINCIPAL
          Text(
            'Módulos Principales',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 600;
              final children = [
                Expanded(
                  flex: isSmallScreen ? 0 : 1,
                  child: _buildModuleCard(
                    context,
                    title: 'Inventario',
                    description: 'Administra productos, stock y movimientos',
                    icon: Icons.inventory_2_rounded,
                    color: Colors.blue,
                    onTap: () => onNavigate(1),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 0 : 24, height: isSmallScreen ? 16 : 0),
                Expanded(
                  flex: isSmallScreen ? 0 : 1,
                  child: _buildModuleCard(
                    context,
                    title: 'Tesorería',
                    description: 'Controla ingresos, egresos y balance',
                    icon: Icons.account_balance_wallet_rounded,
                    color: Colors.green,
                    onTap: () => onNavigate(2),
                  ),
                ),
              ];
              
              if (isSmallScreen) {
                return Column(
                  children: children.whereType<Expanded>().map((e) => e.child).toList()
                    ..insert(1, const SizedBox(height: 16)),
                );
              } else {
                return Row(
                  children: children,
                );
              }
            }
          ),

          const SizedBox(height: 40),

          // 3. ACTIVIDAD RECIENTE (OPCIONAL)
          Text(
            'Actividad reciente',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildRecentActivity(context, treasury),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(BuildContext context, {required String title, required String description, required IconData icon, required Color color, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 48, color: color),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  'Ir a $title',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: color, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, TreasuryProvider treasury) {
    final theme = Theme.of(context);
    
    // Tomar los últimos 5 registros de tesorería como actividad reciente (simplificación)
    final recentRecords = List.from(treasury.records)
      ..sort((a, b) => b.date.compareTo(a.date));
      
    final displayRecords = recentRecords.take(5).toList();

    if (displayRecords.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'No hay actividad reciente',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: displayRecords.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final record = displayRecords[index];
          final isIncome = record.isIncome;
          
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: isIncome ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              child: Icon(
                isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                color: isIncome ? Colors.green : Colors.red,
              ),
            ),
            title: Text(
              record.concept,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              DateFormat('dd MMM yyyy, HH:mm').format(record.date),
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
            ),
            trailing: Text(
              '${isIncome ? '+' : '-'}${currencyFormat.format(record.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isIncome ? Colors.green : Colors.red,
                fontSize: 16,
              ),
            ),
          );
        },
      ),
    );
  }
}
