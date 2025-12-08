import 'package:isar/isar.dart';
import 'package:myapp/transaction_model.dart';
import 'package:uuid/uuid.dart';

part 'account_model.g.dart';

@collection
class Account {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  late String name;
  late double balance;

  @Backlink(to: 'account')
  final transactions = IsarLinks<Transaction>();

  Account({
    required this.name,
    required this.balance,
  }) {
    uuid = const Uuid().v4();
  }
}
