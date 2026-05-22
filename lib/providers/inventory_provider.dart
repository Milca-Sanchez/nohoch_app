import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../models/inventory_category.dart';
import '../models/inventory_history.dart';
import '../services/database_service.dart';
import 'package:uuid/uuid.dart';

class InventoryProvider with ChangeNotifier {
  final DatabaseService _dbService;
  List<InventoryItem> _items = [];
  List<InventoryCategory> _categories = [];
  List<InventoryHistory> _history = [];
  final List<InventoryHistory> _localDeletions = [];
  bool _isLoading = false;

  InventoryProvider(this._dbService) {
    _loadData();
  }

  List<InventoryItem> get items => _items;
  List<InventoryCategory> get categories => _categories;
  List<InventoryHistory> get history => _history;
  bool get isLoading => _isLoading;

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();
    try {
      _categories = await _dbService.getCategories();
      _items = await _dbService.getInventory();
      final dbHistory = await _dbService.getInventoryHistory();
      _history = [..._localDeletions, ...dbHistory];
    } catch (e) {
      print('Error al cargar datos de inventario: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItem(InventoryItem item, String userName, {Uint8List? imageBytes}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _dbService.addInventoryItem(item, imageBytes: imageBytes);
      
      final history = InventoryHistory(
        id: const Uuid().v4(),
        itemId: item.id,
        date: DateTime.now(),
        action: 'Artículo \'${item.name}\' agregado por $userName',
        newQuantity: item.quantity,
        details: 'Registro inicial del material en el sistema.',
      );
      await _dbService.addHistoryRecord(history);
    } catch (e) {
      print('Error al agregar artículo: $e');
    } finally {
      await _loadData();
    }
  }

  Future<void> updateItem(InventoryItem item, String userName, {Uint8List? imageBytes}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _dbService.updateInventoryItem(item, imageBytes: imageBytes);
      
      final history = InventoryHistory(
        id: const Uuid().v4(),
        itemId: item.id,
        date: DateTime.now(),
        action: 'Artículo \'${item.name}\' modificado por $userName',
        newQuantity: item.quantity,
        details: 'Modificación de detalles del material.',
      );
      await _dbService.addHistoryRecord(history);
    } catch (e) {
      print('Error al actualizar artículo: $e');
    } finally {
      await _loadData();
    }
  }

  Future<void> deleteItem(String itemId, String userName) async {
    _isLoading = true;
    notifyListeners();
    try {
      final itemIndex = _items.indexWhere((i) => i.id == itemId);
      if (itemIndex != -1) {
        final item = _items[itemIndex];
        await _dbService.deleteInventoryItem(itemId);
        final history = InventoryHistory(
          id: const Uuid().v4(),
          itemId: itemId,
          date: DateTime.now(),
          action: '🗑 ${item.name} eliminada',
          newQuantity: 0,
          oldQuantity: item.quantity,
          details: 'Material eliminado permanentemente del sistema por $userName.',
        );
        _localDeletions.add(history);
        await _dbService.addHistoryRecord(history);
      }
    } catch (e) {
      print('Error al eliminar artículo: $e');
    } finally {
      await _loadData();
    }
  }

  Future<void> updateQuantity(String itemId, int newQuantity, String reason, String userName) async {
    _isLoading = true;
    notifyListeners();
    try {
      final itemIndex = _items.indexWhere((i) => i.id == itemId);
      if (itemIndex != -1) {
        final oldItem = _items[itemIndex];
        final updatedItem = oldItem.copyWith(quantity: newQuantity, lastUpdateDate: DateTime.now());
        await _dbService.updateInventoryItem(updatedItem);
        final history = InventoryHistory(
          id: const Uuid().v4(),
          itemId: itemId,
          date: DateTime.now(),
          action: 'Cantidad actualizada por $userName',
          oldQuantity: oldItem.quantity,
          newQuantity: newQuantity,
          details: reason,
        );
        await _dbService.addHistoryRecord(history);
      }
    } catch (e) {
      print('Error al actualizar cantidad: $e');
    } finally {
      await _loadData();
    }
  }

  Future<List<InventoryHistory>> getItemHistory(String itemId) async {
    return await _dbService.getHistoryForItem(itemId);
  }

  Future<List<InventoryHistory>> getInventoryHistory() async {
    return _history;
  }
}