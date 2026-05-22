import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../providers/inventory_provider.dart';
import '../providers/auth_provider.dart';
import '../models/inventory_item.dart';

class AddInventoryItemScreen extends StatefulWidget {
  final InventoryItem? itemToEdit;
  const AddInventoryItemScreen({super.key, this.itemToEdit});

  @override
  State<AddInventoryItemScreen> createState() => _AddInventoryItemScreenState();
}

class _AddInventoryItemScreenState extends State<AddInventoryItemScreen> {
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  String _name = '';
  String? _categoryId;
  int _quantity = 1;
  String _status = 'Bueno';
  String _description = '';
  String _location = '';
  String _iconName = 'build';
  String? _imagePath;

  final List<String> _statuses = ['Bueno', 'Regular', 'Malo', 'Dañado', 'En reparación'];
  
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

  @override
  void initState() {
    super.initState();
    if (widget.itemToEdit != null) {
      final item = widget.itemToEdit!;
      _name = item.name;
      _categoryId = item.categoryId;
      _quantity = item.quantity;
      _status = item.status;
      _description = item.description;
      _location = item.location;
      _iconName = item.iconName;
      _imagePath = item.imagePath;
      
      // Si el estado no está en la lista de estados, lo agregamos para evitar error de DropdownButton
      if (!_statuses.contains(_status)) {
        _statuses.add(_status);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        String finalPath = pickedFile.path;
        
        if (!kIsWeb) {
          finalPath = await _saveImagePermanently(pickedFile.path);
        }

        setState(() {
          _imagePath = finalPath;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar la imagen: $e')),
        );
      }
    }
  }

  Future<String> _saveImagePermanently(String tempPath) async {
    final directory = await getApplicationDocumentsDirectory();
    final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_${tempPath.split(Platform.pathSeparator).last}';
    final savedFile = File('${directory.path}/$uniqueName');
    await File(tempPath).copy(savedFile.path);
    return savedFile.path;
  }

  void _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      final inventory = Provider.of<InventoryProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      
      // User name
      final userName = auth.currentUser?.name ?? 'Administrador';

      if (widget.itemToEdit != null) {
        final updatedItem = widget.itemToEdit!.copyWith(
          name: _name,
          categoryId: _categoryId!,
          quantity: _quantity,
          status: _status,
          description: _description,
          iconName: _iconName,
          location: _location,
          lastUpdateDate: DateTime.now(),
          imagePath: _imagePath,
        );

        await inventory.updateItem(updatedItem, userName);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Artículo "$_name" actualizado correctamente')),
          );
          Navigator.pop(context);
        }
      } else {
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
          imagePath: _imagePath,
        );

        await inventory.addItem(newItem, userName);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Artículo "$_name" guardado correctamente')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildImageSection(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 200,
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withAlpha(150),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: _imagePath != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      kIsWeb || _imagePath!.startsWith('http') || _imagePath!.startsWith('blob:')
                          ? Image.network(
                              _imagePath!,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(_imagePath!),
                              fit: BoxFit.cover,
                            ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Material(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                            onPressed: () {
                              setState(() {
                                _imagePath = null;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sin imagen del material',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withAlpha(180),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(_imagePath != null ? 'Cambiar imagen' : 'Subir imagen'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context);
    final theme = Theme.of(context);
    
    final categories = inventory.categories;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemToEdit != null ? 'Editar' : 'Agregar'),
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
              // Image Section
              _buildImageSection(theme),
              const SizedBox(height: 24),

              // Name
              TextFormField(
                initialValue: _name,
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
                value: _categoryId,
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
                      initialValue: _quantity.toString(),
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
                initialValue: _location,
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
                initialValue: _description,
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
              const SizedBox(height: 32),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveItem,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isLoading
                        ? 'Guardando...'
                        : (widget.itemToEdit != null ? 'Editar' : 'Agregar'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
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
