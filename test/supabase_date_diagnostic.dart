import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Diagnostic date parsing test from Supabase', () async {
    try {
      await Supabase.initialize(
        url: 'https://oqeilsrwqvrlquitqisy.supabase.co',
        anonKey: 'sb_publishable_LsfgabbecaegiEAr3YBRZQ_46TZ3LZc',
      );
      final supabase = Supabase.instance.client;

      print('=== 1. QUERYING LATEST HISTORIAL INVENTARIO ===');
      final invResponse = await supabase
          .from('historial_inventario')
          .select()
          .order('fecha', ascending: false)
          .limit(3);

      for (var row in invResponse) {
        final rawFecha = row['fecha'];
        final parsed = DateTime.parse(rawFecha);
        final local = parsed.toLocal();
        print('Raw: $rawFecha | Parsed (UTC? ${parsed.isUtc}): $parsed | Local: $local');
      }

      print('=== 2. QUERYING LATEST HISTORIAL FINANCIERO ===');
      final finResponse = await supabase
          .from('historial_financiero')
          .select()
          .order('fecha', ascending: false)
          .limit(3);

      for (var row in finResponse) {
        final rawFecha = row['fecha'];
        final parsed = DateTime.parse(rawFecha);
        final local = parsed.toLocal();
        print('Raw: $rawFecha | Parsed (UTC? ${parsed.isUtc}): $parsed | Local: $local');
      }

    } catch (e) {
      print('❌ ERROR: $e');
    }
  });
}
