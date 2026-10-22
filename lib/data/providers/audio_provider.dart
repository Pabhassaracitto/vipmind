import 'package:flutter/material.dart';
import '../../core/services/audio_service.dart';

class AudioProvider extends ChangeNotifier {
  String _currentAmbient = 'none';
  bool _isSoundEnabled = true;

  String get currentAmbient => _currentAmbient;
  bool get isSoundEnabled => _isSoundEnabled;
  bool get isAmbientPlaying => AudioService.isAmbientPlaying;

  /// Starts an ambient loop. `'none'` (or an empty value) stops it, so callers
  /// never have to special-case the "off" option.
  void playAmbient(String type) {
    if (type.isEmpty || type == 'none') {
      stopAmbient();
      return;
    }
    _currentAmbient = type;
    AudioService.playAmbient(type);
    notifyListeners();
  }

  void stopAmbient() {
    _currentAmbient = 'none';
    AudioService.stopAmbient();
    notifyListeners();
  }

  void toggleAmbient() {
    AudioService.toggleAmbient();
    _currentAmbient = AudioService.isAmbientPlaying ? 'forest' : 'none';
    notifyListeners();
  }

  void toggleSound() {
    _isSoundEnabled = !_isSoundEnabled;
    notifyListeners();
  }

  void playClickIfEnabled() {
    if (_isSoundEnabled) {
      AudioService.playClick();
    }
  }
}