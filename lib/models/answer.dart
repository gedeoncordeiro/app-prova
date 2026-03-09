class Answer {
  final String questionId;
  final String answer;
  final DateTime timestamp;
  bool isCorrect;
  int? timeSpent; // em segundos

  Answer({
    required this.questionId,
    required this.answer,
    required this.timestamp,
    this.isCorrect = false,
    this.timeSpent,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      questionId: json['questionId'].toString(),
      answer: json['answer'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isCorrect: json['isCorrect'] ?? false,
      timeSpent: json['timeSpent'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'answer': answer,
      'timestamp': timestamp.toIso8601String(),
      'isCorrect': isCorrect,
      'timeSpent': timeSpent,
    };
  }
}

class ExamSubmission {
  final String studentId;
  final String examId;
  final List<Answer> answers;
  final int fraudAttempts;
  final DateTime submissionTime;
  final bool completed;

  ExamSubmission({
    required this.studentId,
    required this.examId,
    required this.answers,
    required this.fraudAttempts,
    required this.submissionTime,
    required this.completed,
  });

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'exam_id': examId,
      'answers': answers.map((a) => {
        'question_id': a.questionId,
        'answer': a.answer,
      }).toList(),
      'fraud_attempts': fraudAttempts,
      'submission_time': submissionTime.toIso8601String(),
      'completed': completed,
    };
  }
}