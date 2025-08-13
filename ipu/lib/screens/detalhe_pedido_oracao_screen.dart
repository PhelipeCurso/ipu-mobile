import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pedido_oracao_model.dart';

class DetalhePedidoOracaoScreen extends StatefulWidget {
  final PedidoOracaoModel pedido;
  final bool podeMarcarComoLido; // opcional: override

  const DetalhePedidoOracaoScreen({
    super.key,
    required this.pedido,
    this.podeMarcarComoLido = false,
  });

  @override
  State<DetalhePedidoOracaoScreen> createState() =>
      _DetalhePedidoOracaoScreenState();
}

class _DetalhePedidoOracaoScreenState extends State<DetalhePedidoOracaoScreen> {
  late bool _lido;
  bool _salvando = false;
  bool _deletando = false;
  String? _currentUid;
  String? _ownerUid;

  @override
  void initState() {
    super.initState();
    _lido = widget.pedido.lido ?? false;
    _currentUid = FirebaseAuth.instance.currentUser?.uid;
    // tente os nomes de campo possíveis no model
    _ownerUid = widget.pedido.uid ?? widget.pedido.id ?? widget.pedido.uid;
  }

  bool get _isOwner => _currentUid != null && _ownerUid != null && _currentUid == _ownerUid;
  bool get _canModify => widget.podeMarcarComoLido || _isOwner;

  Future<void> _atualizarLido(bool valor) async {
    final prev = _lido;
    setState(() {
      _lido = valor;
      _salvando = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('pedidos_oracao')
          .doc(widget.pedido.id)
          .update({'lido': valor});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(valor ? 'Pedido marcado como lido ✅' : 'Marcado como não lido')),
      );
    } catch (e) {
      setState(() => _lido = prev);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar: $e')),
      );
    } finally {
      setState(() => _salvando = false);
    }
  }

  Future<void> _deletarPedido() async {
    if (!_isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você não tem permissão para excluir este pedido.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir pedido'),
        content: const Text('Tem certeza que deseja excluir este pedido de oração? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Excluir')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _deletando = true);

    try {
      await FirebaseFirestore.instance
          .collection('pedidos_oracao')
          .doc(widget.pedido.id)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pedido excluído com sucesso.')));
      Navigator.of(context).pop(true); // retorna true para a página anterior (pode usar para atualizar lista)
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
    } finally {
      setState(() => _deletando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final texto = widget.pedido.mensagem ?? ''; // garante que não seja null
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        // título com nome do usuário + emoji de oração + ícone de lido
        title: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      widget.pedido.nome ?? 'Pedido de Oração',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('🙏🏽', style: TextStyle(fontSize: 18)), // emoji pedido
                  const SizedBox(width: 6),
                  Icon(
                    _lido ? Icons.check_circle : Icons.circle_outlined,
                    color: _lido ? Colors.green : Colors.grey,
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_isOwner)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deletarPedido,
              tooltip: 'Excluir pedido',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _deletando
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // opcional: dados meta (data, autor)
                    if (widget.pedido.dataCriacao != null)
                      Text(
                        'Enviado em: ${widget.pedido.dataCriacao}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    const SizedBox(height: 8),
                    // Texto do pedido (usa SelectableText para facilitar copiar)
                    SelectableText(
                      texto.isNotEmpty ? texto : 'Sem mensagem.',
                      style: const TextStyle(fontSize: 16, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    if (_canModify)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Marcar como lido'),
                          Switch(
                            value: _lido,
                            onChanged: (valor) => _atualizarLido(valor),
                          ),
                        ],
                      ),
                    if (_salvando) const LinearProgressIndicator(),
                  ],
                ),
              ),
      ),
    );
  }
}
