import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ipu/widgets/menu_lateral_widget.dart';

class HomeServicoWidget extends StatefulWidget {
  const HomeServicoWidget({super.key});

  @override
  State<HomeServicoWidget> createState() => _HomeServicoWidgetState();
}

class _HomeServicoWidgetState extends State<HomeServicoWidget> {
  String? nomeSegmento;
  List<Map<String, dynamic>> destaques = [];

  @override
  void initState() {
    super.initState();
    carregarDestaques();
  }

  Future<void> carregarDestaques() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
    final userData = userDoc.data();

    if (userData == null || userData['areaDeServico'] == null || userData['areaDeServico'].isEmpty) return;

    setState(() {
      nomeSegmento = userData['areaDeServico'];
    });

    final snap = await FirebaseFirestore.instance
        .collection('destaques')
        .where('segmento', isEqualTo: nomeSegmento)
        .orderBy('criadoEm', descending: true)
        .limit(10)
        .get();

    final lista = snap.docs.map((doc) => doc.data()).toList();

    setState(() {
      destaques = List<Map<String, dynamic>>.from(lista);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MenuLateralWidget(
        exibirMenuLancamentos: false,
        podeGerenciarAgenda: false,
        podeVerPedidosOracao: false,
        podeEditarAgendas: false,
      ),
      appBar: AppBar(title: const Text('Destaques da Área de Serviço')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: nomeSegmento == null
            ? const Center(child: Text('Você não está vinculado a uma área de serviço.'))
            : destaques.isEmpty
                ? const Center(child: Text('Nenhum destaque encontrado.'))
                : ListView.builder(
                    itemCount: destaques.length,
                    itemBuilder: (context, index) {
                      final item = destaques[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(item['titulo'] ?? 'Sem título'),
                          subtitle: Text(item['descricao'] ?? ''),
                          trailing: Text(item['data'] ?? ''),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
