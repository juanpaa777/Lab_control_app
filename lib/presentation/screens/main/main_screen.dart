import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lab_control_app/config/theme/app_theme.dart';

/// Rutas raiz donde el menu inferior DEBE ser visible.
const List<String> _rootPaths = ['/home', '/reservations', '/history', '/profile'];

bool _isRootPath(String location) {
  return _rootPaths.any((root) => location == root);
}

class MainScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
      ),
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  /// Siempre navegar al ROOT de cada pestana para evitar restaurar sub-pantallas.
  /// Por ejemplo: tocar "Inicio" siempre va a /home, no al ultimo equipo visto.
  void _onTap(int index) {
    context.go(_rootPaths[index]);
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final navVisible = _isRootPath(location);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: false,
      body: widget.navigationShell,
      bottomNavigationBar: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: !navVisible
            ? const SizedBox(width: double.infinity, height: 0)
            : Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                padding: EdgeInsets.only(bottom: bottomPadding),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: BottomNavigationBar(
                    currentIndex: widget.navigationShell.currentIndex,
                    onTap: _onTap,
                    backgroundColor: Colors.white,
                    elevation: 0,
                    type: BottomNavigationBarType.fixed,
                    selectedItemColor: AppTheme.primary,
                    unselectedItemColor: const Color(0xFF9E9E9E),
                    selectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 11,
                    ),
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home_outlined),
                        activeIcon: Icon(Icons.home_rounded),
                        label: 'Inicio',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.qr_code_outlined),
                        activeIcon: Icon(Icons.qr_code_rounded),
                        label: 'Reservas',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.history_outlined),
                        activeIcon: Icon(Icons.history_rounded),
                        label: 'Historial',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.person_outline),
                        activeIcon: Icon(Icons.person_rounded),
                        label: 'Perfil',
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}