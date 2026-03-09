enum QuestionType {
  multipleChoice,
  trueFalse,
  shortAnswer,
}

class Question {
  final String id;
  final String text;
  final QuestionType type;
  final List<String> options;
  final String? correctAnswer;
  final int points;
  final String? imageUrl;

  Question({
    required this.id,
    required this.text,
    required this.type,
    required this.options,
    this.correctAnswer,
    required this.points,
    this.imageUrl,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'].toString(),
      text: json['text'] ?? '',
      type: _parseQuestionType(json['type']),
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'],
      points: json['points'] ?? 1,
      imageUrl: json['imageUrl'],
    );
  }

  static QuestionType _parseQuestionType(String type) {
    switch (type.toLowerCase()) {
      case 'multiplechoice':
      case 'multiple_choice':
        return QuestionType.multipleChoice;
      case 'truefalse':
      case 'true_false':
        return QuestionType.trueFalse;
      default:
        return QuestionType.shortAnswer;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'type': type.toString(),
      'options': options,
      'correctAnswer': correctAnswer,
      'points': points,
      'imageUrl': imageUrl,
    };
  }
}