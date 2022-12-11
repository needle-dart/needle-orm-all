import 'dart:convert';
import 'dart:io';

import 'package:minerva/minerva.dart';
import 'package:needle_orm/needle_orm.dart';

class ServiceMiddleware extends Middleware {
  final bool trace;
  late ServerContext serverContext;
  ServiceMiddleware({this.trace = true});

  @override
  void initialize(ServerContext context) {
    serverContext = context;
  }

  @override
  Future<dynamic> handle(
      MiddlewareContext context, MiddlewarePipelineNode? next) async {
    if (next == null) {
      return NotFoundResult();
    }

    var result = await next.handle(context);
    if (result is Model) {
      return JsonResult(result.toMap());
    } else if (result is List) {
      var jsonHeader = MinervaHttpHeaders()..contentType = ContentType.json;
      if (result.isNotEmpty &&
          result.whereType<Model>().length == result.length) {
        var body = result.map((e) => (e as Model).toMap()).toList();
        return OkResult(body: jsonEncode(body), headers: jsonHeader);
      } else if (result is List<Map>) {
        return OkResult(body: jsonEncode(result), headers: jsonHeader);
      }
    }
    return result;
  }
}

class TimingMiddleware extends Middleware {
  late ServerContext serverContext;

  @override
  void initialize(ServerContext context) {
    serverContext = context;
  }

  @override
  Future<dynamic> handle(
      MiddlewareContext context, MiddlewarePipelineNode? next) async {
    if (next == null) {
      return NotFoundResult();
    }

    var timeStart = DateTime.now();
    var result = await next.handle(context);
    serverContext.logPipeline.info(
        'time used [${DateTime.now().difference(timeStart).inMilliseconds} ms] , uri: ${context.request.uri} ');
    return result;
  }
}
