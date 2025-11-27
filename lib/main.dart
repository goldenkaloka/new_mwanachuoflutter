import 'package:flutter/material.dart';
import 'package:mwanachuo/config/supabase_config.dart';
import 'package:mwanachuo/config/onesignal_config.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/main_app.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    await SupabaseConfig.initialize();
    await OneSignalConfig.initialize();
    await initializeDependencies();

    runApp(const MwanachuoshopApp());
  } catch (e, stackTrace) {
    debugPrint('Initialization failed: $e\n$stackTrace');
    // Run a simple error app if initialization fails
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('Initialization Failed:\n$e'))),
      ),
    );
  }
}
