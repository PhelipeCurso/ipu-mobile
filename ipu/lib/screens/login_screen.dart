import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _mostrarFormulario = false;
  bool _loading = false;

  bool lembrarLogin = false;
  bool biometriaDisponivel = false;

  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  final _secureStorage = const FlutterSecureStorage();
  final _auth = LocalAuthentication();

  // =====================================================
  @override
  void initState() {
    super.initState();
    _carregarLoginSalvo();
    _verificarBiometria();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _mostrarFormulario = true);
    });
  }

  // =====================================================
  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  // =====================================================
  // CARREGAR LOGIN SALVO
  // =====================================================
  Future<void> _carregarLoginSalvo() async {
    final prefs = await SharedPreferences.getInstance();

    final email = prefs.getString('email');
    final lembrar = prefs.getBool('lembrar') ?? false;
    final senha = await _secureStorage.read(key: 'senha');

    if (lembrar) {
      _emailController.text = email ?? '';
      _senhaController.text = senha ?? '';
    }

    if (mounted) {
      setState(() => lembrarLogin = lembrar);
    }
  }

  // =====================================================
  // BIOMETRIA
  // =====================================================
  Future<void> _verificarBiometria() async {
    final canCheck = await _auth.canCheckBiometrics;
    final supported = await _auth.isDeviceSupported();

    if (mounted) {
      setState(() {
        biometriaDisponivel = canCheck && supported;
      });
    }
  }

  Future<bool> _autenticarBiometria() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Confirme sua identidade para entrar',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> _loginComBiometria() async {
    final ok = await _autenticarBiometria();
    if (!ok) return;

    final email = _emailController.text;
    final senha = await _secureStorage.read(key: 'senha');

    if (email.isEmpty || senha == null) {
      _snack('Ative "Lembrar meu login" primeiro');
      return;
    }

    try {
      setState(() => _loading = true);

      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );

      final uid = cred.user!.uid;

      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        Navigator.pushReplacementNamed(context, '/welcome');
      } else {
        Navigator.pushReplacementNamed(context, '/cadastro');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // =====================================================
  // SALVAR LOGIN
  // =====================================================
  Future<void> _salvarLogin(String email, String senha) async {
    final prefs = await SharedPreferences.getInstance();

    if (lembrarLogin) {
      await prefs.setString('email', email);
      await prefs.setBool('lembrar', true);
      await _secureStorage.write(key: 'senha', value: senha);
    } else {
      await prefs.remove('email');
      await prefs.setBool('lembrar', false);
      await _secureStorage.delete(key: 'senha');
    }
  }

  // =====================================================
  Future<void> resetSenha() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _snack('Digite seu e-mail primeiro');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _snack('Link de redefinição enviado para seu e-mail');
    } on FirebaseAuthException catch (e) {
      _snack(e.message ?? 'Erro ao enviar e-mail');
    }
  }

  // =====================================================
  // LOGIN EMAIL/SENHA
  // =====================================================
  Future<void> loginEmailSenha(BuildContext context) async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();

    if (email.isEmpty || senha.isEmpty) {
      _snack('Preencha e-mail e senha');
      return;
    }

    try {
      setState(() => _loading = true);

      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );

      await _salvarLogin(email, senha);

      final uid = cred.user!.uid;

      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        Navigator.pushReplacementNamed(context, '/welcome');
      } else {
        Navigator.pushReplacementNamed(context, '/cadastro');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // =====================================================
  // LOGIN GOOGLE
  // =====================================================
  Future<void> loginComGoogle(BuildContext context) async {
    try {
      setState(() => _loading = true);

      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final cred = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(cred);

      final uid = userCredential.user!.uid;

      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      if (doc.exists) {
        Navigator.pushReplacementNamed(context, '/welcome');
      } else {
        Navigator.pushReplacementNamed(context, '/cadastro');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // =====================================================
  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // =====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/img/login.png', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.4)),

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
                  ),
                ],
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Bem-Vindo! 👋🏽✊🏽✌🏽️',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.vermelho,
                        ),
                      ),

                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration:
                            const InputDecoration(labelText: 'E-mail'),
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _senhaController,
                        obscureText: true,
                        decoration:
                            const InputDecoration(labelText: 'Senha'),
                      ),

                      CheckboxListTile(
                        value: lembrarLogin,
                        onChanged: (v) =>
                            setState(() => lembrarLogin = v ?? false),
                        title: const Text("Lembrar meu login"),
                        controlAffinity:
                            ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: resetSenha,
                          child: const Text('Esqueci minha senha'),
                        ),
                      ),

                      const SizedBox(height: 12),

                      ElevatedButton(
                        onPressed:
                            _loading ? null : () => loginEmailSenha(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.vermelho,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Entrar'),
                      ),

                      const SizedBox(height: 12),

                      ElevatedButton.icon(
                        onPressed:
                            _loading ? null : () => loginComGoogle(context),
                        icon: Image.asset('assets/img/google.png', height: 22),
                        label: const Text('Entrar com Google'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),

                      // 🔥 BOTÃO BIOMETRIA (única adição)
                      if (biometriaDisponivel && lembrarLogin)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: ElevatedButton.icon(
                            onPressed:
                                _loading ? null : _loginComBiometria,
                            icon: const Icon(Icons.fingerprint),
                            label: const Text('Entrar com biometria'),
                            style: ElevatedButton.styleFrom(
                              minimumSize:
                                  const Size(double.infinity, 48),
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, '/cadastro'),
                        child: const Text(
                          'Não tem conta? Cadastre-se',
                          style: TextStyle(
                            color: AppColors.vermelho,
                            decoration: TextDecoration.underline,
                          ),
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
