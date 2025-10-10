import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';

class YouTubeVideo {
  final String videoId;
  final String title;
  final String thumbnailUrl;
  final String channelTitle;

  YouTubeVideo({
    required this.videoId,
    required this.title,
    required this.thumbnailUrl,
    required this.channelTitle,
  });
}

class YouTubeService {
  static const _baseUrl = 'https://www.googleapis.com/youtube/v3';
  // Prefer build-time env var; fallback to local constant for dev
  static const String _envApiKey = String.fromEnvironment('YOUTUBE_API_KEY');
  static String get _apiKey =>
      _envApiKey.isNotEmpty ? _envApiKey : ApiKeys.youtubeApiKey;

  static Future<List<YouTubeVideo>> searchMeditationVideos({
    String query = 'guided meditation',
    int maxResults = 20,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/search?part=snippet&maxResults=$maxResults&q=${Uri.encodeComponent(query)}&type=video&safeSearch=moderate&order=relevance&key=$_apiKey',
    );

    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('YouTube API error: ${resp.statusCode} ${resp.body}');
    }

    final data = json.decode(resp.body) as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? []);
    return items
        .map((e) {
          final id = e['id']?['videoId'] as String? ?? '';
          final snippet = e['snippet'] as Map<String, dynamic>? ?? {};
          final title = snippet['title'] as String? ?? 'Untitled';
          final channelTitle = snippet['channelTitle'] as String? ?? '';
          final thumb =
              (snippet['thumbnails']?['medium']?['url'] ??
                      snippet['thumbnails']?['default']?['url'] ??
                      '')
                  as String;
          return YouTubeVideo(
            videoId: id,
            title: title,
            thumbnailUrl: thumb,
            channelTitle: channelTitle,
          );
        })
        .where((v) => v.videoId.isNotEmpty)
        .toList();
  }
}
