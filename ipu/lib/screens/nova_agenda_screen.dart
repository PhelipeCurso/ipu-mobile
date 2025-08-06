import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';


class NovaAgendaScreen extends StatefulWidget {
  const NovaAgendaScreen({super.key});

  @override
  State<NovaAgendaScreen> createState() => _NovaAgendaScreenState();
}

class _NovaAgendaScreenState extends State<NovaAgendaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _localController = TextEditingController();
  DateTime? _dataHoraSelecionada;

  bool _carregando = false;

  Future<void> _salvarEvento() async {
  if (!_formKey.currentState!.validate() || _dataHoraSelecionada == null) return;

  setState(() => _carregando = true);

  try {
    await FirebaseFirestore.instance.collection('agenda').add({
      'titulo': _tituloController.text.trim(),
      'descricao': _descricaoController.text.trim(),
      'local': _localController.text.trim(),
      'dataHora': Timestamp.fromDate(_dataHoraSelecionada!),
      'criadoEm': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento salvo com sucesso!')),
      );
      Navigator.pop(context);
    }
  } catch (e) {
    print('Erro ao salvar evento: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Erro ao salvar evento.')),
    );
  }

  setState(() => _carregando = false);
}


  Future<void> _selecionarDataHora() async {
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );

    if (data == null) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Evento'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _carregando
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _tituloController,
                      decoration: const InputDecoration(labelText: 'Título'),
                      validator: (value) =>
                          value!.trim().isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descricaoController,
                      decoration: const InputDecoration(labelText: 'Descrição'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _localController,
                      decoration: const InputDecoration(labelText: 'Local'),
                      validator: (value) =>
                          value!.trim().isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                        _dataHoraSelecionada == null
                            ? 'Selecione data e hora'
                            : '${_dataHoraSelecionada!.day}/${_dataHoraSelecionada!.month}/${_dataHoraSelecionada!.year} às ${_dataHoraSelecionada!.hour.toString().padLeft(2, '0')}:${_dataHoraSelecionada!.minute.toString().padLeft(2, '0')}',
                      ),
                      trailing: const Icon(Icons.edit),
                      onTap: _selecionarDataHora,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _salvarEvento,
                      icon: const Icon(Icons.save),
                      label: const Text('Salvar Evento'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    )
                  ],
                ),
              ),
      ),
    );
  }
}
