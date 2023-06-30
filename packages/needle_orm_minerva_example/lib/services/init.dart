import 'package:minerva/minerva.dart';
import 'package:needle_orm_minerva_example/services/services.dart';

Future<void> initData(ServerContext context, MinervaRequest request) async {
  var count = await UserQuery().count();
  var n = 5;
  for (int i = count; i < count + n; i++) {
    var user = User()
      ..name = 'name_$i'
      ..loginName = 'name_$i'
      ..address = 'China Shanghai street_$i'
      ..age = (n * 0.1).toInt();
    user.resetPassword('newPassw0rd');
    await user.save();

    var book = Book()
      ..author = user
      ..price = n * 0.3
      ..title = 'Dart$i';
    await book.insert();
  }
}
