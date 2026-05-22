import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/inventory_provider.dart';
import '../providers/auth_provider.dart';
import '../models/inventory_item.dart';
import '../models/inventory_category.dart';
import '../models/inventory_history.dart';
import 'add_inventory_item_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final InventoryItem item;
  final InventoryCategory category;

  const ItemDetailScreen({super.key, required this.item, required this.category});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  String _getCategoryEmoji(String categoryId) {
    switch (categoryId) {
      case 'c1':
        return '📝';
      case 'c2':
        return '🧹';
      case 'c3':
        return '⚽';
      case 'c4':
        return '🔊';
      default:
        return '📦';
    }
  }

  void _showFullImage(BuildContext context, String imagePath, String itemName, String itemId) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withAlpha(230),
        pageBuilder: (context, animation, secondaryAnimation) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                itemName,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            body: Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: kIsWeb || imagePath.startsWith('http') || imagePath.startsWith('blob:')
                    ? Image.network(
                        imagePath,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator(color: Colors.white));
                        },
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.broken_image, size: 80, color: Colors.white54),
                        ),
                      )
                    : Image.file(
                        File(imagePath),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.broken_image, size: 80, color: Colors.white54),
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductImage(BuildContext context, InventoryItem item, InventoryCategory category) {
    final imagePath = item.imagePath;
    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              category.color.withAlpha(50),
              category.color.withAlpha(20),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: category.color.withAlpha(80),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          _getCategoryEmoji(category.id),
          style: const TextStyle(fontSize: 44),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showFullImage(context, imagePath, item.name, item.id),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: category.color.withAlpha(80),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: kIsWeb || imagePath.startsWith('http') || imagePath.startsWith('blob:')
            ? Image.network(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image, size: 40),
                ),
              )
            : Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image, size: 40),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inventory = Provider.of<InventoryProvider>(context);

    // Find the item from provider for real-time reactivity
    final item = inventory.items.firstWhere(
      (i) => i.id == widget.item.id,
      orElse: () => widget.item,
    );
    
    final category = inventory.categories.firstWhere(
      (c) => c.id == item.categoryId,
      orElse: () => widget.category,
    );

    final isLowStock = item.quantity < category.lowStockThreshold;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Material'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Opciones',
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
            onSelected: (value) {
              if (value == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddInventoryItemScreen(itemToEdit: item),
                  ),
                );
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
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera
            Row(
              children: [
                _buildProductImage(context, item, category),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category.name,
                        style: theme.textTheme.titleMedium?.copyWith(color: category.color),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Chip(
                            label: Text('Cantidad: ${item.quantity}'),
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          ),
                          const SizedBox(width: 8),
                          if (isLowStock)
                            Chip(
                              avatar: const Icon(Icons.warning, color: Colors.white, size: 16),
                              label: const Text('Poco stock', style: TextStyle(color: Colors.white)),
                              backgroundColor: Colors.redAccent,
                            ),
                        ],
                      )
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showUpdateQuantityDialog(context, item),
                  icon: const Icon(Icons.edit),
                  label: const Text('Cantidad'),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Descripción
            Text('Descripción', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              item.description.isNotEmpty ? item.description : 'Sin descripción disponible.', 
              style: theme.textTheme.bodyLarge
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Detalles adicionales
            Text('Detalles de Ubicación', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.place_outlined, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  item.location.isNotEmpty ? item.location : 'Sin ubicación especificada',
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Historial
            Text('Historial de Actualizaciones', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            FutureBuilder<List<InventoryHistory>>(
              future: Provider.of<InventoryProvider>(context, listen: false).getItemHistory(item.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Error al cargar historial: ${snapshot.error}');
                }
                
                final history = snapshot.data ?? [];
                
                if (history.isEmpty) {
                  return const Text('No hay registros en el historial.');
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final record = history[index];
                    return ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(record.action, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (record.oldQuantity != null && record.newQuantity != null)
                            Text('Cantidad actualizada de ${record.oldQuantity} a ${record.newQuantity}'),
                          if (record.details != null && record.details!.isNotEmpty)
                            Text(record.details!, style: const TextStyle(fontStyle: FontStyle.italic)),
                          Text(_dateFormat.format(record.date), style: theme.textTheme.bodySmall),
                        ],
                      ),
                      isThreeLine: true,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateQuantityDialog(BuildContext context, InventoryItem item) {
    final provider = Provider.of<InventoryProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userName = auth.currentUser?.name ?? 'Administrador';
    
    final controller = TextEditingController(text: item.quantity.toString());
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Actualizar Cantidad'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Nueva Cantidad'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Motivo / Detalles'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newQuantity = int.tryParse(controller.text);
              if (newQuantity != null) {
                final navigator = Navigator.of(context);
                await provider.updateQuantity(
                  item.id,
                  newQuantity,
                  reasonController.text.isEmpty ? 'Ajuste manual' : reasonController.text,
                  userName,
                );
                if (mounted) {
                  navigator.pop();
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
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
                  Navigator.pop(context); // Volver al listado del inventario
                  
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
}