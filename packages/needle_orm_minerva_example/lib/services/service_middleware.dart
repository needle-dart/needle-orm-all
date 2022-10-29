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

    var timeStart = DateTime.now();
    var result = await next.handle(context);
    serverContext.logPipeline.info(
        'time used [${DateTime.now().difference(timeStart).inMilliseconds} ms] , uri: ${context.request.uri} ');
    if (result is Model) {
      return JsonResult(result.toMap());
    } else if (result is List) {
      if (result.isNotEmpty &&
          result.whereType<Model>().length == result.length) {
        var body = result.map((e) => (e as Model).toMap()).toList();
        var jsonHeader = MinervaHttpHeaders()..contentType = ContentType.json;
        return OkResult(body: jsonEncode(body), headers: jsonHeader);
      }
    }
    return result;
  }
}
