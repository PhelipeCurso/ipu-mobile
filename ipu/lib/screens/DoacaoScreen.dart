import 'package:flutter/material.dart';
import '../app.dart';
import '../services/doacao_service.dart';
import 'ComprovantePixScreen.dart';

class DoacaoScreen extends StatefulWidget {
  const DoacaoScreen({super.key});

  @override
  State<DoacaoScreen> createState() => _DoacaoScreenState();
}

class _DoacaoScreenState extends State<DoacaoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _formKey = GlobalKey<FormState>();
  final _valorDizimoController = TextEditingController();
  final _valorOfertaController = TextEditingController();

  final _doacaoService = DoacaoService();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _valorDizimoController.dispose();
    _valorOfertaController.dispose();
    super.dispose();
  }

  Future<void> _confirmarDoacao(String tipo) async {
    if (!_formKey.currentState!.validate()) return;

    final controller =
        tipo == 'dizimo' ? _valorDizimoController : _valorOfertaController;

    final valor =
        double.tryParse(controller.text.replaceAll(',', '.'));

    if (valor == null || valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valor inválido')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final doacaoId = await _doacaoService.criarDoacao(
        valor: valor,
        tipo: tipo,
      );

      controller.clear();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ComprovantePixScreen(
            doacaoId: doacaoId,
            valor: valor,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao registrar doação')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contribuições'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Dízimos'),
            Tab(text: 'Ofertas'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildForm('dizimo', _valorDizimoController),
              _buildForm('oferta', _valorOfertaController),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(String tipo, TextEditingController controller) {
    final titulo = tipo == 'dizimo'
        ? 'Digite o valor do seu dízimo'
        : 'Digite o valor da sua oferta';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Valor (R\$)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (v) =>
              v == null || v.isEmpty ? 'Informe um valor válido' : null,
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : () => _confirmarDoacao(tipo),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vermelho,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Realizar PIX',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }
}
