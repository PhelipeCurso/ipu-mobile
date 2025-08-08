class PedidoOracaoModel {
  final String id;
  final String? titulo;
  final String? descricao;
  final bool? lido;

  PedidoOracaoModel({
    required this.id,
    this.titulo,
    this.descricao,
    this.lido,
  });

  factory PedidoOracaoModel.fromMap(String id, Map<String, dynamic> map) {
    return PedidoOracaoModel(
      id: id,
      titulo: map['titulo'],
      descricao: map['descricao'],
      lido: map['lido'] ?? false,
    );
  }
}
