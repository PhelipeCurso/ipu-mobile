import 'package:cloud_firestore/cloud_firestore.dart';

class AgendamentoGabinete {
  final String id;
  final String membroId;
  final String pastorId;
  final String motivo;
  final String descricao;
  final DateTime dataHora;
  final String status;
  final String? observacao;

  AgendamentoGabinete({
    required this.id,
    required this.membroId,
    required this.pastorId,
    required this.motivo,
    required this.descricao,
    required this.dataHora,
    required this.status,
    this.observacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'membroId': membroId,
      'pastorId': pastorId,
      'motivo': motivo,
      'descricao': descricao,
      'dataHora': Timestamp.fromDate(dataHora),
      'status': status,
      'observacao': observacao,
    };
  }

  factory AgendamentoGabinete.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AgendamentoGabinete(
      id: doc.id,
      membroId: data['membroId'],
      pastorId: data['pastorId'],
      motivo: data['motivo'],
      descricao: data['descricao'],
      dataHora: (data['dataHora'] as Timestamp).toDate(),
      status: data['status'],
      observacao: data['observacao'],
    );
  }
}
