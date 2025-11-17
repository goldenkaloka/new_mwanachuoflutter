import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://yhuujolmbqvntzifoaed.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlodXVqb2xtYnF2bnR6aWZvYWVkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIyODc2MzMsImV4cCI6MjA3Nzg2MzYzM30.B7FfUaFzqqwNeTjcuunUSxQDLSbc2dz0lsOWaSVNa30';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}

