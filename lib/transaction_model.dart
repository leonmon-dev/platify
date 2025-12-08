
import 'package:isar_community/isar.dart';

part 'transaction_model.g.dart';

@collection
class Transaction {
  Id id = Isar.autoIncrement;

  late double amount;
  late DateTime date;
  late String description;
}
