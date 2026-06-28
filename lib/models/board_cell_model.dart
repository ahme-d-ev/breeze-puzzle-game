import 'package:flutter/material.dart';

import 'block_model.dart';

class BoardCellModel {
  const BoardCellModel({
    required this.color,
    this.specialType = SpecialBlockType.none,
    this.bombCountdown = 0,
    this.iceHitsRemaining = 1,
  });

  final Color color;
  final SpecialBlockType specialType;
  final int bombCountdown;
  final int iceHitsRemaining;

  bool get isBomb => specialType == SpecialBlockType.bomb;

  bool get isIce => specialType == SpecialBlockType.ice;

  bool get isMagnet => specialType == SpecialBlockType.magnet;

  BoardCellModel copyWith({
    Color? color,
    SpecialBlockType? specialType,
    int? bombCountdown,
    int? iceHitsRemaining,
  }) {
    return BoardCellModel(
      color: color ?? this.color,
      specialType: specialType ?? this.specialType,
      bombCountdown: bombCountdown ?? this.bombCountdown,
      iceHitsRemaining: iceHitsRemaining ?? this.iceHitsRemaining,
    );
  }

  BoardCellModel tickBomb() {
    return copyWith(bombCountdown: bombCountdown - 1);
  }

  BoardCellModel weakenIce() {
    return copyWith(iceHitsRemaining: iceHitsRemaining - 1);
  }
}
