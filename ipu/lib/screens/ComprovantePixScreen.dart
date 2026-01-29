import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class ComprovantePixScreen extends StatelessWidget {
  final String doacaoId;
  final double valor;

  const ComprovantePixScreen({
    super.key,
    required this.doacaoId,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contribuição via PIX')),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('configuracoes')
                .doc('pix')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Configurações do PIX não encontradas.'),
            );
          }

          final pix = snapshot.data!.data() as Map<String, dynamic>;

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  const Icon(
                    Icons.volunteer_activism,
                    color: Colors.pinkAccent,
                    size: 80,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Contribua com amor 💖',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.pinkAccent,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _infoRow(Icons.person, 'Titular', pix['nome']),
                  _infoRow(Icons.account_balance, 'Banco', pix['banco']),
                  _infoRow(Icons.vpn_key, 'Chave PIX', pix['chave']),
                  _infoRow(Icons.info_outline, 'Tipo', pix['tipo']),
                  const SizedBox(height: 16),
                  if (pix['observacao'] != null)
                    Text(
                      pix['observacao'],
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 20,
                      ),
                    ),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copiar Chave PIX'),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: pix['chave'].toString()),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Chave PIX copiada!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.home),
                    label: const Text('Voltar à tela inicial'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.pinkAccent),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Flexible(child: Text(value ?? '-', overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
