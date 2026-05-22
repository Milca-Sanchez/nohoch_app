import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/inventory_provider.dart';
import '../models/inventory_item.dart';
import '../models/inventory_category.dart';
import '../services/export_service.dart';
import 'item_detail_screen.dart';
import 'add_inventory_item_screen.dart';
import '../providers/auth_provider.dart';

class InventoryView extends StatefulWidget {
  const InventoryView({super.key});

  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> {
  String _selectedCategoryId = 'all';

  String _getCategoryEmoji(String categoryId) {
    switch (categoryId) {
      case 'c1': return '📝';
      case 'c2': return '🧹';
      case 'c3': return '⚽';
      case 'c4': return '🔊';
      default: return '📦';
    }
  }

  Widget _buildCardImage(String? imagePath, InventoryCategory category) {
    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              category.color.withAlpha(35),
              category.color.withAlpha(12),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          _getCategoryEmoji(category.id),
          style: const TextStyle(fontSize: 54),
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
        child: kIsWeb || imagePath.startsWith('http') || imagePath.startsWith('blob:')
            ? Image.network(
                imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 120,
                errorBuilder: (context, error, stackTrace) => _buildFallback(category),
              )
            : Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                width: double.infinity,
                height: 120,
                errorBuilder: (context, error, stackTrace) => _buildFallback(category),
              ),
      );
    }
  }

  Widget _buildFallback(InventoryCategory category) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image, size: 36, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context);
    final theme = Theme.of(context);

    if (inventory.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Filtrar items
    var displayedItems = _selectedCategoryId == 'all'
        ? inventory.items.toList()
        : inventory.items.where((i) => i.categoryId == _selectedCategoryId).toList();

    // Ordenar automáticamente: Bajo stock (< category.lowStockThreshold) al inicio
    displayedItems.sort((a, b) {
      final aCat = inventory.categories.firstWhere((c) => c.id == a.categoryId);
      final bCat = inventory.categories.firstWhere((c) => c.id == b.categoryId);
      final aLow = a.quantity < aCat.lowStockThreshold;
      final bLow = b.quantity < bCat.lowStockThreshold;
      if (aLow && !bLow) return -1;
      if (!aLow && bLow) return 1;
      return a.name.compareTo(b.name);
    });

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Inventario de Materiales',
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
                      onTap: () => _handleExport(context, isPdf: true),
                    ),
                    const SizedBox(width: 8),
                    _buildExportButton(
                      label: 'Exportar CSV',
                      icon: Icons.table_chart,
                      color: Colors.green.shade700,
                      onTap: () => _handleExport(context, isPdf: false),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Barra de filtros (Categorías) - Diseño premium interactivo (Estilo Choose Category)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none, // Permite dibujar las sombras completas de los cards
              child: Row(
                children: [
                  _buildFilterChip('all', 'Todos', theme, theme.colorScheme.primary, '📦'),
                  ...inventory.categories.map(
                    (cat) => _buildFilterChip(cat.id, cat.name, theme, cat.color, _getCategoryEmoji(cat.id)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Grid de Materiales Horizontal Premium
            Expanded(
              child: displayedItems.isEmpty
                  ? const Center(child: Text('No hay materiales en esta categoría.'))
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 180, // Estandarizado para 2 columnas en mobile, y adaptabilidad en pantallas anchas
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.68, // Ajustado a 0.68 para garantizar altura suficiente y prevenir overflows en pantallas móviles estrechas
                      ),
                      itemCount: displayedItems.length,
                      itemBuilder: (context, index) {
                        final item = displayedItems[index];
                        final category = inventory.categories.firstWhere((c) => c.id == item.categoryId);
                        return _buildItemCard(context, item, category);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
    );
  }

  Widget _buildFilterChip(String id, String label, ThemeData theme, Color categoryColor, String emoji) {
    final isSelected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategoryId = id;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 85,
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? categoryColor.withAlpha(25) 
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? categoryColor : theme.colorScheme.outlineVariant.withAlpha(100),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected 
                    ? categoryColor.withAlpha(30) 
                    : Colors.black.withAlpha(8),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected ? categoryColor : theme.colorScheme.onSurface.withAlpha(160),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 11,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, InventoryItem item, InventoryCategory category) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isLowStock = item.quantity < category.lowStockThreshold;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item, category: category)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLowStock ? Colors.redAccent.withAlpha(128) : theme.colorScheme.outlineVariant.withAlpha(100),
            width: isLowStock ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isLowStock ? Colors.redAccent.withAlpha(20) : Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Standardized centered image/icon container at top
            Stack(
              children: [
                _buildCardImage(item.imagePath, category),
                Positioned(
                  top: 8,
                  right: 8,
                  child: PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.8)
                          : Colors.black.withOpacity(0.6),
                      size: 20,
                    ),
                    tooltip: 'Opciones',
                    elevation: 4,
                    shadowColor: Colors.black.withOpacity(0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 120),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _handleEditItem(context, item);
                      } else if (value == 'delete') {
                        _confirmDeleteItem(context, item);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, color: Colors.blue, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              'Editar',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(height: 1),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                            const SizedBox(width: 10),
                            const Text(
                              'Eliminar',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Bottom details section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            category.name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: category.color,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isLowStock)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withAlpha(30),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 10),
                                SizedBox(width: 2),
                                Text(
                                  'Poco stock',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 8,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha(30),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'En stock',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 8,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    const Divider(height: 1),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cant: ${item.quantity}',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          dateFormat.format(item.lastUpdateDate),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(120),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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

  void _handleExport(BuildContext context, {required bool isPdf}) {
    final inventory = Provider.of<InventoryProvider>(context, listen: false);
    final items = inventory.items;
    final categories = inventory.categories;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        bool onlyLowStock = false;
        return StatefulBuilder(
          builder: (statefulContext, setStateDialog) {
            final theme = Theme.of(statefulContext);
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(
                    isPdf ? Icons.picture_as_pdf : Icons.grid_on,
                    color: isPdf ? Colors.red[800] : Colors.green[800],
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isPdf ? 'Exportar a PDF' : 'Exportar a CSV',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seleccione los materiales a incluir en el reporte:',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  
                  // Option 1: All Materials
                  InkWell(
                    onTap: () {
                      setStateDialog(() {
                        onlyLowStock = false;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: !onlyLowStock ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withAlpha(100),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: !onlyLowStock ? theme.colorScheme.primary.withAlpha(15) : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Radio<bool>(
                            value: false,
                            groupValue: onlyLowStock,
                            onChanged: (val) {
                              setStateDialog(() {
                                onlyLowStock = val!;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Todos los materiales',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Option 2: Low Stock Materials
                  InkWell(
                    onTap: () {
                      setStateDialog(() {
                        onlyLowStock = true;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: onlyLowStock ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withAlpha(100),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: onlyLowStock ? theme.colorScheme.primary.withAlpha(15) : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Radio<bool>(
                            value: true,
                            groupValue: onlyLowStock,
                            onChanged: (val) {
                              setStateDialog(() {
                                onlyLowStock = val!;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Solo bajo stock',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(statefulContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    Navigator.pop(statefulContext);
                    
                    // Show a loading indicator using parent context
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
                    if (isPdf) {
                      await exportService.exportInventoryToPdf(
                        items: items,
                        categories: categories,
                        onlyLowStock: onlyLowStock,
                      );
                    } else {
                      await exportService.exportInventoryToCsv(
                        items: items,
                        categories: categories,
                        onlyLowStock: onlyLowStock,
                      );
                    }
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Descargar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: isPdf ? Colors.redAccent.shade700 : Colors.green.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleEditItem(BuildContext context, InventoryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddInventoryItemScreen(itemToEdit: item)),
    );
  }

  void _confirmDeleteItem(BuildContext context, InventoryItem item) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text(
                'Confirmar eliminación',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text('¿Deseas eliminar este material?\n\n"${item.name}"'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancelar',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final userName = auth.currentUser?.name ?? 'Admin';
                
                final inventory = Provider.of<InventoryProvider>(context, listen: false);
                await inventory.deleteItem(item.id, userName);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${item.name}" eliminado correctamente.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showAddItemDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddInventoryItemScreen()),
    );
  }
}
