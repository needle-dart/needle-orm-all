import 'dart:async';

import 'package:minerva/minerva.dart';

import '../services/domain.dart';

class NContext {
  final Auth? auth;
  final LogPipeline? logger;

  NContext({this.auth, this.logger});

  static NContext? get current {
    return Zone.current[key];
  }

  static final key = #needleServerContext;
}

class Auth {
  final User? user;
  final List<String> permissions;

  Auth(this.user, {this.permissions = const []});
}
