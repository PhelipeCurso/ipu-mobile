import 'package:flutter/material.dart';
import '../../app.dart';
import 'dizimo_screen.dart';
import 'oferta_screen.dart';

class DoacoesHomeScreen extends StatelessWidget {
  const DoacoesHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contribuições')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _card(
              context,
              titulo: 'Dízimos',
              subtitulo: 'Acompanhe seus pagamentos mensais',
              icone: Icons.calendar_month,
              cor: Colors.green,
              page: const DizimoScreen(),
            ),
            const SizedBox(height: 16),
            _card(
              context,
              titulo: 'Ofertas',
              subtitulo: 'Doações espontâneas',
              icone: Icons.volunteer_activism,
              cor: AppColors.vermelho,
              page: const OfertaScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(
    BuildContext context, {
    required String titulo,
    required String subtitulo,
    required IconData icone,
    required Color cor,
    required Widget page,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icone, color: cor, size: 32),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitulo),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        ),
      ),
    );
  }
}
