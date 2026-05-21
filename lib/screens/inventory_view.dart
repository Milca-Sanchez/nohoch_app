import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/inventory_provider.dart';
import '../models/inventory_item.dart';
import '../models/inventory_category.dart';
import 'item_detail_screen.dart';
import 'add_inventory_item_screen.dart';

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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              category.color.withAlpha(40),
              category.color.withAlpha(15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          _getCategoryEmoji(category.id),
          style: const TextStyle(fontSize: 36),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: kIsWeb || imagePath.startsWith('http') || imagePath.startsWith('blob:')
          ? Image.network(
              imagePath,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) => _buildFallback(category),
            )
          : Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) => _buildFallback(category),
            ),
    );
  }

  Widget _buildFallback(InventoryCategory category) {
    return Container(
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
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
            Text(
              'Inventario de Materiales',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Barra de filtros (Categorías)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'Todos los materiales', theme),
                  ...inventory.categories.map(
                    (cat) => _buildFilterChip(cat.id, cat.name, theme),
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
                        maxCrossAxisExtent: 340,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.65,
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
        label: const Text('Nuevo Artículo'),
      ),
    );
  }

  Widget _buildFilterChip(String id, String label, ThemeData theme) {
    final isSelected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategoryId = id;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest.withAlpha(128),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? theme.colorScheme.primary.withAlpha(128) : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
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
        child: Row(
          children: [
            // Left side image
            Expanded(
              flex: 38,
              child: _buildCardImage(item.imagePath, category),
            ),
            
            // Right side details
            Expanded(
              flex: 62,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
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
                    const Spacer(),
                    Text(
                      item.name,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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

  void _showAddItemDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddInventoryItemScreen()),
    );
  }
}
