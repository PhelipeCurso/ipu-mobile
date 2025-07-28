import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MeusLancamentosScreen extends StatelessWidget {
  const MeusLancamentosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Meus Lançamentos')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('lancamentos')
            .where('usuarioId', isEqualTo: uid)
            .orderBy('criadoEm', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('Nenhum lançamento encontrado.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final dados = docs[i].data() as Map<String, dynamic>;
              return ListTile(
                leading: Icon(
                  dados['tipo'] == 'receita' ? Icons.arrow_downward : Icons.arrow_upward,
                  color: dados['tipo'] == 'receita' ? Colors.green : Colors.red,
                ),
                title: Text(dados['descricao'] ?? ''),
                subtitle: Text('Data: ${dados['data'] ?? ''} • Valor: R\$ ${dados['valor']?.toStringAsFixed(2) ?? '0.00'}'),
                trailing: Text(dados['segmento'] ?? '', style: const TextStyle(fontSize: 12)),
              );
            },
          );
        },
      ),
    );
  }
}
