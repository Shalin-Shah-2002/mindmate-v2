import 'package:get/get.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';

class CommunityViewModel extends GetxController {
  final PostService _postService = PostService();
  final AuthService _authService = AuthService();

  // Observable lists
  final RxList<PostModel> posts = <PostModel>[].obs;
  final RxList<PostModel> userPosts = <PostModel>[].obs;

  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool isLoadingUserPosts = false.obs;
  final RxBool isCreatingPost = false.obs;

  // Post creation
  final RxString postContent = ''.obs;
  final RxString selectedMood = ''.obs;
  final RxBool isAnonymous = false.obs;
  final RxList<String> selectedTags = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadPosts();
  }

  // Load all posts
  Future<void> loadPosts() async {
    try {
      isLoading.value = true;
      final allPosts = await _postService.getAllPosts();
      posts.value = allPosts;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load posts: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Load user's posts
  Future<void> loadUserPosts(String userId) async {
    try {
      isLoadingUserPosts.value = true;
      final userPostsList = await _postService.getUserPosts(userId);
      userPosts.value = userPostsList;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load user posts: $e');
    } finally {
      isLoadingUserPosts.value = false;
    }
  }

  // Create a new post
  Future<void> createPost() async {
    if (postContent.value.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter some content for your post');
      return;
    }

    try {
      isCreatingPost.value = true;

      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        Get.snackbar('Error', 'Please log in to create a post');
        return;
      }

      final newPost = PostModel(
        id: '',
        userId: currentUser.uid,
        content: postContent.value.trim(),
        imageUrl: '', // Will be handled separately for image posts
        isAnonymous: isAnonymous.value,
        createdAt: DateTime.now(),
        likesCount: 0,
        commentsCount: 0,
        sharesCount: 0,
      );

      final success = await _postService.createPost(newPost);

      if (success) {
        // Clear form
        clearPostForm();

        // Refresh posts
        await loadPosts();

        Get.snackbar('Success', 'Post created successfully!');
        Get.back(); // Close create post dialog/screen
      } else {
        Get.snackbar('Error', 'Failed to create post');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to create post: $e');
    } finally {
      isCreatingPost.value = false;
    }
  }

  // Like/Unlike a post
  Future<void> toggleLike(String postId, int index) async {
    try {
      final success = await _postService.likePost(postId);
      if (success) {
        // Reload posts to get updated counts
        await loadPosts();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to like post: $e');
    }
  }

  // Add comment to a post
  Future<void> addComment(String postId, String content, int postIndex) async {
    if (content.trim().isEmpty) return;

    try {
      final success = await _postService.addComment(postId, content);
      if (success) {
        // Reload posts to get updated counts
        await loadPosts();
        Get.snackbar('Success', 'Comment added successfully');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to add comment: $e');
    }
  }

  // Get comments for a post
  Future<List<CommentModel>> getPostComments(String postId) async {
    try {
      return await _postService.getPostComments(postId);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load comments: $e');
      return [];
    }
  }

  // Delete post
  Future<void> deletePost(String postId, String postUserId, int index) async {
    try {
      final success = await _postService.deletePost(postId, postUserId);
      if (success) {
        posts.removeAt(index);
        Get.snackbar('Success', 'Post deleted successfully');
      } else {
        Get.snackbar('Error', 'You can only delete your own posts');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete post: $e');
    }
  }

  // Report post
  Future<void> reportPost(String postId, String reason) async {
    try {
      final success = await _postService.reportPost(postId, reason);
      if (success) {
        Get.snackbar('Success', 'Post reported successfully');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to report post: $e');
    }
  }

  // Post creation form methods
  void updateContent(String content) {
    postContent.value = content;
  }

  void selectMood(String mood) {
    selectedMood.value = mood;
  }

  void toggleAnonymous() {
    isAnonymous.value = !isAnonymous.value;
  }

  void addTag(String tag) {
    if (!selectedTags.contains(tag) && selectedTags.length < 5) {
      selectedTags.add(tag);
    }
  }

  void removeTag(String tag) {
    selectedTags.remove(tag);
  }

  void clearPostForm() {
    postContent.value = '';
    selectedMood.value = '';
    isAnonymous.value = false;
    selectedTags.clear();
  }

  // Refresh posts
  Future<void> refreshPosts() async {
    await loadPosts();
  }

  // Check if current user liked a post
  Future<bool> isPostLiked(String postId) async {
    return await _postService.isPostLiked(postId);
  }

  // Available moods for post creation
  List<String> get availableMoods => [
    'Happy',
    'Sad',
    'Anxious',
    'Excited',
    'Grateful',
    'Frustrated',
    'Peaceful',
    'Overwhelmed',
    'Hopeful',
    'Confused',
  ];

  // Popular tags for mental health posts
  List<String> get popularTags => [
    'mentalhealth',
    'selfcare',
    'anxiety',
    'depression',
    'wellness',
    'therapy',
    'mindfulness',
    'support',
    'recovery',
    'positivity',
    'motivation',
    'gratitude',
  ];
}
