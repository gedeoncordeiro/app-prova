import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exam.dart';
import '../models/answer.dart';
import '../services/api_service.dart';
import '../services/security_service.dart';
import '../widgets/question_widget.dart';
import '../widgets/timer_widget.dart';
import '../utils/app_constants.dart';

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  late Exam _exam;
  late int _currentQuestionIndex;
  final Map<String, String> _answers = {};
  final Map<String, int> _questionStartTime = {};
  Timer? _autoSaveTimer;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _exam = ModalRoute.of(context)!.settings.arguments as Exam;
    _currentQuestionIndex = 0;
    _startQuestionTimer();
    _startAutoSave();
  }

  void _startQuestionTimer() {
    _questionStartTime[_exam.questions[_currentQuestionIndex].id] =
        DateTime.now().millisecondsSinceEpoch;
  }

  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(
      const Duration(seconds: AppConstants.autoSaveInterval),
      (_) => _autoSaveAnswers(),
    );
  }

  Future<void> _autoSaveAnswers() async {
    if (_answers.isEmpty) return;

    final apiService = Provider.of<ApiService>(context, listen: false);

    for (var entry in _answers.entries) {
      final answer = Answer(
        questionId: entry.key,
        answer: entry.value,
        timestamp: DateTime.now(),
      );
      await apiService.submitAnswer(_exam.id, answer);
    }
  }

  void _handleAnswerSelected(String questionId, String answer) {
    setState(() {
      _answers[questionId] = answer;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _exam.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _startQuestionTimer();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
      _startQuestionTimer();
    }
  }

  Future<void> _submitExam() async {
    if (_isSubmitting) return;

    // Verificar se todas as questões foram respondidas
    if (_answers.length < _exam.questions.length) {
      final confirm = await _showConfirmDialog(
        'Atenção',
        'Você ainda não respondeu todas as questões. Deseja enviar mesmo assim?',
      );
      if (!confirm) return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final securityService =
          Provider.of<SecurityService>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);

      // Criar lista de respostas
      final answers = _answers.entries.map((entry) {
        return Answer(
          questionId: entry.key,
          answer: entry.value,
          timestamp: DateTime.now(),
        );
      }).toList();

      // Criar submissão
      final submission = ExamSubmission(
        studentId: '123', // TODO: Pegar do storage
        examId: _exam.id,
        answers: answers,
        fraudAttempts: securityService.fraudAttempts,
        submissionTime: DateTime.now(),
        completed: true,
      );

      // Enviar para API
      final success = await apiService.submitExam(submission);

      if (success && mounted) {
        // Parar monitoramento
        securityService.stopExamMonitoring();

        // Cancelar timer
        _autoSaveTimer?.cancel();

        // Navegar para tela de resultado
        Navigator.pushReplacementNamed(
          context,
          '/result',
          arguments: {
            'exam': _exam,
            'answers': answers,
          },
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar prova: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final securityService = Provider.of<SecurityService>(context);
    final currentQuestion = _exam.questions[_currentQuestionIndex];

    // O widget WillPopScope está depreciado, mas PopScope
    // ainda não possui o parâmetro onWillPop na versão atual do SDK.
    // Mantemos o uso antigo para compatibilidade.
    return WillPopScope(
      onWillPop: () async {
        // Bloquear botão de voltar durante a prova
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_exam.title),
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  // Timer
                  TimerWidget(
                    duration: _exam.duration * 60,
                    onTimerComplete: _submitExam,
                  ),
                  const SizedBox(height: 8),
                  // Progresso
                  LinearProgressIndicator(
                    value: (_currentQuestionIndex + 1) / _exam.questions.length,
                    // ignore: deprecated_member_use
                    backgroundColor: Colors.grey.withOpacity(0.3),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Questão ${_currentQuestionIndex + 1} de ${_exam.questions.length}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: securityService.isBlocked
            ? _buildBlockedWidget()
            : Column(
                children: [
                  // Questão atual
                  Expanded(
                    child: QuestionWidget(
                      question: currentQuestion,
                      selectedAnswer: _answers[currentQuestion.id],
                      onAnswerSelected: (answer) =>
                          _handleAnswerSelected(currentQuestion.id, answer),
                    ),
                  ),

                  // Navegação
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          offset: const Offset(0, -2),
                          blurRadius: 4,
                          // ignore: deprecated_member_use
                          color: Colors.grey.withOpacity(0.1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Botão anterior
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _currentQuestionIndex > 0
                                ? _previousQuestion
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('ANTERIOR'),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Botão próximo/enviar
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _currentQuestionIndex ==
                                    _exam.questions.length - 1
                                ? _submitExam
                                : _nextQuestion,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              _currentQuestionIndex ==
                                      _exam.questions.length - 1
                                  ? 'ENVIAR'
                                  : 'PRÓXIMO',
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

  Widget _buildBlockedWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.block,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Prova Bloqueada',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Você excedeu o número máximo de tentativas de fraude.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text('VOLTAR AO INÍCIO'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}
