import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/exam_screen.dart';
import 'screens/result_screen.dart';
import 'services/security_service.dart';
import 'services/api_service.dart';
import 'utils/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar serviços de segurança
  final securityService = SecurityService();
  await securityService.initialize();
  
  // Verificar permissões necessárias
  await _checkPermissions();
  
  runApp(MyApp(securityService: securityService));
}

Future<void> _checkPermissions() async {
  // Solicitar permissões necessárias
  await [
    Permission.storage,
    Permission.photos,
  ].request();
}

class MyApp extends StatelessWidget {
  final SecurityService securityService;
  
  const MyApp({super.key, required this.securityService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => securityService),
        Provider(create: (_) => ApiService()),
        Provider(create: (_) => FlutterSecureStorage()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
          ),
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/exam': (context) => const ExamScreen(),
          '/result': (context) => const ResultScreen(),
        },
      ),
    );
  }
}