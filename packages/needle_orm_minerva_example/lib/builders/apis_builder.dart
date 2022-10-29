import 'package:minerva/minerva.dart';
import 'package:needle_orm_minerva_example/apis/book_api.dart';

class ApisBuilder extends MinervaApisBuilder {
  @override
  List<Api> build() {
    var apis = <Api>[BookApi()];
    return apis;
  }
}
