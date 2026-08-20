import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:lab_control_app/config/constants/environment.dart';

class WatchPairingMobileScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser; // Pasa el Map del usuario logueado
  const WatchPairingMobileScreen({super.key, required this.currentUser});

  @override
  State<WatchPairingMobileScreen> createState() => _WatchPairingMobileScreenState();
}

class _WatchPairingMobileScreenState extends State<WatchPairingMobileScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String _message = '';
  bool _isError = false;

  Future<void> _linkWatchDevice() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _message = 'Por favor, ingresa el código mostrado en el Reloj';
        _isError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
      _isError = false;
    });

    final String baseUrl = Environment.apiUrl;

    try {
      final dio = Dio();
      final response = await dio.post(
        '$baseUrl/auth/tv/watch/pair',
        data: {
          'code': code,
          'user': widget.currentUser, // Envía el perfil del usuario autenticado
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _message = '¡Reloj vinculado con éxito! Revisa la pantalla del reloj.';
          _isError = false;
          _codeController.clear();
        });
      } else {
        setState(() {
          _message = response.data['error'] ?? 'No se pudo vincular el reloj. Verifica el código.';
          _isError = true;
        });
      }
    } on DioException catch (e) {
      setState(() {
        String errorMsg = 'Error de red al intentar vincular. Verifica tu conexión.';
        if (e.response?.data != null && e.response?.data is Map) {
          errorMsg = e.response?.data['error'] ?? errorMsg;
        }
        _message = errorMsg;
        _isError = true;
      });
    } catch (e) {
      setState(() {
        _message = 'Error inesperado al intentar vincular.';
        _isError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF16A34A);
    const Color darkEmerald = Color(0xFF15803D);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vincular Reloj Wear OS', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Icon(
              Icons.watch_rounded,
              size: 100,
              color: primaryColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Vincular nuevo Reloj',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ingresa el código de 4 dígitos que aparece en la pantalla de tu reloj inteligente (ej: WR-1234) para autorizar tu sesión y visualizar la información del laboratorio.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 35),
            
            // Campo de Entrada del Código
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              autocorrect: false,
              textCapitalization: TextCapitalization.characters,
              maxLength: 7, // WR-XXXX
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 4.0,
                color: darkEmerald,
              ),
              decoration: InputDecoration(
                hintText: 'WR-0000',
                hintStyle: TextStyle(color: Colors.grey.shade400, letterSpacing: 2.0),
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: primaryColor, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: darkEmerald, width: 2.5),
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // Botón de Envío
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _linkWatchDevice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'AUTORIZAR Y VINCULAR RELOJ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Mensaje de Resultado (Éxito o Error)
            if (_message.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isError 
                      ? const Color(0xFFFEE2E2) 
                      : const Color(0xFFDCFCE7), 
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isError ? Colors.red.shade200 : Colors.green.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                      color: _isError ? Colors.red.shade700 : Colors.green.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _message,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _isError ? Colors.red.shade900 : Colors.green.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}