import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventosScreen extends StatelessWidget {
  const EventosScreen({super.key});

  Future<List<Map<String, dynamic>>> buscarEventos() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('informacoes')
        .doc('eventos')
        .collection('itens')
        .orderBy('criadoEm', descending: true)
        .limit(5)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'titulo': data['titulo'] ?? '',
        'descricao': data['descricao'] ?? '',
        'data': data['data']?.toDate(),
        'midiaUrl': data['midiaUrl'],
        'tipoMidia': data['tipoMidia'],
        'local': data['local'] ?? '',
        'criadoEm': data['criadoEm']?.toDate(),
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Próximos Eventos'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: buscarEventos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum evento encontrado.'));
          }

          final eventos = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: eventos.length,
            itemBuilder: (context, index) {
              final e = eventos[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (e['tipoMidia'] == 'imagem')
                      Image.network(e['midiaUrl'], fit: BoxFit.cover)
                    else if (e['tipoMidia'] == 'video')
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: VideoPlayerWidget(videoUrl: e['midiaUrl']),
                      ),
                      Text(e['titulo'],
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(e['descricao']),
                      const SizedBox(height: 8),
                      Text('📍 Local: ${e['local']}'),
                      if (e['data'] != null)
                        Text(
                          '📅 Data: ${e['data'].toString().substring(0, 10)}',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                    ],
                  ),
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