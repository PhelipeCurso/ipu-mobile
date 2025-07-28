import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NoticiasScreen extends StatelessWidget {
  const NoticiasScreen({super.key});

  Future<List<Map<String, dynamic>>> buscarNoticias() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('informacoes')
        .doc('noticias')
        .collection('itens')
        .orderBy('criadoEm', descending: true)
        .limit(5)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'titulo': data['titulo'] ?? '',
        'descricao': data['descricao'] ?? '',
        'midiaUrl': data['midiaUrl'],
        'tipoMidia': data['tipoMidia'],
        'criadoEm': data['criadoEm']?.toDate(),
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Últimas Notícias'),
        backgroundColor: Colors.redAccent,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: buscarNoticias(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma notícia encontrada.'));
          }

          final noticias = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: noticias.length,
            itemBuilder: (context, index) {
              final n = noticias[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (n['tipoMidia'] == 'imagem')
                      Image.network(n['midiaUrl'], fit: BoxFit.cover)
                    else if (n['tipoMidia'] == 'video')
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: VideoPlayerWidget(videoUrl: n['midiaUrl']),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n['titulo'],
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(n['descricao']),
                          const SizedBox(height: 8),
                          if (n['criadoEm'] != null)
                            Text(
                              'Publicado em: ${n['criadoEm'].toString().substring(0, 10)}',
                              style:
                                  const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class VideoPlayerWidget extends StatelessWidget {
  final String videoUrl;

  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text("🎥 Vídeo aqui (player customizável)"));
    // Para versão real, use `video_player` package se quiser incorporar o player.
  }
}
