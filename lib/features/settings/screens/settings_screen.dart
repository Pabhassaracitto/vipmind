import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../../../data/providers/audio_provider.dart';
import '../../../data/providers/theme_provider.dart';

/// App settings. Real (small) functionality — no placeholder.
///
/// Everything here is backed by providers/SharedPreferences that already exist,
/// so the screen works offline and without Firebase.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const String _storageKeyFocusTimer = 'settings_focus_minutes';

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final audioProvider = context.watch<AudioProvider>();
    final focusMinutes = StorageService.getInt(_storageKeyFocusTimer) ?? 25;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const _SectionHeader(title: 'Appearance'),
          ListTile(
            leading: const Icon(Icons.dark_mode_rounded),
            title: const Text('Theme'),
            subtitle: Text(_themeLabel(themeProvider.themeMode)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _pickTheme(context, themeProvider),
          ),
          const Divider(height: 1),
          const _SectionHeader(title: 'Sound'),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up_rounded),
            title: const Text('Interface sounds'),
            subtitle: const Text('Click and success feedback in the editor'),
            value: audioProvider.isSoundEnabled,
            onChanged: (_) => audioProvider.toggleSound(),
          ),
          ListTile(
            leading: const Icon(Icons.forest_rounded),
            title: const Text('Ambient sound'),
            subtitle: Text(
              audioProvider.isAmbientPlaying
                  ? 'Playing: ${audioProvider.currentAmbient}'
                  : 'Off',
            ),
            trailing: Icon(
              audioProvider.isAmbientPlaying
                  ? Icons.stop_circle_rounded
                  : Icons.play_circle_outline_rounded,
              color: AppColors.primaryBlue,
            ),
            onTap: () => _pickAmbient(context, audioProvider),
          ),
          const Divider(height: 1),
          const _SectionHeader(title: 'Focus'),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Focus session length'),
            subtitle: Text('$focusMinutes minutes (used by Zen Mode)'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _pickFocusMinutes(context),
          ),
          const Divider(height: 1),
          const _SectionHeader(title: 'About'),
          const ListTile(
            leading: Icon(Icons.psychology_rounded),
            title: Text('VipMind'),
            subtitle: Text('Your Brain, Amplified. — version 0.1.0'),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('Feature status'),
            subtitle: Text(
              'Mindmap editor: in progress · AI, Anki, Presentation, Export: '
              'not implemented yet',
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'Follow system';
    }
  }

  Future<void> _pickTheme(
    BuildContext context,
    ThemeProvider provider,
  ) async {
    final mode = await showModalBottomSheet<ThemeMode>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in ThemeMode.values)
              ListTile(
                leading: Icon(_themeIcon(option)),
                title: Text(_themeLabel(option)),
                trailing: provider.themeMode == option
                    ? const Icon(Icons.check_rounded,
                        color: AppColors.primaryBlue)
                    : null,
                onTap: () => Navigator.pop(sheetContext, option),
              ),
          ],
        ),
      ),
    );
    if (mode != null) provider.setThemeMode(mode);
  }

  static IconData _themeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode_rounded;
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
      case ThemeMode.system:
        return Icons.brightness_auto_rounded;
    }
  }

  Future<void> _pickAmbient(
    BuildContext context,
    AudioProvider provider,
  ) async {
    const options = <String, String>{
      'none': 'Stop ambient sound',
      'rain': 'Rain',
      'forest': 'Forest',
      'cafe': 'Café',
    };

    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in options.entries)
              ListTile(
                leading: Icon(entry.key == 'none'
                    ? Icons.stop_rounded
                    : Icons.graphic_eq_rounded),
                title: Text(entry.value),
                onTap: () => Navigator.pop(sheetContext, entry.key),
              ),
          ],
        ),
      ),
    );

    if (choice == null) return;
    if (choice == 'none') {
      provider.stopAmbient();
    } else {
      provider.playAmbient(choice);
    }
  }

  Future<void> _pickFocusMinutes(BuildContext context) async {
    final minutes = await showModalBottomSheet<int>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final value in const [15, 25, 45, 60, 90])
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: Text('$value minutes'),
                onTap: () => Navigator.pop(sheetContext, value),
              ),
          ],
        ),
      ),
    );

    if (minutes != null) {
      await StorageService.setInt(_storageKeyFocusTimer, minutes);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Focus session set to $minutes minutes')),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }
}
