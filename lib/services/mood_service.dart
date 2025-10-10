import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mood_entry.dart';

class MoodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _entriesCol(String userId) {
    return _firestore
        .collection('mood_entries')
        .doc(userId)
        .collection('entries');
  }

  Future<bool> addMoodEntry({
    required String mood,
    required int intensity,
    String note = '',
    DateTime? createdAt,
  }) async {
    try {
      if (_uid == null) return false;
      final entry = MoodEntry(
        id: '',
        userId: _uid!,
        mood: mood,
        intensity: intensity.clamp(1, 5),
        note: note.trim(),
        createdAt: createdAt ?? DateTime.now(),
      );
      await _entriesCol(_uid!).add(entry.toMap());
      return true;
    } catch (e) {
      print('MoodService.addMoodEntry error: $e');
      return false;
    }
  }

  Future<List<MoodEntry>> getRecentEntries({int limit = 30}) async {
    try {
      if (_uid == null) return [];
      final qs = await _entriesCol(
        _uid!,
      ).orderBy('createdAt', descending: true).limit(limit).get();
      return qs.docs.map((d) => MoodEntry.fromMap(d.data(), d.id)).toList();
    } catch (e) {
      print('MoodService.getRecentEntries error: $e');
      return [];
    }
  }

  Stream<List<MoodEntry>> entriesStream({int limit = 60}) {
    if (_uid == null) {
      // Return an empty stream if not logged in
      return const Stream<List<MoodEntry>>.empty();
    }
    return _entriesCol(_uid!)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((d) => MoodEntry.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  Future<bool> deleteEntry(String entryId) async {
    try {
      if (_uid == null) return false;
      await _entriesCol(_uid!).doc(entryId).delete();
      return true;
    } catch (e) {
      print('MoodService.deleteEntry error: $e');
      return false;
    }
  }
}
