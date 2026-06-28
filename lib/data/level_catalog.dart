import '../models/block_model.dart';
import '../models/level_model.dart';

class LevelCatalog {
  LevelCatalog._();

  static final List<LevelModel> allLevels = List<LevelModel>.unmodifiable(
    List<LevelModel>.generate(50, (int index) {
      final int levelNumber = index + 1;
      if (levelNumber <= 15) {
        final int targetScore = 600 + (index * 120);
        return LevelModel(
          number: levelNumber,
          title: 'Score Sprint ${levelNumber.toString().padLeft(2, '0')}',
          objective: LevelObjective(
            type: LevelObjectiveType.score,
            targetValue: targetScore,
          ),
          rewardCoins: 25 + (index * 3),
          generationProfile: const BlockGenerationProfile(
            specialChance: 0.18,
            bombChance: 0.42,
            iceChance: 0.28,
            magnetChance: 0.30,
          ),
        );
      }

      if (levelNumber <= 30) {
        final int targetLines = 3 + (index - 15);
        return LevelModel(
          number: levelNumber,
          title: 'Line Breaker ${levelNumber.toString().padLeft(2, '0')}',
          objective: LevelObjective(
            type: LevelObjectiveType.clearLines,
            targetValue: targetLines,
          ),
          rewardCoins: 35 + ((index - 15) * 3),
          generationProfile: const BlockGenerationProfile(
            specialChance: 0.22,
            bombChance: 0.36,
            iceChance: 0.34,
            magnetChance: 0.30,
          ),
        );
      }

      final int targetIceBlocks = 4 + (index - 30);
      return LevelModel(
        number: levelNumber,
        title: 'Ice Hunt ${levelNumber.toString().padLeft(2, '0')}',
        objective: LevelObjective(
          type: LevelObjectiveType.destroyIceBlocks,
          targetValue: targetIceBlocks,
        ),
        rewardCoins: 45 + ((index - 30) * 4),
        generationProfile: const BlockGenerationProfile(
          specialChance: 0.36,
          bombChance: 0.18,
          iceChance: 0.62,
          magnetChance: 0.20,
        ),
      );
    }),
  );

  static LevelModel getByNumber(int levelNumber) {
    return allLevels[levelNumber - 1];
  }
}
