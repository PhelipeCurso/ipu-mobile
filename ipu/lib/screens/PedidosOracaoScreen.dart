import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pedido_oracao_model.dart';
import 'detalhe_pedido_oracao_screen.dart';

class PedidosOracaoScreen extends StatelessWidget {
  final bool podeMarcarComoLido; // controle de permissão

  const PedidosOracaoScreen({super.key, this.podeMarcarComoLido = false});

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
              final pedido = pedidos[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(
                    pedido.titulo ?? 'Pedido sem título',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    pedido.descricao ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Icon(
                    pedido.lido == true ? Icons.check_circle : Icons.circle_outlined,
                    color: pedido.lido == true ? Colors.green : Colors.grey,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetalhePedidoOracaoScreen(
                          pedido: pedido,
                          podeMarcarComoLido: podeMarcarComoLido,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
