import 'dart:developer';

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

DatabaseConnection openConnection() {
  return DatabaseConnection.delayed(Future(() async {
    final result = await WasmDatabase.open(
      databaseName: 'my-app-db', // prefer to not use the same name as the older db
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );

    if (result.missingFeatures.isNotEmpty) {
      // Depending on your app, you might want to show a warning to the user
      // that not all features are available.
      log('Using ${result.chosenImplementation} due to missing browser features: ${result.missingFeatures}');
    }

    return result.resolvedExecutor;
  }));
}
