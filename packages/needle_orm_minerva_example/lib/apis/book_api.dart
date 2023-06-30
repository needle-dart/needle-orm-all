import 'package:minerva/minerva.dart';

import '../services/services.dart';
import 'common.dart';

class BookApi extends ApiBase {
  @override
  void build(Endpoints endpoints) {
    endpoints.get('/book', findOneBook);

    endpoints.get('/book2', createOneBook);

    endpoints.get('/book3', findSomeBooks);

    endpoints.get('/book4', findSomeBooks2);

    endpoints.get('/init', initData);
  }
}
