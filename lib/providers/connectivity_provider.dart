import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityProvider extends ChangeNotifier {
  bool _hasInternet = true;

  bool get hasInternet => _hasInternet;

  final Connectivity _connectivity = Connectivity();

  ConnectivityProvider() {
    _listen();
  }

  Future<void> _listen() async {
    final result = await _connectivity.checkConnectivity();

    _update(result);

    _connectivity.onConnectivityChanged.listen(_update);
  }

  void _update(List<ConnectivityResult> results) {
    final connected =
        results.isNotEmpty &&
        !results.contains(ConnectivityResult.none);

    if (_hasInternet != connected) {
      _hasInternet = connected;
      notifyListeners();
    }
  }
}