import 'package:drift/drift.dart';
import 'package:myapp/account_model.dart';

@DataClassName('Transaction')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get description => text()();
  RealColumn get amount => real()();
  IntColumn get accountId => integer().references(Accounts, #id)();
  DateTimeColumn get date => dateTime()();
}
