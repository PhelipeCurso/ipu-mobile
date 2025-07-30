// Tela AgendaScreen com edicao e exclusao
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ipu/screens/nova_agenda_screen.dart';

class AgendaScreen extends StatelessWidget {
  final bool podeEditarAgendas;

  const AgendaScreen({super.key, required this.podeEditarAgendas});

  void _excluirEvento(BuildContext context, String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir este evento?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: const Text('Excluir'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await FirebaseFirestore.instance.collection('agenda').doc(id).delete();
    }
  }

  void _editarEvento(BuildContext context, DocumentSnapshot doc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditarAgendaScreen(documento: doc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda da Igreja')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('agenda')
            .orderBy('dataHora')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final eventos = snapshot.data!.docs;

          if (eventos.isEmpty) {
            return const Center(child: Text('Nenhum evento cadastrado.'));
          }

          return ListView.builder(
            itemCount: eventos.length,
            itemBuilder: (context, index) {
              final doc = eventos[index];
              final data = doc.data() as Map<String, dynamic>;
              final dataHora = (data['dataHora'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(data['titulo'] ?? 'Sem título'),
                  subtitle: Text(
                    '${DateFormat('dd/MM/yyyy - HH:mm').format(dataHora)}\nLocal: ${data['local']}',
                  ),
                  isThreeLine: true,
                  trailing: podeEditarAgendas
                      ? PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'editar') _editarEvento(context, doc);
                            if (value == 'excluir') _excluirEvento(context, doc.id);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'editar',
                              child: Text('Editar'),
                            ),
                            const PopupMenuItem(
                              value: 'excluir',
                              child: Text('Excluir'),
                            ),
                          ],
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: podeEditarAgendas
    ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NovaAgendaScreen()),
          );
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      )
    : null,
    );
  }
}

class EditarAgendaScreen extends StatefulWidget {
  final DocumentSnapshot documento;
  const EditarAgendaScreen({super.key, required this.documento});

  @override
  State<EditarAgendaScreen> createState() => _EditarAgendaScreenState();
}

class _EditarAgendaScreenState extends State<EditarAgendaScreen> {
  late TextEditingController _tituloController;
  late TextEditingController _descricaoController;
  late TextEditingController _localController;
  DateTime? _dataHoraSelecionada;

  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    final data = widget.documento.data() as Map<String, dynamic>;
    _tituloController = TextEditingController(text: data['titulo']);
    _descricaoController = TextEditingController(text: data['descricao']);
    _localController = TextEditingController(text: data['local']);
    _dataHoraSelecionada = (data['dataHora'] as Timestamp).toDate();
  }

  Future<void> _atualizarEvento() async {
    if (_tituloController.text.trim().isEmpty ||
        _localController.text.trim().isEmpty ||
        _dataHoraSelecionada == null) return;

    setState(() => _carregando = true);

    try {
      await FirebaseFirestore.instance
          .collection('agenda')
          .doc(widget.documento.id)
          .update({
        'titulo': _tituloController.text.trim(),
        'descricao': _descricaoController.text.trim(),
        'local': _localController.text.trim(),
        'dataHora': Timestamp.fromDate(_dataHoraSelecionada!),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      print('Erro ao atualizar: $e');
    }

    setState(() => _carregando = false);
  }

  Future<void> _selecionarDataHora() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataHoraSelecionada ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (data == null) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dataHoraSelecionada ?? DateTime.now()),
    );
    if (hora == null) return;

    setState(() {
      _dataHoraSelecionada = DateTime(
        data.year,
        data.month,
        data.day,
        hora.hour,
        hora.minute,
      );
    });
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _localController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Evento')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _carregando
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  TextField(
                    controller: _tituloController,
                    decoration: const InputDecoration(labelText: 'Título'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descricaoController,
                    decoration: const InputDecoration(labelText: 'Descrição'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _localController,
                    decoration: const InputDecoration(labelText: 'Local'),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      _dataHoraSelecionada == null
                          ? 'Selecione data e hora'
                          : '${_dataHoraSelecionada!.day}/${_dataHoraSelecionada!.month}/${_dataHoraSelecionada!.year} - ${_dataHoraSelecionada!.hour}:${_dataHoraSelecionada!.minute.toString().padLeft(2, '0')}',
                    ),
                    trailing: const Icon(Icons.edit),
                    onTap: _selecionarDataHora,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _atualizarEvento,
                    icon: const Icon(Icons.save),
                    label: const Text('Salvar Alterações'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  )
                ],
              ),
      ),
    );
  }
}
