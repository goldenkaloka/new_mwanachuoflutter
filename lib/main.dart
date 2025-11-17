import 'package:flutter/material.dart';
import 'package:mwanachuo/config/supabase_config.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/main_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseConfig.initialize();

  // Initialize dependency injection
  await initializeDependencies();

  runApp(const MwanachuoshopApp());
}
