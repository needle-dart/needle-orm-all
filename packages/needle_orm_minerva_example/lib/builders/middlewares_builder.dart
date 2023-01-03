import 'package:minerva/minerva.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'auth_middleware.dart';
import 'jwt_auth_middleware_builder.dart';

import '../services/services.dart';

class MiddlewaresBuilder extends MinervaMiddlewaresBuilder {
  @override
  Future<List<Middleware>> build() async {
    var middlewares = <Middleware>[];

    var configuration = ConfigurationManager();

    await configuration.load();

    var key = SecretKey(configuration['secret']);

    var jwtMiddleware = JwtAuthMiddlewareBuilder(key).build();

    // Adds middleware for handling errors in middleware pipeline
    middlewares.add(ErrorMiddleware());

    middlewares.add(jwtMiddleware);

    middlewares.add(AuthMiddleware());

    // middlewares.add(TimingMiddleware());

    middlewares.add(ServiceMiddleware());

    // Adds middleware for query mappings to endpoints in middleware pipeline
    middlewares.add(EndpointMiddleware());

    return middlewares;
  }
}
