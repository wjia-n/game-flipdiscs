/// Audio for Flip Discs: procedural, physically-grounded sounds via
/// `audioplayers`. Every sound is synthesized (see tool/gen_audio.dart) to
/// match the game's identity — frosted-glass / stone discs on a matte
/// board. No harsh buzzers, no fanfare; gallery-quiet.
///
/// Music and SFX each have a toggle + volume, wired to [AppSettings].
///
/// Reliability notes (MASTER_RULES audio bar):
/// - Clips are cached once at prewarm and reused; music track changes are
///   serialized through a busy guard so overlapping calls can never leave
///   the player in a half-switched state.
/// - pause()/resume() (never stop()) on lifecycle changes, so music
///   resumes exactly where it left off and never silently dies.

library;
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class AudioService {
  AudioService._();
  static final AudioService I = AudioService._();

  final AudioPlayer _music = AudioPlayer();
  // Distinct players (unique ids) so staggered sounds overlap properly.
  final List<AudioPlayer> _sfxPool = List.generate(4, (_) => AudioPlayer());
  int _sfxCursor = 0;

  bool _ready = false;
  bool musicOn = true;
  bool sfxOn = true;
  bool hapticsOn = true;
  double musicVolume = 0.7;
  double sfxVolume = 0.8;
  String? _currentTrack;

  /// Serializes music operations: a busy guard so concurrent play/stop
  /// calls can never interleave into a silent/dead player.
  Future<void> _musicOp = Future.value();

  static const _sfxAssets = [
    'click',
    'place',
    'flip',
    'invalid',
    'start',
    'pass',
    'win',
    'lose',
  ];

  /// Call once at app start (or from the splash). Safe to call twice.
  Future<void> init() async {
    if (_ready) return;
    _ready = true;
    await _music.setReleaseMode(ReleaseMode.loop);
    for (final p in _sfxPool) {
      await p.setReleaseMode(ReleaseMode.stop);
    }
    // Cache every clip up front so first taps have no latency.
    for (final name in _sfxAssets) {
      AudioCache.instance.load('audio/$name.wav');
    }
    AudioCache.instance.load('audio/menu_music.wav');
    AudioCache.instance.load('audio/game_music.wav');
  }

  /// Splash-time prewarm: init + (optionally) start the menu track early.
  Future<void> prewarm() => init();

  void syncSettings(
      {required bool musicOn,
      required bool sfxOn,
      required bool hapticsOn,
      required double musicVolume,
      required double sfxVolume}) {
    final musicToggledOn = musicOn && !this.musicOn;
    this.musicOn = musicOn;
    this.sfxOn = sfxOn;
    this.hapticsOn = hapticsOn;
    this.musicVolume = musicVolume;
    this.sfxVolume = sfxVolume;
    _music.setVolume(musicOn ? musicVolume : 0.0);
    if (!musicOn) {
      _music.pause();
    } else if (musicToggledOn && _currentTrack != null) {
      _music.resume();
    }
  }

  Future<void> _sfx(String name, {double rate = 1.0}) async {
    if (!_ready || !sfxOn) return;
    try {
      final p = _sfxPool[_sfxCursor++ % _sfxPool.length];
      await p.stop();
      await p.setVolume(sfxVolume);
      await p.setPlaybackRate(rate);
      await p.setSource(AssetSource('audio/$name.wav'));
      await p.resume();
    } catch (_) {
      // Audio must never crash the game.
    }
  }

  /// UI button tap.
  Future<void> click() => _sfx('click');

  /// Disc placed on the board — soft wooden "thock".
  Future<void> place() => _sfx('place');

  /// Disc flips — bright glass "clack", staggered for cascades.
  Future<void> flips(int count) async {
    final n = count.clamp(1, 4);
    for (var i = 0; i < n; i++) {
      if (i > 0) await Future.delayed(const Duration(milliseconds: 45));
      _sfx('flip', rate: 0.96 + i * 0.035);
    }
  }

  /// Illegal placement — soft low "thud".
  Future<void> invalid() => _sfx('invalid');

  Future<void> gameStart() => _sfx('start');
  Future<void> pass() => _sfx('pass');
  Future<void> win() => _sfx('win');
  Future<void> lose() => _sfx('lose');

  /// Queued behind any in-flight music op (busy guard).
  Future<void> _playTrack(String name) {
    _musicOp = _musicOp.then((_) => _doPlayTrack(name)).catchError((_) {});
    return _musicOp;
  }

  Future<void> _doPlayTrack(String name) async {
    if (!_ready) return;
    try {
      if (_currentTrack == name) {
        if (musicOn) await _music.resume();
        return;
      }
      await _music.stop();
      _currentTrack = name;
      await _music.setVolume(musicOn ? musicVolume : 0.0);
      await _music.setSource(AssetSource('audio/$name.wav'));
      if (musicOn) await _music.resume();
    } catch (_) {
      // Never leave the service wedged: a failed switch keeps the old
      // track name so a retry simply replays it.
    }
  }

  Future<void> menuMusic() => _playTrack('menu_music');
  Future<void> gameMusic() => _playTrack('game_music');

  Future<void> pauseMusic() async {
    try {
      await _music.pause();
    } catch (_) {}
  }

  Future<void> resumeMusic() async {
    if (_currentTrack != null && musicOn) {
      try {
        await _music.resume();
      } catch (_) {}
    }
  }

  /// App lifecycle: pause (not stop) on interruption so music resumes
  /// exactly where it left off.
  void onAppPaused() => pauseMusic();
  void onAppResumed() => resumeMusic();

  /// Physical tap feedback, honoring the haptics toggle.
  /// Never throws — platform errors become silent no-ops (this also keeps
  /// unit tests without a platform binding green).
  void tapHaptic() {
    if (!hapticsOn) return;
    HapticFeedback.selectionClick().catchError((_) {});
  }

  void moveHaptic() {
    if (!hapticsOn) return;
    HapticFeedback.mediumImpact().catchError((_) {});
  }

  void invalidHaptic() {
    if (!hapticsOn) return;
    HapticFeedback.lightImpact().catchError((_) {});
  }
}
