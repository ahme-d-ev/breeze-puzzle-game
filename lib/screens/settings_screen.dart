import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/game_audio_service.dart';
import '../services/storage_service.dart';
import '../services/theme_manager.dart';
import '../widgets/app_background.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService = StorageService();
  final GameAudioService _audioService = GameAudioService();

  bool _musicEnabled = true;
  bool _soundEffectsEnabled = true;
  bool _vibrationEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final bool musicEnabled = await _storageService.isMusicEnabled();
    final bool soundEffectsEnabled = await _storageService
        .isSoundEffectsEnabled();
    final bool vibrationEnabled = await _storageService.isVibrationEnabled();
    if (!mounted) {
      return;
    }

    setState(() {
      _musicEnabled = musicEnabled;
      _soundEffectsEnabled = soundEffectsEnabled;
      _vibrationEnabled = vibrationEnabled;
      _isLoading = false;
    });
  }

  Future<void> _setMusicEnabled(bool value) async {
    await _storageService.setMusicEnabled(value);
    if (!mounted) {
      return;
    }
    setState(() {
      _musicEnabled = value;
    });
  }

  Future<void> _setSoundEffectsEnabled(bool value) async {
    await _storageService.setSoundEffectsEnabled(value);
    if (!mounted) {
      return;
    }
    setState(() {
      _soundEffectsEnabled = value;
    });
    if (value) {
      await _audioService.playPlaceSound();
    }
  }

  Future<void> _setVibrationEnabled(bool value) async {
    await _storageService.setVibrationEnabled(value);
    if (!mounted) {
      return;
    }
    setState(() {
      _vibrationEnabled = value;
    });
  }

  Color _readableOn(Color bg) {
    return bg.computeLuminance() > 0.48
        ? const Color(0xFF10233F)
        : const Color(0xFFF3F8FF);
  }

  @override
  Widget build(BuildContext context) {
    final activeTheme = context.watch<ThemeManager>().activeTheme;
    final Color primaryText = _readableOn(activeTheme.panelColor);
    final Color secondaryText = primaryText.withValues(alpha: 0.84);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(color: primaryText)),
        iconTheme: IconThemeData(color: primaryText),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: GamePanel(
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SwitchListTile.adaptive(
                              value: _musicEnabled,
                              onChanged: _setMusicEnabled,
                              activeThumbColor:
                                  activeTheme.selectedBlockBorderColor,
                              activeTrackColor: activeTheme.boardBorderColor,
                              secondary: Icon(
                                Icons.music_note,
                                color: primaryText,
                              ),
                              title: Text(
                                'Music',
                                style: TextStyle(color: primaryText),
                              ),
                            ),
                            Divider(color: activeTheme.boardGridLineColor),
                            SwitchListTile.adaptive(
                              value: _soundEffectsEnabled,
                              onChanged: _setSoundEffectsEnabled,
                              activeThumbColor:
                                  activeTheme.selectedBlockBorderColor,
                              activeTrackColor: activeTheme.boardBorderColor,
                              secondary: Icon(
                                Icons.volume_up,
                                color: primaryText,
                              ),
                              title: Text(
                                'Sound Effects',
                                style: TextStyle(color: primaryText),
                              ),
                            ),
                            Divider(color: activeTheme.boardGridLineColor),
                            SwitchListTile.adaptive(
                              value: _vibrationEnabled,
                              onChanged: _setVibrationEnabled,
                              activeThumbColor:
                                  activeTheme.selectedBlockBorderColor,
                              activeTrackColor: activeTheme.boardBorderColor,
                              secondary: Icon(
                                Icons.vibration,
                                color: primaryText,
                              ),
                              title: Text(
                                'Vibration',
                                style: TextStyle(color: primaryText),
                              ),
                            ),
                            if (!_musicEnabled || !_soundEffectsEnabled)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  'Some audio features are currently disabled.',
                                  style: TextStyle(
                                    color: secondaryText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
