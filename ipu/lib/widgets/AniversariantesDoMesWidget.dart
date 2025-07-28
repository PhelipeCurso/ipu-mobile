import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AniversariantesWidget extends StatefulWidget {
  const AniversariantesWidget({super.key});

  @override
  State<AniversariantesWidget> createState() => _AniversariantesWidgetState();
}

class _AniversariantesWidgetState extends State<AniversariantesWidget> {
  List<Map<String, dynamic>> aniversariantes = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregarAniversariantesDoMes();
  }

  Future<void> carregarAniversariantesDoMes() async {
    final agora = DateTime.now();
    final mesAtual = agora.month;

    final snapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .get();

    final lista = snapshot.docs
        .map((doc) {
          final dados = doc.data();
          final dataNascimento = dados['dataNascimento'];

          if (dataNascimento != null && dataNascimento is String) {
            final data = DateTime.tryParse(dataNascimento);
            if (data != null && data.month == mesAtual) {
              return {
                'nome': dados['nome'] ?? 'Sem nome',
                'data': data,
              };
            }
          }
          return null;
        })
        .whereType<Map<String, dynamic>>()
        .toList();

    lista.sort((a, b) => a['data'].day.compareTo(b['data'].day));

    setState(() {
      aniversariantes = lista;
      carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 24, bottom: 8),
          child: Text(
            '🎉 Aniversariantes do Mês',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        if (carregando)
          const Center(child: CircularProgressIndicator())
        else if (aniversariantes.isEmpty)
          const Text('Nenhum aniversariante encontrado.')
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: aniversariantes.map((aniv) {
              final nome = aniv['nome'];
              final data = DateFormat('dd/MM').format(aniv['data']);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('• $nome - $data',
                    style: const TextStyle(fontSize: 16)),
              );
            }).toList(),
          ),
      ],
    );
  }
}
