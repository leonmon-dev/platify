import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/isar_service.dart';
import 'package:myapp/account_model.dart';
import 'package:myapp/transaction_model.dart';

class MovementsScreen extends StatefulWidget {
  const MovementsScreen({super.key});

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen> {
  final _formKey = GlobalKey<FormState>();
  Account? _selectedAccount;
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isIncome = true;

  @override
  Widget build(BuildContext context) {
    final isarService = context.read<IsarService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Movimiento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              FutureBuilder<List<Account>>(
                future: isarService.getAllAccounts(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  return DropdownButtonFormField<Account>(
                    decoration: const InputDecoration(
                      labelText: 'Cuenta',
                      border: OutlineInputBorder(),
                    ),
                    items: snapshot.data!.map((account) {
                      return DropdownMenuItem(
                        value: account,
                        child: Text(account.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAccount = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Por favor, selecciona una cuenta';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa un monto';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Por favor, ingresa un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Gasto'),
                  Switch(
                    value: _isIncome,
                    onChanged: (value) {
                      setState(() {
                        _isIncome = value;
                      });
                    },
                  ),
                  const Text('Ingreso'),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final amount = double.parse(_amountController.text);
                    final transaction = Transaction(
                      amount: _isIncome ? amount : -amount,
                      date: DateTime.now(),
                      description: _descriptionController.text,
                    );

                    isarService.saveTransaction(
                        _selectedAccount!.uuid, transaction);

                    Navigator.pop(context);
                  }
                },
                child: const Text('Guardar Movimiento'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
