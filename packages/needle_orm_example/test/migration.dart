import 'package:logging/logging.dart';
import 'package:needle_orm_example/common.dart';

import 'package:needle_orm_example/domain.dart';
import 'package:needle_orm_migration_runner/mariadb.dart';
import 'package:needle_orm_migration_runner/needle_orm_migration_runner.dart';
import 'package:needle_orm_migration_runner/postgres.dart';

void main(List<String> args) async {
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print(
        '${record.level.name}: ${record.time} ${record.loggerName}: ${record.message}');
  });

  args = ['refresh'];

  {
    var migrationRunner = MariaDbMigrationRunner(await initMariaConnection(),
        migrations: allMigrations);
    await runMigrations(migrationRunner, args);
  }

  {
    var migrationRunner = PostgresMigrationRunner(
        await initPostgreSQLConnection(),
        migrations: allMigrations);
    await runMigrations(migrationRunner, args);
  }
}
