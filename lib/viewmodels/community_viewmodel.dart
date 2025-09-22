import 'package:get/get.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';
import '../services/search_service.dart';
import 'auth_viewmodel.dart';
import 'package:get/get_rx/src/rx_workers/rx_workers.dart';

class CommunityViewModel extends GetxController {
  final PostService _postService = PostService();
  final AuthService _authService = AuthService();
  final SearchService _searchService = SearchService();

  // Observable lists
  final RxList<PostModel> posts = <PostModel>[].obs;
  final RxList<PostModel> userPosts = <PostModel>[].obs;

  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool isLoadingUserPosts = false.obs;
  final RxBool isCreatingPost = false.obs;
  final RxBool hasTriedLoadingUserPosts =
      false.obs; // Track if we've attempted to load user posts

  // Track which posts are currently being liked to prevent multiple clicks
  final RxSet<String> likingPosts = <String>{}.obs;

  // Search state
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;
  final RxList<UserModel> searchUsersResults = <UserModel>[].obs;
  final RxList<PostModel> searchPostsResults = <PostModel>[].obs;
  final RxBool showSearchResults = false.obs;
  late final Worker _searchWorker;

  // Post creation
  final RxString postContent = ''.obs;
  final RxString selectedMood = ''.obs;
  final RxBool isAnonymous = false.obs;
  final RxList<String> selectedTags = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadPosts();
    // Debounced search
    _searchWorker = debounce<String>(searchQuery, (q) async {
      final text = q.trim();
      if (text.isEmpty) {
        showSearchResults.value = false;
        searchUsersResults.clear();
        searchPostsResults.clear();
        return;
      }
      await _runSearch(text);
    }, time: const Duration(milliseconds: 300));
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

  void updateSearchQuery(String value) {
    searchQuery.value = value;
  }

  void clearSearch() {
    searchQuery.value = '';
    isSearching.value = false;
    showSearchResults.value = false;
    searchUsersResults.clear();
    searchPostsResults.clear();
  }

  @override
  void onClose() {
    _searchWorker.dispose();
    super.onClose();
  }

  Future<void> _runSearch(String query) async {
    try {
      isSearching.value = true;
      showSearchResults.value = true;
      // Run in parallel
      final usersF = _searchService.searchUsers(query, limit: 15);
      final postsF = _searchService.searchPosts(query, limit: 30);
      final results = await Future.wait([usersF, postsF]);
      searchUsersResults.assignAll(results[0] as List<UserModel>);
      searchPostsResults.assignAll(results[1] as List<PostModel>);
    } catch (e) {
      Get.snackbar('Search error', 'Failed to search: $e');
    } finally {
      isSearching.value = false;
    }
  }

  // Load user's posts
  Future<void> loadUserPosts() async {
    if (hasTriedLoadingUserPosts.value) return; // Only try once

    final currentUser = Get.find<AuthViewModel>().userModel;
    if (currentUser == null) return;

    try {
      isLoadingUserPosts.value = true;
      hasTriedLoadingUserPosts.value = true;

      // Get user posts using PostService directly
      final posts = await _postService.getUserPosts(currentUser.id);
      userPosts.value = posts;
      print('CommunityViewModel: Loaded ${posts.length} user posts');
    } catch (e) {
      print('CommunityViewModel: Error loading user posts: $e');

      // Check if the error is related to missing index and try fallback
      if (e.toString().contains('failed-precondition') ||
          e.toString().contains('index is currently building') ||
          e.toString().contains('requires an index')) {
        print('CommunityViewModel: Trying fallback method due to index issue');
        try {
          final fallbackPosts = await _postService.getUserPostsSimple(
            currentUser.id,
          );
          userPosts.value = fallbackPosts;
          print(
            'CommunityViewModel: Fallback loaded ${fallbackPosts.length} user posts',
          );
        } catch (fallbackError) {
          print('CommunityViewModel: Fallback also failed: $fallbackError');
        }
      }
    } finally {
      isLoadingUserPosts.value = false;
    }
  }

  // Add method to manually retry loading user posts
  Future<void> retryLoadUserPosts() async {
    hasTriedLoadingUserPosts.value = false; // Reset the flag
    await loadUserPosts();
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

  // Like/Unlike a post with optimistic updates
  Future<void> toggleLike(String postId, int index) async {
    // Prevent multiple simultaneous like requests on same post
    if (likingPosts.contains(postId)) return;

    // Get the current post and keep a reference to revert on error
    if (index < 0 || index >= posts.length) return;
    final post = posts[index];

    try {
      likingPosts.add(postId);

      // Check current like status
      final isCurrentlyLiked = await _postService.isPostLiked(postId);

      // OPTIMISTIC UPDATE: Update UI immediately for better UX using copyWith
      final optimisticLikeCount = isCurrentlyLiked
          ? (post.likesCount > 0 ? post.likesCount - 1 : 0)
          : post.likesCount + 1;

      final optimisticPost = post.copyWith(likesCount: optimisticLikeCount);

      // Update UI immediately (replace single item)
      posts[index] = optimisticPost;

      // Now make the API call
      final success = await _postService.likePost(postId);

      if (!success) {
        // If API call failed, revert the optimistic update
        posts[index] = post;
        Get.snackbar('Error', 'Failed to like post. Please try again.');
      } else {
        print(
          'CommunityViewModel: Post ${isCurrentlyLiked ? 'unliked' : 'liked'} successfully',
        );
      }
    } catch (e) {
      // If there's an error, revert to original state (only revert the single item)
      if (index >= 0 && index < posts.length) {
        posts[index] = post;
      }
      Get.snackbar('Error', 'Failed to like post: $e');
    } finally {
      likingPosts.remove(postId);
    }
  }

  // Add comment to a post
  Future<void> addComment(String postId, String content, int postIndex) async {
    if (content.trim().isEmpty) return;

    try {
      final success = await _postService.addComment(postId, content);
      if (success) {
        // Update the local post data instead of refreshing everything
        if (postIndex >= 0 && postIndex < posts.length) {
          final post = posts[postIndex];

          // Create updated post with incremented comment count
          final updatedPost = PostModel(
            id: post.id,
            userId: post.userId,
            content: post.content,
            imageUrl: post.imageUrl,
            isAnonymous: post.isAnonymous,
            createdAt: post.createdAt,
            likesCount: post.likesCount,
            commentsCount: post.commentsCount + 1,
            sharesCount: post.sharesCount,
          );

          posts[postIndex] = updatedPost;
        }
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

  // Check if a post is currently being liked (for UI loading state)
  bool isPostBeingLiked(String postId) {
    return likingPosts.contains(postId);
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
