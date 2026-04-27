import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../models/treasury_record.dart';
import '../models/inventory_category.dart';
import '../models/inventory_history.dart';
import '../models/financial_history.dart';

class MockDatabaseService {
  // Categorías
  final List<InventoryCategory> _categories = [
    InventoryCategory(id: 'c1', name: 'Papelería', iconName: 'edit', color: Colors.blue, lowStockThreshold: 10),
    InventoryCategory(id: 'c2', name: 'Servicios Generales', iconName: 'cleaning_services', color: Colors.green, lowStockThreshold: 3),
    InventoryCategory(id: 'c3', name: 'Recreación y Dinámicas', iconName: 'sports_soccer', color: Colors.orange, lowStockThreshold: 5),
    InventoryCategory(id: 'c4', name: 'Electrónica y Audio', iconName: 'speaker', color: Colors.purple, lowStockThreshold: 2),
  ];

  // Inventario Mock
  late final List<InventoryItem> _inventory = [
    InventoryItem(
      id: '1', name: 'Hojas Blancas (Paquete)', categoryId: 'c1', quantity: 2, status: 'Bueno',
      description: 'Paquete de 500 hojas blancas tamaño carta.', iconName: 'sticky_note_2',
      registrationDate: DateTime.now().subtract(const Duration(days: 30)), lastUpdateDate: DateTime.now().subtract(const Duration(days: 2))
    ),
    InventoryItem(
      id: '2', name: 'Tijeras', categoryId: 'c1', quantity: 15, status: 'Bueno',
      description: 'Tijeras de uso general para oficina.', iconName: 'content_cut',
      registrationDate: DateTime.now().subtract(const Duration(days: 40)), lastUpdateDate: DateTime.now().subtract(const Duration(days: 10))
    ),
    InventoryItem(
      id: '3', name: 'Bocina Bluetooth', categoryId: 'c4', quantity: 3, status: 'Bueno',
      description: 'Bocina portátil de 40W para reuniones pequeñas.', iconName: 'speaker',
      registrationDate: DateTime.now().subtract(const Duration(days: 60)), lastUpdateDate: DateTime.now().subtract(const Duration(days: 5))
    ),
    InventoryItem(
      id: '4', name: 'Micrófono Inalámbrico', categoryId: 'c4', quantity: 4, status: 'Regular',
      description: 'Sistema de 2 micrófonos inalámbricos UHF.', iconName: 'mic',
      registrationDate: DateTime.now().subtract(const Duration(days: 90)), lastUpdateDate: DateTime.now().subtract(const Duration(days: 20))
    ),
    InventoryItem(
      id: '5', name: 'Balón de Fútbol', categoryId: 'c3', quantity: 1, status: 'Malo',
      description: 'Balón número 5 para dinámicas con jóvenes.', iconName: 'sports_soccer',
      registrationDate: DateTime.now().subtract(const Duration(days: 120)), lastUpdateDate: DateTime.now().subtract(const Duration(days: 1))
    ),
    InventoryItem(
      id: '6', name: 'Escobas', categoryId: 'c2', quantity: 8, status: 'Bueno',
      description: 'Escobas de cerdas suaves para interior.', iconName: 'cleaning_services',
      registrationDate: DateTime.now().subtract(const Duration(days: 15)), lastUpdateDate: DateTime.now().subtract(const Duration(days: 5))
    ),
  ];

  // Historial de Inventario Mock
  final List<InventoryHistory> _history = [
    InventoryHistory(id: 'h1', itemId: '3', date: DateTime.now().subtract(const Duration(days: 5)), action: 'Cantidad actualizada', oldQuantity: 5, newQuantity: 3, details: 'Se prestaron 2 bocinas al grupo de jóvenes.'),
    InventoryHistory(id: 'h2', itemId: '1', date: DateTime.now().subtract(const Duration(days: 2)), action: 'Uso de material', oldQuantity: 5, newQuantity: 2, details: 'Se utilizaron 3 paquetes en la asamblea.'),
  ];

  // Tesorería Mock
  final List<TreasuryRecord> _treasury = [
    TreasuryRecord(
      id: '1', concept: 'Diezmos Enero', amount: 5000, date: DateTime.now().subtract(const Duration(days: 7)),
      description: 'Recaudación general del mes', responsible: 'Admin', isIncome: true,
    ),
    TreasuryRecord(
      id: '2', concept: 'Curso de primeros auxilios', amount: 2200, date: DateTime.now().subtract(const Duration(days: 5)),
      description: '4 personas, solicitado por el movimiento', responsible: 'Lia', notes: 'Cruz Roja', isIncome: false,
    ),
    TreasuryRecord(
      id: '3', concept: 'Ofrenda Especial', amount: 1200, date: DateTime.now().subtract(const Duration(days: 3)),
      description: 'Ofrenda recolectada en evento de jóvenes', responsible: 'Tesorero', isIncome: true,
    ),
    TreasuryRecord(
      id: '4', concept: 'Mantenimiento Audio', amount: 1500, date: DateTime.now().subtract(const Duration(days: 1)),
      description: 'Reparación de cables y consola', responsible: 'Admin', notes: 'Factura pagada', isIncome: false,
    ),
  ];

  // Historial Financiero Mock
  final List<FinancialHistory> _financialHistory = [
    FinancialHistory(id: 'fh1', recordId: '2', date: DateTime.now().subtract(const Duration(days: 5)), action: 'Egreso registrado', responsible: 'Lia', details: 'Registro de egreso por \$2200.'),
  ];

  // --- Categorías ---
  Future<List<InventoryCategory>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_categories);
  }

  // --- Inventario ---
  Future<List<InventoryItem>> getInventory() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return List.unmodifiable(_inventory);
  }

  Future<void> addInventoryItem(InventoryItem item) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _inventory.add(item);
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _inventory.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _inventory[index] = item;
    }
  }

  // --- Historial Inventario ---
  Future<List<InventoryHistory>> getHistoryForItem(String itemId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _history.where((h) => h.itemId == itemId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> addHistoryRecord(InventoryHistory record) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _history.add(record);
  }

  // --- Tesorería ---
  Future<List<TreasuryRecord>> getTreasuryRecords() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return List.unmodifiable(_treasury);
  }

  Future<void> addTreasuryRecord(TreasuryRecord record) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _treasury.add(record);
  }

  Future<void> updateTreasuryRecord(TreasuryRecord record) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _treasury.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      _treasury[index] = record;
    }
  }
  
  Future<void> deleteTreasuryRecord(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _treasury.removeWhere((r) => r.id == id);
  }

  // --- Historial Financiero ---
  Future<List<FinancialHistory>> getFinancialHistory() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_financialHistory);
  }

  Future<void> addFinancialHistory(FinancialHistory record) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _financialHistory.add(record);
  }
}
