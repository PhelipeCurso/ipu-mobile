import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GabineteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔹 Cria um novo agendamento — usado por pastor ou membro
  Future<void> criarAgendamento({
    required String idPastor,
    required String nomePastor,
    required String idMembro,
    required String nomeMembro,
    required String motivo,
    required DateTime data,
    required String criadoPor, // "pastor" ou "membro"
  }) async {
    await _firestore.collection('agendamentos').add({
      'idPastor': idPastor,
      'nomePastor': nomePastor,
      'idMembro': idMembro,
      'nomeMembro': nomeMembro,
      'motivo': motivo,
      'data': data,
      'status': 'pendente',
      'criadoPor': criadoPor,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  /// 🔹 Retorna os agendamentos criados pelo pastor logado
  Stream<QuerySnapshot> listarAgendamentosCriadosPorPastor() {
    final user = _auth.currentUser;
    return _firestore
        .collection('agendamentos')
        .where('idPastor', isEqualTo: user?.uid)
        .where('criadoPor', isEqualTo: 'pastor')
        .orderBy('data', descending: false)
        .snapshots();
  }

  /// 🔹 Retorna todos os agendamentos vinculados ao pastor logado
  Stream<QuerySnapshot> listarTodosAgendamentosDoPastor() {
    final user = _auth.currentUser;
    return _firestore
        .collection('agendamentos')
        .where('idPastor', isEqualTo: user?.uid)
        .orderBy('data', descending: false)
        .snapshots();
  }

  /// 🔹 Retorna os agendamentos criados por membros para o pastor logado
  Stream<QuerySnapshot> listarAgendamentosRecebidosDoMembro() {
    final user = _auth.currentUser;
    return _firestore
        .collection('agendamentos')
        .where('idPastor', isEqualTo: user?.uid)
        .where('criadoPor', isEqualTo: 'membro')
        .orderBy('data', descending: false)
        .snapshots();
  }

  /// 🔹 Retorna os agendamentos criados pelo membro logado
  Stream<QuerySnapshot> listarAgendamentosCriadosPorMembro() {
    final user = _auth.currentUser;
    return _firestore
        .collection('agendamentos')
        .where('idMembro', isEqualTo: user?.uid)
        .where('criadoPor', isEqualTo: 'membro')
        .orderBy('data', descending: false)
        .snapshots();
  }

  /// 🔹 Retorna os agendamentos recebidos do pastor para o membro logado
  Stream<QuerySnapshot> listarAgendamentosFeitosPeloPastorParaMembro() {
    final user = _auth.currentUser;
    return _firestore
        .collection('agendamentos')
        .where('idMembro', isEqualTo: user?.uid)
        .where('criadoPor', isEqualTo: 'pastor')
        .orderBy('data', descending: false)
        .snapshots();
  }

  /// 🔹 Atualiza o status do agendamento
  Future<void> atualizarStatus(String agendamentoId, String novoStatus) async {
    await _firestore.collection('agendamentos').doc(agendamentoId).update({
      'status': novoStatus,
    });
  }

  /// 🔹 Retorna a lista de membros (para dropdown do pastor)
  Future<List<Map<String, dynamic>>> listarMembros() async {
    final query =
        await _firestore
            .collection('usuarios')
            .where('tipoUsuario', isEqualTo: 'Membro')
            .get();

    return query.docs
        .map((doc) => {'id': doc.id, 'nome': doc['nome'] ?? 'Sem nome'})
        .toList();
  }

  /// 🔹 Retorna dados do pastor logado (para preencher ao criar agendamento)
  Future<Map<String, dynamic>?> buscarPastorAtual() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('usuarios').doc(user.uid).get();
    return doc.exists ? doc.data() : null;
  }

  /// 🔹 Retorna dados do membro logado (para preencher ao criar agendamento)
  Future<Map<String, dynamic>?> buscarMembroAtual() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('usuarios').doc(user.uid).get();
    return doc.exists ? doc.data() : null;
  }
}
