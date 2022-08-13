import 'package:h_ide/enum/lsp_response_type.dart';

abstract class LSPResponse {
  LSPResponse(this.type);
  final LSPResponseType type;

  factory LSPResponse.fromMap(dynamic map) {
    final data = Map<String, dynamic>.from(map);
    final event = data["event"];
    if (event == null) {
      return Response.fromMap(data);
    }
    return Notification.fromMap(data);
  }

  Map<String, dynamic> toMap();
}

class Response extends LSPResponse {
  Response({
    required this.id,
    required this.error,
    required this.result,
  }) : super(LSPResponseType.response);
  final String id;
  final dynamic error;
  final dynamic result;

  factory Response.fromMap(dynamic map) {
    final data = Map<String, dynamic>.from(map);
    return Response(
      id: data["id"],
      error: data["error"],
      result: data["result"],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "error": error,
      "result": result,
    };
  }
}

class Notification extends LSPResponse {
  Notification({
    required this.event,
    required this.params,
  }) : super(LSPResponseType.notification);
  final String event;
  final dynamic params;

  factory Notification.fromMap(dynamic map) {
    final data = Map<String, dynamic>.from(map);
    return Notification(
      event: data["event"],
      params: data["params"],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      "event": event,
      "params": params,
    };
  }
}
