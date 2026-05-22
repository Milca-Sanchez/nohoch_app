import '../models/inventory_item.dart';
import '../models/treasury_record.dart';
import '../models/inventory_category.dart';
import '../models/inventory_history.dart';
import '../models/financial_history.dart';

abstract class DatabaseService {
  Future<List<InventoryCategory>> getCategories();
  Future<List<InventoryItem>> getInventory();
  Future<void> addInventoryItem(InventoryItem item);
  Future<void> updateInventoryItem(InventoryItem item);
  Future<void> deleteInventoryItem(String id);
  Future<List<InventoryHistory>> getInventoryHistory();
  Future<List<InventoryHistory>> getHistoryForItem(String itemId);
  Future<void> addHistoryRecord(InventoryHistory record);
  Future<List<TreasuryRecord>> getTreasuryRecords();
  Future<void> addTreasuryRecord(TreasuryRecord record);
  Future<void> updateTreasuryRecord(TreasuryRecord record);
  Future<void> deleteTreasuryRecord(String id);
  Future<List<FinancialHistory>> getFinancialHistory();
  Future<void> addFinancialHistory(FinancialHistory history);
}