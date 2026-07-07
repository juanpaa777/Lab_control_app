import 'dart:io';
import 'package:flutter/foundation.dart';

class Environment {
  // Resuelve la dirección IP del host según la plataforma (localhost en Windows/Web, 10.0.2.2 en Android)
  static String get apiUrl {
    if (kIsWeb) return 'http://localhost:8080/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:8080/api';
    return 'http://localhost:8080/api';
  }
  
  static const String appName = 'LabControl';
}
