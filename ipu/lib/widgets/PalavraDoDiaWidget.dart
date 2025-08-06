
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'dart:convert';
class PalavraDoDiaWidget extends StatefulWidget {
  const PalavraDoDiaWidget({super.key});

  @override
  State<PalavraDoDiaWidget> createState() => _PalavraDoDiaWidgetState();
}

class _PalavraDoDiaWidgetState extends State<PalavraDoDiaWidget> {
  String palavra = '';
  String referencia = '';
  bool carregando = true;

  final List<String> referencias = [
    'joao+3:16',
    'salmos+23:1',
    'filipenses+4:13',
    'romanos+8:28',
    'provérbios+3:5',
    'salmos+119:105',
    'mateus+5:9',
    'isaías+41:10',
  ];

  @override
  void initState() {
    super.initState();
    carregarPalavra();
  }

  Future<void> carregarPalavra() async {
    setState(() => carregando = true);
    final ref = referencias[Random().nextInt(referencias.length)];
    final url = Uri.parse('https://bible-api.com/$ref?translation=almeida');

    try {
      final resposta = await http.get(url);
      if (resposta.statusCode == 200) {
        final data = json.decode(resposta.body);
        setState(() {
          palavra = data['text']?.trim() ?? '';
          referencia = data['reference'] ?? '';
          carregando = false;
        });
      } else {
        setState(() {
          palavra = 'Não foi possível carregar a Palavra do Dia.';
          referencia = '';
          carregando = false;
        });
      }
    } catch (e) {
      setState(() {
        palavra = 'Erro ao buscar a Palavra do Dia.';
        referencia = '';
        carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return carregando
        ? const Center(child: CircularProgressIndicator())
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📖 Palavra do Dia:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(palavra, style: const TextStyle(fontSize: 18, color: Colors.white)),
              const SizedBox(height: 8),
              Text(
                referencia,
                style: const TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: carregarPalavra,
                icon: const Icon(Icons.refresh),
                label: const Text('Nova Palavra'),
              ),
            ],
          );
  }
}
