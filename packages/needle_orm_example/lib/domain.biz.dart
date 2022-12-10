part of 'domain.dart';

extension BizImpl on User {
  bool isAdmin() {
    return name!.startsWith('admin');
  }
}
