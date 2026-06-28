import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/level_model.dart';
import '../models/game_theme_model.dart';
import '../services/level_manager.dart';
import '../services/storage_service.dart';
import '../services/theme_manager.dart';
import '../widgets/app_background.dart';
import 'game_screen.dart';

class JourneyModeScreen extends StatefulWidget {
  const JourneyModeScreen({super.key});

  @override
  State<JourneyModeScreen> createState() => _JourneyModeScreenState();
}

class _JourneyModeScreenState extends State<JourneyModeScreen> {
  late final LevelManager _levelManager;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _levelManager = LevelManager(StorageService());
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    await _levelManager.loadProgress();
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _openLevel(LevelModel level) async {
    if (!_levelManager.canStart(level)) {
      return;
    }

    final bool? completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => GameScreen(level: level, levelManager: _levelManager),
      ),
    );

    await _levelManager.loadProgress();
    if (!mounted) {
      return;
    }

    setState(() {});

    if (completed == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Level ${level.number} cleared')));
    }
  }

  Color _readableOn(Color bg) {
    return bg.computeLuminance() > 0.48
        ? const Color(0xFF10233F)
        : const Color(0xFFF3F8FF);
  }

  @override
  Widget build(BuildContext context) {
    final GameThemeModel activeTheme = context
        .watch<ThemeManager>()
        .activeTheme;
    final Color primaryText = _readableOn(activeTheme.panelColor);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: activeTheme.selectedBlockBorderColor,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _JourneyHeader(
                        levelManager: _levelManager,
                        activeTheme: activeTheme,
                        primaryText: primaryText,
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.center,
                                child: Container(
                                  width: 5,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        const Color(0x006AE3FF),
                                        const Color(
                                          0xFF6AE3FF,
                                        ).withValues(alpha: 0.5),
                                        const Color(0x006AE3FF),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                              ),
                            ),
                            ListView.builder(
                              padding: const EdgeInsets.only(bottom: 24),
                              itemCount: _levelManager.levels.length,
                              itemBuilder: (context, index) {
                                final LevelModel level =
                                    _levelManager.levels[index];
                                final bool unlocked = _levelManager.isUnlocked(
                                  level,
                                );
                                final bool isLeft = index.isEven;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: isLeft
                                        ? MainAxisAlignment.start
                                        : MainAxisAlignment.end,
                                    children: [
                                      if (!isLeft) const Spacer(),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 290,
                                        ),
                                        child: _JourneyLevelCard(
                                          level: level,
                                          unlocked: unlocked,
                                          activeTheme: activeTheme,
                                          onTap: unlocked
                                              ? () => _openLevel(level)
                                              : null,
                                        ),
                                      ),
                                      if (isLeft) const Spacer(),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _JourneyHeader extends StatelessWidget {
  const _JourneyHeader({
    required this.levelManager,
    required this.activeTheme,
    required this.primaryText,
  });

  final LevelManager levelManager;
  final GameThemeModel activeTheme;
  final Color primaryText;

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: activeTheme.selectedBlockBorderColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.map_rounded, color: primaryText, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Journey Mode',
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Unlocked: ${levelManager.highestUnlockedLevelNumber}/${levelManager.levels.length}',
                  style: TextStyle(
                    color: primaryText.withValues(alpha: 0.78),
                    fontSize: 13,
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

class _JourneyLevelCard extends StatelessWidget {
  const _JourneyLevelCard({
    required this.level,
    required this.unlocked,
    required this.activeTheme,
    required this.onTap,
  });

  final LevelModel level;
  final bool unlocked;
  final GameThemeModel activeTheme;
  final VoidCallback? onTap;

  Color _readableOn(Color bg) {
    return bg.computeLuminance() > 0.48
        ? const Color(0xFF10233F)
        : const Color(0xFFF3F8FF);
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryText = _readableOn(activeTheme.panelColor);
    final Color secondaryText = primaryText.withValues(alpha: 0.82);
    final Color accent = unlocked
        ? activeTheme.boardBorderColor
        : activeTheme.boardGridLineColor.withValues(alpha: 0.9);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: unlocked ? 1 : 0.72,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: unlocked
                    ? [
                        activeTheme.boardFillColor,
                        activeTheme.boardEmptyCellColor,
                      ]
                    : [
                        activeTheme.panelColor,
                        activeTheme.panelColor.withValues(alpha: 0.8),
                      ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: accent.withValues(alpha: 0.7),
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: unlocked
                          ? [
                              activeTheme.selectedBlockBorderColor,
                              activeTheme.boardBorderColor,
                            ]
                          : [
                              activeTheme.boardEmptyCellColor,
                              activeTheme.boardFillColor,
                            ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${level.number}',
                      style: TextStyle(
                        color: primaryText,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level.title,
                        style: TextStyle(
                          color: primaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        level.objective.label,
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        level.subtitle,
                        style: TextStyle(
                          color: secondaryText.withValues(alpha: 0.82),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      unlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                      color: unlocked
                          ? activeTheme.specialIceColor
                          : activeTheme.specialBombColor,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${level.rewardCoins}',
                      style: TextStyle(
                        color: activeTheme.selectedBlockBorderColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
