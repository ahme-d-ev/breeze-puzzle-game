import 'package:flutter/material.dart';
import 'package:block_puz_2026/models/block_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rotateCellsClockwise rotates a matrix 90 degrees clockwise', () {
    final List<List<int>> rotated = BlockModel.rotateCellsClockwise(const [
      [1, 0],
      [1, 1],
    ]);

    expect(rotated, const [
      [1, 1],
      [1, 0],
    ]);
  });

  test('rotatedClockwise preserves block metadata', () {
    final BlockModel block = BlockModel(
      type: BlockType.lShape,
      cells: const [
        [1, 0],
        [1, 0],
        [1, 1],
      ],
      color: const Color(0xFF66BB6A),
      specialType: SpecialBlockType.magnet,
      bombCountdown: 3,
      iceDurability: 2,
    );

    final BlockModel rotated = block.rotatedClockwise();

    expect(rotated.type, block.type);
    expect(rotated.color, block.color);
    expect(rotated.specialType, block.specialType);
    expect(rotated.bombCountdown, block.bombCountdown);
    expect(rotated.iceDurability, block.iceDurability);
    expect(rotated.cells, const [
      [1, 1, 1],
      [1, 0, 0],
    ]);
  });
}
