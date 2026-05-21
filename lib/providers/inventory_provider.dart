import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../models/inventory_category.dart';
import '../models/inventory_history.dart';
import '../services/mock_database_service.dart';
import 'package:uuid/uuid.dart';

class InventoryProvider with ChangeNotifier {
  final MockDatabaseService _dbService;
  List<InventoryItem> _items = [];
  List<InventoryCategory> _categories = [];
  bool _isLoading = false;

  InventoryProvider(this._dbService) {
    _loadData();
  }

  List<InventoryItem> get items => _items;
  List<InventoryCategory> get categories => _categories;
  bool get isLoading => _isLoading;

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    _categories = await _dbService.getCategories();
    _items = await _dbService.getInventory();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addItem(InventoryItem item, String userName) async {
    _isLoading = true;
    notifyListeners();
    await _dbService.addInventoryItem(item);
    
    // Registro de historial
    final history = InventoryHistory(
      id: const Uuid().v4(),
      itemId: item.id,
      date: DateTime.now(),
      action: 'Artículo \'${item.name}\' agregado por $userName',
      newQuantity: item.quantity,
      details: 'Registro inicial del material en el sistema.',
    );
    await _dbService.addHistoryRecord(history);
    
    await _loadData();
  }

  Future<void> updateItem(InventoryItem item, String userName) async {
    _isLoading = true;
    notifyListeners();
    await _dbService.updateInventoryItem(item);
    
    // Registro de historial
    final history = InventoryHistory(
      id: const Uuid().v4(),
      itemId: item.id,
      date: DateTime.now(),
      action: 'Artículo \'${item.name}\' modificado por $userName',
      newQuantity: item.quantity,
      details: 'Modificación de detalles del material.',
    );
    await _dbService.addHistoryRecord(history);
    
    await _loadData();
  }

  Future<void> updateQuantity(String itemId, int newQuantity, String reason) async {
    _isLoading = true;
    notifyListeners();

    final itemIndex = _items.indexWhere((i) => i.id == itemId);
    if (itemIndex != -1) {
      final oldItem = _items[itemIndex];
      final updatedItem = oldItem.copyWith(
        quantity: newQuantity,
        lastUpdateDate: DateTime.now(),
      );
      
      await _dbService.updateInventoryItem(updatedItem);

      // Registro de historial
      final history = InventoryHistory(
        id: const Uuid().v4(),
        itemId: itemId,
        date: DateTime.now(),
        action: 'Cantidad actualizada',
        oldQuantity: oldItem.quantity,
        newQuantity: newQuantity,
        details: reason,
      );
      await _dbService.addHistoryRecord(history);
    }
    await _loadData();
  }

  Future<List<InventoryHistory>> getItemHistory(String itemId) async {
    return await _dbService.getHistoryForItem(itemId);
  }
}
