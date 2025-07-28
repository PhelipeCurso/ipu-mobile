import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class HomeYoutubeWidget extends StatefulWidget {
  const HomeYoutubeWidget({super.key});

  @override
  State<HomeYoutubeWidget> createState() => _HomeYoutubeWidgetState();
}

class _HomeYoutubeWidgetState extends State<HomeYoutubeWidget> {
  List<dynamic> videos = [];

  // 🔑 Substitua por sua chave e canal reais
  final String apiKey = 'SUA_API_KEY';
  final String channelId = 'ID_DO_SEU_CANAL';

  @override
  void initState() {
    super.initState();
    fetchVideos();
  }

  Future<void> fetchVideos() async {
    final url = Uri.parse(
      'https://www.googleapis.com/youtube/v3/search?key=$apiKey&channelId=$channelId&part=snippet,id&order=date&maxResults=10',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        videos = data['items']
            .where((item) => item['id']['kind'] == 'youtube#video')
            .toList();
      });
    } else {
      print('Erro ao buscar vídeos: ${response.statusCode}');
    }
  }

  Future<void> _openVideo(String videoId) async {
    final url = 'https://www.youtube.com/watch?v=$videoId';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      print('Não foi possível abrir o vídeo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return videos.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              final videoId = video['id']['videoId'];
              final snippet = video['snippet'];
              final title = snippet['title'];
              final thumbnailUrl = snippet['thumbnails']['high']['url'];

              return GestureDetector(
                onTap: () => _openVideo(videoId),
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          thumbnailUrl,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
}
