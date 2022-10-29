import 'package:minerva/minerva.dart';
import 'package:needle_orm_minerva_example/apis/apis.dart';

class ApisBuilder extends MinervaApisBuilder {
  @override
  List<Api> build() {
    return allApi;
  }
}
