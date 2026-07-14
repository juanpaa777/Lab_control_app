import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lab_control_app/config/theme/app_theme.dart';
import 'package:lab_control_app/presentation/widgets/shared/custom_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Imagen de fondo
          Positioned.fill(
            child: Image.network(
              'https://umg.edu.gt/img/laboratorios/in3.webp',
              fit: BoxFit.cover,
            ),
          ),
          
          // 2. Efecto de vidrio desdibujado más denso (Frosted Glassmorphism)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
              child: Container(
                color: Colors.white.withOpacity(0.75), // Mayor opacidad para asegurar legibilidad
              ),
            ),
          ),
          
          // 3. Contenido interactivo
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  
                  // Logo o Icono Universitario resaltado con sombra suave y fondo blanco vidrio
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 80,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Nombre de la App
                  Text(
                    'LabControl',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800, // Extra bold en Flutter
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Slogan con mayor contraste y grosor
                  Text(
                    'Préstamos de equipo tecnológico ágiles para estudiantes y laboratorios universitarios.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600, // Semi-bold para legibilidad
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
                  
                  // Footer con mayor contraste
                  Text(
                    'Versión 1.0.0 • LabControl Estudiantes',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textPrimary.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
