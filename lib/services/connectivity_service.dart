import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Stream<bool> get connectivityStream => _connectivity.onConnectivityChanged
      .map((results) => results.any(_isOnline));

  Future<bool> isOnline() async {
    var results = await _connectivity.checkConnectivity();
    return results.any(_isOnline);
  }

  bool _isOnline(ConnectivityResult result) {
    return result != ConnectivityResult.none;
  }
}
