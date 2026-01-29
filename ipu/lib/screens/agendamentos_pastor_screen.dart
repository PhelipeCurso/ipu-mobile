import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/gabinete_service.dart';

class AgendamentosPastorScreen extends StatefulWidget {
  const AgendamentosPastorScreen({super.key});

  @override
  State<AgendamentosPastorScreen> createState() => _AgendamentosPastorScreenState();
}

class _AgendamentosPastorScreenState extends State<AgendamentosPastorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final service = GabineteService();
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
        title: const Text("Agendamentos do Pastor"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.event_note, color: Colors.green), text: "Criados por mim"),
            Tab(icon: Icon(Icons.inbox, color: Colors.blue), text: "Recebidos dos membros"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListaAgendamentos("pastor"),
          _buildListaAgendamentos("membro"),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => _abrirFormularioAgendamento(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Lista de agendamentos (criados pelo pastor ou recebidos dos membros)
  Widget _buildListaAgendamentos(String criadoPor) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('agendamentos')
          .where('idPastor', isEqualTo: user!.uid)
          .where('criadoPor', isEqualTo: criadoPor)
          .orderBy('data', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              criadoPor == "pastor"
                  ? "Nenhum agendamento criado por você."
                  : "Nenhum agendamento recebido dos membros.",
            ),
          );
        }

        return ListView(
          children: snapshot.data!.docs.map((doc) {
            final dados = doc.data() as Map<String, dynamic>;
            final data = (dados['data'] as Timestamp?)?.toDate();
            final motivo = dados['motivo'] ?? '';
            final status = dados['status'] ?? 'pendente';
            final membro = dados['nomeMembro'] ?? '';

            return Card(
              color: _getStatusColor(status),
              margin: const EdgeInsets.all(8),
              child: ListTile(
                leading: Icon(
                  _getStatusIcon(status),
                  color: _getIconColor(status),
                  size: 32,
                ),
                title: Text(
                  motivo,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "Membro: $membro\n"
                  "Data: ${data != null ? data.toString().substring(0, 16) : 'Sem data'}\n"
                  "Status: $status",
                ),
                trailing: criadoPor == "membro"
                    ? PopupMenuButton<String>(
                        onSelected: (valor) async {
                          if (valor == "Confirmar") {
                            await service.atualizarStatus(doc.id, "confirmado");
                          } else if (valor == "Cancelar") {
                            await service.atualizarStatus(doc.id, "cancelado");
                          } else if (valor == "Reagendar") {
                            final novaData = await showDatePicker(
                              context: context,
                              initialDate: data ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (novaData != null) {
                              final novaHora = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (novaHora != null) {
                                final novaDataCompleta = DateTime(
                                  novaData.year,
                                  novaData.month,
                                  novaData.day,
                                  novaHora.hour,
                                  novaHora.minute,
                                );
                                await doc.reference.update({
                                  'data': novaDataCompleta,
                                  'status': 'reagendado', // <-- salva o status corretamente
                                });
                              }
                            }
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: "Confirmar",
                            child: Text("✅ Confirmar"),
                          ),
                          PopupMenuItem(
                            value: "Cancelar",
                            child: Text("❌ Cancelar"),
                          ),
                          PopupMenuItem(
                            value: "Reagendar",
                            child: Text("📅 Reagendar"),
                          ),
                        ],
                      )
                    : null,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// Formulário para o pastor criar novo agendamento
  Future<void> _abrirFormularioAgendamento(BuildContext context) async {
    final membrosSnapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('tipoUsuario', isEqualTo: 'Membro')
        .get();

    final membros = membrosSnapshot.docs;
    final TextEditingController motivoController = TextEditingController();
    DateTime? dataSelecionada;
    String? membroSelecionadoId;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Novo Agendamento"),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: membroSelecionadoId,
                  items: membros.map((doc) {
                    final data = doc.data();
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(data['nome'] ?? 'Sem nome'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => membroSelecionadoId = value),
                  decoration: const InputDecoration(labelText: "Selecione o Membro"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: motivoController,
                  decoration: const InputDecoration(labelText: "Motivo"),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      dataSelecionada == null
                          ? "Nenhuma data selecionada"
                          : "Data: ${dataSelecionada.toString().substring(0, 16)}",
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.calendar_today, color: Colors.green),
                      onPressed: () async {
                        final hoje = DateTime.now();
                        final data = await showDatePicker(
                          context: context,
                          initialDate: hoje,
                          firstDate: hoje,
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              if (membroSelecionadoId == null ||
                  motivoController.text.isEmpty ||
                  dataSelecionada == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Preencha todos os campos.")),
                );
                return;
              }

              final pastorDoc = await FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(user!.uid)
                  .get();

              final membroDoc = await FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(membroSelecionadoId)
                  .get();

              await service.criarAgendamento(
                idPastor: user!.uid,
                nomePastor: pastorDoc['nome'] ?? 'Sem nome',
                idMembro: membroSelecionadoId!,
                nomeMembro: membroDoc['nome'] ?? 'Sem nome',
                motivo: motivoController.text,
                data: dataSelecionada!,
                criadoPor: "pastor",
              );

              Navigator.pop(context);
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }
}
