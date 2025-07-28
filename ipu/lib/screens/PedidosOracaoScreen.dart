import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pedido_oracao_model.dart';
import '../widgets/envio_pedidos_oracao.dart';

class PedidosOracaoScreen extends StatelessWidget {
  const PedidosOracaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos de Oração'),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pedidos_oracao')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar os pedidos.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final pedidos = snapshot.data!.docs.map((doc) {
            return PedidoOracaoModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
          }).toList();

          if (pedidos.isEmpty) {
            return const Center(child: Text('Nenhum pedido de oração.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: pedidos.length,
            itemBuilder: (context, index) {
              return EnvioPedidosOracao(pedido: pedidos[index]);
            },
          );
        },
      ),
    );
  }
}
