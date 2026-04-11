import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://ntsvoexuhippdbfnivud.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im50c3ZvZXh1aGlwcGRiZm5pdnVkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk0MDAzNjksImV4cCI6MjA3NDk3NjM2OX0.28KnXm1B6qcPyuvSUbDgoktCRdZnTVJes8rVMARu19c',
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
