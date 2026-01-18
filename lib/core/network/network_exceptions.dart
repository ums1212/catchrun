class NoNetworkException implements Exception {
  final String message;
  NoNetworkException([this.message = '인터넷 연결이 필요합니다.']);

  @override
  String toString() => message;
}
