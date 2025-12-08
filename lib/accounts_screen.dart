
import 'package:flutter/material.dart';
import 'package:platify/account_model.dart';
import 'package:platify/add_account_screen.dart';
import 'package:platify/isar_service.dart';
import 'package:provider/provider.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  late Stream<List<Account>> _accountStream;

  @override
  void initState() {
    super.initState();
    final isarService = Provider.of<IsarService>(context, listen: false);
    _accountStream = isarService.listenToAccounts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
      ),
      body: StreamBuilder<List<Account>>(
        stream: _accountStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No accounts yet.'));
          }

          final accounts = snapshot.data!;

          return ListView.builder(
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return ListTile(
                title: Text(account.name),
                subtitle: Text('Balance: \$${account.balance.toStringAsFixed(2)}'),
                onTap: () {
                  // Navigate to transaction details screen (to be implemented)
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddAccountScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
