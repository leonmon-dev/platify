
import 'package:isar_community/isar.dart';
import 'package:platify/transaction_model.dart';

part 'account_model.g.dart';

@collection
class Account {
  Id id = Isar.autoIncrement;

  late String name;
  late double balance;

  final transactions = IsarLinks<Transaction>();
}
