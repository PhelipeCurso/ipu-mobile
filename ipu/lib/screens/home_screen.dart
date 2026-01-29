import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ipu/widgets/menu_lateral_widget.dart';
import 'package:intl/intl.dart';
import 'package:ipu/widgets/AniversariantesDoMesWidget.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ipu/screens/AgendaScreen.dart';
import 'package:ipu/widgets/PalavraDoDiaWidget.dart';

class AppColors {
  static const vermelho = Color(0xFFC42112);
  static const preto = Color(0xFF262626);
  static const branco = Color(0xFFF2F2F2);
  static const verde = Color(0xFF3D5A40);
  static const dourado = Color(0xFFC49F48);
  static const azul = Color(0xFF1B4D5C);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String palavra = '';
  String referencia = '';
  bool carregando = true;
  bool exibirMenuLancamentos = false;
  bool podeGerenciarAgenda = false;
  bool podeVerPedidosOracao = false;
  bool podeEditarAgendas = false;

  final List<String> referencias = [
    'joao+3:16',
    'salmos+23:1',
    'filipenses+4:13',
    'romanos+8:28',
    'provérbios+3:5',
    'salmos+119:105',
    'mateus+5:9',
    'isaías+41:10',
  ];

  final TextEditingController pedidoOracaoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    carregarPalavra();
    verificarCargoEclesiastico();
    configurarFirebaseMessaging();
    const PalavraDoDiaWidget();
  }

  @override
  void dispose() {
    pedidoOracaoController.dispose();
    super.dispose();
  }

  Future<void> verificarCargoEclesiastico() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
    final dados = doc.data() ?? {};

    setState(() {
      exibirMenuLancamentos = dados['cargoEclesiastico'] == true;
      podeGerenciarAgenda = dados['podeGerenciarAgenda'] == true;
      podeVerPedidosOracao = dados['podeVerPedidosOracao'] == true;
      podeEditarAgendas = dados['podeEditarAgendas'] == true;
    });
  }

  void configurarFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Solicita permissão (iOS) e configurações (Android)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('🔔 Permissão concedida: ${settings.authorizationStatus}');

    // Obtem o token do dispositivo
    final token = await FirebaseMessaging.instance.getToken();
    print('📱 FCM Token: $token');

    // Salva no Firestore (opcional, mas necessário se quiser enviar notificação para esse usuário)
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && token != null) {
      final userRef = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid);

      await userRef.update({'fcmToken': token});

      print('✅ Token salvo no Firestore com sucesso');
    }

    // Escuta notificações enquanto o app está em primeiro plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notificacao = message.notification;
      if (notificacao != null) {
        print('🔔 Nova notificação recebida: ${notificacao.title}');
        // Você pode mostrar uma snackbar/dialog aqui
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${notificacao.title ?? ''}: ${notificacao.body ?? ''}',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
    // 🔔 "📬 Inscrito em todos os tópicos de notificação"
    await messaging.subscribeToTopic('agendaEventos');
    await messaging.subscribeToTopic('noticias');
    await messaging.subscribeToTopic('eventos');
    await messaging.subscribeToTopic('aniversariantes');
    print('📬 Inscrito em todos os tópicos de notificação');
  }

  Future<void> carregarPalavra() async {
    setState(() => carregando = true);

    final ref = referencias[Random().nextInt(referencias.length)];
    final url = Uri.parse('https://bible-api.com/$ref?translation=almeida');

    try {
      final resposta = await http.get(url);
      if (resposta.statusCode == 200) {
        final data = json.decode(resposta.body);
        setState(() {
          palavra = data['text']?.trim() ?? '';
          referencia = data['reference'] ?? '';
          carregando = false;
        });
      } else {
        setState(() {
          palavra = 'Não foi possível carregar a Palavra do Dia.';
          referencia = '';
          carregando = false;
        });
      }
    } catch (e) {
      setState(() {
        palavra = 'Erro ao buscar a Palavra do Dia.';
        referencia = '';
        carregando = false;
      });
    }
  }

  Future<void> testeConsultaNoticias() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('informacoes')
            .doc('noticias')
            .collection('items')
            .get();

    print('Total de notícias encontradas: ${snapshot.docs.length}');
    for (var doc in snapshot.docs) {
      final data = doc.data();
      print('Notícia: ${data['titulo']} - Criada em: ${data['criadoEm']}');
    }
  }

  Future<void> testarConsultaSemOrderBy() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('informacoes')
              .doc('noticias')
              .collection('itens')
              .get();

      print(
        '📥 Total documentos encontrados (sem orderBy): ${snapshot.docs.length}',
      );
      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('📄 Título: ${data['titulo']}, criadoEm: ${data['criadoEm']}');
      }
    } catch (e) {
      print('❌ Erro: $e');
    }
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/');
  }

  void testarLeituraManual() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('informacoes')
            .doc('noticias')
            .collection('itens')
            .doc('DuuAl3yo79njgThqN9PJ')
            .get();

    if (doc.exists) {
      print('✅ Documento lido manualmente: ${doc.data()}');
    } else {
      print('❌ Documento não encontrado!');
    }
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget buildBulletList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('• $item', style: const TextStyle(fontSize: 16)),
                ),
              )
              .toList(),
    );
  }

  Widget buildPrayerRequestField(TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🙏 Pedido de Oração',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Digite seu pedido aqui...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () async {
            final texto = controller.text.trim();
            if (texto.isEmpty) return;

            final user = FirebaseAuth.instance.currentUser;
            if (user == null) {
              print('❌ Usuário não autenticado');
              return;
            }

            try {
              await FirebaseFirestore.instance
                  .collection('pedidos_oracao')
                  .add({
                    'mensagem': texto,
                    'uid': user.uid,
                    'email': user.email,
                    'nome': user.displayName,
                    'timestamp': FieldValue.serverTimestamp(),
                    'lido': false,
                  });

              controller.clear();

              // Você pode mostrar um SnackBar ou Toast aqui
              print('📨 Pedido enviado com sucesso!');
            } catch (e) {
              print('Erro ao enviar pedido: $e');
            }
          },
          child: const Text('Enviar Pedido'),
        ),
      ],
    );
  }

  Widget buildDonationButton(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.pinkAccent,
        minimumSize: const Size.fromHeight(50),
      ),
      onPressed: () {
        Navigator.pushNamed(context, '/doacao');
      },
      icon: const Icon(Icons.favorite),
      label: const Text('Faça sua Contribuição 💖', style: TextStyle(fontSize: 18)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Início'),
        backgroundColor: AppColors.vermelho,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      drawer: MenuLateralWidget(
        exibirMenuLancamentos: exibirMenuLancamentos,
        podeGerenciarAgenda: podeGerenciarAgenda,
        podeVerPedidosOracao: podeVerPedidosOracao,
        podeEditarAgendas: podeEditarAgendas,
      ),
      body:
          carregando
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  // 📸 Fundo com imagem local
                  Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/img/papeldeparedehome.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // 🌓 Camada escura sobre a imagem
                  Container(color: Colors.black.withOpacity(0.5)),

                  // 🌟 Conteúdo
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PalavraDoDiaWidget(),

                        // 🔔 Últimas Notícias
                        buildSectionTitle('📢 Últimas Notícias'),
                        StreamBuilder<QuerySnapshot>(
                          stream:
                              FirebaseFirestore.instance
                                  .collection('informacoes')
                                  .doc('noticias')
                                  .collection('itens')
                                  .orderBy('criadoEm', descending: true)
                                  .limit(1)
                                  .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final docs = snapshot.data?.docs ?? [];

                            if (docs.isEmpty) {
                              return const Text('Nenhuma notícia encontrada.');
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...docs.map((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final titulo = data['titulo'] ?? 'Sem título';
                                  final timestamp = data['criadoEm'];
                                  final dataTexto =
                                      timestamp is Timestamp
                                          ? DateFormat(
                                            'dd/MM/yyyy',
                                          ).format(timestamp.toDate())
                                          : 'Data desconhecida';
                                  final imagem = data['midiaUrl'];

                                  return Card(
                                    elevation: 2,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (imagem != null)
                                          ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(12),
                                                ),
                                            child: Image.network(
                                              imagem,
                                              height: 180,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                titulo,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                dataTexto,
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed:
                                        () => Navigator.pushNamed(
                                          context,
                                          '/noticias',
                                        ),
                                    icon: const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                    ),
                                    label: const Text('Ver todas'),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        // 🗓️ Próximos Eventos
                        buildSectionTitle('📅 Próximos Eventos'),
                        StreamBuilder<QuerySnapshot>(
                          stream:
                              FirebaseFirestore.instance
                                  .collection('informacoes')
                                  .doc('eventos')
                                  .collection('itens')
                                  .orderBy('criadoEm', descending: true)
                                  .limit(1)
                                  .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final docs = snapshot.data?.docs ?? [];

                            if (docs.isEmpty) {
                              return const Text('Nenhum evento encontrado.');
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...docs.map((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final titulo = data['titulo'] ?? 'Sem título';
                                  final timestamp = data['criadoEm'];
                                  final dataTexto =
                                      timestamp is Timestamp
                                          ? DateFormat(
                                            'dd/MM/yyyy',
                                          ).format(timestamp.toDate())
                                          : 'Data desconhecida';
                                  final imagem = data['midiaUrl'];

                                  return Card(
                                    elevation: 2,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (imagem != null)
                                          ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(12),
                                                ),
                                            child: Image.network(
                                              imagem,
                                              height: 180,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                titulo,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                dataTexto,
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed:
                                        () => Navigator.pushNamed(
                                          context,
                                          '/eventos',
                                        ),
                                    icon: const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                    ),
                                    label: const Text('Ver todos'),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 16),
                        buildDonationButton(context),
                        const SizedBox(height: 24),
                        buildPrayerRequestField(pedidoOracaoController),

                        const AniversariantesWidget(),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
