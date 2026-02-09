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

    final segmento = userDoc.data()?['areaDeServico'] ?? 'desconhecido';

    // =========================
    // Monta objeto primeiro
    // =========================
    final Map<String, dynamic> data = {
      'valor': valor,
      'valorCentavos': (valor * 100).round(),
      'usuarioId': user.uid,
      'segmento': segmento,
      'tipo': tipo,
      'origem': 'app-mobile',
      'gateway': 'manual_pix',
      'dataDoacao': FieldValue.serverTimestamp(),
      'data': Timestamp.now(),

      // financeiro
      'status': 'pendente',
      'comprovanteUrl': null,

      // auditoria
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // adiciona mesRef apenas para dízimo
    if (mesRef != null) {
      data['mesRef'] = mesRef;
    }

    // =========================
    // salva uma única vez
    // =========================
    final docRef = await _db.collection('doacoes').add(data);

    return docRef.id;
  }
}
