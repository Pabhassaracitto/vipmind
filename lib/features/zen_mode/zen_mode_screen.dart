import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../core/services/storage_service.dart';
import '../../data/providers/audio_provider.dart';

/// Distraction-free focus mode: dark screen, one thought at a time,
/// optional ambient sound and a countdown taken from Settings.
///
/// Works fully offline (SharedPreferences + bundled audio assets).
class ZenModeScreen extends StatefulWidget {
  const ZenModeScreen({super.key});

  @override
  State<ZenModeScreen> createState() => _ZenModeScreenState();
}

class _ZenModeScreenState extends State<ZenModeScreen> {
  static const String _storageKeyFocusMinutes = 'settings_focus_minutes';
  static const String _storageKeyIdeas = 'zen_captured_ideas';

  final TextEditingController _ideaController = TextEditingController();
  final List<String> _ideas = [];

  Timer? _ticker;
  int _remainingSeconds = 0;
  int _totalSeconds = 0;
  bool _isRunning = false;

  /// False until the first Start. Without it a fresh session offered "Resume"
  /// (there is time left on the clock but nothing has run yet).
  bool _hasStarted = false;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final minutes = StorageService.getInt(_storageKeyFocusMinutes) ?? 25;
    setState(() {
      _totalSeconds = minutes * 60;
      _remainingSeconds = _totalSeconds;
      _ideas.addAll(_readIdeas());
    });
  }

  List<String> _readIdeas() {
    final raw = StorageService.getStringList(_storageKeyIdeas) ?? const [];
    return List<String>.from(raw);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ideaController.dispose();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _ticker?.cancel();
      setState(() => _isRunning = false);
      return;
    }

    if (_remainingSeconds <= 0) {
      setState(() => _remainingSeconds = _totalSeconds);
    }

    setState(() {
      _isRunning = true;
      _hasStarted = true;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _remainingSeconds--);
      if (_remainingSeconds <= 0) {
        timer.cancel();
        setState(() {
          _isRunning = false;
          _remainingSeconds = 0;
        });
        context.read<AudioProvider>().stopAmbient();
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  Future<void> _captureIdea() async {
    final text = _ideaController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _ideas.insert(0, text);
      _ideaController.clear();
    });
    await StorageService.setStringList(_storageKeyIdeas, _ideas);
    // The await above is a real gap: the widget can be gone by the time the
    // write finishes, and using `context` after that is undefined behaviour.
    if (!mounted) return;
    context.read<AudioProvider>().playClickIfEnabled();
  }

  String get _clock {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: _isFullscreen
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              foregroundColor: AppColors.textLight,
              elevation: 0,
              title: const Text('Zen Mode'),
              actions: [
                IconButton(
                  tooltip: audioProvider.isAmbientPlaying
                      ? 'Stop ambient sound'
                      : 'Play ambient sound',
                  icon: Icon(
                    audioProvider.isAmbientPlaying
                        ? Icons.graphic_eq_rounded
                        : Icons.music_off_rounded,
                  ),
                  onPressed: () => audioProvider.toggleAmbient(),
                ),
                IconButton(
                  tooltip: 'Fullscreen',
                  icon: const Icon(Icons.fullscreen_rounded),
                  onPressed: _toggleFullscreen,
                ),
              ],
            ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              _clock,
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w200,
                letterSpacing: 4,
                color: AppColors.textLight,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _toggleTimer,
              icon: Icon(
                _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: AppColors.calmGreen,
              ),
              label: Text(
                _isRunning ? 'Pause' : (_hasStarted ? 'Resume' : 'Start'),
                style: const TextStyle(color: AppColors.calmGreen),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _ideaController,
                style: const TextStyle(color: AppColors.textLight),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _captureIdea(),
                decoration: InputDecoration(
                  hintText: 'Capture one thought, press enter…',
                  hintStyle:
                      const TextStyle(color: AppColors.textLightSecondary),
                  filled: true,
                  fillColor: AppColors.surfaceDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_rounded,
                        color: AppColors.primaryBlueLight),
                    onPressed: _captureIdea,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _ideas.isEmpty
                  ? const Center(
                      child: Text(
                        'Nothing captured yet',
                        style: TextStyle(color: AppColors.textLightSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      itemCount: _ideas.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.bolt_rounded,
                                size: 18, color: AppColors.accentYellow),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _ideas[index],
                                style: const TextStyle(
                                    color: AppColors.textLight, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
