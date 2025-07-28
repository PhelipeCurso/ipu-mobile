import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class MenuLateralWidget extends StatefulWidget {
  final bool exibirMenuLancamentos;
  final bool podeGerenciarAgenda;
  final bool podeVerPedidosOracao;

  const MenuLateralWidget({
    super.key,
    required this.exibirMenuLancamentos,
    required this.podeGerenciarAgenda,
    required this.podeVerPedidosOracao,
  });

  @override
  State<MenuLateralWidget> createState() => _MenuLateralWidgetState();
}

class _MenuLateralWidgetState extends State<MenuLateralWidget> {
  String _nome = '';
  String _imagem = '';

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuarioLocal();
  }

  Future<void> _carregarDadosUsuarioLocal() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nome = prefs.getString('nome_usuario') ?? FirebaseAuth.instance.currentUser?.displayName ?? 'Usuário';
      _imagem = prefs.getString('imagem_usuario') ?? '';
    });
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(_nome),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: (_imagem.isNotEmpty && File(_imagem).existsSync())
                  ? FileImage(File(_imagem))
                  : null,
              child: _imagem.isEmpty
                  ? Text(
                      _nome.isNotEmpty ? _nome[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.red, fontSize: 24),
                    )
                  : null,
            ),
            decoration: const BoxDecoration(color: Colors.red),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Início'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text('Agenda da Semana'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.video_library),
            title: const Text('Canal do YouTube'),
            onTap: () => Navigator.pop(context),
          ),
          if (widget.exibirMenuLancamentos)
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Lançamentos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/lancamentos');
              },
            ),
          if (widget.podeVerPedidosOracao)
            ListTile(
              leading: const Icon(Icons.library_books),
              title: const Text('Pedidos de Oração'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/pedidos-oracao');
              },
            ),
          if (widget.podeGerenciarAgenda)
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Gerenciar Informações'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/gerenciar-informacoes');
              },
            ),
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('Doação'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/doacao');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configurações'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/configuracoes');
            },
          ),
          ListTile(
          leading: const Icon(Icons.location_on),
          title: const Text('📍 Faça-nos uma Visita'),
          onTap: () async {
          const endereco = 'Igreja Pentecostal Unida, Rua Exemplo, 123, Cidade - UF';
          final encodedAddress = Uri.encodeComponent(endereco);
          final googleMapsUrl = 'https://maps.app.goo.gl/co8P7qotMc9aG1jx6';

           if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
           await launchUrl(Uri.parse(googleMapsUrl), mode: LaunchMode.externalApplication);
            } else {
             ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Não foi possível abrir o Maps')),
         );
       }
     },
   ),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair'),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
