import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'database.dart';
import 'add_transaction_screen.dart';

class MovementsScreen extends StatelessWidget {
  final Account account;

  const MovementsScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context);
    final formatCurrency = NumberFormat.simpleCurrency(decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: Text(account.name),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Saldo Actual', style: TextStyle(fontSize: 20, color: Colors.grey)),
                    const SizedBox(height: 8),
                    StreamBuilder<double>(
                      stream: db.watchAccountBalance(account.id),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Text(formatCurrency.format(account.initialAmount),
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold));
                        }
                        return Text(formatCurrency.format(snapshot.data!),
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Historial de Movimientos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: StreamBuilder<List<Transaction>>(
              stream: db.watchTransactionsForAccount(account.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay movimientos todavía.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }
                final transactions = snapshot.data!;
                return ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    final isIncome = transaction.amount > 0;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: Icon(
                          isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                          color: isIncome ? Colors.green : Colors.red,
                        ),
                        title: Text(transaction.description),
                        subtitle: Text(DateFormat.yMMMd().format(transaction.date)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formatCurrency.format(transaction.amount),
                              style: TextStyle(
                                color: isIncome ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _deleteTransaction(context, db, transaction),
                            ),
                          ],
                        ),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => Padding(
                              padding: MediaQuery.of(context).viewInsets,
                              child: AddTransactionScreen(account: account, transaction: transaction),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text("Nuevo Movimiento"),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: AddTransactionScreen(account: account),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteTransaction(BuildContext context, AppDatabase db, Transaction transaction) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Seguro que quieres eliminar el movimiento "${transaction.description}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await db.deleteTransaction(transaction);
      scaffoldMessenger
        ..removeCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Movimiento eliminado')));
    }
  }
}
