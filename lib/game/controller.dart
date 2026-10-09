/// Game state management for Flip Discs.
///
/// The engine (ReversiEngine) owns the rules; this controller owns the
/// TURN STATE MACHINE. Every turn moves through explicit phases, each
/// driven by exactly one armed timer:
///
///   idle → thinking → placing → flipping → idle → … → over
///
/// - [TurnPhase.thinking]: a bot side is "thinking" (visible narration in
///   its tray); fires [_botCommit].
/// - [TurnPhase.placing]: the chosen disc appears with a place animation.
/// - [TurnPhase.flipping]: flips cascade outward as a visible wave.
/// - [TurnPhase.idle]: a human side is expected to tap (no timer needed).
///
/// A watchdog ([Timer.periodic]) re-arms any phase found without its live
/// timer, so stuck states are impossible by construction. Pause freezes
/// the phase timer; resume re-arms the current phase via the watchdog.

library;
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../game/ai.dart';
import '../game/engine.dart';
import '../services/audio.dart';
import '../services/settings.dart';

enum GameMode { vsBot, twoPlayer, demo }

enum TurnPhase { idle, thinking, placing, flipping, over }

class GameController extends ChangeNotifier {
  final AppSettings settings;
  final GameMode mode;

  final ReversiEngine engine = ReversiEngine();
  final int gameSeed;

  TurnPhase phase = TurnPhase.idle;
  bool over = false;

  /// Cells flipped by the most recent move (for flip animation).
  List<int> lastFlips = [];
  int flipEpoch = 0;

  /// Most recently placed cell (for place animation).
  int lastPlaced = -1;

  /// Invalid-tap feedback: cell index + nonce to retrigger the shake.
  int invalidCell = -1;
  int invalidNonce = 0;

  String? passMessage;
  DateTime startedAt = DateTime.now();
  int? winner; // 0 draw, 1 black, 2 white — set when over

  Timer? _phaseTimer; // the single live phase-transition timer
  Timer? _watchdog; // stuck-state recovery
  bool _disposed = false;
  bool _paused = false;
  bool get paused => _paused;

  MoveOutcome? _pendingOutcome; // move currently being staged
  int _stagedSide = -1; // side whose move is animating (placing/flipping)

  /// Whose tray is "active" right now: while a move animates, the mover —
  /// not the side the engine already advanced to.
  int get displayTurn =>
      (phase == TurnPhase.placing || phase == TurnPhase.flipping) &&
              _stagedSide >= 0
          ? _stagedSide
          : engine.sideToMove;

  GameController({required this.settings, required this.mode})
      : gameSeed = DateTime.now().millisecondsSinceEpoch & 0x3fffffff {
    _watchdog = Timer.periodic(const Duration(seconds: 3), (_) => _recover());
  }

  bool get vsBot => mode == GameMode.vsBot;
  bool get demoMode => mode == GameMode.demo;
  BotDifficulty get difficulty => settings.difficulty;

  int get blackCount => engine.countOf(black);
  int get whiteCount => engine.countOf(white);
  int get turn => engine.sideToMove;
  int get round => (engine.moveNumber ~/ 2) + 1;

  Set<int> get legalMoves => engine.legalMoves().toSet();

  bool isBotSide(int side) => switch (mode) {
        GameMode.vsBot => side == white,
        GameMode.demo => true,
        GameMode.twoPlayer => false,
      };

  bool get botThinking => phase == TurnPhase.thinking;

  bool get humanTurn =>
      !over && phase == TurnPhase.idle && !isBotSide(engine.sideToMove);

  String nameOf(int side) => settings.playerName(side == black ? 0 : 1);

  String get turnLabel {
    if (over) return 'Game over';
    final side = displayTurn;
    if (isBotSide(side)) return '${nameOf(side)} thinking…';
    return '${nameOf(side)} to move';
  }

  /// Per-side tray narration: what that side is visibly doing right now.
  String sideNarration(int side) {
    if (over || side != displayTurn) return '';
    final name = nameOf(side);
    return switch (phase) {
      TurnPhase.thinking => '$name is thinking…',
      TurnPhase.placing =>
        lastPlaced >= 0 ? '$name plays ${squareName(lastPlaced)}' : '$name plays…',
      TurnPhase.flipping => lastFlips.length == 1
          ? 'Flipping 1 disc…'
          : 'Flipping ${lastFlips.length} discs…',
      TurnPhase.idle =>
        isBotSide(side) ? '$name is thinking…' : '$name to move',
      TurnPhase.over => '',
    };
  }

