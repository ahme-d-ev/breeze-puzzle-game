import 'package:flutter/foundation.dart';

import '../data/level_catalog.dart';
import '../game/game_engine.dart';
import '../models/level_model.dart';
import 'storage_service.dart';

class LevelManager extends ChangeNotifier {
  LevelManager(this._storageService);

  final StorageService _storageService;
  final List<LevelModel> levels = LevelCatalog.allLevels;
  int _highestUnlockedLevelNumber = 1;

  int get highestUnlockedLevelNumber => _highestUnlockedLevelNumber;

  Future<void> loadProgress() async {
    _highestUnlockedLevelNumber = await _storageService
        .getJourneyHighestUnlockedLevel();
    notifyListeners();
  }

  bool isUnlocked(LevelModel level) {
    return level.number <= _highestUnlockedLevelNumber;
  }

  LevelModel getLevel(int levelNumber) {
    return LevelCatalog.getByNumber(levelNumber);
  }

  bool canStart(LevelModel level) {
    return isUnlocked(level);
  }

  String objectiveLabel(LevelModel level) {
    return level.objective.label;
  }

  String progressLabel(LevelModel level, GameEngine engine) {
    return switch (level.objective.type) {
      LevelObjectiveType.score =>
        '${engine.score}/${level.objective.targetValue}',
      LevelObjectiveType.clearLines =>
        '${engine.totalClearedLines}/${level.objective.targetValue}',
      LevelObjectiveType.destroyIceBlocks =>
        '${engine.totalDestroyedIceBlocks}/${level.objective.targetValue}',
    };
  }

  bool isLevelComplete(LevelModel level, GameEngine engine) {
    return switch (level.objective.type) {
      LevelObjectiveType.score => engine.score >= level.objective.targetValue,
      LevelObjectiveType.clearLines =>
        engine.totalClearedLines >= level.objective.targetValue,
      LevelObjectiveType.destroyIceBlocks =>
        engine.totalDestroyedIceBlocks >= level.objective.targetValue,
    };
  }

  Future<void> completeLevel(LevelModel level) async {
    final int nextLevel = level.number + 1;
    if (nextLevel > _highestUnlockedLevelNumber && nextLevel <= levels.length) {
      _highestUnlockedLevelNumber = nextLevel;
      await _storageService.saveJourneyHighestUnlockedLevel(
        _highestUnlockedLevelNumber,
      );
      notifyListeners();
      return;
    }

    await _storageService.saveJourneyHighestUnlockedLevel(
      _highestUnlockedLevelNumber,
    );
  }
}
