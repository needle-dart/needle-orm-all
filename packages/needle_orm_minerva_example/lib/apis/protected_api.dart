import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:minerva/minerva.dart';

import 'common.dart';

class ProtectedApi extends ApiBase {
  late final SecretKey _key;

  @override
  Future<void> initialize(ServerContext context) async {
    super.initialize(context).then((value) {
      _key = SecretKey(config['secret']);
    });
  }

  @override
  void build(Endpoints endpoints) {
    endpoints.get('/protected/first', _first,
        authOptions: AuthOptions(jwt: JwtAuthOptions(roles: ['User'])));

    endpoints.get('/protected/second', _second,
        authOptions: AuthOptions(jwt: JwtAuthOptions(roles: ['Admin'])));

    endpoints.get('/protected/third', _third,
        authOptions: AuthOptions(jwt: JwtAuthOptions(permissionLevel: 2)));
  }

  dynamic _first(ServerContext context, MinervaRequest request) {
    var username = _getUsername(request.authContext.jwt!.token);

    return 'First protected data for user: $username.';
  }

  dynamic _second(ServerContext context, MinervaRequest request) {
    /* request.headers.forEach((name, values) {
      print('request header: $name: $values');
    }); */
    var username = _getUsername(request.authContext.jwt!.token);

    return 'Second protected data for user: $username.';
  }

  dynamic _third(ServerContext context, MinervaRequest request) {
    var username = _getUsername(request.authContext.jwt!.token);

    return 'Third protected data for user: $username.';
  }

  String _getUsername(String token) {
    var jwt = JWT.verify(token, _key);

    return jwt.payload['username'];
  }
}
