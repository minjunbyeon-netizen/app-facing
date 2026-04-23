class AppException implements Exception {
  final String messageKo;
  final String? code;
  final int? statusCode;

  AppException(this.messageKo, {this.code, this.statusCode});

  @override
  String toString() => 'AppException($code): $messageKo';
}
