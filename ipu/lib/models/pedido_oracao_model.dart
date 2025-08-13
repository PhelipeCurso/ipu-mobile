// lib/models/pedido_oracao_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PedidoOracaoModel {
  final String id;
  final String? nome;
  final String? mensagem; // texto principal (campo 'mensagem' no Firestore)
  final bool lido;
  final DateTime? dataCriacao;
  final String? uid; // id do autor

  PedidoOracaoModel({
    required this.id,
    this.nome,
    this.mensagem,
    this.lido = false,
    this.dataCriacao,
    this.uid,
  });

  /// Factory compatível com vários nomes de campo e tipos (Timestamp / DateTime).
  factory PedidoOracaoModel.fromMap(String id, Map<String, dynamic> data) {
    // pega texto em 'mensagem' ou 'pedido' (compatibilidade)
    final String? mensagem = (data['mensagem'] as String?) ?? (data['pedido'] as String?);

    // normaliza 'lido' para bool
    bool lido = false;
    final dynamic lidoRaw = data['lido'];
    if (lidoRaw is bool) {
      lido = lidoRaw;
    } else if (lidoRaw is int) {
      lido = lidoRaw != 0;
    } else if (lidoRaw is String) {
      lido = lidoRaw.toLowerCase() == 'true';
    }

    // normaliza timestamp (pode ser Timestamp ou DateTime)
    DateTime? dataCriacao;
    final dynamic ts = data['timestamp'] ?? data['dataCriacao'] ?? data['criadoEm'];
    if (ts is Timestamp) {
      dataCriacao = ts.toDate();
    } else if (ts is DateTime) {
      dataCriacao = ts;
    }

    // uid do autor (vários nomes possíveis)
    final String? uid = (data['uid'] as String?) ?? (data['userId'] as String?) ?? (data['autorId'] as String?);

    return PedidoOracaoModel(
      id: id,
      nome: data['nome'] as String?,
      mensagem: mensagem,
      lido: lido,
      dataCriacao: dataCriacao,
      uid: uid,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'mensagem': mensagem,
      'lido': lido,
      'timestamp': dataCriacao != null ? Timestamp.fromDate(dataCriacao!) : FieldValue.serverTimestamp(),
      'uid': uid,
    };
  }

  @override
  String toString() {
    return 'PedidoOracaoModel(id: $id, nome: $nome, mensagem: ${mensagem?.substring(0, mensagem?.length.clamp(0,40) ?? 0)}, lido: $lido, dataCriacao: $dataCriacao, uid: $uid)';
  }
}
