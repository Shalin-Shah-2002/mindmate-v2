import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Simple user search: tries Firestore query, falls back to client filter
  Future<List<UserModel>> searchUsers(String query, {int limit = 20}) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    try {
      // Prefer lowercase name field if exists
      final lower = q.toLowerCase();
      QuerySnapshot<Map<String, dynamic>>? snapshot;

      try {
        snapshot = await _firestore
            .collection('users')
            .orderBy('nameLower')
            .startAt([lower])
            .endAt(['$lower\uf8ff'])
            .limit(limit)
            .get();
      } catch (_) {
        // Fallback to ordering by name (case-sensitive) and filter client-side
        snapshot = await _firestore
            .collection('users')
            .orderBy('name')
            .limit(100)
            .get();
      }

      final docs = snapshot.docs
          .map((d) => UserModel.fromMap(d.data(), d.id))
          .where((u) {
            final name = (u.name).toLowerCase();
            // No username field in model; rely on name+email
            final email = (u.email).toLowerCase();
            final lq = q.toLowerCase();
            return name.contains(lq) || email.contains(lq);
          })
          .take(limit)
          .toList();

      return docs;
    } catch (e) {
      print('SearchService.searchUsers error: $e');
      return [];
    }
  }

  // Simple posts search: fetch recent and filter by content/authorName
  Future<List<PostModel>> searchPosts(String query, {int limit = 30}) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    try {
      final snapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(120)
          .get();

      final lq = q.toLowerCase();
      final posts = snapshot.docs
          .map((d) => PostModel.fromMap(d.data(), d.id))
          .where((p) {
            final content = p.content.toLowerCase();
            final name =
                (p.authorName.isNotEmpty
                        ? p.authorName
                        : (p.userName.isNotEmpty ? p.userName : ''))
                    .toLowerCase();
            return content.contains(lq) || name.contains(lq);
          })
          .take(limit)
          .toList();

      return posts;
    } catch (e) {
      print('SearchService.searchPosts error: $e');
      return [];
    }
  }
}
