import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoacaoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> criarDoacao({
    required double valor,
    required String tipo,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    final userDoc =
        await _db.collection('usuarios').doc(user.uid).get();

    final segmento = userDoc.data()?['areaDeServico'] ?? 'desconhecido';

    final docRef = await _db.collection('doacoes').add({
      'valor': valor,
      'valorCentavos': (valor * 100).round(),
      'usuarioId': user.uid,
      'segmento': segmento,
      'tipo': tipo, // dizimo | oferta
      'origem': 'app-mobile',
      'gateway': 'manual_pix',
      'dataDoacao': FieldValue.serverTimestamp(),
      'data': Timestamp.now(),

      // controle financeiro
      'status': 'pendente', // pendente | confirmado | cancelado
      'comprovanteUrl': null,

      // auditoria
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  Future<void> confirmarDoacao({
    required String doacaoId,
    required String comprovanteUrl,
  }) async {
    await _db.collection('doacoes').doc(doacaoId).update({
      'status': 'confirmado',
      'comprovanteUrl': comprovanteUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
