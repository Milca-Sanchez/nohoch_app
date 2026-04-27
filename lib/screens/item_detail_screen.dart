import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/inventory_provider.dart';
import '../models/inventory_item.dart';
import '../models/inventory_category.dart';
import '../models/inventory_history.dart';

class ItemDetailScreen extends StatefulWidget {
  final InventoryItem item;
  final InventoryCategory category;

  const ItemDetailScreen({super.key, required this.item, required this.category});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLowStock = widget.item.quantity < widget.category.lowStockThreshold;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Material'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: widget.category.color.withAlpha(30),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(widget.item.icon, size: 40, color: widget.category.color),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.name,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.category.name,
                        style: theme.textTheme.titleMedium?.copyWith(color: widget.category.color),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Chip(
                            label: Text('Cantidad: ${widget.item.quantity}'),
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
                  onPressed: () => _showUpdateQuantityDialog(context),
                  icon: const Icon(Icons.edit),
                  label: const Text('Actualizar Cantidad'),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Descripción
            Text('Descripción', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.item.description, style: theme.textTheme.bodyLarge),
            
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // Historial
            Text('Historial de Actualizaciones', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            FutureBuilder<List<InventoryHistory>>(
              future: Provider.of<InventoryProvider>(context, listen: false).getItemHistory(widget.item.id),
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

  void _showUpdateQuantityDialog(BuildContext context) {
    // Implementación rápida para probar el historial
    final provider = Provider.of<InventoryProvider>(context, listen: false);
    final controller = TextEditingController(text: widget.item.quantity.toString());
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
                await provider.updateQuantity(widget.item.id, newQuantity, reasonController.text.isEmpty ? 'Ajuste manual' : reasonController.text);
                if (mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context); // Volver al listado para refrescar
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
