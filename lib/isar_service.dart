import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:myapp/account_model.dart';
import 'package:myapp/transaction_model.dart';

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
      );
    }

    return Future.value(Isar.getInstance());
  }

  Future<void> saveAccount(Account newAccount) async {
    final isar = await db;
    isar.writeTxnSync<int>(() => isar.accounts.putSync(newAccount));
    notifyListeners();
  }

  Future<void> saveTransaction(
      String accountUuid, Transaction newTransaction) async {
    final isar = await db;

    final account = await isar.accounts
        .where()
        .filter()
        .uuidEqualTo(accountUuid)
        .findFirst();

    if (account != null) {
      newTransaction.account.value = account;
      await isar.writeTxn(() async {
        await isar.transactions.put(newTransaction);
        await newTransaction.account.save();

        account.balance += newTransaction.amount;
        await isar.accounts.put(account);
      });
    }

    notifyListeners();
  }

  Future<Account?> getAccountByUuid(String uuid) async {
    final isar = await db;
    return await isar.accounts.where().filter().uuidEqualTo(uuid).findFirst();
  }

  Future<void> deleteAccount(String uuid) async {
    final isar = await db;
    await isar.writeTxn(() async {
      final account =
          await isar.accounts.where().filter().uuidEqualTo(uuid).findFirst();
      if (account != null) {
        await isar.accounts.delete(account.id);
      }
    });
    notifyListeners();
  }

  Future<List<Account>> getAllAccounts() async {
    final isar = await db;
    return await isar.accounts.where().findAll();
  }

  Stream<List<Account>> listenToAccounts() async* {
    final isar = await db;
    yield* isar.accounts.where().watch(fireImmediately: true);
  }

  Future<void> cleanDb() async {
    final isar = await db;
    await isar.writeTxn(() async => await isar.clear());
  }
}
