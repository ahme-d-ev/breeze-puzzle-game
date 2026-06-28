import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_theme_model.dart';
import '../services/theme_manager.dart';
import '../widgets/app_background.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  Color _readableOn(Color bg) {
    return bg.computeLuminance() > 0.48
        ? const Color(0xFF10233F)
        : const Color(0xFFF3F8FF);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Consumer<ThemeManager>(
            builder: (context, themeManager, _) {
              final GameThemeModel active = themeManager.activeTheme;
              final List<GameThemeModel> themes = themeManager.allThemes;
              final Color primaryText = _readableOn(active.panelColor);

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                    child: Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Theme Shop',
                            style: TextStyle(
                              color: primaryText,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: active.blockContainerColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: active.selectedBlockBorderColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.monetization_on_rounded,
                                color: active.selectedBlockBorderColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${themeManager.coins}',
                                style: TextStyle(
                                  color: primaryText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
                      itemBuilder: (context, index) {
                        final GameThemeModel theme = themes[index];
                        final bool isActive = active.id == theme.id;
                        final bool owned = themeManager.isOwned(theme.id);

                        return _ThemeCard(
                          theme: theme,
                          activeUiTheme: active,
                          owned: owned,
                          isActive: isActive,
                          onTry: () async {
                            await themeManager.previewTheme(theme.id);
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Previewing ${theme.name}.'),
                              ),
                            );
                          },
                          onAction: () async {
                            if (owned) {
                              await themeManager.selectTheme(theme.id);
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${theme.name} equipped.'),
                                ),
                              );
                              return;
                            }

                            final PurchaseResult result = await themeManager
                                .purchaseTheme(theme.id);
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(result.message)),
                            );
                          },
                        );
                      },
                      separatorBuilder: (context, index) {
                        return const SizedBox(height: 12);
                      },
                      itemCount: themes.length,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.theme,
    required this.activeUiTheme,
    required this.owned,
    required this.isActive,
    required this.onTry,
    required this.onAction,
  });

  final GameThemeModel theme;
  final GameThemeModel activeUiTheme;
  final bool owned;
  final bool isActive;
  final VoidCallback onTry;
  final VoidCallback onAction;

  Color _readableOn(Color bg) {
    return bg.computeLuminance() > 0.48
        ? const Color(0xFF10233F)
        : const Color(0xFFF3F8FF);
  }

  @override
  Widget build(BuildContext context) {
    final String actionLabel = owned
        ? (isActive ? 'Equipped' : 'Equip')
        : 'Buy ${theme.price}';
    final bool canTry = !isActive;

    final Color primaryText = _readableOn(activeUiTheme.panelColor);
    final Color secondaryText = primaryText.withValues(alpha: 0.78);

    return GamePanel(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _ThemeSwatch(theme: theme),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  theme.name,
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  theme.description,
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 104,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: canTry ? onTry : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryText,
                      side: BorderSide(color: activeUiTheme.boardGridLineColor),
                    ),
                    child: const Text('Try'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: owned && isActive ? null : onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: owned
                          ? activeUiTheme.specialMagnetColor
                          : activeUiTheme.selectedBlockBorderColor,
                      foregroundColor: _readableOn(
                        activeUiTheme.selectedBlockBorderColor,
                      ),
                      disabledBackgroundColor:
                          activeUiTheme.boardEmptyCellColor,
                      disabledForegroundColor: secondaryText,
                    ),
                    child: Text(actionLabel),
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

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({required this.theme});

  final GameThemeModel theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: theme.backgroundGradient,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.boardBorderColor, width: 1.4),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 42,
              height: 24,
              decoration: BoxDecoration(
                color: theme.boardEmptyCellColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: theme.boardGridLineColor),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 18,
              decoration: BoxDecoration(
                color: theme.bottomBlocksColor,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
