import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/database.dart';
import 'package:provider/provider.dart';

enum TransactionType { income, expense }

class AddTransactionScreen extends StatefulWidget {
  final Account account;
  final Transaction? transaction;

  const AddTransactionScreen({super.key, required this.account, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late DateTime _selectedDate;
  
  TransactionType _transactionType = TransactionType.expense;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.transaction?.description);
    _amountController = TextEditingController(text: widget.transaction != null ? widget.transaction!.amount.abs().toString() : '');
    _selectedDate = widget.transaction?.date ?? DateTime.now();

    if (widget.transaction != null) {
      _transactionType = widget.transaction!.amount > 0 ? TransactionType.income : TransactionType.expense;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final db = Provider.of<AppDatabase>(context, listen: false);
      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      final description = _descriptionController.text;
      final amount = double.parse(_amountController.text);
      
      final finalAmount = _transactionType == TransactionType.income ? amount : -amount;

      if (widget.transaction == null) {
        // Create new transaction
        await db.addTransaction(
          TransactionsCompanion.insert(
            description: description,
            amount: finalAmount,
            accountId: widget.account.id,
            date: _selectedDate,
          ),
        );
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Movimiento agregado')),
        );
      } else {
        // Update existing transaction
        final updatedTransaction = widget.transaction!.copyWith(
          description: description,
          amount: finalAmount,
          date: _selectedDate,
        );
        await db.updateTransaction(updatedTransaction);
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Movimiento actualizado')),
        );
      }
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.transaction == null ? 'Agregar Movimiento' : 'Editar Movimiento',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Text('Cuenta: ${widget.account.name}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            SegmentedButton<TransactionType>(
              segments: const <ButtonSegment<TransactionType>>[
                ButtonSegment<TransactionType>(value: TransactionType.expense, label: Text('Egreso'), icon: Icon(Icons.arrow_downward)),
                ButtonSegment<TransactionType>(value: TransactionType.income, label: Text('Ingreso'), icon: Icon(Icons.arrow_upward)),
              ],
              selected: <TransactionType>{_transactionType},
              onSelectionChanged: (Set<TransactionType> newSelection) {
                setState(() {
                  _transactionType = newSelection.first;
                });
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
                  return 'Por favor ingrese una descripción';
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese un monto';
                }
                if (double.tryParse(value) == null) {
                  return 'Ingrese un número válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text('Fecha: ${DateFormat.yMMMd().format(_selectedDate)}'),
                ),
                TextButton(
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null && pickedDate != _selectedDate) {
                      setState(() {
                        _selectedDate = pickedDate;
                      });
                    }
                  },
                  child: const Text('Cambiar Fecha'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(widget.transaction == null ? 'Guardar' : 'Actualizar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
