import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

QueryExecutor openConnection() {
  final dbFolder = getApplicationDocumentsDirectory();
  final file = dbFolder.then((folder) => File(p.join(folder.path, 'db.sqlite')));

  return LazyDatabase(() async {
    return NativeDatabase(await file);
  });
}
