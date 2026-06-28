import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdmobService {
  static final AdmobService instance = AdmobService._();

  AdmobService._();

  bool _isInitialized = false;

  bool get _isSupportedPlatform {
    if (const bool.fromEnvironment('FLUTTER_TEST')) {
      return false;
    }
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  String get _bannerAdUnitId {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ca-app-pub-3940256099942544/6300978111';
      case TargetPlatform.iOS:
        return 'ca-app-pub-3940256099942544/2934735716';
      default:
        return '';
    }
  }

  String get _interstitialAdUnitId {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ca-app-pub-3940256099942544/1033173712';
      case TargetPlatform.iOS:
        return 'ca-app-pub-3940256099942544/4411468910';
      default:
        return '';
    }
  }

  String get _rewardedAdUnitId {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ca-app-pub-3940256099942544/5224354917';
      case TargetPlatform.iOS:
        return 'ca-app-pub-3940256099942544/1712485313';
      default:
        return '';
    }
  }

  Future<void> initialize() async {
    if (_isInitialized || !_isSupportedPlatform) {
      return;
    }

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
    } catch (_) {
      _isInitialized = false;
    }
  }

  BannerAd? createBannerAd({
    required VoidCallback onLoaded,
    required void Function(LoadAdError error) onFailed,
  }) {
    if (!_isSupportedPlatform || _bannerAdUnitId.isEmpty) {
      return null;
    }

    final BannerAd ad = BannerAd(
      adUnitId: _bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onFailed(error);
        },
      ),
    );

    try {
      ad.load();
    } catch (_) {
      ad.dispose();
      return null;
    }

    return ad;
  }

  Future<InterstitialAd?> loadInterstitialAd() async {
    if (!_isSupportedPlatform || _interstitialAdUnitId.isEmpty) {
      return null;
    }

    final Completer<InterstitialAd?> completer = Completer<InterstitialAd?>();

    try {
      InterstitialAd.load(
        adUnitId: _interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            if (!completer.isCompleted) {
              completer.complete(ad);
            }
          },
          onAdFailedToLoad: (error) {
            if (!completer.isCompleted) {
              completer.complete(null);
            }
          },
        ),
      );
    } catch (_) {
      return null;
    }

    return completer.future;
  }

  Future<RewardedAd?> loadRewardedAd() async {
    if (!_isSupportedPlatform || _rewardedAdUnitId.isEmpty) {
      return null;
    }

    final Completer<RewardedAd?> completer = Completer<RewardedAd?>();

    try {
      RewardedAd.load(
        adUnitId: _rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            if (!completer.isCompleted) {
              completer.complete(ad);
            }
          },
          onAdFailedToLoad: (error) {
            if (!completer.isCompleted) {
              completer.complete(null);
            }
          },
        ),
      );
    } catch (_) {
      return null;
    }

    return completer.future;
  }
}
