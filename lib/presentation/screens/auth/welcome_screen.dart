import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lab_control_app/config/theme/app_theme.dart';
import 'package:lab_control_app/presentation/widgets/shared/custom_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              AppTheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // Logo o Icono Universitario
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 80,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Nombre de la App
                const Text(
                  'LabControl',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Slogan
                const Text(
                  'Préstamos de equipo tecnológico ágiles para estudiantes y laboratorios universitarios.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
                
                const Spacer(),
                
                // Botón Iniciar Sesión
                CustomButton(
                  text: 'Iniciar Sesión',
                  width: double.infinity,
                  onPressed: () => context.push('/login'),
                ),
                const SizedBox(height: 12),
                
                // Botón Registrarse
                CustomButton(
                  text: 'Crear una cuenta',
                  isOutlined: true,
                  width: double.infinity,
                  onPressed: () => context.push('/register'),
                ),
                
                const SizedBox(height: 24),
                
                // Footer
                Text(
                  'Versión 1.0.0 • LabControl Estudiantes',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
