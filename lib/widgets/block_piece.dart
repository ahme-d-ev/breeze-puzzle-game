import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/block_model.dart';
import '../models/game_theme_model.dart';
import '../services/theme_manager.dart';

class BlockPiece extends StatelessWidget {
  const BlockPiece({
    super.key,
    required this.block,
    this.cellSize = 16,
    this.isSelected = false,
  });

  final BlockModel block;
  final double cellSize;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final GameThemeModel theme = context.watch<ThemeManager>().activeTheme;
    final Color accent = block.specialType == SpecialBlockType.none
        ? block.color
        : _specialAccent(theme, block.specialType);
    final Color borderColor = isSelected
        ? theme.selectedBlockBorderColor
        : block.specialType == SpecialBlockType.none
            ? theme.boardGridLineColor.withValues(alpha: 0.72)
            : accent.withValues(alpha: 0.82);

    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.blockContainerColor.withValues(alpha: 0.92),
            accent.withValues(alpha: 0.16),
            theme.blockContainerColor.withValues(alpha: 0.96),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: isSelected ? 1.8 : 1.2),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isSelected ? 0.32 : 0.22),
            blurRadius: isSelected ? 18 : 14,
            spreadRadius: isSelected ? 1.1 : 0.4,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: block.cells.map((List<int> row) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: row.map((int cell) {
                  final bool filled = cell == 1;
                  return Padding(
                    padding: const EdgeInsets.all(1),
                    child: Container(
                      width: cellSize,
                      height: cellSize,
                      decoration: BoxDecoration(
                        gradient: filled
                            ? _spriteGradient(theme.blockSpriteStyle, block.color)
                            : null,
                        color: filled ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: filled
                              ? Colors.white.withValues(alpha: 0.34)
                              : const Color(0x22000000),
                        ),
                        boxShadow: filled
                            ? [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.48),
                                  blurRadius: 5,
                                  spreadRadius: 0.4,
                                ),
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  blurRadius: 1,
                                  offset: const Offset(-1, -1),
                                ),
                              ]
                            : null,
                      ),
                      child: filled
                          ? Stack(
                              children: [
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.white.withValues(alpha: 0.24),
                                          Colors.white.withValues(alpha: 0.05),
                                          Colors.black.withValues(alpha: 0.08),
                                        ],
                                        stops: const [0.0, 0.48, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                                _SpriteShine(
                                  style: theme.blockSpriteStyle,
                                  cellSize: cellSize,
                                ),
                              ],
                            )
                          : null,
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.12),
                      Colors.white.withValues(alpha: 0.02),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.33, 0.8],
                  ),
                ),
              ),
            ),
          ),
          if (block.specialType != SpecialBlockType.none)
            Positioned(right: -2, top: -2, child: _SpecialBadge(block: block)),
        ],
      ),
    );
  }
}

  Color _specialAccent(GameThemeModel theme, SpecialBlockType specialType) {
    return switch (specialType) {
      SpecialBlockType.bomb => theme.specialBombColor,
      SpecialBlockType.ice => theme.specialIceColor,
      SpecialBlockType.magnet => theme.specialMagnetColor,
      SpecialBlockType.none => theme.boardGridLineColor,
    };
  }

  LinearGradient _spriteGradient(BlockSpriteStyle style, Color baseColor) {
    final Color light = _lighten(
      baseColor,
      style == BlockSpriteStyle.space ? 0.42 : 0.28,
    );
    final Color mid = _lighten(
      baseColor,
      style == BlockSpriteStyle.wood ? 0.06 : 0.02,
    );
    final Color dark = _darken(
      baseColor,
      style == BlockSpriteStyle.space ? 0.24 : 0.18,
    );

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [light, mid, dark],
      stops: const [0.0, 0.52, 1.0],
    );
  }

  Color _lighten(Color color, double amount) {
    final HSLColor hsl = HSLColor.fromColor(color);
    final HSLColor lighter = hsl.withLightness(
      (hsl.lightness + amount).clamp(0, 1),
    );
    return lighter.toColor();
  }

  Color _darken(Color color, double amount) {
    final HSLColor hsl = HSLColor.fromColor(color);
    final HSLColor darker = hsl.withLightness(
      (hsl.lightness - amount).clamp(0, 1),
    );
    return darker.toColor();
  }




class _SpriteShine extends StatelessWidget {
  const _SpriteShine({required this.style, required this.cellSize});

  final BlockSpriteStyle style;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    return switch (style) {
      BlockSpriteStyle.classic => Align(
        alignment: Alignment.topLeft,
        child: Container(
          width: cellSize * 0.48,
          height: cellSize * 0.22,
          margin: const EdgeInsets.only(left: 1, top: 1),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.36),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
      BlockSpriteStyle.wood => Align(
        alignment: Alignment.center,
        child: Container(
          width: cellSize * 0.72,
          height: 1,
          decoration: BoxDecoration(
            color: Colors.brown.shade900.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
      BlockSpriteStyle.space => Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              width: cellSize * 0.4,
              height: cellSize * 0.2,
              margin: const EdgeInsets.only(left: 1, top: 1),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              width: cellSize * 0.14,
              height: cellSize * 0.14,
              margin: const EdgeInsets.only(right: 2, bottom: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    };
  }
}

class _SpecialBadge extends StatelessWidget {
  const _SpecialBadge({required this.block});

  final BlockModel block;

  @override
  Widget build(BuildContext context) {
    final GameThemeModel theme = context.watch<ThemeManager>().activeTheme;

    final Color backgroundColor = switch (block.specialType) {
      SpecialBlockType.bomb => theme.specialBombColor,
      SpecialBlockType.ice => theme.specialIceColor,
      SpecialBlockType.magnet => theme.specialMagnetColor,
      SpecialBlockType.none => const Color(0xFF0D2E67),
    };

    final String label = switch (block.specialType) {
      SpecialBlockType.bomb => '${block.bombCountdown}',
      SpecialBlockType.ice => '${block.iceDurability}',
      SpecialBlockType.magnet => 'M',
      SpecialBlockType.none => '',
    };

    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}
