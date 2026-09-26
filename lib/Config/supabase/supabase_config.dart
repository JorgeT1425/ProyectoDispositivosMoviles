


import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://qlzbsnrezplcqdvovrac.supabase.co';
  static const String publishableKey = 'sb_publishable_Ucinp3mNoUgnfHN6tU8S-g_48yEYPPo';

static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: publishableKey,
    );
  }
}
SupabaseClient get supabase => Supabase.instance.client;