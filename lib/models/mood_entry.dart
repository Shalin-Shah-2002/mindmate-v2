import 'package:cloud_firestore/cloud_firestore.dart';

class MoodEntry {
  final String id;
  final String userId;
  final String mood; // e.g., happy, sad, anxious, calm
  final int intensity; // 1-5
  final String note;
  final DateTime createdAt;

  MoodEntry({
    required this.id,
    required this.userId,
    required this.mood,
    required this.intensity,
    required this.note,
    required this.createdAt,
  });

  MoodEntry copyWith({
    String? id,
    String? userId,
    String? mood,
    int? intensity,
    String? note,
    DateTime? createdAt,
  }) {
    return MoodEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mood: mood ?? this.mood,
      intensity: intensity ?? this.intensity,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'mood': mood,
      'intensity': intensity,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      // Lowercased mirrors for potential filtering
      'moodLower': mood.toLowerCase(),
    };
  }

  factory MoodEntry.fromMap(Map<String, dynamic> map, String id) {
    final ts = map['createdAt'];
    DateTime created;
    if (ts is Timestamp) {
      created = ts.toDate();
    } else if (ts is DateTime) {
      created = ts;
    } else {
      created = DateTime.now();
    }

    return MoodEntry(
      id: id,
      userId: map['userId'] ?? '',
      mood: map['mood'] ?? '',
      intensity: (map['intensity'] ?? 3) is int
          ? (map['intensity'] ?? 3)
          : int.tryParse(map['intensity'].toString()) ?? 3,
      note: map['note'] ?? '',
      createdAt: created,
    );
  }
}
