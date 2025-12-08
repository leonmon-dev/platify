import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class PaymentRecord {
  final int month;
  final double principal;
  final double interest;
  final double insurance;
  final double totalPayment;
  final double remainingBalance;

  PaymentRecord({
    required this.month,
    required this.principal,
    required this.interest,
    required this.insurance,
    required this.totalPayment,
    required this.remainingBalance,
  });
}

// FIX: Changed from StatelessWidget to StatefulWidget
class SimulatorsScreen extends StatefulWidget {
  const SimulatorsScreen({super.key});

  @override
  State<SimulatorsScreen> createState() => _SimulatorsScreenState();
}

class _SimulatorsScreenState extends State<SimulatorsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _monthsController = TextEditingController();
  final _installmentController = TextEditingController();
  final _creditController = TextEditingController();
  final _insuranceController = TextEditingController();
  final _interestController = TextEditingController();

  String _interestType = 'Efectivo anual';
  final List<PaymentRecord> _payments = [];
  int _currentPage = 0;
  static const int _itemsPerPage = 10;

  double _loanAmount = 0;
  double _totalPaid = 0;
  double _totalInterest = 0;

  final List<String> _interestTypes = ['Efectivo anual', 'Mes vencido'];

  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'es_CO');

  void _simulate() {
    if (_formKey.currentState!.validate()) {
      final months = int.tryParse(_monthsController.text) ?? 0;
      final creditValue =
          double.tryParse(_creditController.text.replaceAll(',', '.')) ?? 0.0;
      final rawInterest =
          double.tryParse(_interestController.text.replaceAll(',', '.')) ?? 0.0;
      final insuranceValue =
          double.tryParse(_insuranceController.text.replaceAll(',', '.')) ?? 0.0;
      final fixedInstallment =
          double.tryParse(_installmentController.text.replaceAll(',', '.')) ??
          0.0;

      if (months <= 0 || creditValue <= 0.0) {
        setState(() {
          _payments.clear();
          _totalPaid = 0;
          _totalInterest = 0;
        });
        return;
      }

      final annualDecimalRate = rawInterest / 100.0;
      double monthlyRate;
      if (_interestType == 'Efectivo anual') {
        monthlyRate = pow(1 + annualDecimalRate, (1 / 12)) - 1;
      } else {
        monthlyRate = annualDecimalRate / 12;
      }

      double monthlyPayment;
      if (fixedInstallment > 0) {
        monthlyPayment = fixedInstallment;
      } else {
        if (monthlyRate == 0.0) {
          monthlyPayment = (creditValue / months) + insuranceValue;
        } else {
          final factor = pow(1 + monthlyRate, months);
          monthlyPayment =
              (creditValue * monthlyRate * factor) / (factor - 1) +
              insuranceValue;
        }
      }

      setState(() {
        _payments.clear();
        _loanAmount = creditValue;
        _totalPaid = 0;
        _totalInterest = 0;

        double remainingBalance = creditValue;

        for (int month = 1; month <= months; month++) {
          final interestPayment = remainingBalance * monthlyRate;
          final paymentWithoutInsurance = monthlyPayment - insuranceValue;
          double principalPayment = paymentWithoutInsurance - interestPayment;

          if (principalPayment > remainingBalance) {
            principalPayment = remainingBalance;
          }

          if (remainingBalance <= 0) {
            principalPayment = 0;
          }

          final totalPayment =
              principalPayment + interestPayment + insuranceValue;
          remainingBalance -= principalPayment;
          final finalBalance = remainingBalance > 0 ? remainingBalance : 0.0;

          _payments.add(
            PaymentRecord(
              month: month,
              principal: principalPayment,
              interest: interestPayment,
              insurance: insuranceValue,
              totalPayment: totalPayment,
              remainingBalance: finalBalance,
            ),
          );

          _totalPaid += totalPayment;
          _totalInterest += interestPayment;

          if (finalBalance == 0.0) {
            break;
          }
        }
      });
    }
  }

  List<PaymentRecord> _getCurrentPagePayments() {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _payments.sublist(
      startIndex,
      endIndex > _payments.length ? _payments.length : endIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Simulador de Crédito',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _monthsController,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad de meses',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Este campo es obligatorio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _installmentController,
                    decoration: const InputDecoration(
                      labelText: 'Valor de la cuota (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _creditController,
                    decoration: const InputDecoration(
                      labelText: 'Valor del crédito',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Este campo es obligatorio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _insuranceController,
                    decoration: const InputDecoration(
                      labelText: 'Valor de seguro (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _interestController,
                    decoration: const InputDecoration(
                      labelText: 'Porcentaje interés',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Este campo es obligatorio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _interestType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de interés',
                      border: OutlineInputBorder(),
                    ),
                    items: _interestTypes.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _interestType = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _simulate,
                    child: const Text('Simular'),
                  ),
                ],
              ),
            ),
            if (_payments.isNotEmpty) ...[
              const SizedBox(height: 30),
              const Text(
                'Tabla de Pagos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Mes')),
                    DataColumn(label: Text('Capital')),
                    DataColumn(label: Text('Interés')),
                    DataColumn(label: Text('Seguro')),
                    DataColumn(label: Text('Total')),
                    DataColumn(label: Text('Saldo')),
                  ],
                  rows: _getCurrentPagePayments().map((payment) {
                    return DataRow(
                      cells: [
                        DataCell(Text(payment.month.toString())),
                        DataCell(Text(_currencyFormat.format(payment.principal.round()))),
                        DataCell(Text(_currencyFormat.format(payment.interest.round()))),
                        DataCell(Text(_currencyFormat.format(payment.insurance.round()))),
                        DataCell(Text(_currencyFormat.format(payment.totalPayment.round()))),
                        DataCell(
                          Text(_currencyFormat.format(payment.remainingBalance.round())),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _currentPage > 0
                        ? () => setState(() => _currentPage--)
                        : null,
                  ),
                  Text(
                    'Página ${_currentPage + 1} de ${(_payments.length / _itemsPerPage).ceil()}',
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed:
                        (_currentPage + 1) * _itemsPerPage < _payments.length
                        ? () => setState(() => _currentPage++)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                'Resumen',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Valor del préstamo:'),
                          Text('\$${_currencyFormat.format(_loanAmount.round())}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Cantidad total pagada:'),
                          Text('\$${_currencyFormat.format(_totalPaid.round())}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Intereses pagados:'),
                          Text('\$${_currencyFormat.format(_totalInterest.round())}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
  }

  @override
  void dispose() {
    _monthsController.dispose();
    _installmentController.dispose();
    _creditController.dispose();
    _insuranceController.dispose();
    _interestController.dispose();
    super.dispose();
  }
}
