import 'package:flutter/material.dart';
import 'package:platify/account_model.dart';
import 'package:platify/isar_service.dart';
import 'package:platify/transaction_model.dart';
import 'package:provider/provider.dart';

class AddTransactionScreen extends StatefulWidget {
  final Account account;

  const AddTransactionScreen({super.key, required this.account});

  @override
  AddTransactionScreenState createState() => AddTransactionScreenState();
}

class AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isarService = Provider.of<IsarService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Transaction to ${widget.account.name}'),
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
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final newTransaction = Transaction(
                      description: _descriptionController.text,
                      amount: double.parse(_amountController.text),
                      date: DateTime.now(),
                    );

                    isarService.saveTransaction(
                        widget.account.uuid, newTransaction);
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
