import 'package:flutter/foundation.dart';

class NavBarVisibilityProvider extends ChangeNotifier {
  bool _hidden = false;
  bool get hidden => _hidden;

  void setHidden(bool value) {
    if (_hidden == value) return;
    _hidden = value;
    notifyListeners();
  }
}