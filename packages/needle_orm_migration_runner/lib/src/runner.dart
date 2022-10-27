import 'dart:async';

import 'package:needle_orm_migration/needle_orm_migration.dart';

abstract class MigrationRunner {
  void addMigration(Migration migration);

  Future up();

  Future rollback();

  Future reset();

  Future close();
}
