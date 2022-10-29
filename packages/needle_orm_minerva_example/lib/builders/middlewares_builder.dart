import 'package:minerva/minerva.dart';

import '../services/service_middleware.dart';

class MiddlewaresBuilder extends MinervaMiddlewaresBuilder {
  @override
  List<Middleware> build() {
    var middlewares = <Middleware>[];

    // Adds middleware for handling errors in middleware pipeline
    middlewares.add(ErrorMiddleware());

    middlewares.add(ServiceMiddleware());

    // Adds middleware for query mappings to endpoints in middleware pipeline
    middlewares.add(EndpointMiddleware());

    return middlewares;
  }
}
