import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoacaoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> criarDoacao({
    required double valor,
    required String tipo,
    String? mesRef,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    final userDoc = await _db.collection('usuarios').doc(user.uid).get();
    final userData = userDoc.data();

    if (userData == null) {
      throw Exception('Dados do usuário não encontrados');
    }

    final segmento = userData['areaDeServico'] ?? 'desconhecido';
    final nome = userData['nome'] ?? '';
    final cpf = userData['cpf'] ?? '';

    // =========================
    // 🔒 BLOQUEIO DE DÍZIMO DUPLICADO
    // =========================
    if (tipo == 'dizimo' && mesRef != null) {
      final existente =
          await _db
              .collection('doacoes')
              .where('usuarioId', isEqualTo: user.uid)
              .where('tipo', isEqualTo: 'dizimo')
              .where('mesRef', isEqualTo: mesRef)
              .where('status', whereIn: ['pendente', 'confirmado'])
              .get();

      if (existente.docs.isNotEmpty) {
        throw Exception('Dízimo deste mês já registrado.');
      }
    }

    // =========================
    // 📦 MONTA OBJETO
    // =========================
    final Map<String, dynamic> data = {
      // Snapshot do usuário (IMPORTANTE)
      'usuarioId': user.uid,
      'nome': nome,
      'cpf': cpf,

      // Financeiro
      'valor': valor,
      'valorCentavos': (valor * 100).round(),
      'tipo': tipo,
      'segmento': segmento,
      'origem': 'app-mobile',
      'gateway': 'manual_pix',
      'status': 'pendente',
      'comprovanteUrl': null,

      // Datas
      'dataDoacao': FieldValue.serverTimestamp(),
      'data': Timestamp.now(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (mesRef != null) {
      data['mesRef'] = mesRef;
    }

    // =========================
    // 💾 SALVA
    // =========================
    final docRef = await _db.collection('doacoes').add(data);

    return docRef.id;
  }
}
