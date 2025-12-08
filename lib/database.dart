
import 'package:drift/drift.dart';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:myapp/account_model.dart';
import 'package:myapp/transaction_model.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Accounts, Transactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Methods for accounts
  Future<List<Account>> getAllAccounts() => select(accounts).get();
  Stream<List<Account>> watchAllAccounts() => select(accounts).watch();
  Future<int> addAccount(AccountsCompanion entry) {
    return into(accounts).insert(entry);
  }
  Future updateAccount(Account entry) => update(accounts).replace(entry);
  Future deleteAccount(Account entry) => delete(accounts).delete(entry);

  // Methods for transactions
  Future<List<Transaction>> getAllTransactions() => select(transactions).get();
  Stream<List<Transaction>> watchAllTransactions() => select(transactions).watch();
    Stream<List<Transaction>> watchTransactionsForAccount(int accountId) {
    return (select(transactions)..where((t) => t.accountId.equals(accountId))).watch();
  }
  Future<int> addTransaction(TransactionsCompanion entry) {
    return into(transactions).insert(entry);
  }
  Future updateTransaction(Transaction entry) => update(transactions).replace(entry);
  Future deleteTransaction(Transaction entry) => delete(transactions).delete(entry);
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
