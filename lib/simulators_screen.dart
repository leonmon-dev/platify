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
  List<PaymentRecord> _payments = [];
  int _currentPage = 0;
  static const int _itemsPerPage = 10;

  double _loanAmount = 0;
  double _totalPaid = 0;
  double _totalInterest = 0;

  final List<String> _interestTypes = ['Efectivo anual', 'Mes vencido'];

  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'es_CO');

  void _simulate() {
    // --- 1. LECTURA Y VALIDACIÓN DE ENTRADAS (MÁS SEGURO) ---
    // MEJORA: Usamos tryParse para evitar errores si el campo está vacío o es inválido.
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

    // MEJORA: Validación temprana para evitar cálculos innecesarios o errores.
    if (months <= 0 || creditValue <= 0.0) {
      // Puedes mostrar un error al usuario aquí
      setState(() {
        _payments.clear();
        _totalPaid = 0;
        _totalInterest = 0;
      });
      return; // Detiene la ejecución si no hay datos válidos
    }

    // --- 2. CÁLCULO DE TASAS (CORREGIDO) ---
    final annualDecimalRate = rawInterest / 100.0; // ej: 10% -> 0.10

    double monthlyRate;
    if (_interestType == 'Efectivo anual') {
      // *** FIJO #1: Corrección financiera crítica ***
      // Esta es la fórmula correcta para convertir E.A. a Efectiva Mensual (E.M.)
      monthlyRate = pow(1 + annualDecimalRate, (1 / 12)) - 1;
    } else {
      // Asumo que la otra opción es 'Nominal Anual' (que se paga mensual)
      // Tu código original (rate / 12) es para 'Nominal Anual', no 'Efectivo Anual'.
      monthlyRate = annualDecimalRate / 12;
    }

    // --- 3. CÁLCULO DE CUOTA (MÁS SEGURO) ---
    double monthlyPayment;
    if (fixedInstallment > 0) {
      // El usuario proporcionó una cuota fija
      monthlyPayment = fixedInstallment;
    } else {
      // MEJORA: Maneja el caso de interés 0 para evitar división por cero (NaN)
      if (monthlyRate == 0.0) {
        monthlyPayment = (creditValue / months) + insuranceValue;
      } else {
        // Fórmula de cuota fija (amortización francesa)
        final factor = pow(1 + monthlyRate, months);
        monthlyPayment =
            (creditValue * monthlyRate * factor) / (factor - 1) +
            insuranceValue;
      }
    }

    // --- 4. GENERACIÓN DE LA TABLA DE AMORTIZACIÓN ---
    // Limpiamos los resultados anteriores
    setState(() {
      _payments.clear();
      _loanAmount = creditValue;
      _totalPaid = 0;
      _totalInterest = 0;

      double remainingBalance = creditValue;

      for (int month = 1; month <= months; month++) {
        // 1. Calcular pagos del mes
        final interestPayment = remainingBalance * monthlyRate;

        // El pago total sin seguro es la cuota fija menos el seguro
        final paymentWithoutInsurance = monthlyPayment - insuranceValue;

        // El abono a capital es lo que queda de la cuota tras pagar intereses
        double principalPayment = paymentWithoutInsurance - interestPayment;

        // 2. Ajuste para el último pago
        // Si el abono a capital es mayor que el saldo, ajústalo.
        if (principalPayment > remainingBalance) {
          principalPayment = remainingBalance;
        }

        // Si el saldo ya es 0 o negativo, no calcules más
        if (remainingBalance <= 0) {
          principalPayment = 0;
          // Si quieres que pare de generar filas cuando llega a 0
          // break;
        }

        // 3. Recalcular el pago total (importante para la última cuota)
        final totalPayment =
            principalPayment + interestPayment + insuranceValue;

        // 4. Actualizar el saldo
        remainingBalance -= principalPayment;

        // Asegurarse de que el saldo final no sea negativo (por centavos)
        final finalBalance = remainingBalance > 0 ? remainingBalance : 0.0;

        // 5. Guardar registro y sumar totales
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

        // Si el saldo llegó a 0, no sigas iterando
        if (finalBalance == 0.0) {
          break;
        }
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
    return Scaffold(
      appBar: AppBar(title: const Text('Simuladores')),
      body: SingleChildScrollView(
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
                    keyboardType: TextInputType.numberWithOptions(
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
                    keyboardType: TextInputType.numberWithOptions(
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
                    keyboardType: TextInputType.numberWithOptions(
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
                    keyboardType: TextInputType.numberWithOptions(
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
                    value: _interestType,
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
