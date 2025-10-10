import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class YouTubePlayerView extends StatefulWidget {
  final String videoId;
  final String title;

  const YouTubePlayerView({
    super.key,
    required this.videoId,
    required this.title,
  });

  @override
  State<YouTubePlayerView> createState() => _YouTubePlayerViewState();
}

class _YouTubePlayerViewState extends State<YouTubePlayerView> {
  late YoutubePlayerController _controller;
  bool _didFallback = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        strictRelatedVideos: true,
        enableCaption: true,
        playsInline: true,
        // Set to true if you want auto playback (may require mute on some platforms)
        // autoPlay: true,
      ),
    );

    // Probe the player shortly after init. If the underlying WebView channel isn't
    // registered on this device, a method call will throw and we fallback automatically.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted || _didFallback) return;
      try {
        await _controller.playVideo();
        await _controller.pauseVideo();
      } catch (_) {
        _openExternallyAndPop();
      }
    });
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerScaffold(
      controller: _controller,
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            actions: [
              IconButton(
                tooltip: 'Open in YouTube',
                icon: const Icon(Icons.open_in_new),
                onPressed: _openExternally,
              ),
            ],
          ),
          body: Center(
            child: AspectRatio(aspectRatio: 16 / 9, child: player),
          ),
        );
      },
    );
  }

  Future<void> _openExternally() async {
    final url = Uri.parse('https://www.youtube.com/watch?v=${widget.videoId}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openExternallyAndPop() async {
    if (!mounted || _didFallback) return;
    _didFallback = true;
    await _openExternally();
    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }
}
