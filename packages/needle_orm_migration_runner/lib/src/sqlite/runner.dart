import 'dart:async';
import 'dart:collection';
import 'package:needle_orm_migration/needle_orm_migration.dart';
import 'package:logging/logging.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import '../runner.dart';
import '../util.dart';
import 'schema.dart';

class SqliteMigrationRunner implements MigrationRunner {
  final _log = Logger('SqliteMigrationRunner');

  final Map<String, Migration> migrations = {};
  final Queue<Migration> _migrationQueue = Queue();
  final sqlite.Database connection;
  bool _connected = false;

  SqliteMigrationRunner(this.connection,
      {Iterable<Migration> migrations = const [], bool connected = false}) {
    if (migrations.isNotEmpty == true) migrations.forEach(addMigration);
    _connected = connected == true;
  }

  @override
  void addMigration(Migration migration) {
    _migrationQueue.addLast(migration);
  }

  Future _init() async {
    while (_migrationQueue.isNotEmpty) {
      var migration = _migrationQueue.removeFirst();
      var path = await absoluteSourcePath(migration.runtimeType);
      migrations.putIfAbsent(path.replaceAll('\\', '\\\\'), () => migration);
    }

    if (!_connected) {
      _connected = true;
    }

    var stmt = connection.prepare('''
    CREATE TABLE IF NOT EXISTS migrations (
      id serial,
      batch integer,
      path varchar(255),
      PRIMARY KEY(id)
    );
    ''');
    stmt.execute();
  }

  @override
  Future up() async {
    await _init();
    var result = connection.select('SELECT path from migrations;');

    var existing = <String>[];
    if (result.isNotEmpty) {
      existing = result.map((e) => e['path']).cast<String>().toList();
    }

    var toRun = <String>[];
    migrations.forEach((k, v) {
      if (!existing.contains(k)) toRun.add(k);
    });

    if (toRun.isNotEmpty) {
      var result = connection.select('SELECT MAX(batch) from migrations;');
      var curBatch = 0;
      if (result.isNotEmpty) {
        var batch = result[0][0];
        if (batch == null) {
          curBatch = 0;
        } else if (batch is int) {
          curBatch = batch;
        } else {
          curBatch = int.tryParse('$batch') as int;
        }
      }
      var batch = curBatch + 1;

      for (var k in toRun) {
        var migration = migrations[k]!;
        var schema = SqliteSchema();
        migration.up(schema);
        _log.info('Added "$k" into "migrations" table.');
        try {
          await schema.run(connection).then((_) async {
            connection
                .prepare(
                    "INSERT INTO migrations (batch, path) VALUES ($batch, '$k')")
                .execute();
            return;
          });
        } catch (e) {
          _log.severe('Failed to insert into "migrations" table.', e);
        }
      }
    } else {
      _log.warning('Nothing to add into "migrations" table.');
    }
  }

  @override
  Future rollback() async {
    await _init();

    var result = connection.select('SELECT MAX(batch) from migrations;');

    var curBatch = 0;
    if (result.isNotEmpty) {
      var firstRow = result.toList();
      curBatch = int.tryParse(firstRow[0][0]) as int;
    }

    result = connection
        .select('SELECT path from migrations WHERE batch = $curBatch;');
    var existing = <String>[];
    if (result.isNotEmpty) {
      existing = result.map((e) => e['path']).cast<String>().toList();
    }

    var toRun = <String>[];

    migrations.forEach((k, v) {
      if (existing.contains(k)) toRun.add(k);
    });

    if (toRun.isNotEmpty) {
      for (var k in toRun.reversed) {
        var migration = migrations[k]!;
        var schema = SqliteSchema();
        migration.down(schema);
        _log.info('Removed "$k" from "migrations" table.');
        await schema.run(connection).then((_) {
          connection
              .prepare('DELETE FROM migrations WHERE path = \'$k\';')
              .execute();
          return;
        });
      }
    } else {
      _log.warning('Nothing to remove from "migrations" table.');
    }
  }

  @override
  Future reset() async {
    await _init();
    var r =
        connection.select('SELECT path from migrations ORDER BY batch DESC;');
    var existing = <String>[];
    if (r.isNotEmpty) {
      existing = r.map((x) => x['path']).cast<String>().toList();
    }

    var toRun = existing.where(migrations.containsKey).toList();

    if (toRun.isNotEmpty) {
      for (var k in toRun.reversed) {
        var migration = migrations[k]!;
        var schema = SqliteSchema();
        migration.down(schema);
        _log.info('Removed "$k" from "migrations" table.');
        await schema.run(connection).then((_) {
          connection
              .prepare('DELETE FROM migrations WHERE path = \'$k\';')
              .execute();
          return;
        });
      }
    } else {
      _log.warning('Nothing to remove from "migrations" table.');
    }
  }

  @override
  Future close() async {
    return connection.dispose();
  }
}
