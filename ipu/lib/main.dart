import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  await messaging.requestPermission();
  
  // ✅ Inscreve em tópicos
 FirebaseAuth.instance.authStateChanges().listen((user) async {
  if (user != null) {
    await FirebaseMessaging.instance.subscribeToTopic('agendaEventos');
    await FirebaseMessaging.instance.subscribeToTopic('eventos');
    await FirebaseMessaging.instance.subscribeToTopic('noticias');
    await FirebaseMessaging.instance.subscribeToTopic('aniversariantes');
  }
});

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
