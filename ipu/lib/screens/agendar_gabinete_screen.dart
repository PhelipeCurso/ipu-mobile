import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AgendarGabineteScreen extends StatefulWidget {
  const AgendarGabineteScreen({super.key});

  @override
  State<AgendarGabineteScreen> createState() => _AgendarGabineteScreenState();
}

class _AgendarGabineteScreenState extends State<AgendarGabineteScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Define cor do card conforme o status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmado':
        return Colors.green.shade100;
      case 'reagendado':
        return Colors.blue.shade100;
      case 'cancelado':
        return Colors.red.shade100;
      case 'pendente':
      default:
        return Colors.amber.shade100;
    }
  }

  /// Define ícone conforme o status
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmado':
        return Icons.check_circle;
      case 'reagendado':
        return Icons.autorenew;
      case 'cancelado':
        return Icons.cancel;
      case 'pendente':
      default:
        return Icons.hourglass_bottom;
    }
  }

  /// Define cor do ícone conforme o status
  Color _getIconColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmado':
        return Colors.green;
      case 'reagendado':
        return Colors.blue;
      case 'cancelado':
        return Colors.red;
      case 'pendente':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Agendamentos'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.schedule_send, color: Colors.orange), text: 'Criados por mim'),
            Tab(icon: Icon(Icons.church, color: Colors.purple), text: 'Criados pelo Pastor'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAgendamentosMembro(),
          _buildAgendamentosPastor(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
        onPressed: () => _abrirFormularioAgendamento(context),
      ),
    );
  }

  /// Aba 1 - Agendamentos criados pelo próprio membro
  Widget _buildAgendamentosMembro() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('agendamentos')
          .where('idMembro', isEqualTo: user!.uid)
          .where('criadoPor', isEqualTo: 'membro')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final agendamentos = snapshot.data?.docs ?? [];
        if (agendamentos.isEmpty) {
          return const Center(child: Text('Você ainda não fez agendamentos.'));
        }

        return ListView.builder(
          itemCount: agendamentos.length,
          itemBuilder: (context, index) {
            final data = agendamentos[index].data() as Map<String, dynamic>;
            final status = (data['status'] ?? 'pendente').toString();

            return Card(
              color: _getStatusColor(status),
              margin: const EdgeInsets.all(8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(_getStatusIcon(status), color: _getIconColor(status), size: 32),
                title: Text(
                  data['motivo'] ?? 'Sem motivo',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Pastor: ${data['nomePastor'] ?? 'Não informado'}\n'
                  'Status: ${status[0].toUpperCase()}${status.substring(1)}',
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Aba 2 - Agendamentos criados pelo pastor para este membro
  Widget _buildAgendamentosPastor() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('agendamentos')
          .where('idMembro', isEqualTo: user!.uid)
          .where('criadoPor', isEqualTo: 'pastor')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final agendamentos = snapshot.data?.docs ?? [];
        if (agendamentos.isEmpty) {
          return const Center(child: Text('Nenhum agendamento criado pelo pastor.'));
        }

        return ListView.builder(
          itemCount: agendamentos.length,
          itemBuilder: (context, index) {
            final data = agendamentos[index].data() as Map<String, dynamic>;
            final status = (data['status'] ?? 'pendente').toString();

            return Card(
              color: _getStatusColor(status),
              margin: const EdgeInsets.all(8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(_getStatusIcon(status), color: _getIconColor(status), size: 32),
                title: Text(
                  data['motivo'] ?? 'Sem motivo',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Data: ${data['data']?.toDate()?.toString().substring(0, 16) ?? 'Sem data'}\n'
                  'Status: ${status[0].toUpperCase()}${status.substring(1)}',
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Formulário para novo agendamento criado pelo membro
  Future<void> _abrirFormularioAgendamento(BuildContext context) async {
    final pastoresSnapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('tipoUsuario', isEqualTo: 'Pastor')
        .get();

    final pastores = pastoresSnapshot.docs;
    final TextEditingController motivoController = TextEditingController();
    DateTime? dataSelecionada;
    String? pastorSelecionadoId;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo Agendamento'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: pastorSelecionadoId,
                  items: pastores.map((doc) {
                    final data = doc.data();
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(data['nome'] ?? 'Sem nome'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => pastorSelecionadoId = value),
                  decoration: const InputDecoration(labelText: 'Selecione o Pastor'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: motivoController,
                  decoration: const InputDecoration(labelText: 'Motivo do agendamento'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        dataSelecionada == null
                            ? 'Nenhuma data selecionada'
                            : 'Data: ${dataSelecionada.toString().substring(0, 16)}',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today, color: Colors.orange),
                      onPressed: () async {
                        final agora = DateTime.now();
                        final data = await showDatePicker(
                          context: context,
                          initialDate: agora,
                          firstDate: agora,
                          lastDate: DateTime(2100),
                        );
                        if (data != null) {
                          final hora = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (hora != null) {
                            setState(() {
                              dataSelecionada = DateTime(
                                data.year,
                                data.month,
                                data.day,
                                hora.hour,
                                hora.minute,
                              );
                            });
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              if (pastorSelecionadoId == null ||
                  motivoController.text.isEmpty ||
                  dataSelecionada == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Preencha todos os campos.')),
                );
                return;
              }

              final membroDoc = await FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(user!.uid)
                  .get();

              await FirebaseFirestore.instance.collection('agendamentos').add({
                'idPastor': pastorSelecionadoId,
                'nomePastor': pastores
                    .firstWhere((p) => p.id == pastorSelecionadoId)['nome'],
                'idMembro': user!.uid,
                'nomeMembro': membroDoc['nome'],
                'motivo': motivoController.text,
                'data': dataSelecionada,
                'status': 'pendente',
                'criadoPor': 'membro',
                'criadoEm': FieldValue.serverTimestamp(),
              });

              Navigator.pop(context);
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }
}
