import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../services/admob_service.dart';
import '../services/storage_service.dart';
import '../services/theme_manager.dart';
import '../widgets/app_background.dart';
import 'game_screen.dart';

class GameOverScreen extends StatefulWidget {
  const GameOverScreen({super.key, this.score = 0, this.playAgainBuilder});

  final int score;
  final WidgetBuilder? playAgainBuilder;

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen> {
  static const int _rewardedAdCoins = 5;

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isLoadingRewarded = false;

  @override
  void initState() {
    super.initState();
    _loadInterstitialAndShow();
    _loadRewardedAd();
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  Future<void> _loadInterstitialAndShow() async {
    _interstitialAd = await AdmobService.instance.loadInterstitialAd();
    if (!mounted || _interstitialAd == null) {
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) => ad.dispose(),
      onAdFailedToShowFullScreenContent: (ad, error) => ad.dispose(),
    );
    _interstitialAd!.show();
  }

  Future<void> _loadRewardedAd() async {
    _rewardedAd = await AdmobService.instance.loadRewardedAd();
    if (!mounted) {
      _rewardedAd?.dispose();
      return;
    }
    setState(() {});
  }

  void _startNewGame() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: widget.playAgainBuilder ?? ((_) => const GameScreen()),
      ),
    );
  }

  Future<void> _watchRewardAndContinue() async {
    if (_rewardedAd == null || _isLoadingRewarded) {
      return;
    }

    setState(() {
      _isLoadingRewarded = true;
    });

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
        if (mounted) {
          setState(() {
            _isLoadingRewarded = false;
          });
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        if (mounted) {
          setState(() {
            _isLoadingRewarded = false;
          });
        }
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        _grantRewardCoinsAndContinue();
      },
    );
  }

  Future<void> _grantRewardCoinsAndContinue() async {
    await StorageService().addCoins(_rewardedAdCoins);
    if (!mounted) {
      return;
    }

    await context.read<ThemeManager>().refreshCoins();
    if (!mounted) {
      return;
    }

    _startNewGame();
  }

  Color _readableOn(Color bg) {
    return bg.computeLuminance() > 0.48
        ? const Color(0xFF10233F)
        : const Color(0xFFF3F8FF);
  }

  @override
  Widget build(BuildContext context) {
    final activeTheme = context.watch<ThemeManager>().activeTheme;
    final Color primaryText = _readableOn(activeTheme.panelColor);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: GamePanel(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Game Over',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: primaryText,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Score: ${widget.score}',
                        style: TextStyle(
                          fontSize: 24,
                          color: activeTheme.selectedBlockBorderColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _rewardedAd == null || _isLoadingRewarded
                            ? null
                            : _watchRewardAndContinue,
                        child: Text(
                          _isLoadingRewarded
                              ? 'Loading...'
                              : 'Second Chance (Rewarded)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _startNewGame,
                        child: const Text('Play Again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
