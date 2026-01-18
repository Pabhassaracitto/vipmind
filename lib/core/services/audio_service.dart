import 'package:just_audio/just_audio.dart';

class AudioService {
  static final AudioPlayer _player = AudioPlayer();
  static final AudioPlayer _ambientPlayer = AudioPlayer();
  static bool _isAmbientPlaying = false;

  // Sound Effects
  static Future<void> playClick() async {
    try {
      await _player.setAsset('assets/audio/click.mp3');
      await _player.play();
    } catch (e) {
      // Silent fail - audio is optional
    }
  }

  static Future<void> playSuccess() async {
    try {
      await _player.setAsset('assets/audio/success.mp3');
      await _player.play();
    } catch (e) {
      // Silent fail
    }
  }

  static Future<void> playNodeCreate() async {
    try {
      await _player.setAsset('assets/audio/click.mp3');
      await _player.play();
    } catch (e) {
      // Silent fail
    }
  }

  static Future<void> playUndo() async {
    try {
      await _player.setAsset('assets/audio/click.mp3');
      await _player.play();
    } catch (e) {
      // Silent fail
    }
  }

  static Future<void> playRedo() async {
    try {
      await _player.setAsset('assets/audio/click.mp3');
      await _player.play();
    } catch (e) {
      // Silent fail
    }
  }

  static Future<void> playLayoutChange() async {
    try {
      await _player.setAsset('assets/audio/success.mp3');
      await _player.play();
    } catch (e) {
      // Silent fail
    }
  }

  // Ambient Sounds
  static Future<void> playAmbient(String type) async {
    try {
      String assetPath;
      switch (type) {
        case 'rain':
          assetPath = 'assets/audio/ambient_rain.mp3';
          break;
        case 'forest':
          assetPath = 'assets/audio/ambient_forest.mp3';
          break;
        case 'cafe':
          assetPath = 'assets/audio/ambient_cafe.mp3';
          break;
        default:
          assetPath = 'assets/audio/ambient_forest.mp3';
      }

      await _ambientPlayer.setAsset(assetPath);
      await _ambientPlayer.setLoopMode(LoopMode.one);
      await _ambientPlayer.play();
      _isAmbientPlaying = true;
    } catch (e) {
      // Silent fail
    }
  }

  static Future<void> stopAmbient() async {
    try {
      await _ambientPlayer.stop();
      _isAmbientPlaying = false;
    } catch (e) {
      // Silent fail
    }
  }

  static Future<void> toggleAmbient() async {
    if (_isAmbientPlaying) {
      await stopAmbient();
    } else {
      await playAmbient('forest');
    }
  }

  static bool get isAmbientPlaying => _isAmbientPlaying;

  static void dispose() {
    _player.dispose();
    _ambientPlayer.dispose();
  }
}