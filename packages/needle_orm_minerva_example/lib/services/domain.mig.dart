// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// NeedleOrmMigrationGenerator
// **************************************************************************

import 'package:needle_orm_migration/needle_orm_migration.dart';

class _BookMigration extends Migration {
  @override
  void up(Schema schema) {
    schema.create('books', (table) {
      table.serial('id');

      table.varChar('title', length: 255);

      table.float('price');

      table.integer('author_id');

      table.blob('image');

      table.clob('content');

      table.integer('version');

      table.boolean('soft_deleted');

      table.timeStamp('created_at');

      table.timeStamp('updated_at');

      table.varChar('created_by');

      table.varChar('last_updated_by');

      table.varChar('remark', length: 255);
    });
  }

  @override
  void down(Schema schema) {
    schema.drop('books');
  }
}

class _UserMigration extends Migration {
  @override
  void up(Schema schema) {
    schema.create('users', (table) {
      table.serial('id');

      table.varChar('name', length: 255);

      table.varChar('login_name', length: 255);

      table.varChar('password', length: 255);

      table.varChar('address', length: 255);

      table.integer('age');

      table.integer('version');

      table.boolean('soft_deleted');

      table.timeStamp('created_at');

      table.timeStamp('updated_at');

      table.varChar('created_by');

      table.varChar('last_updated_by');

      table.varChar('remark', length: 255);
    });
  }

  @override
  void down(Schema schema) {
    schema.drop('users');
  }
}

class _JobMigration extends Migration {
  @override
  void up(Schema schema) {
    schema.create('jobs', (table) {
      table.serial('id');

      table.varChar('name', length: 255);

      table.integer('version');

      table.boolean('soft_deleted');

      table.timeStamp('created_at');

      table.timeStamp('updated_at');

      table.varChar('created_by');

      table.varChar('last_updated_by');

      table.varChar('remark', length: 255);
    });
  }

  @override
  void down(Schema schema) {
    schema.drop('jobs');
  }
}

final allMigrations = <Migration>[
  _BookMigration(),
  _UserMigration(),
  _JobMigration()
];
