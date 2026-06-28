import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/game_engine.dart';
import '../models/block_model.dart';
import '../models/game_theme_model.dart';
import '../services/theme_manager.dart';

class BoardWidget extends StatefulWidget {
  const BoardWidget({
    super.key,
    required this.gameEngine,
    required this.onBlockPlaced,
  });

  final GameEngine gameEngine;
  final ValueChanged<int> onBlockPlaced;

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget> {
  _HoverPreview? _hoverPreview;
  _HoverPreview? _ghostPreview;

  void _updateHoverPreview(BlockModel block, int row, int column) {
    final BlockPlacement? snappedPlacement = widget.gameEngine
        .findNearestValidPlacement(block, row, column);
    final bool isValid = snappedPlacement != null;

    final _HoverPreview next = _HoverPreview(
      block: block,
      row: snappedPlacement?.row ?? row,
      column: snappedPlacement?.column ?? column,
      isValid: isValid,
    );

    final BlockPlacement? ghostPlacement = isValid
        ? widget.gameEngine.findGhostPlacement(block, next.column)
        : null;
    final _HoverPreview? nextGhost = ghostPlacement == null
        ? null
        : _HoverPreview(
            block: block,
            row: ghostPlacement.row,
            column: ghostPlacement.column,
            isValid: true,
          );

    final bool sameHover = _hoverPreview?.isSameAs(next) ?? false;
    final bool sameGhost = switch ((_ghostPreview, nextGhost)) {
      (null, null) => true,
      (_HoverPreview a?, _HoverPreview b?) => a.isSameAs(b),
      _ => false,
    };

    if (sameHover && sameGhost) {
      return;
    }

    setState(() {
      _hoverPreview = next;
      _ghostPreview = nextGhost;
    });
  }

  void _clearHoverPreview() {
    if (_hoverPreview == null && _ghostPreview == null) {
      return;
    }
    setState(() {
      _hoverPreview = null;
      _ghostPreview = null;
    });
  }

  bool _isPreviewCell(int row, int column) {
    final _HoverPreview? preview = _hoverPreview;
    if (preview == null) {
      return false;
    }

    for (int r = 0; r < preview.block.cells.length; r++) {
      for (int c = 0; c < preview.block.cells[r].length; c++) {
        if (preview.block.cells[r][c] == 0) {
          continue;
        }
        if (preview.row + r == row && preview.column + c == column) {
          return true;
        }
      }
    }

    return false;
  }

  bool _isValidPreview() {
    return _hoverPreview?.isValid ?? false;
  }

  bool _isGhostCell(int row, int column) {
    final _HoverPreview? preview = _ghostPreview;
    if (preview == null) {
      return false;
    }

    for (int r = 0; r < preview.block.cells.length; r++) {
      for (int c = 0; c < preview.block.cells[r].length; c++) {
        if (preview.block.cells[r][c] == 0) {
          continue;
        }
        if (preview.row + r == row && preview.column + c == column) {
          return true;
        }
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final GameThemeModel theme = context.watch<ThemeManager>().activeTheme;

    return ListenableBuilder(
      listenable: widget.gameEngine,
      builder: (context, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.boardBorderColor, width: 3),
            boxShadow: [
              BoxShadow(
                color: theme.boardFrameShadowColor,
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              color: theme.boardFillColor,
              padding: const EdgeInsets.all(6),
              child: AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount:
                      widget.gameEngine.boardSize * widget.gameEngine.boardSize,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: widget.gameEngine.boardSize,
                  ),
                  itemBuilder: (_, index) {
                    final int row = index ~/ widget.gameEngine.boardSize;
                    final int column = index % widget.gameEngine.boardSize;
                    final bool isFilled = widget.gameEngine.isCellFilled(
                      row,
                      column,
                    );
                    final Color? cellColor = widget.gameEngine.getCellColor(
                      row,
                      column,
                    );
                    final SpecialBlockType specialType = widget.gameEngine
                        .getCellSpecialType(row, column);
                    final int bombCountdown = widget.gameEngine
                        .getCellBombCountdown(row, column);
                    final int iceHitsRemaining = widget.gameEngine
                        .getCellIceHitsRemaining(row, column);

                    return DragTarget<BlockDragData>(
                      onWillAcceptWithDetails: (details) {
                        _updateHoverPreview(details.data.block, row, column);
                        return _hoverPreview?.isValid ?? false;
                      },
                      onMove: (details) {
                        _updateHoverPreview(details.data.block, row, column);
                      },
                      onLeave: (data) {
                        _clearHoverPreview();
                      },
                      onAcceptWithDetails: (details) {
                        final _HoverPreview? preview = _hoverPreview;
                        _clearHoverPreview();
                        final bool placed = widget.gameEngine.placeBlockShape(
                          details.data.block,
                          preview?.row ?? row,
                          preview?.column ?? column,
                        );
                        if (placed) {
                          widget.onBlockPlaced(details.data.slotIndex);
                        }
                      },
                      builder: (context, candidateData, rejectedData) {
                        final bool isPreviewing = _isPreviewCell(row, column);
                        final bool isGhosting =
                            !isPreviewing && _isGhostCell(row, column);
                        final bool isValidPreview = _isValidPreview();
                        final bool isClearing = widget.gameEngine
                            .isCellClearing(row, column);
                        final bool isPlacing = widget.gameEngine.isCellPlacing(
                          row,
                          column,
                        );

                        return Padding(
                          padding: const EdgeInsets.all(1.5),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 190),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              color: isClearing
                                  ? Colors.white
                                  : isPlacing
                                  ? (cellColor ?? Colors.lightBlueAccent)
                                  : isFilled
                                  ? (cellColor ?? Colors.blue)
                                  : isGhosting
                                  ? theme.ghostColor
                                  : isPreviewing
                                  ? (isValidPreview
                                        ? theme.validPreviewColor
                                        : theme.invalidPreviewColor)
                                  : theme.boardEmptyCellColor,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: theme.boardGridLineColor,
                                width: 0.5,
                              ),
                              boxShadow: isClearing || isPreviewing
                                  ? [
                                      BoxShadow(
                                        color: isClearing
                                            ? const Color(0x99FFFFFF)
                                            : isValidPreview
                                            ? theme.validPreviewColor
                                            : const Color(0x99E53935),
                                        blurRadius: isClearing ? 18 : 10,
                                        spreadRadius: isClearing ? 2 : 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isClearing
                                ? const _CellClearBeamEffect()
                                : Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      AnimatedScale(
                                        duration: const Duration(
                                          milliseconds: 130,
                                        ),
                                        curve: Curves.easeOutBack,
                                        scale: isPlacing ? 1.08 : 1,
                                        child: const SizedBox.expand(),
                                      ),
                                      if (isFilled &&
                                          specialType != SpecialBlockType.none)
                                        Align(
                                          alignment: Alignment.topRight,
                                          child: Padding(
                                            padding: const EdgeInsets.all(3),
                                            child: _CellSpecialBadge(
                                              specialType: specialType,
                                              bombCountdown: bombCountdown,
                                              iceHitsRemaining:
                                                  iceHitsRemaining,
                                              bombColor: theme.specialBombColor,
                                              iceColor: theme.specialIceColor,
                                              magnetColor:
                                                  theme.specialMagnetColor,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HoverPreview {
  const _HoverPreview({
    required this.block,
    required this.row,
    required this.column,
    required this.isValid,
  });

  final BlockModel block;
  final int row;
  final int column;
  final bool isValid;

  bool isSameAs(_HoverPreview other) {
    return identical(block, other.block) &&
        row == other.row &&
        column == other.column &&
        isValid == other.isValid;
  }
}

class _CellClearBeamEffect extends StatelessWidget {
  const _CellClearBeamEffect();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        final double fade = 1 - t;
        return Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: fade,
              child: Transform.scale(
                scale: 1 + (t * 0.45),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.white,
                        const Color(0xCC8BD3FF),
                        const Color(0x008BD3FF),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Opacity(
              opacity: fade,
              child: Transform.translate(
                offset: Offset((1 - t) * -8, 0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0x00FFFFFF),
                        Color(0xEEFFFFFF),
                        Color(0x00FFFFFF),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CellSpecialBadge extends StatelessWidget {
  const _CellSpecialBadge({
    required this.specialType,
    required this.bombCountdown,
    required this.iceHitsRemaining,
    required this.bombColor,
    required this.iceColor,
    required this.magnetColor,
  });

  final SpecialBlockType specialType;
  final int bombCountdown;
  final int iceHitsRemaining;
  final Color bombColor;
  final Color iceColor;
  final Color magnetColor;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = switch (specialType) {
      SpecialBlockType.bomb => bombColor,
      SpecialBlockType.ice => iceColor,
      SpecialBlockType.magnet => magnetColor,
      SpecialBlockType.none => const Color(0xFF0D2E67),
    };

    final String label = switch (specialType) {
      SpecialBlockType.bomb => '$bombCountdown',
      SpecialBlockType.ice => '$iceHitsRemaining',
      SpecialBlockType.magnet => 'M',
      SpecialBlockType.none => '',
    };

    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(9),
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
