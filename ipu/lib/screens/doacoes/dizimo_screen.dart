import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app.dart';
import '../../services/doacao_service.dart';
import '../ComprovantePixScreen.dart';

class DizimoScreen extends StatefulWidget {
  const DizimoScreen({super.key});

  @override
  State<DizimoScreen> createState() => _DizimoScreenState();
}

class _DizimoScreenState extends State<DizimoScreen> {
  final _controller = TextEditingController();
  final _service = DoacaoService();

  bool _loading = false;
  String _mesSelecionado = '';

  @override
  void initState() {
    super.initState();
    _mesSelecionado = _mesAtual();
  }

  String _mesAtual() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  List<String> _mesesAno() {
    final ano = DateTime.now().year;
    return List.generate(
      12,
      (i) => '$ano-${(i + 1).toString().padLeft(2, '0')}',
    );
  }

  // =========================
  // PAGAR
  // =========================
  Future<void> _pagar() async {
    final valor = double.tryParse(_controller.text.replaceAll(',', '.'));

    if (valor == null || valor <= 0) return;

    setState(() => _loading = true);

    try {
      final id = await _service.criarDoacao(
        valor: valor,
        tipo: 'dizimo',
        mesRef: _mesSelecionado,
      );

      _controller.clear();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ComprovantePixScreen(doacaoId: id, valor: valor),
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  // =========================
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Dízimos')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<QuerySnapshot>(
          // ✅ QUERY CORRIGIDA AQUI
          stream:
              FirebaseFirestore.instance
                  .collection('doacoes')
                  .where('usuarioId', isEqualTo: uid)
                  .where('tipo', isEqualTo: 'dizimo')
                  .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;

            // agora usa mesRef como chave
            final Map<String, String> statusMap = {};

            for (var d in docs) {
              final data = d.data() as Map<String, dynamic>;

              if (!data.containsKey('mesRef'))
                continue; // ← ignora docs antigos

              final mes = data['mesRef'];
              final status = data['status'];

              statusMap[mes] = status;
            }

            final confirmado =
                statusMap.values.where((s) => s == 'confirmado').length;

            final fidelidade = ((confirmado / 12) * 100).round();

            final statusGeral = _calcularStatusGeral(statusMap);

            return Column(
              children: [
                _statusCard(statusGeral, fidelidade),
                const SizedBox(height: 16),
                _formPagamento(),
                const SizedBox(height: 20),
                Expanded(child: _historico(statusMap)),
              ],
            );
          },
        ),
      ),
    );
  }

  // =========================
  Widget _statusCard(String status, int fidelidade) {
    Color cor;

    switch (status) {
      case 'Em dia':
        cor = Colors.green;
        break;
      case 'Pendente':
        cor = Colors.orange;
        break;
      default:
        cor = Colors.red;
    }

    return Card(
      color: cor.withOpacity(0.15),
      child: ListTile(
        leading: Icon(Icons.verified, color: cor),
        title: Text(
          status,
          style: TextStyle(color: cor, fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Fidelidade anual: $fidelidade%'),
      ),
    );
  }

  // =========================
  Widget _formPagamento() {
    final nomes = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _mesSelecionado,
              decoration: const InputDecoration(labelText: 'Mês referência'),
              items:
                  _mesesAno().map((id) {
                    final mes = int.parse(id.split('-')[1]);
                    return DropdownMenuItem(
                      value: id,
                      child: Text('${nomes[mes - 1]}'),
                    );
                  }).toList(),
              onChanged: (v) => setState(() => _mesSelecionado = v!),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Valor (R\$)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loading ? null : _pagar,
              child: const Text('Enviar comprovante (pendente)'),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  Widget _historico(Map<String, String> statusMap) {
    final ano = DateTime.now().year;

    final nomes = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];

    return ListView.builder(
      itemCount: 12,
      itemBuilder: (_, i) {
        final id = '$ano-${(i + 1).toString().padLeft(2, '0')}';

        final status = statusMap[id];

        IconData icon;
        Color cor;
        String texto;

        if (status == 'confirmado') {
          icon = Icons.check_circle;
          cor = Colors.green;
          texto = 'Confirmado';
        } else if (status == 'pendente') {
          icon = Icons.hourglass_bottom;
          cor = Colors.orange;
          texto = 'Aguardando confirmação';
        } else {
          icon = Icons.cancel;
          cor = Colors.red;
          texto = 'Em aberto';
        }

        return Card(
          child: ListTile(
            leading: Icon(icon, color: cor),
            title: Text('${nomes[i]}/$ano'),
            subtitle: Text(texto),
          ),
        );
      },
    );
  }

  // =========================
  String _calcularStatusGeral(Map<String, String> map) {
    if (map.containsValue('pendente')) return 'Pendente';

    final mesAtual = DateTime.now().month;

    for (int i = 1; i <= mesAtual; i++) {
      final id = '${DateTime.now().year}-${i.toString().padLeft(2, '0')}';
      if (map[id] != 'confirmado') return 'Atrasado';
    }

    return 'Em dia';
  }
}
