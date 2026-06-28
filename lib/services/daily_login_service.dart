import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'storage_service.dart';

class DailyLoginResult {
  const DailyLoginResult({
    required this.shouldShowDialog,
    required this.rewardGranted,
    required this.spoofDetected,
    required this.rewardCoins,
    required this.streak,
    required this.totalCoins,
    this.message,
  });

  final bool shouldShowDialog;
  final bool rewardGranted;
  final bool spoofDetected;
  final int rewardCoins;
  final int streak;
  final int totalCoins;
  final String? message;
}

class DailyLoginService {
  DailyLoginService(this._storageService);

  final StorageService _storageService;

  static const String _lastClaimedEpochDayKey = 'daily_last_claimed_epoch_day';
  static const String _streakKey = 'daily_login_streak';
  static const String _highestSeenEpochMsKey = 'daily_highest_seen_epoch_ms';
  static const int _clockRollbackToleranceMs = 5 * 60 * 1000;

  Future<DailyLoginResult> checkAndClaimDailyReward() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final DateTime now = DateTime.now();
    final int nowMs = now.millisecondsSinceEpoch;
    final int highestSeenMs = prefs.getInt(_highestSeenEpochMsKey) ?? 0;

    if (highestSeenMs > 0 &&
        nowMs + _clockRollbackToleranceMs < highestSeenMs) {
      final int totalCoins = await _storageService.getCoinBalance();
      final int streak = prefs.getInt(_streakKey) ?? 0;
      return DailyLoginResult(
        shouldShowDialog: true,
        rewardGranted: false,
        spoofDetected: true,
        rewardCoins: 0,
        streak: streak,
        totalCoins: totalCoins,
        message:
            'Device time appears inconsistent. Daily reward is locked until time is corrected.',
      );
    }

    if (nowMs > highestSeenMs) {
      await prefs.setInt(_highestSeenEpochMsKey, nowMs);
    }

    final int todayEpochDay = _toEpochDay(now);
    final int? lastClaimedEpochDay = prefs.getInt(_lastClaimedEpochDayKey);

    if (lastClaimedEpochDay == todayEpochDay) {
      final int totalCoins = await _storageService.getCoinBalance();
      return DailyLoginResult(
        shouldShowDialog: false,
        rewardGranted: false,
        spoofDetected: false,
        rewardCoins: 0,
        streak: prefs.getInt(_streakKey) ?? 0,
        totalCoins: totalCoins,
      );
    }

    final int previousStreak = prefs.getInt(_streakKey) ?? 0;
    final int nextStreak;
    if (lastClaimedEpochDay != null &&
        todayEpochDay - lastClaimedEpochDay == 1) {
      nextStreak = previousStreak + 1;
    } else {
      nextStreak = 1;
    }

    final int rewardCoins = _rewardForStreak(nextStreak);
    final int totalCoins = await _storageService.addCoins(rewardCoins);

    await prefs.setInt(_lastClaimedEpochDayKey, todayEpochDay);
    await prefs.setInt(_streakKey, nextStreak);

    return DailyLoginResult(
      shouldShowDialog: true,
      rewardGranted: true,
      spoofDetected: false,
      rewardCoins: rewardCoins,
      streak: nextStreak,
      totalCoins: totalCoins,
    );
  }

  Future<int> getCurrentStreak() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_streakKey) ?? 0;
  }

  @visibleForTesting
  int rewardForStreak(int streak) => _rewardForStreak(streak);

  int _rewardForStreak(int streak) {
    final int capped = streak.clamp(1, 14);
    return 20 + (capped * 5);
  }

  int _toEpochDay(DateTime dt) {
    final DateTime localMidnight = DateTime(dt.year, dt.month, dt.day);
    return localMidnight.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  }
}
