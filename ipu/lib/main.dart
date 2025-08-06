import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'theme_notifier.dart';
import 'app.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔔 Background FCM: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ✅ Ativa App Check com provider de depuração
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  // ✅ Ativa atualização automática do token
  FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);

  // ✅ Exibe o token para copiar e registrar no Firebase Console
  //String? token = await FirebaseAppCheck.instance.getToken(true);
  //print("🔥 App Check Token: $token");

  // ✅ Configurações de push notifications
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // ✅ Solicita permissão
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // ✅ Inscreve em tópicos
  await messaging.subscribeToTopic('agendaEventos');
  await messaging.subscribeToTopic('eventos');
  await messaging.subscribeToTopic('noticias');
  await messaging.subscribeToTopic('aniversariantes');

  // ✅ Ouve mensagens recebidas com o app aberto
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('🔔 FCM: ${message.notification?.title}');
  });

  // ✅ Inicia o app
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const MyApp(),
    ),
  );
}
