import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../viewmodels/mood_viewmodel.dart';
import '../../models/mood_entry.dart';

class MoodTrackerView extends StatelessWidget {
  const MoodTrackerView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Get.put(MoodViewModel());
    final color = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(title: const Text('Track your mood')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How are you feeling today?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Obx(
                () => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: vm.moods.map((m) {
                    final selected = vm.selectedMood.value == m;
                    return ChoiceChip(
                      label: Text(m),
                      selected: selected,
                      onSelected: (_) => vm.selectedMood.value = m,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : color,
                      ),
                      selectedColor: color,
                      backgroundColor: color.withValues(alpha: 0.1),
                      side: BorderSide(color: color.withValues(alpha: 0.3)),
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
                () => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: vm.isSaving.value ? null : vm.submit,
                    icon: vm.isSaving.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Save mood'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Recent entries',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
    );
  }
}

class _MoodEntryTile extends StatelessWidget {
  final MoodEntry e;
  final VoidCallback onDelete;
  const _MoodEntryTile({required this.e, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Text(
              e.intensity.toString(),
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
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
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
            color: Colors.redAccent,
            tooltip: 'Delete',
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
