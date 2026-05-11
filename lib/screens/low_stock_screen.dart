import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/inventory_provider.dart';
import '../models/inventory_item.dart';
import '../models/inventory_category.dart';
import 'item_detail_screen.dart';

class LowStockScreen extends StatelessWidget {
  const LowStockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context);
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');

    final lowStockItems = inventory.items.where((i) => i.quantity <= 5).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos Críticos'),
      ),
      body: lowStockItems.isEmpty
          ? const Center(child: Text('No hay productos con bajo stock.'))
          : ListView.builder(
              padding: const EdgeInsets.all(24.0),
              itemCount: lowStockItems.length,
              itemBuilder: (context, index) {
                final item = lowStockItems[index];
                final category = inventory.categories.firstWhere(
                  (c) => c.id == item.categoryId,
                  orElse: () => InventoryCategory(id: '', name: 'Desconocida', color: Colors.grey, iconName: '', lowStockThreshold: 5),
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  color: Colors.red.withOpacity(0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.redAccent, width: 1),
                  ),
                  elevation: 0,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon, color: Colors.redAccent),
                    ),
                    title: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Categoría: ${category.name}'),
                        const SizedBox(height: 4),
                        Text('Actualizado: ${dateFormat.format(item.lastUpdateDate)}'),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Quedan: ${item.quantity}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ItemDetailScreen(item: item, category: category),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
