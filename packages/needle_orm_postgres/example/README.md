```
import 'package:mysql1/mysql1.dart';
import 'package:needle_orm/needle_orm.dart';
import 'package:needle_orm_postgres/needle_orm_postgres.dart';


Future<Database> initPostgreSQL() async {
  return PostgreSqlPoolDatabase(PgPool(
    PgEndpoint(
      host: 'localhost',
      port: 5432,
      database: 'needle',
      username: 'postgres',
      password: 'postgres',
    ),
    settings: PgPoolSettings()
      ..maxConnectionAge = Duration(hours: 1)
      ..concurrency = 5,
  ));
}

```