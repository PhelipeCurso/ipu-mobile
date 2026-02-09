import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme_notifier.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  String _nome = '';
  String _caminhoImagem = '';
  bool _modoEscuro = false;
  bool _notificacoesAtivas = true;
  String _versao = '';

  final _nomeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  // =========================
  // CARREGAR DADOS
  // =========================
  Future<void> _carregarDados() async {
    final prefs = await SharedPreferences.getInstance();
    final info = await PackageInfo.fromPlatform();

    setState(() {
      _nome = prefs.getString('nome_usuario') ?? '';
      _caminhoImagem = prefs.getString('imagem_usuario') ?? '';
      _modoEscuro = prefs.getBool('modo_escuro') ?? false;
      _notificacoesAtivas = prefs.getBool('notificacoes_ativas') ?? true;
      _versao = info.version;
      _nomeController.text = _nome;
    });
  }

  // =========================
  // SALVAR NOME
  // =========================
  Future<void> _salvarNome() async {
    if (_nomeController.text.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nome_usuario', _nomeController.text.trim());

    setState(() {
      _nome = _nomeController.text.trim();
    });
  }

  // =========================
  // IMAGEM
  // =========================
  Future<void> _trocarImagem() async {
    final picker = ImagePicker();
    final imagem = await picker.pickImage(source: ImageSource.gallery);

    if (imagem != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('imagem_usuario', imagem.path);

      setState(() {
        _caminhoImagem = imagem.path;
      });
    }
  }

  // =========================
  // TEMA
  // =========================
  Future<void> _alternarTema(bool valor) async {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    themeNotifier.toggleTheme(valor);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('modo_escuro', valor);

    setState(() {
      _modoEscuro = valor;
    });
  }

  // =========================
  // 🔔 NOTIFICAÇÕES
  // =========================
  Future<void> _alternarNotificacoes(bool valor) async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    setState(() {
      _notificacoesAtivas = valor;
    });

    await prefs.setBool('notificacoes_ativas', valor);

    if (user == null) return;

    final messaging = FirebaseMessaging.instance;

    if (valor) {
      // 🔹 ATIVAR
      await messaging.requestPermission();

      final token = await messaging.getToken();

      if (token != null) {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .set({
          'fcmTokens': FieldValue.arrayUnion([token])
        }, SetOptions(merge: true));
      }

    } else {
      // 🔹 DESATIVAR (remove token do servidor)
      final token = await messaging.getToken();

      if (token != null) {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .update({
          'fcmTokens': FieldValue.arrayRemove([token])
        });
      }

      await messaging.deleteToken();
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: GestureDetector(
              onTap: _trocarImagem,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: (_caminhoImagem.isNotEmpty &&
                        File(_caminhoImagem).existsSync())
                    ? FileImage(File(_caminhoImagem))
                    : null,
                child:
                    _caminhoImagem.isEmpty ? const Icon(Icons.person, size: 50) : null,
              ),
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: _nomeController,
            decoration: const InputDecoration(
              labelText: 'Nome do usuário',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.edit),
            ),
            onSubmitted: (_) => _salvarNome(),
          ),

          const SizedBox(height: 20),

          SwitchListTile(
            title: const Text('Modo Escuro'),
            value: _modoEscuro,
            onChanged: _alternarTema,
            secondary: const Icon(Icons.dark_mode),
          ),

          // 🔥 NOVO SWITCH
          SwitchListTile(
            title: const Text('Notificações'),
            value: _notificacoesAtivas,
            onChanged: _alternarNotificacoes,
            secondary: const Icon(Icons.notifications_active),
          ),

          const Divider(),

          ListTile(
            title: const Text('Versão do App'),
            subtitle: Text(_versao),
            leading: const Icon(Icons.info_outline),
          ),
        ],
      ),
    );
  }
}
