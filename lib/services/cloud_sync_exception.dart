class CloudSyncException implements Exception {
  const CloudSyncException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
