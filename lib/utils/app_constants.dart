import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'ExamSecure';
  static const String appVersion = '1.0.0';

  // API
  static const String apiBaseUrl = 'https://api.examsecure.com/v1';
  static const int apiTimeout = 30; // segundos

  // Security
  static const int maxFraudAttempts = 3;
  static const bool enableScreenshotBlock = true;
  static const bool enableAppSwitchDetection = true;
  static const bool enableBackgroundMonitoring = true;

  // Exam
  static const int autoSaveInterval = 30; // segundos
  static const int warningTimeMinutes = 5;
  static const int dangerTimeMinutes = 1;

  // Storage Keys
  static const String storageAuthToken = 'auth_token';
  static const String storageStudentId = 'student_id';
  static const String storageExamId = 'exam_id';
  static const String storageFraudAttempts = 'fraud_attempts';

  // Routes
  static const String routeLogin = '/login';
  static const String routeDashboard = '/dashboard';
  static const String routeExam = '/exam';
  static const String routeResult = '/result';

  // Messages
  static const String msgConnectionError =
      'Erro de conexão. Verifique sua internet.';
  static const String msgLoginError = 'Matrícula ou senha inválidos.';
  static const String msgExamBlocked =
      'Prova bloqueada devido a múltiplas tentativas de fraude.';
  static const String msgExamSubmitted = 'Prova enviada com sucesso!';

  // Colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color backgroundColor = Color(0xFFF5F5F5);

  // Fonts
  static const String fontFamily = 'Roboto';
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeXLarge = 18.0;
  static const double fontSizeXXLarge = 20.0;

  // Padding
  static const double paddingSmall = 4.0;
  static const double paddingMedium = 8.0;
  static const double paddingLarge = 16.0;
  static const double paddingXLarge = 24.0;
  static const double paddingXXLarge = 32.0;

  // Animation
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Curve animationCurve = Curves.easeInOut;
}
