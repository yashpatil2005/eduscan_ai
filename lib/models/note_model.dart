import 'package:cloud_firestore/cloud_firestore.dart';

class Flashcard {
  final String question;
  final String answer;

  const Flashcard({required this.question, required this.answer});

  Map<String, dynamic> toJson() {
    return {'question': question, 'answer': answer};
  }

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
    );
  }
}

class Note {
  final String id;
  final String title;
  final String summary;
  // **CHANGE**: Replaced fileUrl with googleDriveFileId
  final String? googleDriveFileId;
  final List<String> youtubeLinks;
  final String conceptDiagramUrl;
  final List<Flashcard> flashcards;
  final String userId;
  final DateTime createdAt;

  Note({
    required this.id,
    required this.title,
    required this.summary,
    this.googleDriveFileId,
    required this.youtubeLinks,
    required this.conceptDiagramUrl,
    required this.flashcards,
    required this.userId,
    required this.createdAt,
  });

  Note copyWith({
    String? googleDriveFileId,
    String? userId,
    DateTime? createdAt,
  }) {
    return Note(
      id: id,
      title: title,
      summary: summary,
      googleDriveFileId: googleDriveFileId ?? this.googleDriveFileId,
      youtubeLinks: youtubeLinks,
      conceptDiagramUrl: conceptDiagramUrl,
      flashcards: flashcards,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'googleDriveFileId': googleDriveFileId,
      'youtubeLinks': youtubeLinks,
      'conceptDiagramUrl': conceptDiagramUrl,
      'flashcards': flashcards.map((f) => f.toJson()).toList(),
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      summary: json['summary'] ?? '',
      googleDriveFileId: json['googleDriveFileId'],
      youtubeLinks: List<String>.from(json['youtubeLinks'] ?? []),
      conceptDiagramUrl: json['conceptDiagramUrl'] ?? '',
      flashcards:
          (json['flashcards'] as List<dynamic>?)
              ?.map((f) => Flashcard.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
      userId: json['userId'] ?? '',
      createdAt: (json['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }
}
