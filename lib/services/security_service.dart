import 'dart:async';
import 'package:flutter/material.dart';
import 'package:screenshot_callback/screenshot_callback.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FraudType {
  screenshot,
  appSwitch,
  screenLock,
  multiTouch,
}

class FraudAttempt {
  final FraudType type;
  final DateTime timestamp;

  FraudAttempt({required this.type, required this.timestamp});
}

class SecurityService extends ChangeNotifier {
  int _fraudAttempts = 0;
  bool _isExamActive = false;
  // ignore: unused_field
  String? _currentExamId; // mantém o ID da prova atual, usado futuramente
  final List<FraudAttempt> _fraudLog = [];

  // Limite de tentativas de fraude
  static const int maxFraudAttempts = 3;

  // Callback para screenshot
  late ScreenshotCallback _screenshotCallback;

  // Stream para monitorar mudanças no app
  final _appLifecycleStream = AppLifecycleListener(
    onResume: _onResume,
    onPause: _onPause,
    onInactive: _onInactive,
    onDetach: _onDetach,
  );

  SecurityService() {
    _initializeSecurity();
  }

  int get fraudAttempts => _fraudAttempts;
  bool get isExamActive => _isExamActive;
  bool get isBlocked => _fraudAttempts >= maxFraudAttempts;
  List<FraudAttempt> get fraudLog => List.unmodifiable(_fraudLog);

  void _initializeSecurity() {
    // Inicializar callback de screenshot
    _screenshotCallback = ScreenshotCallback()
      ..addListener(() {
        if (_isExamActive) {
          _registerFraud(FraudType.screenshot, 'Captura de tela detectada');
        }
      });

    // Inicializar serviço em background
    _initializeBackgroundService();
  }

  Future<void> initialize() async {
    // Carregar tentativas salvas
    final prefs = await SharedPreferences.getInstance();
    _fraudAttempts = prefs.getInt('fraud_attempts') ?? 0;
    notifyListeners();
  }

  void startExamMonitoring(String examId) {
    _isExamActive = true;
    _currentExamId = examId;
    _fraudAttempts = 0;
    _fraudLog.clear();

    // Iniciar serviço em background
    FlutterBackgroundService().invoke('startMonitoring');
    notifyListeners();
  }

  void stopExamMonitoring() {
    _isExamActive = false;
    _currentExamId = null;
    FlutterBackgroundService().invoke('stopMonitoring');
    notifyListeners();
  }

  void _registerFraud(FraudType type, String description) {
    if (!_isExamActive || isBlocked) return;

    _fraudAttempts++;
    final attempt = FraudAttempt(type: type, timestamp: DateTime.now());
    _fraudLog.add(attempt);

    // Salvar localmente
    _saveFraudAttempt(type);

    // Notificar listeners
    notifyListeners();

    // Verificar se bloqueou
    if (isBlocked) {
      _blockExam();
    }
  }

  Future<void> _saveFraudAttempt(FraudType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('fraud_attempts', _fraudAttempts);

    // Salvar log
    final logKey = 'fraud_log_${DateTime.now().millisecondsSinceEpoch}';
    await prefs.setString(
        logKey, '${type.name}:${DateTime.now().toIso8601String()}');
  }

  void _blockExam() {
    // Bloquear a prova
    // Disparar evento para tela atual
    notifyListeners();
  }

  // Métodos de ciclo de vida do app
  static void _onResume() {
    // Verificar se estava em prova ativa
    // Registrar retorno ao app
  }

  static void _onPause() {
    // App foi minimizado
    // Implementar lógica se necessário
  }

  static void _onInactive() {
    // App perdeu foco (ex: bloqueio de tela)
    // Implementar lógica se necessário
  }

  static void _onDetach() {
    // App foi fechado
    // Implementar lógica se necessário
  }

  // Inicializar serviço em background
  void _initializeBackgroundService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: (service) {},
        onBackground: _onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        autoStart: false,
        onStart: _onStart,
        isForegroundMode: true,
      ),
    );
  }

  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) {
    if (service is AndroidServiceInstance) {
      service.on('startMonitoring').listen((event) {
        // Iniciar monitoramento
        service.setAsForegroundService();
      });

      service.on('stopMonitoring').listen((event) {
        // Parar monitoramento
        service.stopSelf();
      });
    }
  }

  @pragma('vm:entry-point')
  static bool _onIosBackground(ServiceInstance service) {
    return true;
  }

  @override
  void dispose() {
    _screenshotCallback.dispose();
    _appLifecycleStream.dispose();
    super.dispose();
  }
}
