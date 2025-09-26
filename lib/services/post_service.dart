import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Simple in-memory cache to avoid repeated user lookups per session
  final Map<String, Map<String, dynamic>> _userCache = {};

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Create a new post
  Future<bool> createPost(PostModel post) async {
    try {
      if (currentUserId == null) return false;

      // Denormalize author fields for reliable display
      final data = post.toMap();
      if (!post.isAnonymous) {
        // Prefer users collection, fallback to FirebaseAuth user fields
        final userData = await _fetchUserData(currentUserId!);
        final authUser = _auth.currentUser;
        final name =
            userData['displayName'] ??
            userData['name'] ??
            userData['username'] ??
            authUser?.displayName ??
            '';
        final photoUrl =
            (userData['profilePhotoUrl'] ??
                    userData['photoURL'] ??
                    userData['photoUrl'] ??
                    userData['avatarUrl'] ??
                    userData['avatar'] ??
                    userData['profilePic'] ??
                    userData['profile_picture'] ??
                    userData['imageUrl'] ??
                    userData['imageURL'] ??
                    authUser?.photoURL ??
                    '')
                .toString();
        data['authorName'] = name;
        data['userName'] = name;
        // Lowercased mirrors to support indexed search
        data['authorNameLower'] = name.toLowerCase();
        data['userNameLower'] = name.toLowerCase();
        data['profilePhotoUrl'] = photoUrl;
      }
      // Always store contentLower for search
      data['contentLower'] = (post.content).toLowerCase();

      await _firestore.collection('posts').add(data);
      return true;
    } catch (e) {
      print('Error creating post: $e');
      return false;
    }
  }

  // Get all posts (recent first)
  Future<List<PostModel>> getAllPosts({int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final posts = querySnapshot.docs
          .map((doc) => PostModel.fromMap(doc.data(), doc.id))
          .toList();

      // Enrich posts with author display names and profile photo when not anonymous
      for (var i = 0; i < posts.length; i++) {
        final p = posts[i];
        if (p.userId.isNotEmpty && !p.isAnonymous) {
          final userData = await _fetchUserData(p.userId);
          final name =
              userData['displayName'] ??
              userData['name'] ??
              userData['username'] ??
              userData['fullName'] ??
              '';
          // Try common field names for photo URL
          final photoUrl =
              (userData['profilePhotoUrl'] ??
                      userData['photoURL'] ??
                      userData['photoUrl'] ??
                      userData['avatarUrl'] ??
                      userData['avatar'] ??
                      userData['profilePic'] ??
                      userData['profile_picture'] ??
                      userData['imageUrl'] ??
                      userData['imageURL'] ??
                      '')
                  .toString();
          posts[i] = p.copyWith(
            authorName: name,
            userName: name,
            profilePhotoUrl: photoUrl,
          );
        }
      }

      return posts;
    } catch (e) {
      print('Error getting posts: $e');
      return [];
    }
  }

  // Get posts by specific user
  Future<List<PostModel>> getUserPosts(String userId, {int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final posts = querySnapshot.docs
          .map((doc) => PostModel.fromMap(doc.data(), doc.id))
          .toList();

      // Enrich with author names and profile photo when not anonymous
      for (var i = 0; i < posts.length; i++) {
        final p = posts[i];
        if (p.userId.isNotEmpty && !p.isAnonymous) {
          final userData = await _fetchUserData(p.userId);
          final name =
              userData['displayName'] ??
              userData['name'] ??
              userData['username'] ??
              userData['fullName'] ??
              '';
          final photoUrl =
              (userData['profilePhotoUrl'] ??
                      userData['photoURL'] ??
                      userData['photoUrl'] ??
                      userData['avatarUrl'] ??
                      userData['avatar'] ??
                      userData['profilePic'] ??
                      userData['profile_picture'] ??
                      userData['imageUrl'] ??
                      userData['imageURL'] ??
                      '')
                  .toString();
          posts[i] = p.copyWith(
            authorName: name,
            userName: name,
            profilePhotoUrl: photoUrl,
          );
        }
      }

      return posts;
    } catch (e) {
      print('Error getting user posts: $e');
      // If the query fails due to index issues, try a simpler query
      return await getUserPostsSimple(userId, limit: limit);
    }
  }

  // Fallback method for user posts without ordering (simpler query)
  Future<List<PostModel>> getUserPostsSimple(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .limit(limit)
          .get();

      final posts = querySnapshot.docs
          .map((doc) => PostModel.fromMap(doc.data(), doc.id))
          .toList();

      // Sort by createdAt manually
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Enrich with author names and profile photo when not anonymous
      for (var i = 0; i < posts.length; i++) {
        final p = posts[i];
        if (p.userId.isNotEmpty && !p.isAnonymous) {
          final userData = await _fetchUserData(p.userId);
          final name =
              userData['displayName'] ??
              userData['name'] ??
              userData['username'] ??
              userData['fullName'] ??
              '';
          final photoUrl =
              (userData['profilePhotoUrl'] ??
                      userData['photoURL'] ??
                      userData['photoUrl'] ??
                      userData['avatarUrl'] ??
                      userData['avatar'] ??
                      userData['profilePic'] ??
                      userData['profile_picture'] ??
                      userData['imageUrl'] ??
                      userData['imageURL'] ??
                      '')
                  .toString();
          posts[i] = p.copyWith(
            authorName: name,
            userName: name,
            profilePhotoUrl: photoUrl,
          );
        }
      }

      return posts;
    } catch (e) {
      print('Error getting user posts (simple): $e');
      return [];
    }
  }

  // Get posts stream for real-time updates
  Stream<List<PostModel>> getPostsStream({int limit = 20}) {
    // Note: Stream mapping is kept synchronous; downstream UI should fetch author names if needed.
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PostModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Helper to fetch a user's data from `users` collection
  Future<Map<String, dynamic>> _fetchUserData(String userId) async {
    try {
      // Check cache first
      final cached = _userCache[userId];
      if (cached != null) return cached;

      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          _userCache[userId] = data;
          return data;
        }
      }
      return {};
    } catch (e) {
      print('Error fetching user data: $e');
      return {};
    }
  }

  // Like a post
  Future<bool> likePost(String postId) async {
    try {
      if (currentUserId == null) return false;

      final likeRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(currentUserId);

      // Check if already liked
      final likeDoc = await likeRef.get();
      if (likeDoc.exists) {
        // Unlike the post
        await likeRef.delete();
        await _decrementLikeCount(postId);
      } else {
        // Like the post
        final like = LikeModel(
          id: currentUserId!,
          userId: currentUserId!,
          createdAt: DateTime.now(),
        );
        await likeRef.set(like.toMap());
        await _incrementLikeCount(postId);
      }
      return true;
    } catch (e) {
      print('Error liking post: $e');
      return false;
    }
  }

  // Check if current user liked a post
  Future<bool> isPostLiked(String postId) async {
    try {
      if (currentUserId == null) return false;

      final likeDoc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(currentUserId)
          .get();

      return likeDoc.exists;
    } catch (e) {
      print('Error checking if post is liked: $e');
      return false;
    }
  }

  // Add comment to post
  Future<bool> addComment(String postId, String content) async {
    try {
      if (currentUserId == null) return false;

      final comment = CommentModel(
        id: '',
        userId: currentUserId!,
        content: content,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add(comment.toMap());

      await _incrementCommentCount(postId);
      return true;
    } catch (e) {
      print('Error adding comment: $e');
      return false;
    }
  }

  // Get comments for a post
  Future<List<CommentModel>> getPostComments(String postId) async {
    try {
      final querySnapshot = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .orderBy('createdAt', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => CommentModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting comments: $e');
      return [];
    }
  }

  // Real-time comments stream for a post (ascending by createdAt)
  Stream<List<CommentModel>> getPostCommentsStream(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CommentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Delete a post (only by owner)
  Future<bool> deletePost(String postId, String postUserId) async {
    try {
      if (currentUserId == null || currentUserId != postUserId) return false;

      await _firestore.collection('posts').doc(postId).delete();
      return true;
    } catch (e) {
      print('Error deleting post: $e');
      return false;
    }
  }

  // Report a post
  Future<bool> reportPost(String postId, String reason) async {
    try {
      if (currentUserId == null) return false;

      await _firestore.collection('reports').add({
        'postId': postId,
        'reportedBy': currentUserId,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error reporting post: $e');
      return false;
    }
  }

  // Private helper methods
  Future<void> _incrementLikeCount(String postId) async {
    await _firestore.collection('posts').doc(postId).update({
      'likesCount': FieldValue.increment(1),
    });
  }

  Future<void> _decrementLikeCount(String postId) async {
    await _firestore.collection('posts').doc(postId).update({
      'likesCount': FieldValue.increment(-1),
    });
  }

  Future<void> _incrementCommentCount(String postId) async {
    await _firestore.collection('posts').doc(postId).update({
      'commentsCount': FieldValue.increment(1),
    });
  }
}
