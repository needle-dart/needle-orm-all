import 'package:minerva/minerva.dart';

import 'auth_api.dart';
import 'book_api.dart';
import 'protected_api.dart';

List<Api> allApi = [BookApi(), AuthApi(), ProtectedApi()];
