import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exam_secure/main.dart';
import 'package:exam_secure/services/security_service.dart';

void main() {
  testWidgets('App carrega corretamente', (WidgetTester tester) async {
    // Constrói o aplicativo com um serviço de segurança fake
    final securityService = SecurityService();
    await tester.pumpWidget(MyApp(securityService: securityService));

    // Verifica se um MaterialApp foi carregado
    expect(find.byType(MaterialApp), findsOneWidget);

    // Verifica se a tela inicial existe
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
