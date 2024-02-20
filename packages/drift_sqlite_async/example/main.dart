import 'package:drift/drift.dart';
import 'package:drift_sqlite_async/drift_sqlite_async.dart';
import 'package:sqlite_async/sqlite_async.dart';

part 'main.g.dart';

class TodoItems extends Table {
  @override
  String get tableName => 'todos';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get description => text()();
}

@DriftDatabase(tables: [TodoItems])
class TodoDatabase extends _$TodoDatabase {
  TodoDatabase(SqliteConnection db) : super(SqliteAsyncDriftConnection(db));

  @override
  int get schemaVersion => 1;
}

Future<void> main() async {
  final db = SqliteDatabase(path: 'example.db');

  // Example where the schema is managed manually
  await db.execute(
      'CREATE TABLE IF NOT EXISTS todos(id integer primary key, description text)');

  final tdb = TodoDatabase(db);

  // Watch a query on the Drift database
  tdb.select(tdb.todoItems).watch().listen((todos) {
    print('Todos: $todos');
  });

  // Insert using the Drift database
  await tdb
      .into(tdb.todoItems)
      .insert(TodoItemsCompanion.insert(description: 'Test Drift'));

  // Insert using the sqlite_async database
  await db.execute('INSERT INTO todos(description) VALUES(?)', ['Test Direct']);

  await Future.delayed(const Duration(milliseconds: 100));

  await tdb.close();
  await db.close();
}
