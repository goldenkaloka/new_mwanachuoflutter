import 'package:flutter/material.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'dart:io' show Platform;
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:mwanachuo/config/supabase_config.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/main_app.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  // Preserve native splash screen until Flutter is ready to draw its first frame
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Set global system UI style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Suppress mouse_tracker.dart debug assertions on Windows
  if (kDebugMode && Platform.isWindows) {
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exception is AssertionError &&
          details.stack?.toString().contains('mouse_tracker.dart') == true) {
        return;
      }
      FlutterError.presentError(details);
    };
  }

  runApp(const MwanachuoAppWrapper());
}

class MwanachuoAppWrapper extends StatefulWidget {
  const MwanachuoAppWrapper({super.key});

  @override
  State<MwanachuoAppWrapper> createState() => _MwanachuoAppWrapperState();
}

class _MwanachuoAppWrapperState extends State<MwanachuoAppWrapper> {
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      // Remove native splash as soon as our first frame is rendered
      // This is the fastest way to replace native splash with Flutter UI
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FlutterNativeSplash.remove();
      });

      // Run critical initializations in parallel
      await Future.wait([SupabaseConfig.initialize(), Hive.initFlutter()]);

      await initializeDependencies();

      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Initialization failed: $e\n$stackTrace');
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
        // Ensure splash remains removed on error
        FlutterNativeSplash.remove();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.teal),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SelectableText(
                'Initialization Failed:\n\n$_error\n\nPlease restart the app.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      );
    }

    if (!_initialized) {
      // Show a beautiful loading screen while Supabase/DI is booting up
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.teal),
        home: const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: kPrimaryColor),
                SizedBox(height: 24),
                Text(
                  'Starting Mwanachuo...',
                  style: TextStyle(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const MwanachuoshopApp();
  }
}
