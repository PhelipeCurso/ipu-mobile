import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class LancamentoDespesaScreen extends StatefulWidget {
  const LancamentoDespesaScreen({super.key});

  @override
  State<LancamentoDespesaScreen> createState() =>
      _LancamentoDespesaScreenState();
}

class _LancamentoDespesaScreenState extends State<LancamentoDespesaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dados = {'valor': '', 'descricao': '', 'data': ''};
  File? _anexo;
  bool _salvando = false;
  String? _segmentoUsuario;

  @override
  void initState() {
    super.initState();
    _carregarSegmentoUsuario();
  }

  Future<void> _carregarSegmentoUsuario() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc =
        await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
    setState(() {
      _segmentoUsuario = doc['areaDeServico'];
    });
  }

  Future<void> _selecionarImagem() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() => _anexo = File(img.path));
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_segmentoUsuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Segmento do usuário não encontrado.')),
      );
      return;
    }

    if (_anexo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anexo obrigatório para despesas.')),
      );
      return;
    }

    _formKey.currentState!.save();
    setState(() => _salvando = true);

    try {
      // ✅ Verifica e converte o valor com . como separador
      final valor = double.tryParse(_dados['valor']!.replaceAll(',', '.'));
      if (valor == null) {
        throw Exception('Valor inválido');
      }

      // ✅ Upload do anexo
      final ref = FirebaseStorage.instance
          .ref()
          .child('comprovantes')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(_anexo!);
      final comprovanteUrl = await ref.getDownloadURL();

      final uid = FirebaseAuth.instance.currentUser!.uid;

      final dadosLancamento = {
        'tipo': 'despesa',
        'valor': valor,
        'descricao': _dados['descricao'],
        'data': _dados['data'],
        'comprovanteUrl': comprovanteUrl,
        'segmento': _segmentoUsuario,
        'usuarioId': uid,
        'criadoEm': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('lancamentos')
          .add(dadosLancamento);

      await FirebaseFirestore.instance.collection('contas_pagar').add({
        'valor': valor,
        'descricao': _dados['descricao'],
        'data': Timestamp.now(),
        'segmento': _segmentoUsuario,
        'usuarioId': uid,
        'criadoEm': Timestamp.now(),
        'comprovanteUrl': comprovanteUrl,
        'status': 'pendente',
        'origem': 'app-mobile',
      });

      setState(() => _salvando = false);

      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Sucesso!'),
              content: const Text('Despesa salva com sucesso.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.pushReplacementNamed(
                      context,
                      '/meus-lancamentos',
                    );
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    } catch (e) {
      setState(() => _salvando = false);
      debugPrint('Erro ao salvar despesa: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Despesa')),
      body:
          _salvando
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Descrição',
                        ),
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? 'Informe a descrição'
                                    : null,
                        onSaved: (v) => _dados['descricao'] = v!,
                      ),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Valor'),
                        keyboardType: TextInputType.number,
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? 'Informe o valor'
                                    : null,
                        onSaved: (v) => _dados['valor'] = v!,
                      ),

                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Data'),
                        keyboardType: TextInputType.datetime,
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? 'Informe a data'
                                    : null,
                        onSaved: (v) => _dados['data'] = v!,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _selecionarImagem,
                        icon: const Icon(Icons.attach_file),
                        label: Text(
                          _anexo != null
                              ? 'Comprovante selecionado'
                              : 'Selecionar anexo (obrigatório)',
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _salvar,
                        child: const Text('Salvar Despesa'),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
