import 'dart:math';

import 'package:flutter/material.dart';

enum BlockType { square, line, lShape, tShape }

enum SpecialBlockType { none, bomb, ice, magnet }

class BlockGenerationProfile {
  const BlockGenerationProfile({
    this.specialChance = 0.24,
    this.bombChance = 0.34,
    this.iceChance = 0.33,
    this.magnetChance = 0.33,
  });

  final double specialChance;
  final double bombChance;
  final double iceChance;
  final double magnetChance;

  static const BlockGenerationProfile defaultProfile = BlockGenerationProfile();
}

class BlockModel {
  BlockModel({
    required this.type,
    required this.cells,
    required this.color,
    this.specialType = SpecialBlockType.none,
    this.bombCountdown = 0,
    this.iceDurability = 1,
  });

  final BlockType type;
  final List<List<int>> cells;
  final Color color;
  final SpecialBlockType specialType;
  final int bombCountdown;
  final int iceDurability;

  BlockModel rotatedClockwise() {
    return BlockModel(
      type: type,
      cells: rotateCellsClockwise(cells),
      color: color,
      specialType: specialType,
      bombCountdown: bombCountdown,
      iceDurability: iceDurability,
    );
  }

  static final Random _random = Random();

  static final List<BlockModel> _templates = <BlockModel>[
    BlockModel(
      type: BlockType.square,
      cells: const <List<int>>[
        <int>[1, 1],
        <int>[1, 1],
      ],
      color: const Color(0xFFFFA726),
    ),
    BlockModel(
      type: BlockType.line,
      cells: const <List<int>>[
        <int>[1, 1, 1, 1],
      ],
      color: const Color(0xFF4FC3F7),
    ),
    BlockModel(
      type: BlockType.lShape,
      cells: const <List<int>>[
        <int>[1, 0],
        <int>[1, 0],
        <int>[1, 1],
      ],
      color: const Color(0xFF66BB6A),
    ),
    BlockModel(
      type: BlockType.tShape,
      cells: const <List<int>>[
        <int>[1, 1, 1],
        <int>[0, 1, 0],
      ],
      color: const Color(0xFFAB47BC),
    ),
  ];

  factory BlockModel.random({
    BlockGenerationProfile profile = BlockGenerationProfile.defaultProfile,
  }) {
    final BlockModel template = _templates[_random.nextInt(_templates.length)];
    final bool useSpecialBlock = _random.nextDouble() < profile.specialChance;
    if (!useSpecialBlock) {
      return BlockModel(
        type: template.type,
        cells: template.cells
            .map((List<int> row) => List<int>.from(row))
            .toList(),
        color: template.color,
      );
    }

    final SpecialBlockType specialType = _pickSpecialType(profile);
    return BlockModel(
      type: template.type,
      cells: template.cells
          .map((List<int> row) => List<int>.from(row))
          .toList(),
      color: _specialColorFor(specialType, template.color),
      specialType: specialType,
      bombCountdown: specialType == SpecialBlockType.bomb
          ? 4 + _random.nextInt(3)
          : 0,
      iceDurability: specialType == SpecialBlockType.ice ? 2 : 1,
    );
  }

  static SpecialBlockType _pickSpecialType(BlockGenerationProfile profile) {
    final double roll = _random.nextDouble();
    final double bombThreshold = profile.bombChance;
    final double iceThreshold = bombThreshold + profile.iceChance;

    if (roll < bombThreshold) {
      return SpecialBlockType.bomb;
    }

    if (roll < iceThreshold) {
      return SpecialBlockType.ice;
    }

    return SpecialBlockType.magnet;
  }

  static Color _specialColorFor(SpecialBlockType specialType, Color baseColor) {
    return switch (specialType) {
      SpecialBlockType.bomb => const Color(0xFFFF5252),
      SpecialBlockType.ice => const Color(0xFF6AE3FF),
      SpecialBlockType.magnet => const Color(0xFFFFD54F),
      SpecialBlockType.none => baseColor,
    };
  }

  static List<List<int>> rotateCellsClockwise(List<List<int>> cells) {
    if (cells.isEmpty) {
      return <List<int>>[];
    }

    final int rowCount = cells.length;
    final int columnCount = cells.first.length;
    return List<List<int>>.generate(columnCount, (int column) {
      return List<int>.generate(rowCount, (int row) {
        return cells[rowCount - 1 - row][column];
      });
    });
  }
}

class BlockDragData {
  BlockDragData({required this.block, required this.slotIndex});

  final BlockModel block;
  final int slotIndex;
}
