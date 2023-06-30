import 'dart:async';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:minerva/minerva.dart';
import 'package:needle_orm_minerva_example/common/ncontext.dart';
import 'package:needle_orm_minerva_example/services/domain.dart';

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

    User? user = await context.request.user(context.context);
    NContext ctx =
        NContext(auth: Auth(user), logger: context.context.logPipeline);

    return await runZoned(() async {
      var result = await next.handle(context);

      return result;
    }, zoneValues: {NContext.key: ctx});
  }
}

late final SecretKey _key;

extension _AuthExtension on MinervaRequest {
  Future<User?> user(ServerContext context) async {
    if (authContext.jwt == null) {
      return null;
    }
    return _getUser(authContext.jwt!.token, context);
  }

  Future<User?> _getUser(String token, ServerContext context) async {
    var jwt = JWT.verify(token, _key);
    // context.logPipeline.info('payload: ${jwt.payload}, sub: ${jwt.subject}');
    var userId = jwt.payload['id'];
    var q = UserQuery();
    q.where([q.id.eq(userId)]);
    return await q.findUnique();
  }
}
