
import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:platify/account_model.dart';
import 'package:platify/transaction_model.dart';

class IsarService extends ChangeNotifier {
  late Future<Isar> db;

  IsarService() {
    db = openDB();
  }

  Future<Isar> openDB() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      return await Isar.open(
        [AccountSchema, TransactionSchema],
        directory: dir.path,
        inspector: true,
      );
    }

    return Future.value(Isar.getInstance());
  }

  Future<void> saveAccount(Account newAccount) async {
    final isar = await db;
    isar.writeTxnSync<int>(() => isar.collection<Account>().putSync(newAccount));
    notifyListeners();
  }

  Future<void> saveTransaction(
      Account account, Transaction newTransaction) async {
    final isar = await db;
    account.balance += newTransaction.amount;
    isar.writeTxnSync<int>(
        () => isar.collection<Transaction>().putSync(newTransaction));

    isar.writeTxnSync(() async {
      account.transactions.add(newTransaction);
      await account.transactions.save();
    });
    notifyListeners();
  }

  Future<List<Account>> getAllAccounts() async {
    final isar = await db;
    return await isar.collection<Account>().where().findAll();
  }

  Stream<List<Account>> listenToAccounts() async* {
    final isar = await db;
    yield* isar.collection<Account>().where().watch(fireImmediately: true);
  }
}
