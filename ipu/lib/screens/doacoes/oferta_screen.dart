import 'package:flutter/material.dart';
import '../../app.dart';
import '../../services/doacao_service.dart';
import '../ComprovantePixScreen.dart';

class OfertaScreen extends StatefulWidget {
  const OfertaScreen({super.key});

  @override
  State<OfertaScreen> createState() => _OfertaScreenState();
}

class _OfertaScreenState extends State<OfertaScreen> {
  final _controller = TextEditingController();
  final _service = DoacaoService();
  bool _loading = false;

  Future<void> _pagar() async {
    final valor =
        double.tryParse(_controller.text.replaceAll(',', '.'));

    if (valor == null || valor <= 0) return;

    setState(() => _loading = true);

    try {
      final id = await _service.criarDoacao(
        valor: valor,
        tipo: 'oferta',
      );

      _controller.clear();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ComprovantePixScreen(
            doacaoId: id,
            valor: valor,
          ),
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ofertas')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Valor (R\$)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _pagar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.vermelho,
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Realizar PIX'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
