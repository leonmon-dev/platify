
import 'package:flutter/material.dart';
import 'package:platify/accounts_screen.dart';
import 'package:platify/isar_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isarService = IsarService();

  runApp(MyApp(isarService: isarService));
}

class MyApp extends StatelessWidget {
  final IsarService isarService;

  const MyApp({super.key, required this.isarService});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: isarService,
      child: MaterialApp(
        title: 'Platify',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const AccountsScreen(),
      ),
    );
  }
}
