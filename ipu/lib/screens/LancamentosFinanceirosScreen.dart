import 'package:flutter/material.dart';
import 'LancamentoReceitaScreen.dart';
import 'LancamentoDespesaScreen.dart';

class LancamentosFinanceirosScreen extends StatelessWidget {
  const LancamentosFinanceirosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Número de abas
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lançamentos Financeiros'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.attach_money), text: 'Receita'),
              Tab(icon: Icon(Icons.money_off), text: 'Despesa'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            LancamentoReceitaScreen(),
            LancamentoDespesaScreen(),
          ],
        ),
      ),
    );
  }
}