  /// Algebraic square name: columns a–h left→right, rows 1–8 bottom→top.
  static String squareName(int index) {
    const cols = 'abcdefgh';
    final row = 8 - (index ~/ 8);
    return '${cols[index % 8]}$row';
  }

  /// Stagger delay for a flipped cell: the cascade ripples outward from
  /// the placed disc, so the flip wave is visibly physical.
  Duration flipDelayFor(int index) {
    if (phase != TurnPhase.flipping || lastPlaced < 0) {
      return Duration.zero;
    }
    if (!lastFlips.contains(index)) return Duration.zero;
    final dr = (index ~/ 8 - lastPlaced ~/ 8).abs();
    final dc = (index % 8 - lastPlaced % 8).abs();
    final wave = dr > dc ? dr : dc;
    return Duration(milliseconds: wave * 90);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _phaseTimer?.cancel();
    _phaseTimer = null;
    _watchdog?.cancel();
    _watchdog = null;
    super.dispose();
  }

  Future<void> start() async {
    engine.reset();
    over = false;
    winner = null;
    phase = TurnPhase.idle;
    lastFlips = [];
    lastPlaced = -1;
    flipEpoch++;
    invalidCell = -1;
    passMessage = null;
    _pendingOutcome = null;
    _stagedSide = -1;
    startedAt = DateTime.now();
    await AudioService.I.gameStart();
    _notify();
    _advance();
  }

  /// Arms the single phase timer. Only one may be live at a time.
  void _arm(Duration d, void Function() fn) {
    if (_disposed || _paused) return;
    _phaseTimer?.cancel();
    _phaseTimer = Timer(d, () {
      _phaseTimer = null;
      if (!_disposed && !_paused) fn();
    });
  }

  /// Watchdog: if a phase ever loses its timer, recover immediately.
  /// Makes stuck states impossible by construction.
  void _recover() {
    if (_disposed || _paused) return;
    if (over) {
      if (phase != TurnPhase.over) {
        phase = TurnPhase.over;
        _notify();
      }
      return;
    }
    if (_phaseTimer != null) return; // healthy: a transition is scheduled
    switch (phase) {
      case TurnPhase.thinking:
        _botCommit(); // thinking with no timer: commit now
      case TurnPhase.placing:
        _toFlipping(); // placing with no timer: start the cascade
      case TurnPhase.flipping:
        _afterMove(); // flipping with no timer: settle the move
      case TurnPhase.idle:
        if (isBotSide(engine.sideToMove)) _beginBotTurn();
      case TurnPhase.over:
        break;
    }
  }

  /// Advance the state machine after a settled move (or at game start).
  void _advance() {
    if (_disposed || _paused || over) return;
    if (engine.isGameOver) {
      _finish();
      return;
    }
    final side = engine.sideToMove;
    if (isBotSide(side)) {
      _beginBotTurn();
    } else {
      phase = TurnPhase.idle;
      _notify();
    }
  }

  void _beginBotTurn() {
    if (_disposed || _paused || over) return;
    phase = TurnPhase.thinking;
    _notify();
    // Visible "thinking" beat — the bot never resolves instantly.
    _arm(const Duration(milliseconds: 950), _botCommit);
  }

  void _botCommit() {
    if (_disposed || _paused || over) return;
    if (phase != TurnPhase.thinking) return;
    final side = engine.sideToMove;
    final moves = engine.legalMoves(side);
    if (moves.isEmpty) {
      // Defensive: the engine auto-passes inside play(), so the side to
      // move always has a move unless the game is over.
      _advance();
      return;
    }
    final choice = chooseBotMove(engine, side, difficulty,
        seed: gameSeed + engine.moveNumber);
    final outcome = engine.play(choice);
    if (outcome == null) {
      // AI only picks legal moves; if this ever happened, skip the turn
      // rather than wedge the machine.
      _advance();
      return;
    }
    if (vsBot) engine.markBotMove();
    _stageMove(outcome, choice, side);
  }

