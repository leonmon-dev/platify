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
    if (!_formKey.currentState!.validate()) return;

    final months = int.tryParse(_monthsController.text) ?? 0;
    final creditValue =
        double.tryParse(_creditController.text.replaceAll(',', '.')) ?? 0.0;
    final rawInterest =
        double.tryParse(_interestController.text.replaceAll(',', '.')) ?? 0.0;
    final insuranceValue =
        double.tryParse(_insuranceController.text.replaceAll(',', '.')) ?? 0.0;
    final fixedInstallment =
        double.tryParse(_installmentController.text.replaceAll(',', '.')) ?? 0.0;

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
      monthlyRate = annualDecimalRate;
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
            (creditValue * monthlyRate * factor) / (factor - 1) + insuranceValue;
      }
    }

    setState(() {
      _payments.clear();
      _loanAmount = creditValue;
      _totalPaid = 0;
      _totalInterest = 0;

      double remainingBalance = creditValue;

      for (int month = 1; month <= months; month++) {
        if (remainingBalance <= 0.01) {
          break;
        }

        final interestPayment = remainingBalance * monthlyRate;
        double principalPayment = monthlyPayment - insuranceValue - interestPayment;
        double totalPaymentForMonth = monthlyPayment;

        if (principalPayment > remainingBalance) {
          principalPayment = remainingBalance;
          totalPaymentForMonth = principalPayment + interestPayment + insuranceValue;
        }

        remainingBalance -= principalPayment;

        final finalBalance = remainingBalance > 0 ? remainingBalance : 0.0;

        _payments.add(
          PaymentRecord(
            month: month,
            principal: principalPayment,
            interest: interestPayment,
            insurance: insuranceValue,
            totalPayment: totalPaymentForMonth,
            remainingBalance: finalBalance,
          ),
        );

        _totalPaid += totalPaymentForMonth;
        _totalInterest += interestPayment;
      }
    });
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Simuladores'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Simulador de Crédito',
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTextFormField(
                        controller: _creditController,
                        label: 'Valor del crédito',
                        icon: Icons.monetization_on_outlined,
                        isCurrency: true,
                      ),
                      _buildTextFormField(
                        controller: _monthsController,
                        label: 'Cantidad de meses',
                        icon: Icons.calendar_today_outlined,
                      ),
                      _buildTextFormField(
                        controller: _interestController,
                        label: 'Porcentaje interés (%)',
                        icon: Icons.show_chart_outlined,
                      ),
                      DropdownButtonFormField<String>(
                        decoration: _inputDecoration('Tipo de interés', Icons.tune_outlined),
                        value: _interestType,
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
                      const SizedBox(height: 16),
                       _buildTextFormField(
                        controller: _installmentController,
                        label: 'Valor de la cuota (opcional)',
                        icon: Icons.payment_outlined,
                         isCurrency: true,
                         required: false,
                      ),
                      _buildTextFormField(
                        controller: _insuranceController,
                        label: 'Valor de seguro (opcional)',
                        icon: Icons.security_outlined,
                        isCurrency: true,
                        required: false,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _simulate,
                        child: const Text('Simular', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_payments.isNotEmpty) ...[
              const SizedBox(height: 30),
              Text(
                'Tabla de Pagos',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                 elevation: 4,
                 clipBehavior: Clip.antiAlias,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                 child: SizedBox(
                   width: double.infinity,
                   child: DataTable(
                     headingRowColor: MaterialStateProperty.resolveWith((states) => theme.colorScheme.primary),
                     headingTextStyle: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                     columns: const [
                       DataColumn(label: Text('Mes')),
                       DataColumn(label: Text('Capital')),
                       DataColumn(label: Text('Interés')),
                       DataColumn(label: Text('Seguro')),
                       DataColumn(label: Text('Total')),
                       DataColumn(label: Text('Saldo')),
                     ],
                     rows: _getCurrentPagePayments().map((payment) {
                        final index = _payments.indexOf(payment);
                       return DataRow(
                         color: MaterialStateProperty.resolveWith((states) => index.isEven ? Colors.white : Colors.grey.shade100),
                         cells: [
                           DataCell(Text(payment.month.toString())),
                           DataCell(Text('\$${_currencyFormat.format(payment.principal.round())}')),
                           DataCell(Text('\$${_currencyFormat.format(payment.interest.round())}')),
                           DataCell(Text('\$${_currencyFormat.format(payment.insurance.round())}')),
                           DataCell(Text('\$${_currencyFormat.format(payment.totalPayment.round())}')),
                           DataCell(Text('\$${_currencyFormat.format(payment.remainingBalance.round())}')),
                         ],
                       );
                     }).toList(),
                   ),
                 ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: _currentPage > 0
                        ? () => setState(() => _currentPage--)
                        : null,
                  ),
                  Text(
                    'Página ${_currentPage + 1} de ${(_payments.length / _itemsPerPage).ceil()}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed:
                        (_currentPage + 1) * _itemsPerPage < _payments.length
                        ? () => setState(() => _currentPage++)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Text(
                'Resumen del Crédito',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildSummaryRow('Valor del préstamo:', _loanAmount, theme),
                      const Divider(height: 24),
                      _buildSummaryRow('Cantidad total pagada:', _totalPaid, theme, isTotal: true),
                      const Divider(height: 24),
                      _buildSummaryRow('Total intereses pagados:', _totalInterest, theme, isInterest: true),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isCurrency = false,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: _inputDecoration(label, icon),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: isCurrency
            ? [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))]
            : [FilteringTextInputFormatter.digitsOnly],
        validator: required
            ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Este campo es obligatorio';
                }
                return null;
              }
            : null,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.grey.shade100,
       enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  Widget _buildSummaryRow(String title, double value, ThemeData theme, {bool isTotal = false, bool isInterest = false}) {
    final style = theme.textTheme.titleMedium?.copyWith(
      fontWeight: isTotal || isInterest ? FontWeight.bold : FontWeight.normal,
      color: isInterest ? theme.colorScheme.error : (isTotal ? theme.colorScheme.primary : null),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: theme.textTheme.bodyLarge),
        Text('\$${_currencyFormat.format(value.round())}', style: style),
      ],
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
