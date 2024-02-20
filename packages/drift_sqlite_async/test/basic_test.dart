import 'package:drift/drift.dart';
import 'package:drift_sqlite_async/src/executor.dart';
import 'package:sqlite_async/sqlite_async.dart';
import 'package:test/test.dart';

import './utils/test_utils.dart';

class EmptyDatabase extends GeneratedDatabase {
  EmptyDatabase(super.executor);

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => [];

  @override
  int get schemaVersion => 1;
}

void main() {
  group('Basic Tests', () {
    late String path;

    setUp(() async {
      path = dbPath();
      await cleanDb(path: path);
    });

    tearDown(() async {
      await cleanDb(path: path);
    });

    createTables(SqliteDatabase db) async {
      await db.writeTransaction((tx) async {
        await tx.execute(
            'CREATE TABLE test_data(id INTEGER PRIMARY KEY AUTOINCREMENT, description TEXT)');
      });
    }

    test('Basic Setup', () async {
      final db = await setupDatabase(path: path);
      final connection = SqliteAsyncDriftConnection(db);
      final dbu = EmptyDatabase(connection);

      await createTables(db);

      final insertRowId = await dbu.customInsert(
          'INSERT INTO test_data(description) VALUES(?)',
          variables: [Variable('Test Data')]);
      expect(insertRowId, greaterThanOrEqualTo(1));

      final result = await dbu
          .customSelect('SELECT description FROM test_data')
          .getSingle();
      expect(result.data, equals({'description': 'Test Data'}));

      await dbu.close();
    });

    test('Flat transaction', () async {
      final db = await setupDatabase(path: path);
      final connection = SqliteAsyncDriftConnection(db);
      final dbu = EmptyDatabase(connection);

      await createTables(db);

      await dbu.transaction(() async {
        await dbu.customInsert('INSERT INTO test_data(description) VALUES(?)',
            variables: [Variable('Test Data')]);

        expect(await db.get('select count(*) as count from test_data'),
            equals({'count': 0}));
      });
      expect(await db.get('select count(*) as count from test_data'),
          equals({'count': 1}));

      await dbu.close();
    });
  });
}
