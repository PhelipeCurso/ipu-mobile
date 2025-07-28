import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class LancamentoReceitaScreen extends StatefulWidget {
  const LancamentoReceitaScreen({super.key});

  @override
  State<LancamentoReceitaScreen> createState() => _LancamentoReceitaScreenState();
}

class _LancamentoReceitaScreenState extends State<LancamentoReceitaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dados = {
    'valor': '',
    'descricao': '',
    'data': '',
  };
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
    final doc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
    setState(() {
      _segmentoUsuario = doc['areaDeServico'];
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_segmentoUsuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Segmento do usuário não encontrado.')),
      );
      return;
    }

    _formKey.currentState!.save();
    setState(() => _salvando = true);

    String? comprovanteUrl;

    if (_anexo != null) {
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('comprovantes')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(_anexo!);
        comprovanteUrl = await ref.getDownloadURL();
      } on FirebaseException catch (e) {
        debugPrint('Erro no upload: ${e.code} - ${e.message}');
        setState(() => _salvando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao fazer upload: ${e.message}')),
        );
        return;
      }
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final dadosLancamento = {
      'tipo': 'receita',
      'valor': double.parse(_dados['valor']!),
      'descricao': _dados['descricao'],
      'data': _dados['data'],
      'comprovanteUrl': comprovanteUrl,
      'segmento': _segmentoUsuario,
      'usuarioId': uid,
      'criadoEm': Timestamp.now(),
    };

    try {
      // ✅ Salvar no geral
      await FirebaseFirestore.instance.collection('lancamentos').add(dadosLancamento);

      // ✅ Salvar em contas_receber
      await FirebaseFirestore.instance.collection('contas_receber').add({
        'valor': double.parse(_dados['valor']!),
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
        builder: (ctx) => AlertDialog(
          title: const Text('Sucesso!'),
          content: const Text('Receita salva com sucesso.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.pushReplacementNamed(context, '/meus-lancamentos');
              },
              child: const Text('OK'),
            )
          ],
        ),
      );
    } catch (e) {
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar receita: $e')),
      );
    }
  }

  Future<void> _selecionarImagem() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() => _anexo = File(img.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Receita')),
      body: _salvando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Descrição'),
                      validator: (v) => v == null || v.isEmpty ? 'Informe a descrição' : null,
                      onSaved: (v) => _dados['descricao'] = v!,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Valor'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? 'Informe o valor' : null,
                      onSaved: (v) => _dados['valor'] = v!,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Data'),
                      keyboardType: TextInputType.datetime,
                      validator: (v) => v == null || v.isEmpty ? 'Informe a data' : null,
                      onSaved: (v) => _dados['data'] = v!,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _selecionarImagem,
                      icon: const Icon(Icons.attach_file),
                      label: Text(
                        _anexo != null
                            ? 'Comprovante selecionado'
                            : 'Selecionar anexo (opcional)',
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _salvar,
                      child: const Text('Salvar Receita'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
