import 'package:minerva/minerva.dart';

import '../services/services.dart';

class BookApi extends Api {
  @override
  void build(Endpoints endpoints) {
    endpoints.get('/book', findOneBook);

    endpoints.get('/book2', createOneBook);

    endpoints.get('/book3', findSomeBooks);
  }
}
