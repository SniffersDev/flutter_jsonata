class JsonataResult {
  final dynamic data;
  final JsonataError? error;

  JsonataResult.success(this.data) : error = null;
  JsonataResult.error(dynamic error)
      : data = null,
        error = (error is JsonataError)
            ? error
            : JsonataError('Evaluation failed', error);

  bool get isSuccess => error == null;
  bool get isError => error != null;
}

class JsonataError implements Exception {
  final String message;
  final dynamic cause;
  final String? code;
  final int? position;
  final String? token;

  JsonataError(
    this.message, [
    this.cause,
    this.code,
    this.position,
    this.token,
  ]);

  @override
  String toString() => 'JsonataError: $message';
}
