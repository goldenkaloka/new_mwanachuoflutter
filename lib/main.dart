import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'dart:io' show Platform;
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:mwanachuo/config/supabase_config.dart';
import 'package:mwanachuo/config/onesignal_config.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/main_app.dart';

Future<void> main() async {
  // Preserve native splash screen until Flutter is ready
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    // Suppress mouse_tracker.dart debug assertions on Windows
    // These are harmless debug-only warnings that spam the console
    if (kDebugMode && Platform.isWindows) {
      // Filter out mouse_tracker.dart assertion errors
      FlutterError.onError = (FlutterErrorDetails details) {
        // Ignore mouse_tracker.dart assertions - they're harmless debug warnings
        if (details.exception is AssertionError &&
            details.stack?.toString().contains('mouse_tracker.dart') == true) {
          // Silently ignore these assertions
          return;
        }
        // Log other errors normally
        FlutterError.presentError(details);
      };
      debugPrint(
        '⚠️  Running on Windows - mouse tracker assertions will be filtered',
      );
    }

    await SupabaseConfig.initialize();
    await OneSignalConfig.initialize();
    await initializeDependencies();

    runApp(const MwanachuoshopApp());

    // Native splash will be removed by InitialRouteHandler when navigation occurs
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