  /// Player taps a cell. Handles placement, invalid feedback, passes,
  /// bot replies and game end.
  Future<void> tapCell(int index) async {
    if (over || _paused) return;
    if (!humanTurn) return;

    final side = engine.sideToMove;
    final outcome = engine.play(index);
    if (outcome == null) {
      // Illegal placement: gentle shake + soft low thock (gallery calm).
      invalidCell = index;
      invalidNonce++;
      AudioService.I.invalid();
      AudioService.I.invalidHaptic();
      _notify();
      return;
    }
    _stageMove(outcome, index, side);
  }

  /// Stages a committed move visibly: placing → flipping cascade.
  void _stageMove(MoveOutcome outcome, int index, int side) {
    _pendingOutcome = outcome;
    _stagedSide = side;
    lastPlaced = index;
    lastFlips = outcome.flips;
    flipEpoch++;
    passMessage = outcome.opponentPassed
        ? '${nameOf(opponentOf(engine.sideToMove))} has no moves — passes'
        : null;
    AudioService.I.place();
    AudioService.I.moveHaptic();
    phase = TurnPhase.placing;
    _notify();
    // Let the placed disc land before the cascade starts.
    _arm(const Duration(milliseconds: 340), _toFlipping);
  }

  void _toFlipping() {
    if (_disposed || _paused || over) return;
    if (phase != TurnPhase.placing) return;
    phase = TurnPhase.flipping;
    if (lastFlips.isNotEmpty) {
      AudioService.I.flips(lastFlips.length);
    }
    _notify();
    // Long enough for the outermost flip wave to finish.
    var waves = 0;
    if (lastPlaced >= 0) {
      for (final f in lastFlips) {
        final dr = (f ~/ 8 - lastPlaced ~/ 8).abs();
        final dc = (f % 8 - lastPlaced % 8).abs();
        final w = dr > dc ? dr : dc;
        if (w > waves) waves = w;
      }
    }
    _arm(Duration(milliseconds: 420 + waves * 90), _afterMove);
  }

  void _afterMove() {
    if (_disposed || _paused || over) return;
    final outcome = _pendingOutcome;
    _pendingOutcome = null;
    _stagedSide = -1;
    if (outcome == null) {
      _advance();
      return;
    }
    if (outcome.gameOver) {
      _finish();
      return;
    }
    if (outcome.opponentPassed) {
      AudioService.I.pass();
    }
    _advance();
  }

  /// Undo: in vs-bot mode pops a full round (bot + human) so it is the
  /// human's turn again; in 2-player mode pops a single move.
  void undo() {
    if (over || phase != TurnPhase.idle || !engine.canUndo) return;
    AudioService.I.click();
    _phaseTimer?.cancel();
    _phaseTimer = null;
    _pendingOutcome = null;
    _stagedSide = -1;
    if (vsBot) {
      var guard = 0;
      do {
        if (!engine.undo()) break;
        guard++;
      } while (engine.sideToMove != black && guard < 4);
    } else {
      engine.undo();
    }
    lastFlips = [];
    lastPlaced = -1;
    flipEpoch++;
    passMessage = null;
    if (demoMode) {
      _advance();
    } else {
      phase = TurnPhase.idle;
      _notify();
    }
  }

  void setPaused(bool value) {
    if (_paused == value || _disposed) return;
    _paused = value;
    if (value) {
      _phaseTimer?.cancel();
      _phaseTimer = null;
      AudioService.I.pauseMusic();
    } else {
      AudioService.I.resumeMusic();
      _recover(); // re-arm the current phase
      _notify();
    }
  }

  void _finish() {
    over = true;
    phase = TurnPhase.over;
    _phaseTimer?.cancel();
    _phaseTimer = null;
    final r = engine.result;
    winner = r.winner;
    settings.recordResult(vsBot: vsBot || demoMode, winner: winner!);
    if (winner == 0) {
      AudioService.I.lose();
    } else if (!vsBot || winner == black) {
      AudioService.I.win();
    } else {
      AudioService.I.lose();
    }
    _notify();
  }

  Duration get duration => DateTime.now().difference(startedAt);
}
