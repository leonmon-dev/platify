import 'package:flutter/material.dart';
import 'package:myapp/add_transaction_screen.dart';
import 'package:myapp/database.dart';
import 'package:provider/provider.dart';

class MovementsScreen extends StatelessWidget {
  final int accountId;

  const MovementsScreen({super.key, required this.accountId});

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<AppDatabase>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movements'),
      ),
      body: Column(
        children: [
          FutureBuilder<Account?>(
            future: (database.select(database.accounts)..where((a) => a.id.equals(accountId))).getSingleOrNull(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final account = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      'Current Balance: \$${account.balance.toStringAsFixed(2)}',
                       style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<List<Transaction>>(
              stream: database.watchTransactionsForAccount(accountId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No transactions for this account yet.'));
                }

                final transactions = snapshot.data!;

                return ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    final isIncome = transaction.amount > 0;
                    return ListTile(
                      leading: Icon(
                        isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isIncome ? Colors.green : Colors.red,
                      ),
                      title: Text(transaction.description),
                      subtitle: Text(transaction.date.toLocal().toString().split(' ')[0]),
                      trailing: Text(
                        '${isIncome ? '+' : ''}\$${transaction.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: isIncome ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
           Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionScreen(accountId: accountId),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
