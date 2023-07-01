// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'domain.dart';

// **************************************************************************
// NeedleOrmMigrationGenerator
// **************************************************************************

class BookMigration extends Migration {
  @override
  void up(Schema schema) {
    schema.create('books', (table) {
      table.varChar('title', length: 255, comment: 'xxx');

      table.float('price');

      table.integer('author_id');

      table.blob('image');

      table.clob('content');

      table.serial('id');

      table.integer('version');

      table.boolean('deleted');

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

class UserMigration extends Migration {
  @override
  void up(Schema schema) {
    schema.create('users', (table) {
      table.varChar('name', length: 255);

      table.varChar('login_name', length: 255);

      table.varChar('address', length: 255);

      table.integer('age');

      table.serial('id');

      table.integer('version');

      table.boolean('deleted');

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

class JobMigration extends Migration {
  @override
  void up(Schema schema) {
    schema.create('jobs', (table) {
      table.varChar('name', length: 255);

      table.serial('id');

      table.integer('version');

      table.boolean('deleted');

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
  BookMigration(),
  UserMigration(),
  JobMigration()
];
