import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../meditation/meditation_view.dart';
import '../../services/youtube_service.dart';
import 'youtube_player_view.dart';
import '../../widgets/brand_ui.dart';
import '../../widgets/loading_animation.dart';

class ResourcesView extends StatelessWidget {
  const ResourcesView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 48),
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
                'Resources',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              bottom: const TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorWeight: 3,
                tabs: [
                  Tab(text: 'Videos', icon: Icon(Icons.play_circle_outline)),
                  Tab(text: 'Articles', icon: Icon(Icons.menu_book_outlined)),
                  Tab(text: 'Tools', icon: Icon(Icons.build_outlined)),
                ],
              ),
            ),
          ),
        ),
        body: BrandBackground(
          child: TabBarView(
            children: [_VideosTab(), _ArticlesTab(), _ToolsTab()],
          ),
        ),
      ),
    );
  }
}

class _ResourceItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _ResourceItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6D83F2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFF6D83F2),
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Shared section builder for tabs
Widget _section(
  BuildContext context, {
  required String title,
  required Color color,
  required List<_ResourceItem> items,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.folder_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                  ).createShader(bounds),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ...items.map((e) => e.build(context)),
        const SizedBox(height: 8),
      ],
    ),
  );
}

class _VideosTab extends StatefulWidget {
  @override
  State<_VideosTab> createState() => _VideosTabState();
}

class _VideosTabState extends State<_VideosTab> {
  late Future<List<YouTubeVideo>> _future;
  final Map<String, String> _categoryQueries = const {
    'All': 'meditation',
    'Sleep': 'sleep meditation',
    'Deep Sleep': 'deep sleep meditation',
    'Morning': 'morning meditation',
    'Focus': 'focus meditation',
    'Study': 'study focus meditation',
    'Anxiety': 'anxiety meditation',
    'Stress Relief': 'stress relief meditation',
    'Relaxation': 'relaxation meditation',
    'Breathing': 'breathing exercise meditation',
    'Mindfulness': 'mindfulness meditation',
    'Body Scan': 'body scan meditation',
    'Yoga Nidra': 'yoga nidra',
    'Confidence': 'confidence meditation',
    'Self-Love': 'self love meditation',
    'Gratitude': 'gratitude meditation',
    'Kids': 'kids meditation',
    'Beginners': 'meditation for beginners',
    'Advanced': 'advanced meditation',
  };
  String _selected = 'All';

  @override
  void initState() {
    super.initState();
    _future = YouTubeService.searchMeditationVideos(
      query: _categoryQueries[_selected]!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<YouTubeVideo>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: [
              _buildChips(context),
              const Expanded(child: Center(child: InlineLoading())),
            ],
          );
        }
        if (snapshot.hasError) {
          return Column(
            children: [
              _buildChips(context),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Failed to load videos. Please try again later.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        final videos = snapshot.data ?? [];
        if (videos.isEmpty) {
          return Column(
            children: [
              _buildChips(context),
              const Expanded(
                child: Center(child: Text('No meditation videos found.')),
              ),
            ],
          );
        }

        return Column(
          children: [
            _buildChips(context),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: videos.length,
                itemBuilder: (context, index) {
                  final v = videos[index];
                  return GestureDetector(
                    onTap: () => Get.to(
                      () =>
                          YouTubePlayerView(videoId: v.videoId, title: v.title),
                    ),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    v.thumbnailUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, _, __) =>
                                        Container(color: Colors.grey[300]),
                                  ),
                                  Align(
                                    alignment: Alignment.center,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black45,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      child: const Icon(
                                        Icons.play_arrow,
                                        color: Colors.white,
                                        size: 36,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  v.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  v.channelTitle,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChips(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: _categoryQueries.keys.map((c) {
          final selected = c == _selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(c),
              selected: selected,
              onSelected: (val) {
                if (!val) return;
                setState(() {
                  _selected = c;
                  _future = YouTubeService.searchMeditationVideos(
                    query: _categoryQueries[c] ?? 'meditation',
                  );
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ArticlesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      _ResourceItem(
        title: 'Managing Anxiety: A Starter Guide',
        subtitle: 'Evidence-informed techniques you can try today',
        icon: Icons.menu_book_outlined,
        color: const Color(0xFF22C55E),
        onTap: () {
          Get.snackbar('Open article', 'Hook up to in-app content or links');
        },
      ),
      _ResourceItem(
        title: 'Sleep Hygiene Essentials',
        subtitle: 'Small changes to improve sleep quality',
        icon: Icons.bedtime,
        color: const Color(0xFFF59E0B),
        onTap: () {
          Get.snackbar('Open article', 'Hook up to in-app content or links');
        },
      ),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _section(
          context,
          title: 'Recommended Reads',
          color: const Color(0xFF22C55E),
          items: items,
        ),
      ],
    );
  }
}

class _ToolsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _section(
          context,
          title: 'Crisis & Support',
          color: const Color(0xFFEF4444),
          items: [
            _ResourceItem(
              title: 'Immediate help (call/SOS)',
              subtitle: 'If you or someone is in danger',
              icon: Icons.sos_outlined,
              color: const Color(0xFFEF4444),
              onTap: () {
                Get.snackbar(
                  'Emergency',
                  'Please contact your local emergency number.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red.withValues(alpha: 0.08),
                  colorText: Colors.red[800],
                );
              },
            ),
            _ResourceItem(
              title: 'Crisis hotlines',
              subtitle: 'Trusted organizations in your region',
              icon: Icons.phone_in_talk_outlined,
              color: const Color(0xFFF97316),
              onTap: () {
                Get.snackbar(
                  'Crisis hotlines',
                  'Add region-specific numbers here.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.orange.withValues(alpha: 0.08),
                  colorText: Colors.orange[800],
                );
              },
            ),
          ],
        ),
        _section(
          context,
          title: 'Exercises',
          color: const Color(0xFF10B981),
          items: [
            _ResourceItem(
              title: 'Guided meditations',
              subtitle: 'Short audio practices',
              icon: Icons.headphones,
              color: const Color(0xFF10B981),
              onTap: () =>
                  Get.to(() => const MeditationView(initialTabIndex: 0)),
            ),
            _ResourceItem(
              title: 'Breathing exercise',
              subtitle: '4-4-4 calming cycle',
              icon: Icons.self_improvement,
              color: const Color(0xFF06B6D4),
              onTap: () =>
                  Get.to(() => const MeditationView(initialTabIndex: 1)),
            ),
            _ResourceItem(
              title: 'Meditation timer',
              subtitle: 'Choose a duration and focus',
              icon: Icons.timer,
              color: const Color(0xFF6366F1),
              onTap: () =>
                  Get.to(() => const MeditationView(initialTabIndex: 2)),
            ),
          ],
        ),
        _section(
          context,
          title: 'Self-Assessments',
          color: const Color(0xFFF59E0B),
          items: [
            _ResourceItem(
              title: 'Stress check-in',
              subtitle: 'Quick scale to reflect on stress',
              icon: Icons.assignment_outlined,
              color: const Color(0xFFF59E0B),
              onTap: () {
                Get.snackbar(
                  'Coming soon',
                  'Add brief, validated screeners (non-diagnostic).',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
