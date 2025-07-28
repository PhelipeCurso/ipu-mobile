import 'package:flutter/material.dart';
import '../models/pedido_oracao_model.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EnvioPedidosOracao extends StatelessWidget {
  final PedidoOracaoModel pedido;

  const EnvioPedidosOracao({super.key, required this.pedido});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '🙋 ${pedido.nome}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: Icon(
                    pedido.lido ? Icons.mark_email_read : Icons.mark_email_unread,
                    color: pedido.lido ? Colors.green : Colors.grey,
                  ),
                  tooltip: pedido.lido ? 'Já lido' : 'Marcar como lido',
                  onPressed: pedido.lido
                      ? null
                      : () async {
                          await FirebaseFirestore.instance
                              .collection('pedidos_oracao')
                              .doc(pedido.id)
                              .update({'lido': true});

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Marcado como lido')),
                          );
                        },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              pedido.pedido,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              '📅 ${pedido.criadoEm.day}/${pedido.criadoEm.month}/${pedido.criadoEm.year}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
