import 'dart:async';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:minerva/minerva.dart';

class AuthMiddleware extends Middleware {
  late ServerContext serverContext;

  @override
  Future<void> initialize(ServerContext context) async {
    serverContext = context;

    var configuration = ConfigurationManager();

    await configuration.load();

    _key = SecretKey(configuration['secret']);
  }

  @override
  Future<dynamic> handle(
      MiddlewareContext context, MiddlewarePipelineNode? next) async {
    if (next == null) {
      return NotFoundResult();
    }

    return await runZoned(() async {
      // print(Zone.current[#username]);

      var result = await next.handle(context);

      return result;
    }, zoneValues: {
      #username: context.request.username(context.context),
      #logger: context.context.logPipeline
    });
  }
}

late final SecretKey _key;

extension _AuthExtension on MinervaRequest {
  String? username(ServerContext context) {
    if (authContext.jwt == null) {
      return null;
    }
    return _getUsername(authContext.jwt!.token, context);
  }

  String? _getUsername(String token, ServerContext context) {
    var jwt = JWT.verify(token, _key);
    context.logPipeline.info('payload: ${jwt.payload}, sub: ${jwt.subject}');
    return jwt.payload['username'];
  }
}
