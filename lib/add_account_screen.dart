import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:myapp/database.dart';
import 'package:provider/provider.dart';

class AddAccountScreen extends StatefulWidget {
  final Account? account;

  const AddAccountScreen({super.key, this.account});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _type;
  late double _initialAmount;

  final List<String> _accountTypes = [
    'Cuenta de ahorros',
    'Cuenta corriente',
    'Tarjeta de crédito'
  ];

  @override
  void initState() {
    super.initState();
    _type = widget.account?.type ?? _accountTypes[0];
    _name = widget.account?.name ?? '';
    _initialAmount = widget.account?.initialAmount ?? 0.0;
  }

  Future<void> _saveAccount() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final database = Provider.of<AppDatabase>(context, listen: false);
      final isUpdating = widget.account != null;

      try {
        if (isUpdating) {
          final account = widget.account!
              .copyWith(name: _name, type: _type, initialAmount: _initialAmount);
          await database.updateAccount(account);
        } else {
          final account = AccountsCompanion(
              name: drift.Value(_name),
              type: drift.Value(_type),
              initialAmount: drift.Value(_initialAmount));
          await database.addAccount(account);
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Cuenta ${isUpdating ? 'actualizada' : 'agregada'} con éxito.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar la cuenta: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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
          children: [
            Text(
              widget.account == null ? 'Agregar cuenta' : 'Editar cuenta',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: _name,
              decoration:
                  const InputDecoration(labelText: 'Nombre de la cuenta'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese un nombre';
                }
                return null;
              },
              onSaved: (value) => _name = value!,
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Tipo de cuenta'),
              initialValue: _type,
              items: _accountTypes.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _type = newValue!;
                });
              },
              onSaved: (value) => _type = value!,
            ),
            TextFormField(
              initialValue: _initialAmount.toString(),
              decoration: const InputDecoration(labelText: 'Monto inicial'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese una cantidad';
                }
                if (double.tryParse(value) == null) {
                  return 'Por favor, ingrese un número válido';
                }
                return null;
              },
              onSaved: (value) => _initialAmount = double.parse(value!),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveAccount,
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
