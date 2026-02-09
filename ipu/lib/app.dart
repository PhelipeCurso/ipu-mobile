import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/login_screen.dart';
import 'screens/cadastro_screen.dart';
import 'screens/home_screen.dart';
import 'screens/configuracoes_screen.dart';
import 'theme_notifier.dart';
import 'screens/LancamentoReceitaScreen.dart';
import 'screens/MeusLancamentosScreen.dart';
import 'screens/LancamentoDespesaScreen.dart';
import 'screens/LancamentosFinanceirosScreen.dart';
import 'screens/doacoes/DoacaoScreen.dart';
import 'screens/WelcomeScreen.dart';
import 'screens/gerenciar_informacoes_page.dart';
import 'screens/eventos_screen.dart';
import 'screens/noticias_screen.dart';
import 'screens/PedidosOracaoScreen.dart';
import 'screens/AgendaScreen.dart';
import 'screens/doacoes/doacoes_home_screen.dart';


/// 🔥 NECESSÁRIO para background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}


/// navigator global para abrir telas via push
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const MyApp(),
    ),
  );
}


/// =============================
/// NOTIFICAÇÕES SERVICE
/// =============================
class NotificationService {
  static final _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    // 🔹 Permissão iOS/Android 13+
    await _messaging.requestPermission();

    // 🔹 Token
    final token = await _messaging.getToken();
    await _saveToken(token);

    // 🔹 refresh token
    _messaging.onTokenRefresh.listen(_saveToken);

    // 🔹 foreground
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Notificação recebida em foreground');
    });

    // 🔹 quando usuário toca na notificação
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNavigation);

    // 🔹 app fechado
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _handleNavigation(initial);
    }
  }


  static Future<void> _saveToken(String? token) async {
    if (token == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .set({
      'fcmTokens': FieldValue.arrayUnion([token])
    }, SetOptions(merge: true));
  }


  /// 🔥 navegação usando data payload da Cloud Function
  static void _handleNavigation(RemoteMessage message) {
    final tipo = message.data['tipo'];

    if (tipo == 'agendamento') {
      navigatorKey.currentState?.pushNamed(
        '/agenda',
      );
    }
  }
}



/// =============================
/// CORES / TEMA
/// =============================
class AppColors {
  static const vermelho = Color(0xFFC42112);
  static const preto = Color(0xFF262626);
  static const branco = Color(0xFFF2F2F2);
  static const verde = Color(0xFF3D5A40);
  static const dourado = Color(0xFFC49F48);
  static const azul = Color(0xFF1B4D5C);
}

final ThemeData appTheme = ThemeData(
  scaffoldBackgroundColor: AppColors.branco,
  primaryColor: AppColors.vermelho,
  useMaterial3: true,
  fontFamily: 'Montserrat',
  colorScheme: ColorScheme.fromSwatch().copyWith(
    secondary: AppColors.azul,
  ),
);



/// =============================
/// APP PRINCIPAL
/// =============================
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();
    NotificationService.init(); // 🔥 inicia notificações
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      navigatorKey: navigatorKey, // 🔥 importante
      title: 'IPU App',
      theme: appTheme,
      darkTheme: ThemeData.dark(),
      themeMode: themeNotifier.value,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/cadastro': (context) => const CadastroScreen(),
        '/home': (context) => const HomeScreen(),
        '/configuracoes': (context) => const ConfiguracoesScreen(),
        '/receita': (context) => const LancamentoReceitaScreen(),
        '/meus-lancamentos': (context) => const MeusLancamentosScreen(),
        '/despesa': (context) => const LancamentoDespesaScreen(),
        '/lancamentos': (context) => const LancamentosFinanceirosScreen(),
        '/doacao': (context) => const DoacoesHomeScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/gerenciar-informacoes': (context) => const GerenciarInformacoesPage(),
        '/eventos': (context) => const EventosScreen(),
        '/noticias': (context) => const NoticiasScreen(),
        '/pedidos-oracao': (context) => const PedidosOracaoScreen(),
        '/nova-agenda': (context) => const AgendaScreen(podeEditarAgendas: true),
        '/agenda': (context) => const AgendaScreen(podeEditarAgendas: false),
      },
    );
  }
}
