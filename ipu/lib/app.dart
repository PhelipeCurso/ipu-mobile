import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/cadastro_screen.dart';
import 'screens/home_screen.dart';
import 'screens/configuracoes_screen.dart';
import 'theme_notifier.dart';
import 'screens/LancamentoReceitaScreen.dart';
import 'screens/MeusLancamentosScreen.dart';
import 'screens/LancamentoDespesaScreen.dart';
import 'screens/LancamentosFinanceirosScreen.dart';
import 'screens/ComprovantePixScreen.dart';
import 'screens/DoacaoScreen.dart';
import 'screens/WelcomeScreen.dart';
import 'screens/gerenciar_informacoes_page.dart';
import 'screens/eventos_screen.dart';
import 'screens/noticias_screen.dart';
import 'screens/PedidosOracaoScreen.dart';  
import 'screens/AgendaScreen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Cores da identidade visual IPU
class AppColors {
  static const vermelho = Color(0xFFC42112);
  static const preto = Color(0xFF262626);
  static const branco = Color(0xFFF2F2F2);
  static const verde = Color(0xFF3D5A40);
  static const dourado = Color(0xFFC49F48);
  static const azul = Color(0xFF1B4D5C);
}

/// Tema da IPU
final ThemeData appTheme = ThemeData(
  scaffoldBackgroundColor: AppColors.branco,
  primaryColor: AppColors.vermelho,
  useMaterial3: true,
  fontFamily: 'Montserrat',
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.vermelho,
    foregroundColor: Colors.white,
    titleTextStyle: TextStyle(
      fontFamily: 'BebasNeue',
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(fontSize: 16, fontFamily: 'Montserrat'),
    titleLarge: TextStyle(
      fontFamily: 'BebasNeue',
      fontSize: 26,
      color: AppColors.preto,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.vermelho,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  colorScheme: ColorScheme.fromSwatch().copyWith(
    secondary: AppColors.azul,
  ),
);

/// App principal com rotas e tema IPU
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
     final themeNotifier = Provider.of<ThemeNotifier>(context);
    return MaterialApp(
      title: 'IPU App',
      theme: appTheme,
       darkTheme: ThemeData.dark(),
      themeMode: themeNotifier.value,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/cadastro': (context) => const CadastroScreen(),
        '/home': (context) => const HomeScreen(),
        '/configuracoes': (context) => const ConfiguracoesScreen(),
        '/receita': (context) => const LancamentoReceitaScreen(),
        '/meus-lancamentos': (context) => const MeusLancamentosScreen(), // ✅ aqui
        '/despesa': (context) => const LancamentoDespesaScreen(),
        '/lancamentos': (context) => const LancamentosFinanceirosScreen(),
        '/doacao': (context) => const DoacaoScreen(),
        '/comprovante-pix': (context) => const ComprovantePixScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/gerenciar-informacoes': (context) => const GerenciarInformacoesPage(),
        '/eventos': (context) => const EventosScreen(),
        '/noticias': (context) => const NoticiasScreen(),
        '/pedidos-oracao': (context) => const PedidosOracaoScreen(),
        '/nova-agenda': (context) => const AgendaScreen(podeEditarAgendas: true),
        '/agenda': (context) => const AgendaScreen(podeEditarAgendas: false),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
