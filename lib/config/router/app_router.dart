import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lab_control_app/presentation/providers/auth_provider.dart';
import 'package:lab_control_app/presentation/screens/auth/welcome_screen.dart';
import 'package:lab_control_app/presentation/screens/auth/login_screen.dart';
import 'package:lab_control_app/presentation/screens/auth/register_screen.dart';
import 'package:lab_control_app/presentation/screens/main/main_screen.dart';
import 'package:lab_control_app/presentation/screens/equipment/equipment_detail_screen.dart';
import 'package:lab_control_app/presentation/screens/equipment/reservation_form_screen.dart';
import 'package:lab_control_app/presentation/screens/equipment/equipment_form_screen.dart';
import 'package:lab_control_app/presentation/screens/reservation/reservation_qr_screen.dart';
import 'package:lab_control_app/presentation/screens/reservation/qr_scanner_screen.dart';
import 'package:lab_control_app/presentation/views/home_view.dart';
import 'package:lab_control_app/presentation/views/reservations_view.dart';
import 'package:lab_control_app/presentation/views/history_view.dart';
import 'package:lab_control_app/presentation/views/profile_view.dart';

class GoRouterRefreshListenable extends ChangeNotifier {
  bool _isAuthed = false;

  GoRouterRefreshListenable(Ref ref) {
    ref.listen<AuthState>(
      authProvider,
      (previous, next) {
        if (next.isAuthed != _isAuthed) {
          _isAuthed = next.isAuthed;
          notifyListeners();
        }
      },
      fireImmediately: true,
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = GoRouterRefreshListenable(ref);

  return GoRouter(
    initialLocation: '/welcome',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      // Si el enrutador está cargando o inicializando, evitar redirecciones
      if (authState.isLoading) return null;

      final isLoggingIn = state.matchedLocation == '/login' ||
                          state.matchedLocation == '/register' ||
                          state.matchedLocation == '/welcome';

      if (!authState.isAuthed) {
        // Si el alumno no ha iniciado sesión y no está en las pantallas públicas, redirigir a Welcome
        if (!isLoggingIn) return '/welcome';
      } else {
        // Si el alumno ya está logueado y está en Welcome, Login o Register, redirigir a Home
        if (isLoggingIn) return '/home';
      }
      return null;
    },
    routes: [
      // Pantallas Públicas
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      
      // Estructura Shell con BottomNavigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScreen(navigationShell: navigationShell);
        },
        branches: [
          // Pestaña 1: Inicio (Equipos, Categorías, Buscador, Detalle y Formulario)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeView(),
                routes: [
                  GoRoute(
                    path: 'equipment/new',
                    builder: (context, state) => const EquipmentFormScreen(),
                  ),
                  GoRoute(
                    path: 'equipment/:id/edit',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return EquipmentFormScreen(equipmentId: id);
                    },
                  ),
                  GoRoute(
                    path: 'equipment/:id',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return EquipmentDetailScreen(equipmentId: id);
                    },
                    routes: [
                      GoRoute(
                        path: 'reserve',
                        builder: (context, state) {
                          final id = state.pathParameters['id']!;
                          return ReservationFormScreen(equipmentId: id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          
          // Pestaña 2: Reservas Activas (y Código QR)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reservations',
                builder: (context, state) => const ReservationsView(),
                routes: [
                  GoRoute(
                    path: 'qr/:resId',
                    builder: (context, state) {
                      final resId = state.pathParameters['resId']!;
                      return ReservationQrScreen(reservationId: resId);
                    },
                  ),
                  GoRoute(
                    path: 'scan',
                    builder: (context, state) => const QrScannerScreen(),
                  ),
                ],
              ),
            ],
          ),
          
          // Pestaña 3: Historial de Reservas
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryView(),
              ),
            ],
          ),
          
          // Pestaña 4: Perfil del Estudiante
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileView(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
