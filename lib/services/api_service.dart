import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/exam.dart';
import '../models/answer.dart';
import '../utils/app_constants.dart';

class ApiService {
  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // Interceptor para adicionar token de autenticação
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expirado - fazer logout
          await _storage.delete(key: 'auth_token');
        }
        return handler.next(error);
      },
    ));
  }

  // Login do aluno
  Future<Map<String, dynamic>> login(String credential, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'credential': credential,
        'password': password,
      });
      
      if (response.statusCode == 200) {
        final data = response.data;
        await _storage.write(key: 'auth_token', value: data['token']);
        await _storage.write(key: 'student_id', value: data['student_id'].toString());
        return data;
      }
      throw Exception('Falha no login');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Buscar prova disponível
  Future<Exam?> getAvailableExam() async {
    try {
      final studentId = await _storage.read(key: 'student_id');
      final response = await _dio.get('/student/$studentId/exams/available');
      
      if (response.statusCode == 200 && response.data != null) {
        return Exam.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Iniciar prova
  Future<bool> startExam(String examId) async {
    try {
      final studentId = await _storage.read(key: 'student_id');
      final response = await _dio.post('/exam/start', data: {
        'student_id': studentId,
        'exam_id': examId,
        'start_time': DateTime.now().toIso8601String(),
      });
      
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Enviar resposta
  Future<bool> submitAnswer(String examId, Answer answer) async {
    try {
      final studentId = await _storage.read(key: 'student_id');
      final response = await _dio.post('/exam/answer', data: {
        'student_id': studentId,
        'exam_id': examId,
        'question_id': answer.questionId,
        'answer': answer.answer,
        'timestamp': answer.timestamp.toIso8601String(),
      });
      
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Enviar prova completa
  Future<bool> submitExam(ExamSubmission submission) async {
    try {
      final response = await _dio.post('/exam/submit', data: submission.toJson());
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Registrar tentativa de fraude
  Future<void> registerFraudAttempt(String examId, String type) async {
    try {
      final studentId = await _storage.read(key: 'student_id');
      await _dio.post('/exam/fraud', data: {
        'student_id': studentId,
        'exam_id': examId,
        'type': type,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Log error but don't throw - fraud attempts should be recorded locally too
      print('Erro ao registrar fraude: $e');
    }
  }

  String _handleError(DioException error) {
    if (error.response != null) {
      // Erro do servidor
      final data = error.response?.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'];
      }
      return 'Erro ${error.response?.statusCode}: ${error.response?.statusMessage}';
    } else if (error.type == DioExceptionType.connectionTimeout) {
      return 'Tempo limite de conexão excedido';
    } else if (error.type == DioExceptionType.receiveTimeout) {
      return 'Tempo limite de recebimento excedido';
    } else {
      return 'Erro de conexão: ${error.message}';
    }
  }
}