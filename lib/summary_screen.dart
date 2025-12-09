import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/database.dart';
import 'package:provider/provider.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informes'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Account>>(
        stream: db.watchAllAccounts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No hay cuentas para mostrar informes.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            );
          }

          final accounts = snapshot.data!;
          return ListView.builder(
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return AccountTransactionChart(account: account);
            },
          );
        },
      ),
    );
  }
}

class AccountTransactionChart extends StatelessWidget {
  final Account account;

  const AccountTransactionChart({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context, listen: false);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              account.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: StreamBuilder<List<Transaction>>(
                stream: db.watchTransactionsForAccount(account.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: Text('No hay datos de transacciones.'));
                  }

                  final transactions = snapshot.data!;
                  transactions.sort((a, b) => a.date.compareTo(b.date));

                  List<FlSpot> spots = [];
                  double balance = account.initialAmount;

                  // Initial spot
                  final DateTime initialDate = transactions.isNotEmpty 
                      ? transactions.first.date.subtract(const Duration(days: 1)) 
                      : DateTime.now();
                  spots.add(FlSpot(initialDate.millisecondsSinceEpoch.toDouble(), balance));

                  for (var txn in transactions) {
                    balance += txn.amount;
                    spots.add(FlSpot(txn.date.millisecondsSinceEpoch.toDouble(), balance));
                  }

                  if (spots.length == 1) {
                    spots.add(FlSpot(DateTime.now().millisecondsSinceEpoch.toDouble(), spots.first.y));
                  }

                  return LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) - spots.map((s) => s.y).reduce((a,b) => a < b ? a : b)) / 4,
                        verticalInterval: (spots.last.x - spots.first.x) / 4,
                        getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xff37434d), strokeWidth: 1),
                        getDrawingVerticalLine: (value) => const FlLine(color: Color(0xff37434d), strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44, getTitlesWidget: leftTitleWidgets)),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, interval: (spots.last.x - spots.first.x) / 4, getTitlesWidget: bottomTitleWidgets)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xff37434d))),
                      minX: spots.first.x,
                      maxX: spots.last.x,
                      minY: spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 50,
                      maxY: spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 50,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary]),
                          barWidth: 5,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [Theme.of(context).colorScheme.primary.withOpacity(0.3), Theme.of(context).colorScheme.secondary.withOpacity(0.3)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontSize: 10);
    final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
    return SideTitleWidget(axisSide: meta.axisSide, space: 4, child: Text(DateFormat.MMMd().format(date), style: style));
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontSize: 10);
    final formatCurrency = NumberFormat.compactSimpleCurrency(locale: 'es_ES');
    return SideTitleWidget(axisSide: meta.axisSide, space: 4, child: Text(formatCurrency.format(value), style: style, textAlign: TextAlign.center));
  }
}
