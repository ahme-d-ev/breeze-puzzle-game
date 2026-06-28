import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _highScoreKey = 'high_score';
  static const String _journeyHighestUnlockedKey = 'journey_highest_unlocked';
  static const String _coinBalanceKey = 'coin_balance';
  static const String _ownedThemeIdsKey = 'owned_theme_ids';
  static const String _selectedThemeIdKey = 'selected_theme_id';
  static const String _musicEnabledKey = 'music_enabled';
  static const String _soundEffectsEnabledKey = 'sound_effects_enabled';
  static const String _vibrationEnabledKey = 'vibration_enabled';

  Future<void> saveBestScore(int score) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int currentBest = prefs.getInt(_highScoreKey) ?? 0;
    if (score > currentBest) {
      await prefs.setInt(_highScoreKey, score);
    }
  }

  Future<int> getBestScore() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_highScoreKey) ?? 0;
  }

  Future<void> saveJourneyHighestUnlockedLevel(int levelNumber) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int currentHighest = prefs.getInt(_journeyHighestUnlockedKey) ?? 1;
    if (levelNumber > currentHighest) {
      await prefs.setInt(_journeyHighestUnlockedKey, levelNumber);
    }
  }

  Future<int> getJourneyHighestUnlockedLevel() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_journeyHighestUnlockedKey) ?? 1;
  }

  Future<int> getCoinBalance() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_coinBalanceKey) ?? 0;
  }

  Future<void> setCoinBalance(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_coinBalanceKey, value.clamp(0, 99999999));
  }

  Future<int> addCoins(int delta) async {
    final int current = await getCoinBalance();
    final int next = (current + delta).clamp(0, 99999999);
    await setCoinBalance(next);
    return next;
  }

  static Future<List<String>> getOwnedThemeIds() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? ids = prefs.getStringList(_ownedThemeIdsKey);
    if (ids == null || ids.isEmpty) {
      return <String>['classic'];
    }
    if (!ids.contains('classic')) {
      return <String>['classic', ...ids];
    }
    return ids;
  }

  static Future<void> setOwnedThemeIds(List<String> ids) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> normalized = <String>{'classic', ...ids}.toList();
    await prefs.setStringList(_ownedThemeIdsKey, normalized);
  }

  static Future<String> getSelectedThemeId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return (prefs.getString(_selectedThemeIdKey)) ?? 'classic';
  }

  static Future<void> setSelectedThemeId(String themeId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedThemeIdKey, themeId);
  }

  Future<bool> isMusicEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_musicEnabledKey) ?? true;
  }

  Future<void> setMusicEnabled(bool enabled) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicEnabledKey, enabled);
  }

  Future<bool> isSoundEffectsEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundEffectsEnabledKey) ?? true;
  }

  Future<void> setSoundEffectsEnabled(bool enabled) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEffectsEnabledKey, enabled);
  }

  Future<bool> isVibrationEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vibrationEnabledKey) ?? false;
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationEnabledKey, enabled);
  }
}
