import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app.dart'; // para AppColors


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _mostrarFormulario = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() => _mostrarFormulario = true);
    });
  }

  Future<void> loginComGoogle(BuildContext context) async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final cred = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(cred);
      final uid = userCredential.user?.uid;

      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      if (doc.exists) {
        Navigator.pushReplacementNamed(context, '/welcome');
      } else {
        Navigator.pushReplacementNamed(context, '/cadastro');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fazer login: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Imagem de fundo
          Image.asset(
            'assets/img/login.png',
            fit: BoxFit.cover,
          ),
          // Overlay escura
          Container(color: Colors.black.withOpacity(0.4)),

          // Conteúdo com animação
          if (_mostrarFormulario)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Animate(
                effects: const [
                  FadeEffect(duration: Duration(milliseconds: 800)),
                  SlideEffect(
                    begin: Offset(0, 1),
                    end: Offset(0, 0),
                    duration: Duration(milliseconds: 800),
                    curve: Curves.easeOut,
                  ),
                ],
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((255 * 0.65).toInt()),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((255 * 0.2).toInt()),
                        blurRadius: 20,
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Bem-Vindo!👋🏽✊🏽✌🏽️',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.vermelho,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'E-mail'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Senha'),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.vermelho,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          // futura autenticação por e-mail
                        },
                        child: const Text('Entrar'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: Image.asset(
                          'assets/img/google.png',
                          height: 24,
                          width: 24,
                        ),
                        label: const Text(
                          'Entrar com Google',
                          style: TextStyle(color: Colors.black),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.grey),
                          ),
                        ),
                        onPressed: () => loginComGoogle(context),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/cadastro'),
                        child: const Text(
                          'Não tem conta? Cadastre-se',
                          style: TextStyle(
                            color: AppColors.vermelho,
                            decoration: TextDecoration.underline,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
