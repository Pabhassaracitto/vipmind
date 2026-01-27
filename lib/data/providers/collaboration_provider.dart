import 'package:flutter/material.dart';

class CollaborationProvider extends ChangeNotifier {
  List<String> _activeUsers = [];
  final Map<String, Offset> _userCursors = {};
  bool _isConnected = false;

  List<String> get activeUsers => _activeUsers;
  Map<String, Offset> get userCursors => _userCursors;
  bool get isConnected => _isConnected;

  void setConnected(bool value) {
    _isConnected = value;
    notifyListeners();
  }

  void updateUsers(List<String> users) {
    _activeUsers = users;
    notifyListeners();
  }

  void updateCursor(String userId, Offset position) {
    _userCursors[userId] = position;
    notifyListeners();
  }

  void removeCursor(String userId) {
    _userCursors.remove(userId);
    notifyListeners();
  }

  void clearAll() {
    _activeUsers.clear();
    _userCursors.clear();
    _isConnected = false;
    notifyListeners();
  }
}
