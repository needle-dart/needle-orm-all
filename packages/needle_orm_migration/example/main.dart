import 'package:needle_orm_migration/needle_orm_migration.dart';

class UserMigration implements Migration {
  @override
  void up(Schema schema) {
    schema.create('users', (table) {
      table
        ..serial('id').primaryKey()
        ..varChar('username', length: 32).unique()
        ..varChar('password')
        ..boolean('account_confirmed').defaultsTo(false);
    });
  }

  @override
  void down(Schema schema) {
    schema.drop('users');
  }
}

class TodoMigration implements Migration {
  @override
  void up(Schema schema) {
    schema.create('todos', (table) {
      table
        ..serial('id').primaryKey()
        ..integer('user_id').references('users', 'id').onDeleteCascade()
        ..varChar('text')
        ..boolean('completed').defaultsTo(false);
    });
  }

  @override
  void down(Schema schema) {
    schema.drop('todos');
  }
}
