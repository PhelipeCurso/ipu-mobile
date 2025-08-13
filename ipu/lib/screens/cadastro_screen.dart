import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();

  final _dados = {
    'nome': '',
    'cpf': '',
    'dataNascimento': '',
    'estadoCivil': '',
    'batizado': false,
    'dataBatismo': '',
    'cep': '',
    'logradouro': '',
    'numero': '',
    'bairro': '',
    'complemento': '',
    'cidade': '',
    'telefone': '',
    'membroDesde': '',
    'cargoEclesiastico': false,
    'areaDeServico': '',
  };

  bool carregando = false;

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => carregando = true);

    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance.collection('usuarios').doc(user!.uid).set({
      'nome': _dados['nome'],
      'cpf': _dados['cpf'],
      'dataNascimento': _dados['dataNascimento'],
      'estadoCivil': _dados['estadoCivil'],
      'batizado': _dados['batizado'],
      'dataBatismo': _dados['dataBatismo'],
      'endereco': {
        'cep': _dados['cep'],
        'logradouro': _dados['logradouro'],
        'numero': _dados['numero'],
        'bairro': _dados['bairro'],
        'cidade': _dados['cidade'],
        'complemento': _dados['complemento'],
      },
      'telefone': _dados['telefone'],
      'membroDesde': _dados['membroDesde'],
      'cargoEclesiastico': _dados['cargoEclesiastico'],
      'areaDeServico': _dados['areaDeServico'],
      'email': user.email,
      'tipo': 'membro',
      'bloqueado': false,
    });

    setState(() => carregando = false);

    Navigator.pushReplacementNamed(context, '/home');
  }

  Future<List<String>> _buscarAreasDeServico() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('segmentos').get();
    return snapshot.docs.map((doc) => doc['nome'] as String).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro do Membro')),
      body:
          carregando
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildInput('Nome', 'nome'),
                      _buildInput(
                        'CPF',
                        'cpf',
                        tipo: TextInputType.number,
                        formatter: [MaskedInputFormatter('###.###.###-##')],
                      ),
                      _buildInput(
                        'Data de Nascimento',
                        'dataNascimento',
                        tipo: TextInputType.number,
                        formatter: [MaskedInputFormatter('##/##/####')],
                      ),
                      _buildInput('Estado Civil', 'estadoCivil'),
                      _buildCheckbox('É Batizado?', 'batizado'),
                      _buildInput(
                        'Data do Batismo',
                        'dataBatismo',
                        tipo: TextInputType.number,
                        formatter: [MaskedInputFormatter('##/##/####')],
                      ),
                      _buildInput(
                        'Cep',
                        'cep',
                        tipo: TextInputType.number,
                        formatter: [MaskedInputFormatter('#####-###')],
                      ),
                      _buildInput('Logradouro', 'logradouro'),
                      _buildInput('Número', 'numero'),
                      _buildInput('Bairro', 'bairro'),
                      _buildInput('Cidade', 'cidade'),
                      _buildInput('Complemento', 'complemento'),
                      _buildInput(
                        'Telefone',
                        'telefone',
                        tipo: TextInputType.phone,
                        formatter: [MaskedInputFormatter('(##) #####-####')],
                      ),
                      _buildInput(
                        'Membro Desde',
                        'membroDesde',
                        tipo: TextInputType.number,
                        formatter: [MaskedInputFormatter('##/##/####')],
                      ),
                      _buildCheckbox(
                        'Possui cargo eclesiástico?',
                        'cargoEclesiastico',
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<List<String>>(
                        future: _buscarAreasDeServico(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData)
                            return const CircularProgressIndicator();
                          final areas = snapshot.data!;
                          return DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Serve em alguma área?',
                            ),
                            value:
                                (_dados['areaDeServico'] as String?)
                                            ?.isNotEmpty ==
                                        true
                                    ? _dados['areaDeServico'] as String?
                                    : null,
                            items:
                                areas
                                    .map(
                                      (area) => DropdownMenuItem(
                                        value: area,
                                        child: Text(area),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (value) => setState(
                                  () => _dados['areaDeServico'] = value ?? '',
                                ),
                            validator: (value) {
                              if (_dados['cargoEclesiastico'] == true) {
                                return value == null || value.isEmpty
                                    ? 'Selecione um cargo Eclesiástico'
                                    : null;
                              }
                              return null;
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _salvar,
                        child: const Text('Salvar e Continuar'),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildInput(
    String label,
    String campo, {
    TextInputType tipo = TextInputType.text,
    List<TextInputFormatter>? formatter,
  }) {
    return TextFormField(
      keyboardType: tipo,
      inputFormatters: formatter ?? [],
      decoration: InputDecoration(labelText: label),
      validator:
          (value) => value == null || value.isEmpty ? 'Preencha o campo' : null,
      onSaved: (value) => _dados[campo] = value ?? '',
    );
  }

  Widget _buildCheckbox(String label, String campo) {
    return CheckboxListTile(
      value: _dados[campo] as bool,
      onChanged: (val) => setState(() => _dados[campo] = val!),
      title: Text(label),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
