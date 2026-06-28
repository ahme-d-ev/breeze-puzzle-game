import 'package:flutter/services.dart';

import 'storage_service.dart';

class GameAudioService {
  GameAudioService({StorageService? storageService})
    : _storageService = storageService ?? StorageService();

  final StorageService _storageService;

  Future<void> playPlaceSound() async {
    if (!await _storageService.isSoundEffectsEnabled()) {
      return;
    }
    await SystemSound.play(SystemSoundType.click);
  }

  Future<void> playClearSound() async {
    if (!await _storageService.isSoundEffectsEnabled()) {
      return;
    }
    await SystemSound.play(SystemSoundType.alert);
    await Future<void>.delayed(const Duration(milliseconds: 70));
    await SystemSound.play(SystemSoundType.click);
  }

  Future<void> playErrorSound() async {
    if (!await _storageService.isSoundEffectsEnabled()) {
      return;
    }
    await SystemSound.play(SystemSoundType.alert);
  }
}
