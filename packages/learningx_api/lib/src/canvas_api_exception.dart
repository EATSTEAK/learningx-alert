import 'package:dio/dio.dart';

class CanvasApiException implements Exception {
  const CanvasApiException(this.message, {this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final Object? details;

  factory CanvasApiException.fromDio(DioException error) {
    final response = error.response;
    if (response == null) {
      return CanvasApiException(
        error.message ?? 'Network request failed.',
        details: error.error,
      );
    }

    return CanvasApiException(
      _messageFromBody(response.data) ?? 'Canvas API returned ${response.statusCode}.',
      statusCode: response.statusCode,
      details: response.data,
    );
  }

  static String? _messageFromBody(Object? body) {
    if (body is Map<String, dynamic>) {
      final message = body['message'] ?? body['error'] ?? body['error_description'];
      if (message is String && message.isNotEmpty) return message;
    }
    if (body is List && body.isNotEmpty) {
      final first = body.first;
      if (first is Map<String, dynamic>) {
        final message = first['message'] ?? first['error'];
        if (message is String && message.isNotEmpty) return message;
      }
    }
    return null;
  }

  @override
  String toString() {
    final status = statusCode == null ? '' : ' ($statusCode)';
    return 'CanvasApiException$status: $message';
  }
}
