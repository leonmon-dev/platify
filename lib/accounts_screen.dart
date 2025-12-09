
import 'package:flutter/material.dart';
import 'package:myapp/add_account_screen.dart';
import 'package:myapp/database.dart';
import 'package:myapp/movements_screen.dart';
import 'package:provider/provider.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuentas'),
      ),
      body: StreamBuilder<List<Account>>(
        stream: db.watchAllAccounts(),
        builder: (context, snapshot) {
          final accounts = snapshot.data ?? [];

          if (accounts.isEmpty) {
            return const Center(
              child: Text('No hay cuentas. ¡Agrega una!'),
            );
          }

          return ListView.builder(
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(account.name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    'Balance: \${account.balance.toStringAsFixed(2)}',
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MovementsScreen(accountId: account.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (BuildContext context) {
              return Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: const AddAccountScreen(),
              );
            },
          );
        },
      ),
    );
  }
}
