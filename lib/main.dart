import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/enums/operation_mode.dart';
import 'core/providers/app_providers.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_logger.dart';
import 'core/utils/storage_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Capturar errores de Flutter antes de runApp
  FlutterError.onError = (details) {
    AppLogger().error(
      'Flutter Error',
      error: details.exception,
      stackTrace: details.stack,
      tag: 'FLUTTER',
    );
  };

  await AppLogger().initialize();

  // Cargar ajustes persistidos ANTES del primer frame
  final savedMode = await SharedPreferencesHelper.getOperationMode();
  final savedTheme = await SharedPreferencesHelper.getThemeMode();
  final savedSensors = await SharedPreferencesHelper.getSelectedSensors();

  runZonedGuarded(
    () => runApp(
      ProviderScope(
        overrides: [
          operationModeProvider.overrideWith(
            (ref) => savedMode == 'real'
                ? OperationMode.real
                : OperationMode.simulator,
          ),
          themeModeProvider.overrideWith((ref) => savedTheme),
          selectedSensorsProvider.overrideWith((ref) => savedSensors),
        ],
        child: const PegObdApp(),
      ),
    ),
    (error, stack) => AppLogger().critical(
      'Error no manejado',
      error: error,
      stackTrace: stack,
      tag: 'APP',
    ),
  );
}

class PegObdApp extends ConsumerWidget {
  const PegObdApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'PegOBD',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: AppTheme.getThemeMode(themeMode),
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
