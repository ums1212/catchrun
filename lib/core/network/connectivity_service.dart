import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'network_exceptions.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService(Connectivity());
});

final connectivityStateProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return ref.watch(connectivityServiceProvider).onConnectivityChanged;
});

class ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityService(this._connectivity);

  Stream<List<ConnectivityResult>> get onConnectivityChanged => _connectivity.onConnectivityChanged;

  Future<bool> isConnected() async {
    final results = await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  Future<void> ensureConnection() async {
    final results = await _connectivity.checkConnectivity();
    if (!_hasConnection(results)) {
      throw NoNetworkException('인터넷 연결이 끊켰습니다.');
    }
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    // none만 포함되어 있고 다른 연결이 없다면 연결 끊김으로 간주
    if (results.length == 1 && results.first == ConnectivityResult.none) {
      return false;
    }
    // 하나라도 none이 아닌 다른 연결이 있다면 연결된 것으로 간주
    return results.any((r) => r != ConnectivityResult.none);
  }
}
