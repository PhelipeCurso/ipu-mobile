import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'home_screen.dart'; // tela com PageView que faremos depois

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String palavra = '';
  String referencia = '';
  String nome = '';
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
    carregarDados();
  }

  Future<void> carregarDados() async {
    final user = FirebaseAuth.instance.currentUser;
    nome = user?.displayName ?? 'Bem-vindo';

    final random = Random();
    final ref = referencias[random.nextInt(referencias.length)];
    final url = Uri.parse('https://bible-api.com/$ref?translation=almeida');

    try {
      final resposta = await http.get(url);
      if (resposta.statusCode == 200) {
        final data = json.decode(resposta.body);
        setState(() {
          palavra = data['text'].trim();
          referencia = data['reference'];
          carregando = false;
        });
      } else {
        setState(() {
          palavra = 'Não foi possível carregar a Palavra do Dia.';
          referencia = '';
          carregando = false;
        });
      }
    } catch (_) {
      setState(() {
        palavra = 'Erro ao buscar a Palavra do Dia.';
        referencia = '';
        carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Seja Bem-Vindo(a), $nome!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '📖 Palavra do Dia',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '"$palavra"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    referencia,
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    ),
                    child: const Text('Ir para Início'),
                  ),
                ],
              ),
            ),
    );
  }
}
