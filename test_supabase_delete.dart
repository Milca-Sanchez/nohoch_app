import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  print('Iniciando prueba de Supabase...');
  try {
    await Supabase.initialize(
      url: 'https://oqeilsrwqvrlquitqisy.supabase.co',
      anonKey: 'sb_publishable_LsfgabbecaegiEAr3YBRZQ_46TZ3LZc',
    );
    final supabase = Supabase.instance.client;
    
    print('✅ Supabase inicializado correctamente.');

    // 1. Obtener los materiales actuales
    final mats = await supabase.from('materiales').select().limit(5);
    print('Materiales (primeros 5): $mats');

    // 2. Obtener registros de historial_inventario actuales
    final hist = await supabase.from('historial_inventario').select().limit(5);
    print('Historial inventario (primeros 5): $hist');

    // 3. Probar insertar un historial de inventario con material_id = null
    print('Probando inserción de historial con material_id = null...');
    try {
      final res = await supabase.from('historial_inventario').insert({
        'id': 'test-delete-id-12345',
        'material_id': null,
        'fecha': DateTime.now().toUtc().toIso8601String(),
        'accion': '🗑 Material prueba eliminado',
        'cantidad_anterior': 1,
        'cantidad_nueva': 0,
        'detalles': 'Prueba de inserción con material_id nulo',
      });
      print('✅ Inserción de historial con material_id = null EXITOSA.');
      
      // Limpiar el registro insertado
      await supabase.from('historial_inventario').delete().match({'id': 'test-delete-id-12345'});
      print('✅ Registro de prueba eliminado.');
    } catch (e) {
      print('❌ ERROR al insertar historial con material_id = null: $e');
    }

  } catch (e) {
    print('❌ ERROR GENERAL: $e');
  }
}
