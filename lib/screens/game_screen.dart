import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/game_engine.dart';
import '../models/level_model.dart';
import '../models/block_model.dart';
import '../services/level_manager.dart';
import '../services/game_audio_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_background.dart';
import '../widgets/block_piece.dart';
import '../widgets/board_widget.dart';
import 'game_over_screen.dart';
import 'home_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, this.level, this.levelManager});

  final LevelModel? level;
  final LevelManager? levelManager;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final GameEngine _gameEngine = GameEngine();
  final GameAudioService _audioService = GameAudioService();
  final StorageService _storageService = StorageService();
  final List<BlockModel> _availableBlocks = <BlockModel>[];
  final GlobalKey _boardKey = GlobalKey();
  BlockModel? _heldBlock;
  int _coins = 100;
  int? _selectedBlockIndex;
  int _highScore = 0;
  bool _isNavigatingToGameOver = false;
  bool _hasUsedHoldThisTurn = false;
  bool _hasCompletedJourneyLevel = false;
  int _currentRotationCost = _baseRotationCost;
  static const int _baseRotationCost = 10;
  static const int _rotationCostStep = 2;
  static const int _maxRotationCost = 30;
  static const int _traySlotCount = 3;
  final List<OverlayEntry> _comboOverlayEntries = <OverlayEntry>[];
  final List<OverlayEntry> _fxOverlayEntries = <OverlayEntry>[];
  late final AnimationController _shakeController;
  late final List<AnimationController> _slotPopControllers;
  late final List<Animation<double>> _slotPopAnimations;
  double _shakeMagnitude = 0;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _slotPopControllers = List<AnimationController>.generate(
      _traySlotCount,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 320),
        value: 1,
      ),
    );
    _slotPopAnimations = _slotPopControllers
        .map(
          (AnimationController controller) =>
              Tween<double>(begin: 0.72, end: 1).animate(
                CurvedAnimation(parent: controller, curve: Curves.elasticOut),
              ),
        )
        .toList();
    _generateRandomBlocks();
    _playTrayPopForAll();
    _selectedBlockIndex = 0;
    _gameEngine.startGame();
    _gameEngine.addListener(_onScoreChanged);
    _loadHighScore();
    _checkGameOver();
  }

  @override
  void dispose() {
    for (final OverlayEntry entry in _comboOverlayEntries) {
      entry.remove();
    }
    for (final OverlayEntry entry in _fxOverlayEntries) {
      entry.remove();
    }
    _gameEngine.removeListener(_onScoreChanged);
    _gameEngine.dispose();
    _shakeController.dispose();
    for (final AnimationController controller in _slotPopControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _triggerScreenShake(double magnitude) {
    _shakeMagnitude = magnitude;
    _shakeController.forward(from: 0);
  }

  void _playLineClearShake(int clearedLines) {
    if (clearedLines <= 0) {
      return;
    }
    _triggerScreenShake(clearedLines == 1 ? 4 : 10);
  }

  void _showComboFloatingText(int clearedLines) {
    final BuildContext? boardContext = _boardKey.currentContext;
    if (!mounted || boardContext == null || clearedLines <= 0) {
      return;
    }

    final RenderBox? boardBox = boardContext.findRenderObject() as RenderBox?;
    if (boardBox == null || !boardBox.attached) {
      return;
    }

    final int anchorRow =
        _gameEngine.lastComboAnchorRow ?? _gameEngine.boardSize ~/ 2;
    final int anchorColumn =
        _gameEngine.lastComboAnchorColumn ?? _gameEngine.boardSize ~/ 2;
    final Offset boardTopLeft = boardBox.localToGlobal(Offset.zero);
    final double cellSize = boardBox.size.width / _gameEngine.boardSize;
    final Offset anchorOffset = Offset(
      boardTopLeft.dx + (anchorColumn * cellSize) + (cellSize / 2),
      boardTopLeft.dy + (anchorRow * cellSize) + (cellSize / 2),
    );

    _showClearFx(anchorOffset, clearedLines);

    final String label = switch (clearedLines) {
      1 => 'Good',
      2 => 'Great',
      3 => 'Awesome',
      _ => 'Legendary',
    };

    final Color tint = switch (clearedLines) {
      1 => const Color(0xFF7CF7B8),
      2 => const Color(0xFF55D6FF),
      3 => const Color(0xFFFFD54F),
      _ => const Color(0xFFFF8A65),
    };

    final double scale = switch (clearedLines) {
      1 => 1.0,
      2 => 1.14,
      3 => 1.28,
      _ => 1.42,
    };

    final OverlayState overlay = Overlay.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return _FloatingComboText(
          anchor: anchorOffset,
          text: '$label x$clearedLines',
          color: tint,
          scale: scale,
          onComplete: () {
            entry.remove();
            _comboOverlayEntries.remove(entry);
          },
        );
      },
    );

    _comboOverlayEntries.add(entry);
    overlay.insert(entry);
  }

  void _showClearFx(Offset anchor, int clearedLines) {
    if (!mounted || clearedLines <= 0) {
      return;
    }

    final OverlayState overlay = Overlay.of(context);
    final Color tint = switch (clearedLines) {
      1 => const Color(0xFF7CF7B8),
      2 => const Color(0xFF55D6FF),
      3 => const Color(0xFFFFD54F),
      _ => const Color(0xFFFF8A65),
    };

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) {
        return _FxBurstOverlay(
          anchor: anchor,
          tint: tint,
          intensity: clearedLines,
          onComplete: () {
            entry.remove();
            _fxOverlayEntries.remove(entry);
          },
        );
      },
    );

    _fxOverlayEntries.add(entry);
    overlay.insert(entry);
  }

  double _screenShakeOffsetX() {
    if (!_shakeController.isAnimating) {
      return 0;
    }

    final double t = _shakeController.value;
    final double damping = 1 - t;
    return math.sin(t * math.pi * 10) * _shakeMagnitude * damping;
  }

  Future<void> _loadHighScore() async {
    final int savedHighScore = await _storageService.getBestScore();
    if (!mounted) {
      return;
    }
    setState(() {
      _highScore = savedHighScore;
    });
  }

  Future<void> _onScoreChanged() async {
    if (_gameEngine.score <= _highScore) {
      if (await _checkJourneyLevelCompletion()) {
        return;
      }
      _checkGameOver();
      return;
    }

    setState(() {
      _highScore = _gameEngine.score;
    });
    await _storageService.saveBestScore(_highScore);
    if (await _checkJourneyLevelCompletion()) {
      return;
    }
    _checkGameOver();
  }

  Future<bool> _checkJourneyLevelCompletion() async {
    final LevelModel? level = widget.level;
    final LevelManager? levelManager = widget.levelManager;
    if (!mounted ||
        level == null ||
        levelManager == null ||
        _hasCompletedJourneyLevel) {
      return false;
    }

    if (!levelManager.isLevelComplete(level, _gameEngine)) {
      return false;
    }

    _hasCompletedJourneyLevel = true;
    await levelManager.completeLevel(level);
    if (!mounted) {
      return true;
    }

    Navigator.of(context).pop(true);
    return true;
  }

  void _generateRandomBlocks() {
    _availableBlocks
      ..clear()
      ..addAll(
        List<BlockModel>.generate(
          3,
          (_) => BlockModel.random(profile: _blockGenerationProfile),
        ),
      );
  }

  BlockGenerationProfile get _blockGenerationProfile {
    return widget.level?.generationProfile ??
        BlockGenerationProfile.defaultProfile;
  }

  void _playTrayPopForAll() {
    for (final AnimationController controller in _slotPopControllers) {
      controller.forward(from: 0);
    }
  }

  void _selectBlock(int index) {
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedBlockIndex = index;
    });
  }

  Future<void> _holdSelectedBlock() async {
    final int? selectedIndex = _selectedBlockIndex;
    if (!mounted || selectedIndex == null) {
      return;
    }

    if (_hasUsedHoldThisTurn) {
      await _handleInvalidDrop();
      return;
    }

    setState(() {
      final BlockModel selectedBlock = _availableBlocks[selectedIndex];
      if (_heldBlock == null) {
        _heldBlock = selectedBlock;
        _availableBlocks[selectedIndex] = BlockModel.random(
          profile: _blockGenerationProfile,
        );
        _slotPopControllers[selectedIndex].forward(from: 0);
      } else {
        final BlockModel nextHeldBlock = selectedBlock;
        _availableBlocks[selectedIndex] = _heldBlock!;
        _heldBlock = nextHeldBlock;
        _slotPopControllers[selectedIndex].forward(from: 0);
      }
      _hasUsedHoldThisTurn = true;
    });

    await _audioService.playPlaceSound();
    _checkGameOver();
  }

  Future<void> _rotateSelectedBlock() async {
    final int? selectedIndex = _selectedBlockIndex;
    if (!mounted || selectedIndex == null) {
      return;
    }

    if (_coins < _currentRotationCost) {
      await _handleInvalidDrop();
      return;
    }

    setState(() {
      _coins -= _currentRotationCost;
      _availableBlocks[selectedIndex] = _availableBlocks[selectedIndex]
          .rotatedClockwise();
      _slotPopControllers[selectedIndex].forward(from: 0);
      _currentRotationCost = (_currentRotationCost + _rotationCostStep).clamp(
        _baseRotationCost,
        _maxRotationCost,
      );
    });

    await _audioService.playPlaceSound();
    _checkGameOver();
  }

  void _replaceBlockAt(int index) {
    if (!mounted) {
      return;
    }

    final int clearedLines = _gameEngine.lastClearedLineCount;
    _audioService.playPlaceSound();
    if (clearedLines > 0) {
      _audioService.playClearSound();
      _playLineClearShake(clearedLines);
      _showComboFloatingText(clearedLines);
    }

    setState(() {
      _availableBlocks[index] = BlockModel.random(
        profile: _blockGenerationProfile,
      );
      _selectedBlockIndex ??= index;
      _slotPopControllers[index].forward(from: 0);
      _hasUsedHoldThisTurn = false;
    });
    _checkGameOver();
  }

  Future<void> _handleInvalidDrop() async {
    await _audioService.playErrorSound();
    _triggerScreenShake(6);
  }

  Future<void> _checkGameOver() async {
    if (!mounted || _isNavigatingToGameOver || _availableBlocks.isEmpty) {
      return;
    }

    if (_gameEngine.isRunning) {
      final bool hasMove = _gameEngine.hasAnyValidMove(_availableBlocks);
      if (hasMove) {
        return;
      }
    }

    _isNavigatingToGameOver = true;
    _gameEngine.endGame();
    await _storageService.saveBestScore(_gameEngine.score);
    if (!mounted) {
      return;
    }

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => GameOverScreen(
          score: _gameEngine.score,
          playAgainBuilder: widget.level == null
              ? null
              : ((_) => GameScreen(
                  level: widget.level,
                  levelManager: widget.levelManager,
                )),
        ),
      ),
    );
  }

  void _restartGame() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isNavigatingToGameOver = false;
      _heldBlock = null;
      _coins = 100;
      _selectedBlockIndex = 0;
      _hasUsedHoldThisTurn = false;
      _hasCompletedJourneyLevel = false;
      _currentRotationCost = _baseRotationCost;
      _generateRandomBlocks();
      _playTrayPopForAll();
      _gameEngine.startGame();
    });
  }

  Future<void> _openPauseSheet() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xEE2F4D8E), Color(0xEE1C2F62)],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0x88BFE9FF)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x6634A7FF),
                  blurRadius: 22,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Paused',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Resume'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(
                        builder: (_) => const HomeScreen(),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  },
                  icon: const Icon(Icons.home_rounded),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2859A8),
                    foregroundColor: Colors.white,
                  ),
                  label: const Text('Back To Home'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double boardMaxWidth = MediaQuery.of(context).size.width > 560
        ? 520
        : MediaQuery.of(context).size.width - 20;

    return Scaffold(
      body: AppBackground(
        child: AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_screenShakeOffsetX(), 0),
              child: child,
            );
          },
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                children: [
                  if (widget.level != null) ...[
                    _JourneyLevelBanner(
                      level: widget.level!,
                      manager: widget.levelManager,
                      gameEngine: _gameEngine,
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      _HudButton(
                        icon: Icons.pause_rounded,
                        onTap: _openPauseSheet,
                      ),
                      const Spacer(),
                      _ScorePill(
                        highScore: _highScore,
                        gameEngine: _gameEngine,
                      ),
                      const Spacer(),
                      _HudButton(
                        icon: Icons.refresh_rounded,
                        onTap: _restartGame,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _GlassControlBar(
                    heldBlock: _heldBlock,
                    holdLocked: _hasUsedHoldThisTurn,
                    coins: _coins,
                    rotationCost: _currentRotationCost,
                    onHoldTap: _holdSelectedBlock,
                    onRotateTap:
                        _selectedBlockIndex == null ||
                            _coins < _currentRotationCost
                        ? () {
                            _handleInvalidDrop();
                          }
                        : () {
                            _rotateSelectedBlock();
                          },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: boardMaxWidth),
                        child: BoardWidget(
                          key: _boardKey,
                          gameEngine: _gameEngine,
                          onBlockPlaced: _replaceBlockAt,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xCC1B3A80), Color(0xCC0D2558)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x884CC9FF)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x662FA7FF),
                          blurRadius: 20,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _availableBlocks
                          .asMap()
                          .entries
                          .map(
                            (entry) => _TraySlotPedestal(
                              isSelected: _selectedBlockIndex == entry.key,
                              popAnimation: _slotPopAnimations[entry.key],
                              onTap: () => _selectBlock(entry.key),
                              child: Draggable<BlockDragData>(
                                data: BlockDragData(
                                  block: entry.value,
                                  slotIndex: entry.key,
                                ),
                                onDraggableCanceled: (velocity, offset) {
                                  _handleInvalidDrop();
                                },
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: Transform.scale(
                                    scale: 1.12,
                                    child: Opacity(
                                      opacity: 0.95,
                                      child: BlockPiece(
                                        block: entry.value,
                                        isSelected:
                                            _selectedBlockIndex == entry.key,
                                      ),
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.2,
                                  child: BlockPiece(
                                    block: entry.value,
                                    isSelected:
                                        _selectedBlockIndex == entry.key,
                                  ),
                                ),
                                child: BlockPiece(
                                  block: entry.value,
                                  isSelected: _selectedBlockIndex == entry.key,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HudButton extends StatelessWidget {
  const _HudButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF8CC6FF), Color(0xFF4C88D4), Color(0xFF2A4F95)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x88C8ECFF), width: 1.6),
          boxShadow: const [
            BoxShadow(
              color: Color(0x6631B5FF),
              blurRadius: 14,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 31),
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.highScore, required this.gameEngine});

  final int highScore;
  final GameEngine gameEngine;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8EAEDF), Color(0xFF4A67A8), Color(0xFF2D447C)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x99E3F5FF)),
        boxShadow: const [
          BoxShadow(color: Color(0x6639A9FF), blurRadius: 16, spreadRadius: 1),
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            '$highScore',
            style: const TextStyle(
              color: Color(0xFFFFEB9C),
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.emoji_events_rounded,
            color: Color(0xFFFFC530),
            size: 34,
          ),
          const SizedBox(width: 10),
          ListenableBuilder(
            listenable: gameEngine,
            builder: (context, child) {
              return Text(
                '${gameEngine.score}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GlassControlBar extends StatelessWidget {
  const _GlassControlBar({
    required this.heldBlock,
    required this.holdLocked,
    required this.coins,
    required this.rotationCost,
    required this.onHoldTap,
    required this.onRotateTap,
  });

  final BlockModel? heldBlock;
  final bool holdLocked;
  final int coins;
  final int rotationCost;
  final VoidCallback onHoldTap;
  final VoidCallback onRotateTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xDDA9D1FF), Color(0xCC5978BD), Color(0xCC2D4375)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x88E2F4FF), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Color(0x662F9EFF), blurRadius: 22, spreadRadius: 1),
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _HoldSlotCard(
            block: heldBlock,
            isLocked: holdLocked,
            onTap: onHoldTap,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 74,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xDD2B4F92), Color(0xCC1D346E)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0x886FD4FF)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.monetization_on_rounded,
                    color: Color(0xFFFFD54F),
                    size: 34,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$coins',
                    style: const TextStyle(
                      color: Color(0xFFFFF4BF),
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Rotation cost $rotationCost',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFD0E6FF),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          _HudButton(icon: Icons.rotate_right_rounded, onTap: onRotateTap),
        ],
      ),
    );
  }
}

