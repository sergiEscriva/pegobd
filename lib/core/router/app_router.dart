import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/logging/presentation/pages/log_viewer_page.dart';
import '../../features/obd/presentation/pages/sensor_detail_page.dart';
import '../../features/recordings/domain/entities/recording.dart';
import '../../features/recordings/presentation/pages/recording_detail_page.dart';
import '../../features/recordings/presentation/pages/recordings_list_page.dart';
import '../screens/home_screen.dart';

/// Construye el GoRouter de la app.
/// Todas las rutas de navegación secundaria (sensor detail, grabaciones,
/// logs) se declaran aquí para que los widgets usen `context.push()`
/// en vez de Navigator.push() manual.
GoRouter buildRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // ---------------------------------------------------------------
      // Pantalla principal: Bluetooth o Dashboard (condicional interno)
      // ---------------------------------------------------------------
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),

      // ---------------------------------------------------------------
      // Detalle de un sensor en tiempo real
      // ---------------------------------------------------------------
      GoRoute(
        path: '/sensor/:pid',
        builder: (context, state) => SensorDetailPage(
          pid: state.pathParameters['pid']!,
        ),
      ),

      // ---------------------------------------------------------------
      // Lista de grabaciones
      // ---------------------------------------------------------------
      GoRoute(
        path: '/recordings',
        builder: (context, state) => const RecordingsListPage(),
      ),

      // ---------------------------------------------------------------
      // Detalle de una grabación (se pasa el objeto completo como extra)
      // ---------------------------------------------------------------
      GoRoute(
        path: '/recordings/detail',
        builder: (context, state) => RecordingDetailPage(
          recording: state.extra! as Recording,
        ),
      ),

      // ---------------------------------------------------------------
      // Visor de logs internos
      // ---------------------------------------------------------------
      GoRoute(
        path: '/logs',
        builder: (context, state) => const LogViewerScreen(),
      ),
    ],
  );
}
