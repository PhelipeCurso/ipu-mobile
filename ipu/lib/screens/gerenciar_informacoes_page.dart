import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GerenciarInformacoesPage extends StatefulWidget {
  const GerenciarInformacoesPage({super.key});

  @override
  State<GerenciarInformacoesPage> createState() => _GerenciarInformacoesPageState();
}

class _GerenciarInformacoesPageState extends State<GerenciarInformacoesPage> {
  final _formKey = GlobalKey<FormState>();
  String _tipo = 'noticias';
  String _titulo = '';
  String _descricao = '';
  File? _midia;
  String? _tipoMidia;

  bool _carregando = false;
  bool _temPermissao = false;
  bool _verificandoPermissao = true;

  @override
  void initState() {
    super.initState();
    verificarPermissao();
  }

  Future<void> verificarPermissao() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
    final pode = doc.data()?['podeGerenciarAgenda'] ?? false;
    setState(() {
      _temPermissao = pode;
      _verificandoPermissao = false;
    });
  }

  Future<void> selecionarMidia() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery);

    if (result != null) {
      setState(() {
        _midia = File(result.path);
        _tipoMidia = 'imagem';
      });
    }
  }

  Future<String> uploadMidia() async {
    final nomeArquivo = '${DateTime.now().millisecondsSinceEpoch}_${_midia!.path.split('/').last}';
    final ref = FirebaseStorage.instance.ref('agenda/$_tipo/$nomeArquivo');
    await ref.putFile(_midia!);
    return await ref.getDownloadURL();
  }

  Future<void> salvar() async {
    if (!_formKey.currentState!.validate() || _midia == null) return;
    setState(() => _carregando = true);

    try {
      final url = await uploadMidia();
      await FirebaseFirestore.instance.collection('informacoes').doc(_tipo).collection('itens').add({
        'titulo': _titulo,
        'descricao': _descricao,
        'midiaUrl': url,
        'tipoMidia': _tipoMidia,
        'criadoEm': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$_tipo cadastrado com sucesso!')));
      _formKey.currentState!.reset();
      setState(() {
        _midia = null;
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_verificandoPermissao) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_temPermissao) {
      return Scaffold(
        appBar: AppBar(title: Text('Gerenciar Informações')),
        body: Center(child: Text('Você não tem permissão para acessar esta funcionalidade.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Gerenciar Informações')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _tipo,
                decoration: InputDecoration(labelText: 'Tipo'),
                items: [
                  DropdownMenuItem(value: 'noticias', child: Text('Notícia')),
                  DropdownMenuItem(value: 'eventos', child: Text('Evento')),
                ],
                onChanged: (val) => setState(() => _tipo = val!),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Título'),
                validator: (val) => val == null || val.isEmpty ? 'Campo obrigatório' : null,
                onChanged: (val) => _titulo = val,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Descrição (opcional)'),
                onChanged: (val) => _descricao = val,
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: Icon(Icons.image),
                label: Text('Selecionar Imagem'),
                onPressed: selecionarMidia,
              ),
              if (_midia != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Image.file(_midia!, height: 150),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _carregando ? null : salvar,
                child: _carregando
                    ? CircularProgressIndicator()
                    : Text('Salvar ${_tipo == 'noticias' ? 'Notícia' : 'Evento'}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
