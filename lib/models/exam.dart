import 'question.dart';

class Exam {
  final String id;
  final String title;
  final String subject;
  final int duration; // em minutos
  final DateTime startTime;
  final DateTime endTime;
  final List<Question> questions;
  final String? pdfUrl;
  final int maxFraudAttempts;
  final bool shuffleQuestions;
  final bool shuffleOptions;

  Exam({
    required this.id,
    required this.title,
    required this.subject,
    required this.duration,
    required this.startTime,
    required this.endTime,
    required this.questions,
    this.pdfUrl,
    this.maxFraudAttempts = 3,
    this.shuffleQuestions = false,
    this.shuffleOptions = false,
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    var questionsList = <Question>[];
    if (json['questions'] != null) {
      questionsList = List<Question>.from(
        json['questions'].map((q) => Question.fromJson(q))
      );
    }

    return Exam(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      subject: json['subject'] ?? '',
      duration: json['duration'] ?? 60,
      startTime: DateTime.parse(json['startTime'] ?? DateTime.now().toIso8601String()),
      endTime: DateTime.parse(json['endTime'] ?? DateTime.now().toIso8601String()),
      questions: questionsList,
      pdfUrl: json['pdfUrl'],
      maxFraudAttempts: json['maxFraudAttempts'] ?? 3,
      shuffleQuestions: json['shuffleQuestions'] ?? false,
      shuffleOptions: json['shuffleOptions'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'duration': duration,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'questions': questions.map((q) => q.toJson()).toList(),
      'pdfUrl': pdfUrl,
      'maxFraudAttempts': maxFraudAttempts,
      'shuffleQuestions': shuffleQuestions,
      'shuffleOptions': shuffleOptions,
    };
  }

  bool get isAvailable {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  Duration get timeUntilStart => startTime.difference(DateTime.now());
  Duration get timeUntilEnd => endTime.difference(DateTime.now());
}