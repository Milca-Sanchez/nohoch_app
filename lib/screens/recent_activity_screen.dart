import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/inventory_provider.dart';
import '../providers/treasury_provider.dart';
import '../providers/theme_provider.dart';
import '../models/inventory_category.dart';
import '../models/inventory_history.dart';
import '../models/treasury_record.dart';
import 'low_stock_screen.dart';
import 'item_detail_screen.dart';

class RecentActivityScreen extends StatelessWidget {
  final Function(int) onNavigate;
  final bool onlyToday;

  const RecentActivityScreen({
    super.key,
    required this.onNavigate,
    this.onlyToday = false,
  });



  // Determinar el responsable de la modificación del inventario
  String _getInventoryResponsible(InventoryHistory history) {
    final actionLower = history.action.toLowerCase();
    final detailsLower = (history.details ?? '').toLowerCase();
    
    if (actionLower.contains('por administrador') || actionLower.contains('por admin') ||
        detailsLower.contains('por administrador') || detailsLower.contains('por admin') ||
        actionLower.contains('por administrado') || detailsLower.contains('por administrado')) {
      return 'admin';
    }
    
    final porMatch = RegExp(r'por\s+([a-zA-ZáéíóúÁÉÍÓÚñÑ]+)').firstMatch(history.action);
    if (porMatch != null) {
      final user = porMatch.group(1)!.toLowerCase();
      if (user == 'administrador' || user == 'admin' || user.contains('admin')) {
        return 'admin';
      }
    }
    
    return 'inventario';
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // Mostrar un diálogo de detalle de inventario sumamente premium y visual, similar al de tesorería
  void _showInventoryDetailDialog(BuildContext context, InventoryHistory history, InventoryProvider inventory) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd/MM/yyyy • hh:mm a');

    final itemsMatching = inventory.items.where((i) => i.id == history.itemId);
    String itemName = itemsMatching.isNotEmpty ? itemsMatching.first.name : 'Artículo';
    if (itemsMatching.isEmpty && history.action.startsWith('🗑')) {
      final parts = history.action.split(' ');
      if (parts.length >= 2) {
        itemName = parts.sublist(1, parts.length - 1).join(' ');
      }
    }
    
    // Calcular el cambio / cantidad de stock
    String trailingVal = '';
    final actionLower = history.action.toLowerCase();
    if (history.action.startsWith('🗑')) {
      if (history.oldQuantity != null) {
        trailingVal = '-${history.oldQuantity}';
      }
    } else if (actionLower.contains('agregado') || actionLower.contains('registro inicial')) {
      if (history.newQuantity != null) {
        trailingVal = '+${history.newQuantity}';
      }
    } else if (actionLower.contains('eliminado')) {
      if (history.oldQuantity != null) {
        trailingVal = '-${history.oldQuantity}';
      }
    } else {
      if (history.oldQuantity != null && history.newQuantity != null) {
        final diff = history.newQuantity! - history.oldQuantity!;
        trailingVal = diff >= 0 ? '+$diff' : '$diff';
      }
    }

    final responsible = _capitalize(_getInventoryResponsible(history));

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
              // Fila superior con etiqueta
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE65C00).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          color: Color(0xFFE65C00),
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Inventario',
                          style: TextStyle(
                            color: Color(0xFFE65C00),
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
              // Título / Nombre del artículo
              Text(
                itemName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              if (trailingVal.isNotEmpty) ...[
                const SizedBox(height: 8),
                // Cantidad destacada
                Text(
                  trailingVal,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFE65C00),
                    letterSpacing: -1,
                  ),
                ),
              ],
              const Divider(height: 32),
              // Fila de detalles
              _buildDetailRow(
                icon: Icons.person_outline,
                label: 'responsable:',
                value: responsible,
                theme: theme,
              ),
              const SizedBox(height: 14),
              _buildDetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'fecha y hora:',
                value: dateFormat.format(history.date),
                theme: theme,
              ),
              const SizedBox(height: 14),
              _buildDetailRow(
                icon: Icons.description_outlined,
                label: 'acción realizada:',
                value: history.action,
                theme: theme,
              ),
              if (history.details != null && history.details!.isNotEmpty) ...[
                const SizedBox(height: 14),
                _buildDetailRow(
                  icon: Icons.info_outline,
                  label: 'detalles adicionales:',
                  value: history.details!,
                  theme: theme,
                ),
              ],
              if (history.oldQuantity != null && history.newQuantity != null) ...[
                const SizedBox(height: 14),
                _buildDetailRow(
                  icon: Icons.swap_horiz_rounded,
                  label: 'cambio de stock:',
                  value: 'De ${history.oldQuantity} a ${history.newQuantity}',
                  theme: theme,
                ),
              ],
              const SizedBox(height: 24),
              // Botón de viaje rápido
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: itemsMatching.isNotEmpty ? () {
                    Navigator.pop(context);
                    final item = itemsMatching.first;
                    final category = inventory.categories.firstWhere(
                      (c) => c.id == item.categoryId,
                      orElse: () => InventoryCategory(
                        id: '',
                        name: 'Desconocida',
                        color: Colors.grey,
                        iconName: '',
                        lowStockThreshold: 5,
                      ),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ItemDetailScreen(item: item, category: category),
                      ),
                    );
                  } : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    itemsMatching.isNotEmpty ? 'Ver detalle completo del artículo' : 'Artículo no disponible (Eliminado)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Mostrar un diálogo de detalle de tesorería sumamente premium y visual
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
                          : Colors.redAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          record.isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                          color: record.isIncome ? Colors.green : Colors.redAccent,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          record.isIncome ? 'Ingreso' : 'Egreso',
                          style: TextStyle(
                            color: record.isIncome ? Colors.green : Colors.redAccent,
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

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context);
    final treasury = Provider.of<TreasuryProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final isGlobalDark = themeProvider.isDarkMode;
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          onlyToday ? 'Movimientos de Hoy' : 'Historial de Actividad',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: () {
        final isLoading = inventory.isLoading || treasury.isLoading;
        final hasNoData = inventory.history.isEmpty && treasury.financialHistory.isEmpty;

        if (isLoading && hasNoData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final inventoryHistory = inventory.history;
        final List<RecentActivityItem> combinedActivities = [];

        // 1. Mapear historial de Tesorería (Ingresos y Egresos) con íconos dedicados
        for (final fh in treasury.financialHistory) {
          final isIncome = fh.action.toLowerCase().contains('ingreso');
          
          // Extraer concepto y monto de details
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

          // Colores y flechas redondeadas para Tesorería
          final Color iconColor = isIncome ? Colors.green : Colors.redAccent;
          final Color iconBgColor = isIncome
              ? (isGlobalDark ? const Color(0xFF1B3B2B) : Colors.green.withOpacity(0.12))
              : (isGlobalDark ? const Color(0xFF4C2222) : Colors.redAccent.withOpacity(0.12));
          final IconData icon = isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

          final String trailingVal = '${isIncome ? '+' : '-'}${currencyFormat.format(amount)}';
          final Color trailingCol = isIncome ? Colors.green : Colors.redAccent;

          // Buscar el registro real activo para ver detalles
          final recordsMatching = treasury.records.where((r) => r.id == fh.recordId);
          final TreasuryRecord? activeRecord = recordsMatching.isNotEmpty ? recordsMatching.first : null;

          // Generar un título descriptivo: e.g. "Ingreso modificado: Diezmos"
          String displayTitle = '';
          if (fh.action.toLowerCase().contains('modificado')) {
            displayTitle = '${isIncome ? 'Ingreso' : 'Egreso'} modificado: $concept';
          } else if (fh.action.toLowerCase().contains('eliminado')) {
            displayTitle = '${isIncome ? 'Ingreso' : 'Egreso'} eliminado: $concept';
          } else {
            displayTitle = concept;
          }

          combinedActivities.add(
            RecentActivityItem(
              title: displayTitle,
              responsible: fh.responsible,
              date: fh.date,
              icon: icon,
              iconBgColor: iconBgColor,
              iconColor: iconColor,
              activityType: 'treasury',
              relatedId: fh.recordId,
              trailingText: trailingVal,
              trailingColor: trailingCol,
              originalObject: activeRecord, // Si es nulo, significa que fue eliminado
            ),
          );
        }

        // 2. Mapear historial de Inventario -> Caja de paquete en color naranja
        for (final history in inventoryHistory) {
          final itemsMatching = inventory.items.where((i) => i.id == history.itemId);
          final String itemName = itemsMatching.isNotEmpty ? itemsMatching.first.name : 'Artículo';

          const IconData icon = Icons.inventory_2_outlined;
          String titleText = '';
          String trailingVal = '';

          final actionLower = history.action.toLowerCase();

          if (history.action.startsWith('🗑')) {
            titleText = history.action;
            if (history.oldQuantity != null) {
              trailingVal = '-${history.oldQuantity}';
            }
          } else if (actionLower.contains('agregado') || actionLower.contains('registro inicial')) {
            titleText = 'Artículo \'$itemName\' agregado';
            if (history.newQuantity != null) {
              trailingVal = '+${history.newQuantity}';
            }
          } else if (actionLower.contains('eliminado')) {
            titleText = 'Artículo \'$itemName\' eliminado';
            if (history.oldQuantity != null) {
              trailingVal = '-${history.oldQuantity}';
            }
          } else {
            // Modificaciones de stock u otros
            titleText = itemName;
            if (history.oldQuantity != null && history.newQuantity != null) {
              final diff = history.newQuantity! - history.oldQuantity!;
              trailingVal = diff >= 0 ? '+$diff' : '$diff';
            }
          }

          // Color naranja/ámbar premium para el módulo de inventario
          const Color iconColor = Color(0xFFE65C00);
          final Color iconBgColor = isGlobalDark ? const Color(0xFF382319) : const Color(0xFFFDF2E9);

          combinedActivities.add(
            RecentActivityItem(
              title: titleText,
              responsible: _getInventoryResponsible(history),
              date: history.date,
              icon: icon,
              iconBgColor: iconBgColor,
              iconColor: iconColor,
              activityType: 'inventory',
              relatedId: history.itemId,
              trailingText: trailingVal,
              trailingColor: iconColor,
              originalObject: history,
            ),
          );
        }

        // 3. Generar Alertas de bajo stock en tiempo real -> Rojo
        for (final item in inventory.items) {
          final itemsCategories = inventory.categories.where((c) => c.id == item.categoryId);
          final threshold = itemsCategories.isNotEmpty ? itemsCategories.first.lowStockThreshold : 5;
          
          if (item.quantity <= threshold) {
            final Color iconColor = Colors.redAccent;
            final Color iconBgColor = isGlobalDark ? const Color(0xFF4C2222) : Colors.redAccent.withOpacity(0.12);

            combinedActivities.add(
              RecentActivityItem(
                title: item.name,
                responsible: 'alerta de stock',
                date: item.lastUpdateDate,
                icon: Icons.warning_amber_rounded,
                iconBgColor: iconBgColor,
                iconColor: iconColor,
                activityType: 'alert',
                relatedId: item.id,
                trailingText: 'Bajo stock',
                trailingColor: iconColor,
              ),
            );
          }
        }

        // Filtrar por fecha actual si onlyToday es verdadero (utilizando la lógica robusta de cadenas ISO)
        if (onlyToday) {
          final todayStr = DateTime.now().toLocal().toIso8601String().substring(0, 10);
          combinedActivities.removeWhere((a) {
            final dateStr = a.date.toLocal().toIso8601String().substring(0, 10);
            return a.activityType == 'alert' || dateStr != todayStr;
          });
        }

        // Ordenar por fecha (las más recientes primero)
        combinedActivities.sort((a, b) => b.date.compareTo(a.date));

        if (combinedActivities.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: isGlobalDark ? Colors.white30 : Colors.black38,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay actividad registrada',
                    style: TextStyle(
                      fontSize: 16,
                      color: isGlobalDark ? Colors.white54 : Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: isGlobalDark ? const Color(0xFF1E1E2C) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isGlobalDark ? Colors.white10 : Colors.black.withOpacity(0.04),
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: combinedActivities.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: isGlobalDark ? Colors.white10 : Colors.black.withOpacity(0.05),
              ),
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                final activity = combinedActivities[index];

                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: activity.iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      activity.icon,
                      color: activity.iconColor,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    activity.title,
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
                      '${DateFormat('dd/MM/yyyy').format(activity.date)} • ${_capitalize(activity.responsible)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  trailing: Text(
                    activity.trailingText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: activity.trailingColor,
                    ),
                  ),
                  onTap: () {
                    // Regresar al dashboard principal primero
                    Navigator.pop(context);

                    if (activity.activityType == 'alert') {
                      final matches = inventory.items.where((i) => i.id == activity.relatedId);
                      if (matches.isNotEmpty) {
                        final item = matches.first;
                        final category = inventory.categories.firstWhere(
                          (c) => c.id == item.categoryId,
                          orElse: () => InventoryCategory(
                            id: '',
                            name: 'Desconocida',
                            color: Colors.grey,
                            iconName: '',
                            lowStockThreshold: 5,
                          ),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ItemDetailScreen(item: item, category: category),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LowStockScreen(),
                          ),
                        );
                      }
                    } else if (activity.activityType == 'inventory') {
                      // Mostrar diálogo premium de detalles del registro de inventario
                      if (activity.originalObject is InventoryHistory) {
                        _showInventoryDetailDialog(context, activity.originalObject as InventoryHistory, inventory);
                      } else {
                        onNavigate(1);
                      }
                    } else if (activity.activityType == 'treasury') {
                      // Mostrar diálogo premium de detalles del registro de tesorería
                      if (activity.originalObject is TreasuryRecord) {
                        _showTreasuryDetailDialog(context, activity.originalObject as TreasuryRecord);
                      } else {
                        onNavigate(2);
                      }
                    }
                  },
                );
              },
            ),
          ),
        );
      }(),
    );
  }
}

// Clase unificada del modelo de visualización para Actividad Reciente
class RecentActivityItem {
  final String title;
  final String responsible;
  final DateTime date;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String activityType; // 'inventory', 'treasury', 'alert'
  final String? relatedId; // Id correspondiente para abrir detalles
  final String trailingText; // Texto de la derecha (monto o cantidad)
  final Color trailingColor; // Color del texto de la derecha
  final Object? originalObject; // Objeto de origen para abrir detalles

  RecentActivityItem({
    required this.title,
    required this.responsible,
    required this.date,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.activityType,
    this.relatedId,
    required this.trailingText,
    required this.trailingColor,
    this.originalObject,
  });
}
