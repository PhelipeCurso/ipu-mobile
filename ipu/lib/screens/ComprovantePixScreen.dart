import 'package:flutter/material.dart';
import '../app.dart'; // Para AppColors, se necessário
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';


class ComprovantePixScreen extends StatelessWidget {
  const ComprovantePixScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dados do PIX'),
        backgroundColor: AppColors.vermelho,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Use a chave PIX abaixo ou escaneie o QR Code para realizar sua doação.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // ✅ Imagem do QR Code ou dados do PIX
            Image.asset(
              'assets/img/pixipu.png', // Coloque sua imagem na pasta assets/img
              width: 250,
              height: 250,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.home),
              label: const Text('Voltar para o Início'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vermelho,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }
}
