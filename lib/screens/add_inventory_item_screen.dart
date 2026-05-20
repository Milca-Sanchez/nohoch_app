import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../providers/inventory_provider.dart';
import '../providers/auth_provider.dart';
import '../models/inventory_item.dart';

class AddInventoryItemScreen extends StatefulWidget {
  const AddInventoryItemScreen({super.key});

  @override
  State<AddInventoryItemScreen> createState() => _AddInventoryItemScreenState();
}

class _AddInventoryItemScreenState extends State<AddInventoryItemScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _name = '';
  String? _categoryId;
  int _quantity = 1;
  String _status = 'Bueno';
  String _description = '';
  String _location = '';
  String _iconName = 'build';

  final List<String> _statuses = ['Bueno', 'Regular', 'Dañado', 'En reparación'];
  
  final Map<String, IconData> _availableIcons = {
    'build': Icons.build,
    'sticky_note_2': Icons.sticky_note_2,
    'content_cut': Icons.content_cut,
    'speaker': Icons.speaker,
    'mic': Icons.mic,
    'sports_soccer': Icons.sports_soccer,
    'cleaning_services': Icons.cleaning_services,
    'computer': Icons.computer,
    'cable': Icons.cable,
    'book': Icons.book,
  };

  void _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    final inventory = Provider.of<InventoryProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    // User name
    final userName = auth.currentUser?.name ?? 'Administrador';

    final newItem = InventoryItem(
      id: const Uuid().v4(),
      name: _name,
      categoryId: _categoryId!,
      quantity: _quantity,
      status: _status,
      description: _description,
      iconName: _iconName,
      location: _location,
      registrationDate: DateTime.now(),
      lastUpdateDate: DateTime.now(),
    );

    await inventory.addItem(newItem, userName);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Artículo "$_name" guardado correctamente')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context);
    final theme = Theme.of(context);
    
    final categories = inventory.categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Artículo'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Registrar Material',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Name
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Nombre del artículo *',
                  prefixIcon: const Icon(Icons.label_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Requerido' : null,
                onSaved: (value) => _name = value!.trim(),
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Categoría *',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: categories.map((c) {
                  return DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name),
                  );
                }).toList(),
                validator: (value) => value == null ? 'Selecciona una categoría' : null,
                onChanged: (value) {
                  setState(() => _categoryId = value);
                },
              ),
              const SizedBox(height: 16),

              // Quantity & Status
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: '1',
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Cantidad *',
                        prefixIcon: const Icon(Icons.numbers),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Requerido';
                        if (int.tryParse(value) == null) return 'Numérico';
                        if (int.parse(value) < 0) return 'Mayor a 0';
                        return null;
                      },
                      onSaved: (value) => _quantity = int.parse(value!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _status,
                      decoration: InputDecoration(
                        labelText: 'Estado',
                        prefixIcon: const Icon(Icons.info_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _status = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Ubicación',
                  prefixIcon: const Icon(Icons.place_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onSaved: (value) => _location = value?.trim() ?? '',
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 32),
                    child: Icon(Icons.description_outlined),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onSaved: (value) => _description = value?.trim() ?? '',
              ),
              const SizedBox(height: 16),

              // Icon Selector
              DropdownButtonFormField<String>(
                value: _iconName,
                decoration: InputDecoration(
                  labelText: 'Ícono Representativo',
                  prefixIcon: Icon(_availableIcons[_iconName]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _availableIcons.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Row(
                      children: [
                        Icon(entry.value, size: 20),
                        const SizedBox(width: 12),
                        Text(entry.key),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _iconName = value);
                },
              ),
              const SizedBox(height: 32),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _saveItem,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar Artículo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
