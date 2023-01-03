import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:minerva/minerva.dart';

class JwtAuthMiddlewareBuilder {
  final SecretKey _key;

  JwtAuthMiddlewareBuilder(SecretKey key) : _key = key;

  JwtAuthMiddleware build() {
    return JwtAuthMiddleware(tokenVerify: _tokenVerify, getRole: _getRole);
  }

  bool _tokenVerify(ServerContext context, String token) {
    try {
      JWT.verify(token, _key);

      return true;
    } catch (_) {
      return false;
    }
  }

  Role _getRole(ServerContext context, String token) {
    var jwt = JWT.verify(token, _key);

    var payload = jwt.payload as Map<String, dynamic>;

    return Role(payload['role'], permissionLevel: payload['permissionLevel']);
  }
}
