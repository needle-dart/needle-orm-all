import 'package:logging/logging.dart';
import 'package:crypt/crypt.dart';

import 'domain.dart';

// can write business logic here.

extension BizUser on User {
  static final Logger _logger = Logger('USER');
  bool isAdmin() {
    return name!.startsWith('admin');
  }

  void resetPassword(String newPassword) {
    password = Crypt.sha512(newPassword).toString();
  }

  bool verifyPassword(String tryPassword) {
    return Crypt(password!).match(tryPassword);
  }

  static Future<User?> findByLoginName(String loginName) {
    var query = UserQuery()
      ..loginName.eq(loginName)
      ..paging(0, 1);
    return query.findUnique();
  }
}
