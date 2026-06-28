import '../models/block_model.dart';

enum LevelObjectiveType { score, clearLines, destroyIceBlocks }

class LevelObjective {
  const LevelObjective({required this.type, required this.targetValue});

  final LevelObjectiveType type;
  final int targetValue;

  String get label {
    return switch (type) {
      LevelObjectiveType.score => 'Reach $targetValue points',
      LevelObjectiveType.clearLines => 'Clear $targetValue lines',
      LevelObjectiveType.destroyIceBlocks => 'Destroy $targetValue ice blocks',
    };
  }
}

class LevelModel {
  const LevelModel({
    required this.number,
    required this.title,
    required this.objective,
    required this.rewardCoins,
    required this.generationProfile,
  });

  final int number;
  final String title;
  final LevelObjective objective;
  final int rewardCoins;
  final BlockGenerationProfile generationProfile;

  String get subtitle => 'Reward: $rewardCoins coins';
}
