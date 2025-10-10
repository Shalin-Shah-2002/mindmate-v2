import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import '../models/mood_entry.dart';
import '../services/mood_service.dart';

class MoodViewModel extends GetxController {
  final MoodService _moodService = MoodService();

  final RxString selectedMood = ''.obs;
  final RxInt intensity = 3.obs; // 1..5
  final TextEditingController noteController = TextEditingController();

  final RxList<MoodEntry> recentEntries = <MoodEntry>[].obs;
  final RxBool isSaving = false.obs;
  final RxString error = ''.obs;

  Stream<List<MoodEntry>>? entriesStream;
  StreamSubscription<List<MoodEntry>>? _sub;

  final List<String> moods = const [
    'Happy',
    'Calm',
    'Neutral',
    'Sad',
    'Anxious',
    'Stressed',
    'Angry',
    'Tired',
  ];

  @override
  void onInit() {
    super.onInit();
    // Attach a stream for live updates if user is logged in
    entriesStream = _moodService.entriesStream(limit: 60);
    // Subscribe to stream updates
    _sub = entriesStream?.listen((list) {
      recentEntries.assignAll(list);
    });
    // Initial load (in case stream is empty until first snapshot)
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final list = await _moodService.getRecentEntries(limit: 30);
    recentEntries.assignAll(list);
  }

  Future<void> submit() async {
    if (selectedMood.value.isEmpty) {
      error.value = 'Please select a mood';
      return;
    }

    try {
      isSaving.value = true;
      error.value = '';
      final ok = await _moodService.addMoodEntry(
        mood: selectedMood.value,
        intensity: intensity.value,
        note: noteController.text,
      );
      if (ok) {
        noteController.clear();
        // Put newest first
        await _loadRecent();
        Get.snackbar(
          'Saved',
          'Your mood has been recorded',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        error.value = 'Failed to save mood. Please try again.';
      }
    } catch (e) {
      error.value = 'Error: $e';
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteEntry(String id) async {
    final ok = await _moodService.deleteEntry(id);
    if (ok) {
      recentEntries.removeWhere((e) => e.id == id);
    }
  }

  @override
  void onClose() {
    noteController.dispose();
    _sub?.cancel();
    super.onClose();
  }
}
