import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User search with multiple strategies and client-side fallback
  Future<List<UserModel>> searchUsers(String query, {int limit = 20}) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    try {
      final lower = q.toLowerCase();
      final results = <UserModel>[];
      final seen = <String>{};

      // Try nameLower prefix
      try {
        final snap = await _firestore
            .collection('users')
            .orderBy('nameLower')
            .startAt([lower])
            .endAt(['$lower\uf8ff'])
            .limit(50)
            .get();
        for (final d in snap.docs) {
          if (seen.add(d.id)) results.add(UserModel.fromMap(d.data(), d.id));
        }
      } catch (_) {}

      // Try displayNameLower prefix (if present in some docs)
      try {
        final snap = await _firestore
            .collection('users')
            .orderBy('displayNameLower')
            .startAt([lower])
            .endAt(['$lower\uf8ff'])
            .limit(50)
            .get();
        for (final d in snap.docs) {
          if (seen.add(d.id)) results.add(UserModel.fromMap(d.data(), d.id));
        }
      } catch (_) {}

      // Try emailLower prefix
      try {
        final snap = await _firestore
            .collection('users')
            .orderBy('emailLower')
            .startAt([lower])
            .endAt(['$lower\uf8ff'])
            .limit(50)
            .get();
        for (final d in snap.docs) {
          if (seen.add(d.id)) results.add(UserModel.fromMap(d.data(), d.id));
        }
      } catch (_) {}

      // Try name (case-sensitive prefix)
      try {
        final snap = await _firestore
            .collection('users')
            .orderBy('name')
            .startAt([query])
            .endAt(['$query\uf8ff'])
            .limit(50)
            .get();
        for (final d in snap.docs) {
          if (seen.add(d.id)) results.add(UserModel.fromMap(d.data(), d.id));
        }
      } catch (_) {}

      // Try displayName (case-sensitive prefix)
      try {
        final snap = await _firestore
            .collection('users')
            .orderBy('displayName')
            .startAt([query])
            .endAt(['$query\uf8ff'])
            .limit(50)
            .get();
        for (final d in snap.docs) {
          if (seen.add(d.id)) results.add(UserModel.fromMap(d.data(), d.id));
        }
      } catch (_) {}

      // Fallback: fetch larger window and filter locally
      if (results.isEmpty) {
        final snap = await _firestore.collection('users').limit(500).get();
        for (final d in snap.docs) {
          if (seen.add(d.id)) results.add(UserModel.fromMap(d.data(), d.id));
        }
      }

      final lq = q.toLowerCase();
      return results
          .where(
            (u) =>
                u.name.toLowerCase().contains(lq) ||
                u.email.toLowerCase().contains(lq),
          )
          .take(limit)
          .toList();
    } catch (e) {
      print('SearchService.searchUsers error: $e');
      return [];
    }
  }

  // Post search: try contentLower, else client-side filter of recent posts
  Future<List<PostModel>> searchPosts(String query, {int limit = 30}) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    try {
      // Try indexed contentLower
      try {
        final lower = q.toLowerCase();
        final snap = await _firestore
            .collection('posts')
            .orderBy('contentLower')
            .startAt([lower])
            .endAt(['$lower\uf8ff'])
            .limit(60)
            .get();
        final posts = snap.docs
            .map((d) => PostModel.fromMap(d.data(), d.id))
            .toList();
        if (posts.isNotEmpty) return posts.take(limit).toList();
      } catch (_) {}

      // Fallback: recent posts + client-side filter
      final snap = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(200)
          .get();
      final lq = q.toLowerCase();
      return snap.docs
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
    } catch (e) {
      print('SearchService.searchPosts error: $e');
      return [];
    }
  }
}
