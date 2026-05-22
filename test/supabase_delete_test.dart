import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Analyze dates and timezone comparison', () async {
    try {
      await Supabase.initialize(
        url: 'https://oqeilsrwqvrlquitqisy.supabase.co',
        anonKey: 'sb_publishable_LsfgabbecaegiEAr3YBRZQ_46TZ3LZc',
      );
      final supabase = Supabase.instance.client;
      
      final now = DateTime.now();
      print('--- CURRENT LOCAL TIME (now) ---');
      print('now: $now');
      print('now.year: ${now.year}, now.month: ${now.month}, now.day: ${now.day}');
      print('now.timeZoneName: ${now.timeZoneName}');
      print('now.timeZoneOffset: ${now.timeZoneOffset}');

      print('=== INVENTORY HISTORY DATES ===');
      final invHist = await supabase.from('historial_inventario').select();
      for (final row in invHist) {
        final rawFecha = row['fecha'];
        final parsed = DateTime.parse(rawFecha);
        final local = parsed.toLocal();
        final isSameDay = local.year == now.year && local.month == now.month && local.day == now.day;
        print('Raw: $rawFecha | Parsed UTC: $parsed | Local: $local | IsSameDay: $isSameDay');
      }

      print('=== FINANCIAL HISTORY DATES ===');
      final finHist = await supabase.from('historial_financiero').select();
      for (final row in finHist) {
        final rawFecha = row['fecha'];
        final parsed = DateTime.parse(rawFecha);
        final local = parsed.toLocal();
        final isSameDay = local.year == now.year && local.month == now.month && local.day == now.day;
        print('Raw: $rawFecha | Parsed UTC: $parsed | Local: $local | IsSameDay: $isSameDay');
      }

    } catch (e) {
      print('❌ ERROR: $e');
    }
  });
}
