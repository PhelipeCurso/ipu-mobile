import 'package:cloud_firestore/cloud_firestore.dart';

class PedidoOracaoModel {
  final String id;
  final String usuarioId;
  final String nome;
  final String pedido;
  final DateTime criadoEm;
  final bool lido;

  PedidoOracaoModel({
    required this.id,
    required this.usuarioId,
    required this.nome,
    required this.pedido,
    required this.criadoEm,
    this.lido = false,
  });

  factory PedidoOracaoModel.fromMap(String id, Map<String, dynamic> data) {
    final timestamp = data['criadoEm'];
    return PedidoOracaoModel(
      id: id,
      usuarioId: data['usuarioId'] ?? '',
      nome: data['nome'] ?? 'Desconhecido',
      pedido: data['mensagem'] ?? '',
      criadoEm: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
      lido: data['lido'] ?? false,
    );
  }
}
