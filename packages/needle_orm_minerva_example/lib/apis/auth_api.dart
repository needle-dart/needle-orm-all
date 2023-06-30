import 'dart:async';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:minerva/minerva.dart';

import '../services/domain.biz.dart';
import '../services/domain.dart';
import 'common.dart';

class AuthApi extends ApiBase {
  late final SecretKey _key;

  @override
  Future<void> initialize(ServerContext context) async {
    super.initialize(context).then((value) {
      _key = SecretKey(config['secret']);
    });
  }

  @override
  void build(Endpoints endpoints) {
    var filter = RequestFilter(
        body: JsonFilter(fields: [
      JsonField(name: 'username', type: JsonFieldType.string),
      JsonField(name: 'password', type: JsonFieldType.string)
    ]));

    endpoints.post('/auth', _auth, filter: filter);
  }

  dynamic _auth(ServerContext context, MinervaRequest request) async {
    var json = await request.body.asJson();

    String username = json['username'];
    String password = json['password'];

    User? user = await BizUser.findByLoginName(username);

    if (user == null) {
      return {'error': 'user not found [$username]'};
    }

    if (!user.verifyPassword(password)) {
      return {'error': 'auth failed [$username]'};
    }

    logger.info('logged in as user (${user.id}): [$username]');

    var jwt = JWT({
      'id': user.id,
      'username': json['username'],
    }, subject: json['username']);

    var token = jwt.sign(_key, expiresIn: Duration(hours: 24));

    return {'token': token};
  }
}
