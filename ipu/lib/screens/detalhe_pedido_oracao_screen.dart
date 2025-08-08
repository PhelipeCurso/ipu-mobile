import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pedido_oracao_model.dart';

class DetalhePedidoOracaoScreen extends StatefulWidget {
  final PedidoOracaoModel pedido;
  final bool podeMarcarComoLido;

  const DetalhePedidoOracaoScreen({
    super.key,
    required this.pedido,
    this.podeMarcarComoLido = false,
  });

  @override
  State<DetalhePedidoOracaoScreen> createState() => _DetalhePedidoOracaoScreenState();
}

class _DetalhePedidoOracaoScreenState extends State<DetalhePedidoOracaoScreen> {
  late bool _lido;

  @override
  void initState() {
    super.initState();
    _lido = widget.pedido.lido ?? false;
  }

  Future<void> _atualizarLido(bool valor) async {
    setState(() => _lido = valor);
    await FirebaseFirestore.instance
        .collection('pedidos_oracao')
        .doc(widget.pedido.id)
        .update({'lido': valor});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pedido.titulo ?? 'Pedido de Oração'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.pedido.descricao ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            if (widget.podeMarcarComoLido)
              Row(
                children: [
                  Checkbox(
                    value: _lido,
                    onChanged: (valor) {
                      if (valor != null) {
                        _atualizarLido(valor);
                      }
                    },
                  ),
                  const Text('Marcar como lido'),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
