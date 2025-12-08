import 'package:flutter/material.dart';
import 'package:myapp/database.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;

class AddTransactionScreen extends StatefulWidget {
  final int accountId;
  const AddTransactionScreen({super.key, required this.accountId});

  @override
  AddTransactionScreenState createState() => AddTransactionScreenState();
}

class AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isIncome = true;

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<AppDatabase>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || double.tryParse(value) == null) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Expense'),
                  Switch(
                    value: _isIncome,
                    onChanged: (value) {
                      setState(() {
                        _isIncome = value;
                      });
                    },
                  ),
                  const Text('Income'),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final amount = double.parse(_amountController.text);
                    final transaction = TransactionsCompanion(
                      description: drift.Value(_descriptionController.text),
                      amount: drift.Value(_isIncome ? amount : -amount),
                      accountId: drift.Value(widget.accountId),
                      date: drift.Value(DateTime.now()),
                    );
                    database.addTransaction(transaction);

                    // Update account balance
                    database.getAccount(widget.accountId).then((account) {
                      if (account != null) {
                        final newBalance = account.balance + (_isIncome ? amount : -amount);
                        final updatedAccount = account.copyWith(balance: newBalance);
                        database.updateAccount(updatedAccount);
                      }
                    });

                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on AppDatabase {
  Future<Account?> getAccount(int id) {
    return (select(accounts)..where((a) => a.id.equals(id))).getSingleOrNull();
  }
}
