import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../widgets/brand_ui.dart';

class MeditationView extends StatefulWidget {
  final int initialTabIndex;
  const MeditationView({super.key, this.initialTabIndex = 0});

  @override
  State<MeditationView> createState() => _MeditationViewState();
}

class _MeditationViewState extends State<MeditationView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              'Meditation',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              indicatorWeight: 3,
              tabs: const [
                Tab(icon: Icon(Icons.headphones), text: 'Guided'),
                Tab(icon: Icon(Icons.self_improvement), text: 'Breathing'),
                Tab(icon: Icon(Icons.timer), text: 'Timer'),
                Tab(icon: Icon(Icons.format_quote), text: 'Quote'),
              ],
              isScrollable: true,
            ),
          ),
        ),
      ),
      body: BrandBackground(
        child: TabBarView(
          controller: _tabController,
          children: const [
            GuidedMeditationTab(),
            BreathingTab(),
            TimerTab(),
            QuoteTab(),
          ],
        ),
      ),
    );
  }
}

// 1) Guided Meditation (audio-ready scaffold)
class GuidedMeditationTab extends StatefulWidget {
  const GuidedMeditationTab({super.key});

  @override
  State<GuidedMeditationTab> createState() => _GuidedMeditationTabState();
}

class _GuidedMeditationTabState extends State<GuidedMeditationTab> {
  final List<_Track> tracks = const [
    _Track(title: 'Quick Calm', minutes: 2, url: null),
    _Track(title: 'Relax & Release', minutes: 5, url: null),
    _Track(title: 'Deep Focus', minutes: 10, url: null),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tracks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final t = tracks[i];
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
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.spa, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${t.minutes} min guidance',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (ctx) => _GuidedPlayerSheet(track: t),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow, color: Colors.white, size: 20),
                          SizedBox(width: 6),
                          Text(
                            'Start',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GuidedPlayerSheet extends StatefulWidget {
  final _Track track;
  const _GuidedPlayerSheet({required this.track});

  @override
  State<_GuidedPlayerSheet> createState() => _GuidedPlayerSheetState();
}

class _GuidedPlayerSheetState extends State<_GuidedPlayerSheet> {
  final AudioPlayer _player = AudioPlayer();
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onPositionChanged.listen((p) => setState(() => position = p));
    _player.onDurationChanged.listen((d) => setState(() => duration = d));
    _player.onPlayerComplete.listen((event) {
      setState(() => isPlaying = false);
      Get.snackbar(
        'Session complete',
        'Hope you feel better!',
        snackPosition: SnackPosition.BOTTOM,
      );
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (widget.track.url == null) {
      Get.snackbar(
        'Audio not set',
        'Add a valid audio URL to the track in code to enable playback.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (isPlaying) {
      await _player.pause();
      setState(() => isPlaying = false);
    } else {
      await _player.play(UrlSource(widget.track.url!));
      setState(() => isPlaying = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = duration.inMilliseconds == 0
        ? (widget.track.minutes * 60)
        : duration.inSeconds;
    final current = position.inSeconds;
    final progress = total == 0 ? 0.0 : (current / total).clamp(0.0, 1.0);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.headphones),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.track.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text('${widget.track.minutes} min'),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 48,
                onPressed: _toggle,
                icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Stop',
                icon: const Icon(Icons.stop_circle),
                onPressed: () async {
                  await _player.stop();
                  setState(() {
                    isPlaying = false;
                    position = Duration.zero;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Tip: Focus on your breath. If your mind wanders, gently bring it back to the present.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Track {
  final String title;
  final int minutes;
  final String? url; // Provide a valid URL to enable playback
  const _Track({required this.title, required this.minutes, this.url});
}

// 2) Breathing Exercise
class BreathingTab extends StatefulWidget {
  const BreathingTab({super.key});

  @override
  State<BreathingTab> createState() => _BreathingTabState();
}

class _BreathingTabState extends State<BreathingTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool running = false;

  // Simple 4-4-4 cycle: inhale 4s, hold 4s, exhale 4s
  final int inhale = 4;
  final int hold = 4;
  final int exhale = 4;

  String phase = 'Ready';
  Timer? _phaseTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: inhale + hold + exhale),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _phaseTimer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      running = true;
      phase = 'Inhale';
    });
    _controller.repeat();
    _phaseTimer?.cancel();
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final t = timer.tick % (inhale + hold + exhale);
      setState(() {
        if (t < inhale) {
          phase = 'Inhale';
        } else if (t < inhale + hold) {
          phase = 'Hold';
        } else {
          phase = 'Exhale';
        }
      });
    });
  }

  void _stop() {
    _controller.stop();
    _phaseTimer?.cancel();
    setState(() {
      running = false;
      phase = 'Ready';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Text(
            phase,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final progress = _controller.value; // 0..1
                  // map progress to inhale/hold/exhale size
                  final cycle = inhale + hold + exhale;
                  final sec = (progress * cycle);
                  double size;
                  if (sec < inhale) {
                    size = lerpDouble(120, 200, sec / inhale)!;
                  } else if (sec < inhale + hold) {
                    size = 200;
                  } else {
                    final ex = (sec - inhale - hold) / exhale;
                    size = lerpDouble(200, 120, ex)!;
                  }
                  return Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      phase,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: running
                        ? null
                        : const LinearGradient(
                            colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                          ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: running
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
                    color: running ? Colors.grey.shade300 : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: running ? null : _start,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.play_arrow,
                              color: running
                                  ? Colors.grey.shade600
                                  : Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Start',
                              style: TextStyle(
                                color: running
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
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: running
                          ? const Color(0xFF6D83F2)
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: running ? _stop : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.stop,
                              color: running
                                  ? const Color(0xFF6D83F2)
                                  : Colors.grey.shade400,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Stop',
                              style: TextStyle(
                                color: running
                                    ? const Color(0xFF6D83F2)
                                    : Colors.grey.shade400,
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
            ],
          ),
        ],
      ),
    );
  }
}

// helper since dart:ui lerpDouble is hidden in web; re-implement small variant
double? lerpDouble(num? a, num? b, double t) {
  if (a == null && b == null) return null;
  a ??= 0.0;
  b ??= 0.0;
  return a * (1.0 - t) + b * t;
}

// 3) Meditation Timer
class TimerTab extends StatefulWidget {
  const TimerTab({super.key});

  @override
  State<TimerTab> createState() => _TimerTabState();
}

class _TimerTabState extends State<TimerTab> {
  final List<int> presets = [5, 10, 15];
  int selectedMinutes = 5;
  int? customMinutes;
  Timer? _timer;
  int remainingSeconds = 5 * 60;
  bool running = false;

  void _start() {
    _timer?.cancel();
    final total = (customMinutes ?? selectedMinutes) * 60;
    setState(() {
      remainingSeconds = total;
      running = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingSeconds <= 1) {
        t.cancel();
        setState(() {
          running = false;
          remainingSeconds = 0;
        });
        Get.snackbar('Session complete', 'Great job staying present!');
      } else {
        setState(() => remainingSeconds--);
      }
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() => running = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mm = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final ss = (remainingSeconds % 60).toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose duration',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final p in presets)
                ChoiceChip(
                  label: Text('$p min'),
                  selected: (customMinutes == null && selectedMinutes == p),
                  onSelected: (v) {
                    if (!running) {
                      setState(() {
                        customMinutes = null;
                        selectedMinutes = p;
                        remainingSeconds = p * 60;
                      });
                    }
                  },
                ),
              ChoiceChip(
                label: const Text('Custom'),
                selected: customMinutes != null,
                onSelected: (v) async {
                  if (!running) {
                    final val = await _askCustom(context);
                    if (val != null && val > 0) {
                      setState(() {
                        customMinutes = val;
                        remainingSeconds = val * 60;
                      });
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$mm:$ss',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Stay present. Notice your breath.'),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: running
                        ? null
                        : const LinearGradient(
                            colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                          ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: running
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
                    color: running ? Colors.grey.shade300 : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: running ? null : _start,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.play_arrow,
                              color: running
                                  ? Colors.grey.shade600
                                  : Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Start',
                              style: TextStyle(
                                color: running
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
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: running
                          ? const Color(0xFF6D83F2)
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: running ? _stop : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.stop,
                              color: running
                                  ? const Color(0xFF6D83F2)
                                  : Colors.grey.shade400,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Stop',
                              style: TextStyle(
                                color: running
                                    ? const Color(0xFF6D83F2)
                                    : Colors.grey.shade400,
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
            ],
          ),
        ],
      ),
    );
  }

  Future<int?> _askCustom(BuildContext context) async {
    final controller = TextEditingController();
    final minutes = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom minutes'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'e.g. 7'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final v = int.tryParse(controller.text.trim());
              Navigator.pop(ctx, v);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
    return minutes;
  }
}

// 4) Daily Quote
class QuoteTab extends StatefulWidget {
  const QuoteTab({super.key});

  @override
  State<QuoteTab> createState() => _QuoteTabState();
}

class _QuoteTabState extends State<QuoteTab> {
  final List<String> quotes = const [
    'Breathe in calm, exhale tension.',
    'You are exactly where you need to be.',
    'Let your thoughts pass like clouds.',
    'Peace begins with a single breath.',
    'Be kind to your mind today.',
    'Inhale courage, exhale fear.',
    'This moment is enough.',
  ];

  late int index;

  @override
  void initState() {
    super.initState();
    // Deterministic daily index
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    index = seed % quotes.length;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Icon(
            Icons.format_quote,
            size: 48,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            '“${quotes[index]}”',
            style: const TextStyle(fontSize: 22, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                index = Random().nextInt(quotes.length);
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('New quote'),
          ),
        ],
      ),
    );
  }
}
