import 'package:drift/drift.dart';
import 'package:myapp/account_model.dart';
import 'package:myapp/transaction_model.dart';
import 'database.io.dart' if (dart.library.html) 'database.web.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Accounts, Transactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, from, to) async {
        // Estrategia de migración simple que elimina todas las tablas y las vuelve a crear.
        // ADVERTENCIA: Esto eliminará todos los datos existentes.
        for (final table in allTables) {
          await m.deleteTable(table.actualTableName);
          await m.createTable(table);
        }
      },
    );
  }

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

  // Method to calculate account balance
  Stream<double> watchAccountBalance(int accountId) {
    return customSelect(
      'SELECT a.initial_amount + IFNULL(SUM(t.amount), 0) as balance FROM accounts a LEFT JOIN transactions t ON t.account_id = a.id WHERE a.id = ? GROUP BY a.id',
      variables: [Variable.withInt(accountId)],
      readsFrom: {accounts, transactions},
    ).watchSingle()
    .map((row) => row.read<double>('balance'));
  }
}
