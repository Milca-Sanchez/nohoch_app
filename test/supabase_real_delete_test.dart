import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Test deletion of a material and history logs', () async {
    try {
      await Supabase.initialize(
        url: 'https://oqeilsrwqvrlquitqisy.supabase.co',
        anonKey: 'sb_publishable_LsfgabbecaegiEAr3YBRZQ_46TZ3LZc',
      );
      final supabase = Supabase.instance.client;
      final uuid = const Uuid().v4();

      print('1. Creating a temporary category if not exists (using c1)');
      
      print('2. Inserting test material...');
      await supabase.from('materiales').insert({
        'id': uuid,
        'nombre': 'Material de Prueba Delete Test',
        'categoria_id': 'c1',
        'cantidad': 10,
        'estado': 'Disponible',
        'descripcion': 'Temporary test material',
        'nombre_icono': 'box',
        'ubicacion': 'Test shelf',
        'fecha_registro': DateTime.now().toUtc().toIso8601String(),
        'fecha_actualizacion': DateTime.now().toUtc().toIso8601String(),
      });
      print('✅ Material inserted successfully!');

      print('3. Attempting to add a history record for addition...');
      final histId = const Uuid().v4();
      await supabase.from('historial_inventario').insert({
        'id': histId,
        'material_id': uuid,
        'fecha': DateTime.now().toUtc().toIso8601String(),
        'accion': 'Artículo agregado por Test',
        'cantidad_anterior': 0,
        'cantidad_nueva': 10,
        'detalles': 'Registro inicial',
      });
      print('✅ History record for addition inserted!');

      print('4. Deleting history record matching material_id...');
      await supabase.from('historial_inventario').delete().match({'material_id': uuid});
      print('✅ History records deleted!');

      print('5. Deleting material...');
      await supabase.from('materiales').delete().match({'id': uuid});
      print('✅ Material deleted!');

      print('6. Attempting to insert a deletion history record (setting material_id to null)...');
      try {
        final delHistId = const Uuid().v4();
        await supabase.from('historial_inventario').insert({
          'id': delHistId,
          'material_id': null,
          'fecha': DateTime.now().toUtc().toIso8601String(),
          'accion': '🗑 Material de Prueba Delete Test eliminada',
          'cantidad_anterior': 10,
          'cantidad_nueva': 0,
          'detalles': 'Material eliminado permanentemente',
        });
        print('✅ Insertion with material_id: null succeeded!');
      } catch (e) {
        print('❌ Insertion with material_id: null FAILED: $e');
      }

      print('7. Attempting to insert a deletion history record (using deleted material_id)...');
      try {
        final delHistId2 = const Uuid().v4();
        await supabase.from('historial_inventario').insert({
          'id': delHistId2,
          'material_id': uuid,
          'fecha': DateTime.now().toUtc().toIso8601String(),
          'accion': '🗑 Material de Prueba Delete Test eliminada',
          'cantidad_anterior': 10,
          'cantidad_nueva': 0,
          'detalles': 'Material eliminado permanentemente',
        });
        print('✅ Insertion with deleted material_id succeeded!');
      } catch (e) {
        print('❌ Insertion with deleted material_id FAILED: $e');
      }

    } catch (e) {
      print('❌ GLOBAL ERROR: $e');
    }
  });
}