class _HoldSlotCard extends StatelessWidget {
  const _HoldSlotCard({
    required this.block,
    required this.onTap,
    required this.isLocked,
  });

  final BlockModel? block;
  final VoidCallback onTap;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        width: 114,
        height: 92,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isLocked
                ? const [Color(0xFF3B5890), Color(0xFF1E3563)]
                : const [Color(0xFF67B4F7), Color(0xFF2A63A4)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isLocked ? const Color(0x88FFD56A) : const Color(0x88DDF4FF),
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x552FA7FF), blurRadius: 10),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isLocked ? 'HOLD LOCKED' : 'HOLD',
              style: TextStyle(
                color: isLocked ? const Color(0xFFFFE082) : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Center(
                child: block == null
                    ? Container(
                        width: 60,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0x3324C8FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0x88BFE8FF)),
                        ),
                        child: const Text(
                          'EMPTY',
                          style: TextStyle(
                            color: Color(0xFFE3F3FF),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : BlockPiece(block: block!, cellSize: 10, isSelected: true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TraySlotPedestal extends StatelessWidget {
  const _TraySlotPedestal({
    required this.isSelected,
    required this.popAnimation,
    required this.onTap,
    required this.child,
  });

  final bool isSelected;
  final Animation<double> popAnimation;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ScaleTransition(
        scale: popAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            child,
            const SizedBox(height: 5),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 82,
              height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isSelected
                      ? const [Color(0xFFAED7FF), Color(0xFF5D82C6)]
                      : const [Color(0xFF7FA4D3), Color(0xFF45639A)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xCCEDFAFF)
                      : const Color(0x889FCCF5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? const Color(0x994BD7FF)
                        : const Color(0x553EA6FF),
                    blurRadius: isSelected ? 12 : 8,
                    spreadRadius: isSelected ? 1.2 : 0,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JourneyLevelBanner extends StatelessWidget {
  const _JourneyLevelBanner({
    required this.level,
    required this.gameEngine,
    required this.manager,
  });

  final LevelModel level;
  final GameEngine gameEngine;
  final LevelManager? manager;

  @override
  Widget build(BuildContext context) {
    final String progress = manager == null
        ? level.objective.label
        : manager!.progressLabel(level, gameEngine);

    return GamePanel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF2458FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.flag_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Level ${level.number} • ${level.title}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  progress,
                  style: const TextStyle(
                    color: Color(0xFFB9D5FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingComboText extends StatefulWidget {
  const _FloatingComboText({
    required this.anchor,
    required this.text,
    required this.color,
    required this.scale,
    required this.onComplete,
  });

  final Offset anchor;
  final String text;
  final Color color;
  final double scale;
  final VoidCallback onComplete;

  @override
  State<_FloatingComboText> createState() => _FloatingComboTextState();
}

class _FloatingComboTextState extends State<_FloatingComboText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _fadeAnimation = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1.2),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _scaleAnimation = Tween<double>(
      begin: widget.scale,
      end: widget.scale * 1.08,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.forward().whenComplete(widget.onComplete);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: widget.anchor.dx - 64,
          top: widget.anchor.dy - 28 - (_controller.value * 44),
          child: IgnorePointer(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: widget.color.withValues(alpha: 0.72)),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Text(
          widget.text,
          style: TextStyle(
            color: widget.color,
            fontSize: 22 * widget.scale,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _FxBurstOverlay extends StatefulWidget {
  const _FxBurstOverlay({
    required this.anchor,
    required this.tint,
    required this.intensity,
    required this.onComplete,
  });

  final Offset anchor;
  final Color tint;
  final int intensity;
  final VoidCallback onComplete;

  @override
  State<_FxBurstOverlay> createState() => _FxBurstOverlayState();
}

class _FxBurstOverlayState extends State<_FxBurstOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 460 + (widget.intensity * 70)),
    );
    _controller.forward().whenComplete(widget.onComplete);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double size = 70 + (widget.intensity * 16);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double t = _controller.value;
          final double fadeOut = (1 - t).clamp(0, 1);
          final double scale = 0.6 + (t * 1.35);

          return Stack(
            children: [
              Positioned(
                left: widget.anchor.dx - (size / 2),
                top: widget.anchor.dy - (size / 2),
                child: Opacity(
                  opacity: fadeOut,
                  child: Transform.scale(
                    scale: scale,
                    child: SizedBox(
                      width: size,
                      height: size,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/fx/flash_fx.png',
                            color: widget.tint.withValues(alpha: 0.9),
                            colorBlendMode: BlendMode.screen,
                            errorBuilder:
                                (
                                  BuildContext context,
                                  Object error,
                                  StackTrace? stackTrace,
                                ) => DecoratedBox(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        widget.tint.withValues(alpha: 0.66),
                                        widget.tint.withValues(alpha: 0),
                                      ],
                                    ),
                                  ),
                                ),
                          ),
                          Image.asset(
                            'assets/fx/spark.png',
                            color: widget.tint.withValues(alpha: 0.95),
                            colorBlendMode: BlendMode.plus,
                            errorBuilder:
                                (
                                  BuildContext context,
                                  Object error,
                                  StackTrace? stackTrace,
                                ) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              for (int i = 0; i < 6 + widget.intensity; i++)
                _FxSpark(
                  anchor: widget.anchor,
                  progress: t,
                  angle: (math.pi * 2 * i) / (6 + widget.intensity),
                  tint: widget.tint,
                  magnitude: 40 + (widget.intensity * 10),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FxSpark extends StatelessWidget {
  const _FxSpark({
    required this.anchor,
    required this.progress,
    required this.angle,
    required this.tint,
    required this.magnitude,
  });

  final Offset anchor;
  final double progress;
  final double angle;
  final Color tint;
  final double magnitude;

  @override
  Widget build(BuildContext context) {
    final double travel = Curves.easeOut.transform(progress) * magnitude;
    final double dx = math.cos(angle) * travel;
    final double dy = math.sin(angle) * travel;
    final double size = 5 + ((1 - progress) * 3);

    return Positioned(
      left: anchor.dx + dx,
      top: anchor.dy + dy,
      child: Opacity(
        opacity: (1 - progress).clamp(0, 1),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: tint,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: tint.withValues(alpha: 0.75),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
