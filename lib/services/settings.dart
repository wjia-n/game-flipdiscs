/// Local persistence for Flip Discs: settings + lightweight stats.
///
/// Backed by shared_preferences. No backend, everything on-device.

library;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/ai.dart';

class AppSettings extends ChangeNotifier {
  static const _kMusicOn = 'music_on';
  static const _kSfxOn = 'sfx_on';
  static const _kMusicVol = 'music_vol';
  static const _kSfxVol = 'sfx_vol';
  static const _kDifficulty = 'difficulty';
  static const _kShowHints = 'show_hints';
  static const _kHaptics = 'haptics_on';

  static const _kGamesPlayed = 'games_played';
  static const _kBotWins = 'bot_wins';
  static const _kBotLosses = 'bot_losses';
  static const _kBotDraws = 'bot_draws';
  static const _kP2BlackWins = 'p2_black_wins';
  static const _kP2WhiteWins = 'p2_white_wins';
  static const _kP2Draws = 'p2_draws';

  late SharedPreferences _prefs;
  bool _loaded = false;
  bool get loaded => _loaded;

  // --- settings ---
  bool musicOn = true;
  bool sfxOn = true;
  double musicVolume = 0.7;
  double sfxVolume = 0.8;
  BotDifficulty difficulty = BotDifficulty.medium;
  bool showHints = true;
  bool hapticsOn = true;

  // --- stats ---
  int gamesPlayed = 0;
  int botWins = 0;
  int botLosses = 0;
  int botDraws = 0;
  int p2BlackWins = 0;
  int p2WhiteWins = 0;
  int p2Draws = 0;

  /// "EXHIBITION 04"-style session label.
  String get exhibitionLabel =>
      'EXHIBITION ${(gamesPlayed + 1).toString().padLeft(2, '0')}';

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    musicOn = _prefs.getBool(_kMusicOn) ?? true;
    sfxOn = _prefs.getBool(_kSfxOn) ?? true;
    musicVolume = _prefs.getDouble(_kMusicVol) ?? 0.7;
    sfxVolume = _prefs.getDouble(_kSfxVol) ?? 0.8;
    difficulty = BotDifficulty
        .values[_prefs.getInt(_kDifficulty) ?? BotDifficulty.medium.index];
    showHints = _prefs.getBool(_kShowHints) ?? true;
    hapticsOn = _prefs.getBool(_kHaptics) ?? true;

    gamesPlayed = _prefs.getInt(_kGamesPlayed) ?? 0;
    botWins = _prefs.getInt(_kBotWins) ?? 0;
    botLosses = _prefs.getInt(_kBotLosses) ?? 0;
    botDraws = _prefs.getInt(_kBotDraws) ?? 0;
    p2BlackWins = _prefs.getInt(_kP2BlackWins) ?? 0;
    p2WhiteWins = _prefs.getInt(_kP2WhiteWins) ?? 0;
    p2Draws = _prefs.getInt(_kP2Draws) ?? 0;

    _loaded = true;
    notifyListeners();
  }

  Future<void> _saveBool(String k, bool v) async {
    await _prefs.setBool(k, v);
    notifyListeners();
  }

  Future<void> _saveDouble(String k, double v) async {
    await _prefs.setDouble(k, v);
    notifyListeners();
  }

  Future<void> setMusicOn(bool v) async {
    musicOn = v;
    await _saveBool(_kMusicOn, v);
  }

  Future<void> setSfxOn(bool v) async {
    sfxOn = v;
    await _saveBool(_kSfxOn, v);
  }

  Future<void> setMusicVolume(double v) async {
    musicVolume = v.clamp(0.0, 1.0);
    await _saveDouble(_kMusicVol, musicVolume);
  }

  Future<void> setSfxVolume(double v) async {
    sfxVolume = v.clamp(0.0, 1.0);
    await _saveDouble(_kSfxVol, sfxVolume);
  }

  Future<void> setDifficulty(BotDifficulty d) async {
    difficulty = d;
    await _prefs.setInt(_kDifficulty, d.index);
    notifyListeners();
  }

  Future<void> setShowHints(bool v) async {
    showHints = v;
    await _saveBool(_kShowHints, v);
  }

  Future<void> setHapticsOn(bool v) async {
    hapticsOn = v;
    await _saveBool(_kHaptics, v);
  }

  /// Records a finished game: [vsBot] distinguishes the two modes.
  /// [winner] is 1 (Black), 2 (White) or 0 (draw); in vs-bot mode the
  /// human always plays Black.
  Future<void> recordResult({required bool vsBot, required int winner}) async {
    gamesPlayed++;
    if (vsBot) {
      if (winner == 0) {
        botDraws++;
      } else if (winner == 1) {
        botWins++;
      } else {
        botLosses++;
      }
    } else {
      if (winner == 0) {
        p2Draws++;
      } else if (winner == 1) {
        p2BlackWins++;
      } else {
        p2WhiteWins++;
      }
    }
    await _prefs.setInt(_kGamesPlayed, gamesPlayed);
    await _prefs.setInt(_kBotWins, botWins);
    await _prefs.setInt(_kBotLosses, botLosses);
    await _prefs.setInt(_kBotDraws, botDraws);
    await _prefs.setInt(_kP2BlackWins, p2BlackWins);
    await _prefs.setInt(_kP2WhiteWins, p2WhiteWins);
    await _prefs.setInt(_kP2Draws, p2Draws);
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    musicOn = true;
    sfxOn = true;
    musicVolume = 0.7;
    sfxVolume = 0.8;
    difficulty = BotDifficulty.medium;
    showHints = true;
    hapticsOn = true;
    await _prefs.setBool(_kMusicOn, musicOn);
    await _prefs.setBool(_kSfxOn, sfxOn);
    await _prefs.setDouble(_kMusicVol, musicVolume);
    await _prefs.setDouble(_kSfxVol, sfxVolume);
    await _prefs.setInt(_kDifficulty, difficulty.index);
    await _prefs.setBool(_kShowHints, showHints);
    await _prefs.setBool(_kHaptics, hapticsOn);
    notifyListeners();
  }
}
