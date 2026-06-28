import 'package:flutter/foundation.dart';

import '../models/game_theme_model.dart';
import 'storage_service.dart';

class PurchaseResult {
  const PurchaseResult({
    required this.success,
    required this.message,
    required this.remainingCoins,
  });

  final bool success;
  final String message;
  final int remainingCoins;
}

class ThemeManager extends ChangeNotifier {
  ThemeManager({StorageService? storageService})
    : _storageService = storageService ?? StorageService();

  final StorageService _storageService;

  GameThemeModel _activeTheme = GameThemeCatalog.classic;
  Set<String> _ownedThemeIds = <String>{'classic'};
  int _coins = 0;
  bool _isLoaded = false;

  GameThemeModel get activeTheme => _activeTheme;
  int get coins => _coins;
  bool get isLoaded => _isLoaded;
  List<GameThemeModel> get allThemes => GameThemeCatalog.allThemes;

  bool isOwned(String themeId) => _ownedThemeIds.contains(themeId);

  Future<void> load() async {
    _coins = await _storageService.getCoinBalance();
    _ownedThemeIds = (await StorageService.getOwnedThemeIds()).toSet();
    final String selectedId = await StorageService.getSelectedThemeId();

    if (!_ownedThemeIds.contains(selectedId)) {
      _activeTheme = GameThemeCatalog.classic;
      await StorageService.setSelectedThemeId(_activeTheme.id);
    } else {
      _activeTheme = GameThemeCatalog.byId(selectedId);
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> refreshCoins() async {
    _coins = await _storageService.getCoinBalance();
    notifyListeners();
  }

  Future<void> selectTheme(String themeId) async {
    if (!_ownedThemeIds.contains(themeId)) {
      return;
    }

    final GameThemeModel next = GameThemeCatalog.byId(themeId);
    if (next.id == _activeTheme.id) {
      return;
    }

    _activeTheme = next;
    await StorageService.setSelectedThemeId(themeId);
    notifyListeners();
  }

  Future<void> previewTheme(String themeId) async {
    final GameThemeModel next = GameThemeCatalog.byId(themeId);
    if (next.id == _activeTheme.id) {
      return;
    }

    _activeTheme = next;
    notifyListeners();
  }

  Future<PurchaseResult> purchaseTheme(String themeId) async {
    final GameThemeModel theme = GameThemeCatalog.byId(themeId);

    if (_ownedThemeIds.contains(themeId)) {
      return PurchaseResult(
        success: false,
        message: 'Theme already owned',
        remainingCoins: _coins,
      );
    }

    if (_coins < theme.price) {
      return PurchaseResult(
        success: false,
        message: 'Not enough coins',
        remainingCoins: _coins,
      );
    }

    _coins = await _storageService.addCoins(-theme.price);
    _ownedThemeIds = <String>{..._ownedThemeIds, themeId};
    await StorageService.setOwnedThemeIds(_ownedThemeIds.toList());

    _activeTheme = theme;
    await StorageService.setSelectedThemeId(themeId);

    notifyListeners();

    return PurchaseResult(
      success: true,
      message: '${theme.name} unlocked and equipped!',
      remainingCoins: _coins,
    );
  }
}
