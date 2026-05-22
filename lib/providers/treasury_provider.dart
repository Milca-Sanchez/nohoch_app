import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/treasury_record.dart';
import '../models/financial_history.dart';
import '../services/database_service.dart'; // Cambio aquí

class TreasuryProvider with ChangeNotifier {
  final DatabaseService _dbService; // Cambio aquí
  List<TreasuryRecord> _records = [];
  List<FinancialHistory> _financialHistory = [];
  final List<FinancialHistory> _localDeletions = [];
  bool _isLoading = false;

  TreasuryProvider(this._dbService) {
    _loadRecords();
  }

  List<TreasuryRecord> get records => _records;
  List<FinancialHistory> get financialHistory => _financialHistory;
  List<TreasuryRecord> get incomes => _records.where((r) => r.isIncome).toList();
  List<TreasuryRecord> get expenses => _records.where((r) => !r.isIncome).toList();
  
  bool get isLoading => _isLoading;

  double get balance {
    return _records.fold(0, (sum, record) => sum + (record.isIncome ? record.amount : -record.amount));
  }

  double get totalIncome {
    return incomes.fold(0, (sum, r) => sum + r.amount);
  }

  double get totalExpenses {
    return expenses.fold(0, (sum, r) => sum + r.amount);
  }

  Future<void> _loadRecords() async {
    _isLoading = true;
    notifyListeners();
    try {
      _records = await _dbService.getTreasuryRecords();
      final dbHistory = await _dbService.getFinancialHistory();
      _financialHistory = [..._localDeletions, ...dbHistory];
    } catch (e) {
      print('Error al cargar datos financieros: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addRecord(TreasuryRecord record, String userName) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _dbService.addTreasuryRecord(record);
      
      final history = FinancialHistory(
        id: const Uuid().v4(),
        recordId: record.id,
        date: DateTime.now(),
        action: record.isIncome ? 'Ingreso registrado' : 'Egreso registrado',
        responsible: userName,
        details: 'Monto: \$${record.amount} - Concepto: ${record.concept}',
      );
      await _dbService.addFinancialHistory(history);
    } catch (e) {
      print('Error al registrar movimiento: $e');
    } finally {
      await _loadRecords();
    }
  }

  Future<void> deleteRecord(String recordId, String userName) async {
    _isLoading = true;
    notifyListeners();
    try {
      final recordIndex = _records.indexWhere((r) => r.id == recordId);
      if (recordIndex != -1) {
        final record = _records[recordIndex];
        await _dbService.deleteTreasuryRecord(recordId);

        final history = FinancialHistory(
          id: const Uuid().v4(),
          recordId: recordId,
          date: DateTime.now(),
          action: record.isIncome ? 'Ingreso eliminado' : 'Egreso eliminado',
          responsible: userName,
          details: 'Monto: \$${record.amount} - Concepto: ${record.concept}',
        );
        _localDeletions.add(history);
        await _dbService.addFinancialHistory(history);
      }
    } catch (e) {
      print('Error al eliminar movimiento: $e');
    } finally {
      await _loadRecords();
    }
  }

  Future<void> updateRecord(TreasuryRecord record, String userName) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _dbService.updateTreasuryRecord(record);
      
      final history = FinancialHistory(
        id: const Uuid().v4(),
        recordId: record.id,
        date: DateTime.now(),
        action: record.isIncome ? 'Ingreso modificado' : 'Egreso modificado',
        responsible: userName,
        details: 'Monto: \$${record.amount} - Concepto: ${record.concept}',
      );
      await _dbService.addFinancialHistory(history);
    } catch (e) {
      print('Error al actualizar movimiento: $e');
    } finally {
      await _loadRecords();
    }
  }
}