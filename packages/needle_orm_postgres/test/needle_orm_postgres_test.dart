import 'package:logging/logging.dart';
import 'package:needle_orm_postgres/needle_orm_postgres.dart';
import 'package:postgres_pool/postgres_pool.dart';
import 'package:test/test.dart';

void main() {
  test('test IN', () async {
    Logger.root.level = Level.FINE;
    Logger.root.onRecord.listen((record) {
      print(
          '${record.level.name}: ${record.time} ${record.loggerName}: ${record.message}');
    });
    var ds = PostgreSqlPoolDatabase(PgPool(
      PgEndpoint(
        host: 'localhost',
        port: 5432,
        database: 'appdb',
        username: 'postgres',
        password: 'postgres',
      ),
      settings: PgPoolSettings()
        ..maxConnectionAge = Duration(hours: 1)
        ..concurrency = 5,
    ));

    // var rows = await ds.execute(
    //     'books', 'SELECT * FROM books where id < @maxId', {'maxId': 100});
    var rows = await ds.query('SELECT * FROM books where id in @idList ', {
      'idList': [1, 2]
    });
    print(rows);
  });
}
