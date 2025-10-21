import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../viewmodels/mood_viewmodel.dart';
import '../../models/mood_entry.dart';
import '../../widgets/brand_ui.dart';

class MoodTrackerView extends StatelessWidget {
  const MoodTrackerView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Get.put(MoodViewModel());

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
            ),
          ),
          child: AppBar(
            title: const Text(
              'Track Your Mood',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
      ),
      body: SafeArea(
        child: BrandBackground(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BrandGradientText(
                  'How are you feeling today?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: vm.moods.map((m) {
                      final selected = vm.selectedMood.value == m;
                      return GestureDetector(
                        onTap: () => vm.selectedMood.value = m,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: selected
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF6D83F2),
                                      Color(0xFF00C6FF),
                                    ],
                                  )
                                : null,
                            color: selected ? null : Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF6D83F2)
                                  : Colors.grey.shade300,
                              width: selected ? 2 : 1,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF6D83F2,
                                      ).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            m,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Intensity'),
                    Text('1  (low)   -   5 (high)'),
                  ],
                ),
                Obx(
                  () => Slider(
                    min: 1,
                    max: 5,
                    divisions: 4,
                    value: vm.intensity.value.toDouble(),
                    label: vm.intensity.value.toString(),
                    onChanged: (v) => vm.intensity.value = v.round(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: vm.noteController,
                  decoration: InputDecoration(
                    labelText: 'Add a note (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Obx(
                  () => vm.error.value.isEmpty
                      ? const SizedBox.shrink()
                      : Text(
                          vm.error.value,
                          style: const TextStyle(color: Colors.red),
                        ),
                ),
                const SizedBox(height: 8),
                Obx(
                  () => Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: vm.isSaving.value
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                            ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: vm.isSaving.value
                          ? null
                          : [
                              BoxShadow(
                                color: const Color(0xFF6D83F2).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                    ),
                    child: Material(
                      color: vm.isSaving.value
                          ? Colors.grey.shade300
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: vm.isSaving.value ? null : vm.submit,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              vm.isSaving.value
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.grey,
                                            ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.save_rounded,
                                      color: Colors.white,
                                    ),
                              const SizedBox(width: 8),
                              Text(
                                'Save Mood',
                                style: TextStyle(
                                  color: vm.isSaving.value
                                      ? Colors.grey.shade600
                                      : Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Divider(color: Theme.of(context).dividerColor),
                const SizedBox(height: 8),
                const BrandGradientText(
                  'Recent entries',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Obx(() {
                    final items = vm.recentEntries;
                    if (items.isEmpty) {
                      return const Center(
                        child: Text(
                          'No entries yet. Your recent moods will appear here.',
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final e = items[index];
                        return _MoodEntryTile(
                          e: e,
                          onDelete: () => vm.deleteEntry(e.id),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoodEntryTile extends StatelessWidget {
  final MoodEntry e;
  final VoidCallback onDelete;
  const _MoodEntryTile({required this.e, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                e.intensity.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      e.mood,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatTime(e.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                if (e.note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(e.note),
                ],
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: onDelete,
              color: Colors.red,
              tooltip: 'Delete',
              iconSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $ampm';
    }
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
