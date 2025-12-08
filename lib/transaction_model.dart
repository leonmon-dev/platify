import 'package:isar/isar.dart';
import 'package:myapp/account_model.dart';
import 'package:uuid/uuid.dart';

part 'transaction_model.g.dart';

@collection
class Transaction {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  late double amount;
  late DateTime date;
  late String description;

  final account = IsarLink<Account>();

  Transaction({
    required this.amount,
    required this.date,
    required this.description,
  }) {
    uuid = const Uuid().v4();
  }
}
