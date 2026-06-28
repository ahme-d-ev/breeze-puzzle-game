import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_theme_model.dart';
import '../services/theme_manager.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final GameThemeModel theme = context.watch<ThemeManager>().activeTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: theme.backgroundGradient,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _BackgroundGlowPainter(theme)),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(
              height: 110,
              child: IgnorePointer(
                child: CustomPaint(painter: _BottomBlocksPainter(theme)),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class GamePanel extends StatelessWidget {
  const GamePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final GameThemeModel theme = context.watch<ThemeManager>().activeTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      padding: padding,
      decoration: BoxDecoration(
        color: theme.panelColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.panelBorderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _BackgroundGlowPainter extends CustomPainter {
  _BackgroundGlowPainter(this.theme);

  final GameThemeModel theme;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint glow = Paint();

    glow.shader =
        RadialGradient(
          colors: [theme.glowColorA, theme.glowColorA.withValues(alpha: 0)],
        ).createShader(
          Rect.fromCircle(
            center: Offset(size.width * 0.2, size.height * 0.2),
            radius: size.width * 0.5,
          ),
        );
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.2),
      size.width * 0.5,
      glow,
    );

    glow.shader =
        RadialGradient(
          colors: [theme.glowColorB, theme.glowColorB.withValues(alpha: 0)],
        ).createShader(
          Rect.fromCircle(
            center: Offset(size.width * 0.8, size.height * 0.55),
            radius: size.width * 0.45,
          ),
        );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.55),
      size.width * 0.45,
      glow,
    );

    final Paint tile = Paint()..color = theme.tileOverlayColor;
    const double box = 34;
    for (double y = 0; y < size.height; y += box) {
      for (double x = 0; x < size.width; x += box) {
        final bool draw = ((x / box).floor() + (y / box).floor()) % 2 == 0;
        if (draw) {
          canvas.drawRect(Rect.fromLTWH(x, y, box - 2, box - 2), tile);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundGlowPainter oldDelegate) {
    return oldDelegate.theme.id != theme.id;
  }
}

class _BottomBlocksPainter extends CustomPainter {
  _BottomBlocksPainter(this.theme);

  final GameThemeModel theme;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()..color = theme.bottomBlocksColor;
    const double block = 38;
    for (double x = -8; x < size.width + block; x += block) {
      for (double y = size.height - 65; y < size.height + block; y += block) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, block - 6, block - 6),
            const Radius.circular(4),
          ),
          p,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BottomBlocksPainter oldDelegate) {
    return oldDelegate.theme.id != theme.id;
  }
}
