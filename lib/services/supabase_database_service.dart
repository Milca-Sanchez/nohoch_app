import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/inventory_item.dart';
import '../models/treasury_record.dart';
import '../models/inventory_category.dart';
import '../models/inventory_history.dart';
import '../models/financial_history.dart';
import 'database_service.dart'; // Importar la interfaz

class SupabaseDatabaseService implements DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  // ==================== CATEGORÍAS ====================
  @override
  Future<List<InventoryCategory>> getCategories() async {
    try {
      final response = await _supabase
          .from('categorias')
          .select()
          .order('nombre');
      
      return response.map<InventoryCategory>((cat) {
        return InventoryCategory(
          id: cat['id'],
          name: cat['nombre'],
          iconName: cat['nombre_icono'],
          color: Color(cat['color'] as int),
          lowStockThreshold: cat['umbral_bajo_stock'],
        );
      }).toList();
    } catch (e) {
      print('Error al obtener categorías: $e');
      return [];
    }
  }

  // ==================== INVENTARIO ====================
  @override
  Future<List<InventoryItem>> getInventory() async {
    try {
      final response = await _supabase
          .from('materiales')
          .select()
          .order('nombre');
      
      return response.map<InventoryItem>((item) {
        return InventoryItem(
          id: item['id'],
          name: item['nombre'],
          categoryId: item['categoria_id'],
          quantity: item['cantidad'],
          status: item['estado'],
          description: item['descripcion'] ?? '',
          iconName: item['nombre_icono'],
          location: item['ubicacion'] ?? '',
          registrationDate: DateTime.parse(item['fecha_registro']),
          lastUpdateDate: DateTime.parse(item['fecha_actualizacion']),
          imagePath: item['ruta_imagen'],
        );
      }).toList();
    } catch (e) {
      print('Error al obtener inventario: $e');
      return [];
    }
  }

  @override
  Future<void> addInventoryItem(InventoryItem item) async {
    try {
      await _supabase.from('materiales').insert({
        'id': item.id,
        'nombre': item.name,
        'categoria_id': item.categoryId,
        'cantidad': item.quantity,
        'estado': item.status,
        'descripcion': item.description,
        'nombre_icono': item.iconName,
        'ubicacion': item.location,
        'fecha_registro': item.registrationDate.toIso8601String(),
        'fecha_actualizacion': item.lastUpdateDate.toIso8601String(),
        'ruta_imagen': item.imagePath,
      });
    } catch (e) {
      print('Error al agregar artículo: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateInventoryItem(InventoryItem item) async {
    try {
      await _supabase
          .from('materiales')
          .update({
            'nombre': item.name,
            'categoria_id': item.categoryId,
            'cantidad': item.quantity,
            'estado': item.status,
            'descripcion': item.description,
            'nombre_icono': item.iconName,
            'ubicacion': item.location,
            'fecha_actualizacion': item.lastUpdateDate.toIso8601String(),
            'ruta_imagen': item.imagePath,
          })
          .match({'id': item.id});
    } catch (e) {
      print('Error al actualizar artículo: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteInventoryItem(String id) async {
    try {
      await _supabase.from('materiales').delete().match({'id': id});
    } catch (e) {
      print('Error al eliminar artículo: $e');
      rethrow;
    }
  }

  // ==================== HISTORIAL INVENTARIO ====================
  @override
  Future<List<InventoryHistory>> getInventoryHistory() async {
    try {
      final response = await _supabase
          .from('historial_inventario')
          .select()
          .order('fecha', ascending: false);
      
      return response.map<InventoryHistory>((h) {
        return InventoryHistory(
          id: h['id'],
          itemId: h['material_id'],
          date: DateTime.parse(h['fecha']),
          action: h['accion'],
          oldQuantity: h['cantidad_anterior'],
          newQuantity: h['cantidad_nueva'],
          details: h['detalles'],
        );
      }).toList();
    } catch (e) {
      print('Error al obtener historial inventario: $e');
      return [];
    }
  }

  @override
  Future<List<InventoryHistory>> getHistoryForItem(String itemId) async {
    try {
      final response = await _supabase
          .from('historial_inventario')
          .select()
          .eq('material_id', itemId)
          .order('fecha', ascending: false);
      
      return response.map<InventoryHistory>((h) {
        return InventoryHistory(
          id: h['id'],
          itemId: h['material_id'],
          date: DateTime.parse(h['fecha']),
          action: h['accion'],
          oldQuantity: h['cantidad_anterior'],
          newQuantity: h['cantidad_nueva'],
          details: h['detalles'],
        );
      }).toList();
    } catch (e) {
      print('Error al obtener historial del item: $e');
      return [];
    }
  }

  @override
  Future<void> addHistoryRecord(InventoryHistory record) async {
    try {
      await _supabase.from('historial_inventario').insert({
        'id': _uuid.v4(),
        'material_id': record.itemId,
        'fecha': record.date.toIso8601String(),
        'accion': record.action,
        'cantidad_anterior': record.oldQuantity,
        'cantidad_nueva': record.newQuantity,
        'detalles': record.details,
      });
    } catch (e) {
      print('Error al agregar historial: $e');
      rethrow;
    }
  }

  // ==================== TESORERÍA ====================
  @override
  Future<List<TreasuryRecord>> getTreasuryRecords() async {
    try {
      final response = await _supabase
          .from('movimientos_tesoreria')
          .select()
          .order('fecha', ascending: false);
      
      return response.map<TreasuryRecord>((r) {
        return TreasuryRecord(
          id: r['id'],
          concept: r['concepto'],
          amount: (r['monto'] as num).toDouble(),
          date: DateTime.parse(r['fecha']),
          description: r['descripcion'],
          responsible: r['responsable'],
          notes: r['notas'],
          isIncome: r['es_ingreso'],
        );
      }).toList();
    } catch (e) {
      print('Error al obtener movimientos: $e');
      return [];
    }
  }

  @override
  Future<void> addTreasuryRecord(TreasuryRecord record) async {
    try {
      await _supabase.from('movimientos_tesoreria').insert({
        'id': record.id,
        'concepto': record.concept,
        'monto': record.amount,
        'fecha': record.date.toIso8601String(),
        'descripcion': record.description,
        'responsable': record.responsible,
        'notas': record.notes,
        'es_ingreso': record.isIncome,
      });
    } catch (e) {
      print('Error al agregar movimiento: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateTreasuryRecord(TreasuryRecord record) async {
    try {
      await _supabase
          .from('movimientos_tesoreria')
          .update({
            'concepto': record.concept,
            'monto': record.amount,
            'fecha': record.date.toIso8601String(),
            'descripcion': record.description,
            'responsable': record.responsible,
            'notas': record.notes,
            'es_ingreso': record.isIncome,
          })
          .match({'id': record.id});
    } catch (e) {
      print('Error al actualizar movimiento: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteTreasuryRecord(String id) async {
    try {
      await _supabase.from('movimientos_tesoreria').delete().match({'id': id});
    } catch (e) {
      print('Error al eliminar movimiento: $e');
      rethrow;
    }
  }

  // ==================== HISTORIAL FINANCIERO ====================
  @override
  Future<List<FinancialHistory>> getFinancialHistory() async {
    try {
      final response = await _supabase
          .from('historial_financiero')
          .select()
          .order('fecha', ascending: false);
      
      return response.map<FinancialHistory>((fh) {
        return FinancialHistory(
          id: fh['id'],
          recordId: fh['movimiento_id'],
          date: DateTime.parse(fh['fecha']),
          action: fh['accion'],
          responsible: fh['responsable'],
          details: fh['detalles'],
        );
      }).toList();
    } catch (e) {
      print('Error al obtener historial financiero: $e');
      return [];
    }
  }

  @override
  Future<void> addFinancialHistory(FinancialHistory history) async {
    try {
      await _supabase.from('historial_financiero').insert({
        'id': _uuid.v4(),
        'movimiento_id': history.recordId,
        'fecha': history.date.toIso8601String(),
        'accion': history.action,
        'responsable': history.responsible,
        'detalles': history.details,
      });
    } catch (e) {
      print('Error al agregar historial financiero: $e');
      rethrow;
    }
  }
}