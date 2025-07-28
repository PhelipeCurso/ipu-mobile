import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeNoticiasWidget extends StatefulWidget {
  const HomeNoticiasWidget({super.key});

  @override
  State<HomeNoticiasWidget> createState() => _HomeNoticiasWidgetState();
}

class _HomeNoticiasWidgetState extends State<HomeNoticiasWidget> {
  List<Map<String, dynamic>> noticias = [];
  List<Map<String, dynamic>> agenda = [];
  double totalDoacoes = 0;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    await Future.wait([
      carregarNoticias(),
      carregarAgenda(),
      calcularDoacoes(),
    ]);
  }

  Future<void> carregarNoticias() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('noticias')
        .orderBy('data', descending: true)
        .limit(5)
        .get();

    final lista = snapshot.docs.map((doc) {
      final dados = doc.data();
      return {
        'titulo': dados['titulo'],
        'resumo': dados['resumo'] ?? '',
        'data': (dados['data'] as Timestamp).toDate(),
      };
    }).toList();

    setState(() => noticias = lista);
  }

  Future<void> carregarAgenda() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('agenda')
        .orderBy('data')
        .where('data', isGreaterThan: DateTime.now())
        .limit(5)
        .get();

    final lista = snapshot.docs.map((doc) {
      final dados = doc.data();
      return {
        'evento': dados['evento'],
        'data': (dados['data'] as Timestamp).toDate(),
      };
    }).toList();

    setState(() => agenda = lista);
  }

  Future<void> calcularDoacoes() async {
    final agora = DateTime.now();
    final inicioMes = DateTime(agora.year, agora.month, 1);

    final snapshot = await FirebaseFirestore.instance
        .collection('doacoes')
        .where('criadoEm', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioMes))
        .where('cancelado', isEqualTo: false)
        .get();

    final total = snapshot.docs.fold<double>(
      0,
      (soma, doc) => soma + (doc['valor'] as num).toDouble(),
    );

    setState(() => totalDoacoes = total);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: carregarDados,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '📰 Últimas Notícias',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ...noticias.map((n) => ListTile(
                title: Text(n['titulo']),
                subtitle: Text(n['resumo']),
                trailing: Text(DateFormat('dd/MM').format(n['data'])),
              )),
          const Divider(height: 40),
          const Text(
            '📅 Agenda da Semana',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ...agenda.map((a) => ListTile(
                leading: const Icon(Icons.event),
                title: Text(a['evento']),
                trailing: Text(DateFormat('dd/MM').format(a['data'])),
              )),
          const Divider(height: 40),
          const Text(
            '💰 Doações do mês',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ListTile(
            leading: const Icon(Icons.monetization_on),
            title: const Text('Total arrecadado'),
            trailing: Text(
              'R\$ ${totalDoacoes.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}
