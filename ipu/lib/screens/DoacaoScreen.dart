import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../app.dart';
import 'ComprovantePixScreen.dart';

class DoacaoScreen extends StatefulWidget {
  const DoacaoScreen({super.key});

  @override
  State<DoacaoScreen> createState() => _DoacaoScreenState();
}

class _DoacaoScreenState extends State<DoacaoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();

  Future<void> _confirmarDoacao() async {
    if (!_formKey.currentState!.validate()) return;

    final valor = double.tryParse(_valorController.text.replaceAll(',', '.'));
    if (valor == null || valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valor inválido')),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;

    // Buscar segmento do usuário
    final doc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
    final segmento = doc.data()?['areaDeServico'] ?? 'desconhecido';

    // Salvar no Firestore
    await FirebaseFirestore.instance.collection('doacoes').add({
      'valor': valor,
      'usuarioId': uid,
      'segmento': segmento,
      'data': Timestamp.now(),
      'origem': 'app-mobile',
      'status': 'pendente', // Pode ser alterado pelo painel depois
    });

    // Redirecionar para tela do PIX
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ComprovantePixScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doações')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                'Digite o valor da sua doação',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valorController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Valor (R\$)'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe um valor' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirmarDoacao,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.vermelho,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Confirmar Doação',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
