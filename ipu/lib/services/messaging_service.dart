import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessagingService {
  static Future<void> init() async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await messaging.getToken();

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .set({'fcmToken': token}, SetOptions(merge: true));

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .update({'fcmToken': newToken});
    });
  }
}
