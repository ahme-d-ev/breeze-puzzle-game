import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../services/admob_service.dart';
import '../services/daily_login_service.dart';
import '../services/storage_service.dart';
import '../services/theme_manager.dart';
import 'game_screen.dart';
import 'journey_mode_screen.dart';
import 'shop_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  final StorageService _storageService = StorageService();
  late final DailyLoginService _dailyLoginService;
  int _bestScore = 0;

  late final AnimationController _playPulseController;
  late final AnimationController _entryController;
  late final Animation<double> _playScale;
  late final Animation<double> _buttonsFade;
  late final Animation<Offset> _buttonsSlide;

  @override
  void initState() {
    super.initState();

    _dailyLoginService = DailyLoginService(_storageService);

    _playPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();

    _playScale = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _playPulseController, curve: Curves.easeInOut),
    );
    _buttonsFade = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _buttonsSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    _loadBanner();
    _loadBestScore();
    _checkDailyLoginReward();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _playPulseController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _loadBestScore() async {
    final int best = await _storageService.getBestScore();
    if (!mounted) {
      return;
    }
    setState(() {
      _bestScore = best;
    });
  }

  Future<void> _checkDailyLoginReward() async {
    final DailyLoginResult result = await _dailyLoginService
        .checkAndClaimDailyReward();
    if (!mounted || !result.shouldShowDialog) {
      return;
    }

    await context.read<ThemeManager>().refreshCoins();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _DailyLoginDialog(result: result),
      );
    });
  }

  Future<void> _showDailyRewardStatus() async {
    final int streak = await _dailyLoginService.getCurrentStreak();
    final DailyLoginResult result = await _dailyLoginService
        .checkAndClaimDailyReward();
    if (!mounted) {
      return;
    }

    if (result.shouldShowDialog) {
      await context.read<ThemeManager>().refreshCoins();
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _DailyLoginDialog(result: result),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Daily reward already claimed. Current streak: $streak'),
      ),
    );
  }

  void _loadBanner() {
    _bannerAd = AdmobService.instance.createBannerAd(
      onLoaded: () {
        if (!mounted) {
          return;
        }
        setState(() {
          _isBannerLoaded = true;
        });
      },
      onFailed: (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isBannerLoaded = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double maxContentWidth = screenSize.width > 600
        ? 520
        : screenSize.width * 0.92;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/backgraond.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0x6600102B),
                    const Color(0x3300102B),
                    const Color(0xAA000814),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    children: [
                      const Spacer(flex: 8),
                      ScaleTransition(
                        scale: _playScale,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const GameScreen(),
                              ),
                            );
                          },
                          child: SizedBox(
                            width: double.infinity,
                            child: Stack(
                              children: [
                                Container(
                                  height: 86,
                                  margin: const EdgeInsets.only(top: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A3EAF),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                Container(
                                  height: 86,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: <Color>[
                                        Color(0xFF68D8FF),
                                        Color(0xFF2E97FF),
                                        Color(0xFF2E59DE),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x9939C1FF),
                                        blurRadius: 20,
                                        spreadRadius: 1,
                                      ),
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 14,
                                        offset: Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'PLAY',
                                      style: TextStyle(
                                        fontSize: 34,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 1.8,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 66,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const JourneyModeScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.map_rounded, size: 26),
                          label: const Text(
                            'JOURNEY MODE',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xCC1E4B9B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeTransition(
                        opacity: _buttonsFade,
                        child: SlideTransition(
                          position: _buttonsSlide,
                          child: Row(
                            children: [
                              Expanded(
                                child: _HomeActionButton(
                                  icon: Icons.settings,
                                  label: 'Settings',
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => const SettingsScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _HomeActionButton(
                                  icon: Icons.card_giftcard,
                                  label: 'Daily Reward',
                                  onTap: _showDailyRewardStatus,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _HomeActionButton(
                                  icon: Icons.storefront_rounded,
                                  label: 'Shop',
                                  onTap: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => const ShopScreen(),
                                      ),
                                    );
                                    if (!context.mounted) {
                                      return;
                                    }
                                    await context
                                        .read<ThemeManager>()
                                        .refreshCoins();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _HomeStatsPanel(bestScore: _bestScore),
                      const Spacer(flex: 2),
                      if (_isBannerLoaded && _bannerAd != null)
                        SizedBox(
                          width: _bannerAd!.size.width.toDouble(),
                          height: _bannerAd!.size.height.toDouble(),
                          child: AdWidget(ad: _bannerAd!),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeActionButton extends StatelessWidget {
  const _HomeActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xCC3E7ED2), Color(0xCC295AA5)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x88BDEAFF)),
        boxShadow: const [
          BoxShadow(color: Color(0x5533A6FF), blurRadius: 12, spreadRadius: 1),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: const Color(0xFFE9F7FF)),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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

class _HomeStatsPanel extends StatelessWidget {
  const _HomeStatsPanel({required this.bestScore});

  final int bestScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xCC6E89C7), Color(0xCC2C4E91)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x88D4F2FF)),
        boxShadow: const [
          BoxShadow(color: Color(0x663198F4), blurRadius: 14, spreadRadius: 1),
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFFFD257),
                ),
                const SizedBox(width: 8),
                Text(
                  'Best: $bestScore',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 26,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          Expanded(
            child: Consumer<ThemeManager>(
              builder: (context, themeManager, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.monetization_on_rounded,
                      color: Color(0xFFFFD257),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Coins: ${themeManager.coins}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyLoginDialog extends StatelessWidget {
  const _DailyLoginDialog({required this.result});

  final DailyLoginResult result;

  @override
  Widget build(BuildContext context) {
    final bool spoof = result.spoofDetected;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF0D2E67),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: spoof ? const Color(0xFFFF8A65) : const Color(0xFF55D6FF),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              spoof ? Icons.warning_rounded : Icons.card_giftcard_rounded,
              color: spoof ? const Color(0xFFFFB199) : const Color(0xFFFFD54F),
              size: 42,
            ),
            const SizedBox(height: 10),
            Text(
              spoof ? 'Daily Reward Locked' : 'Daily Login Reward',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            if (!spoof) ...[
              Text(
                '+${result.rewardCoins} coins',
                style: const TextStyle(
                  color: Color(0xFFFFD54F),
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Streak: ${result.streak} day${result.streak == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: Color(0xFFB9D5FF),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Total coins: ${result.totalCoins}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ] else ...[
              Text(
                result.message ??
                    'Device time seems manipulated. Correct system time and try again.',
                style: const TextStyle(
                  color: Color(0xFFFFE0D6),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: spoof
                      ? const Color(0xFFB34D2E)
                      : const Color(0xFF2D72FF),
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
