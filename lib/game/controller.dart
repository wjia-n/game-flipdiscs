/// Game state management for Flip Discs.
///
/// Owns the [ReversiEngine], drives bot turns, undo/restart, invalid-move
/// feedback, game-over detection and stats recording. Emits UI state via
/// [ChangeNotifier]; the screens only render.

library;
import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../game/ai.dart';
import '../game/engine.dart';
import '../services/audio.dart';
import '../services/settings.dart';

enum GameMode { vsBot, twoPlayer }

class GameController extends ChangeNotifier {
  final AppSettings settings;
  final GameMode mode;

  final ReversiEngine engine = ReversiEngine();
  final int gameSeed = Random().nextInt(1 << 30);

  bool botThinking = false;
  bool paused = false;
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

  GameController({required this.settings, required this.mode});

  bool get vsBot => mode == GameMode.vsBot;
  BotDifficulty get difficulty => settings.difficulty;

  int get blackCount => engine.countOf(black);
  int get whiteCount => engine.countOf(white);
  int get turn => engine.sideToMove;
  int get round => (engine.moveNumber ~/ 2) + 1;

  Set<int> get legalMoves => engine.legalMoves().toSet();
  bool get humanTurn =>
      !over && (!vsBot || engine.sideToMove == black) && !botThinking;

  String get turnLabel {
    if (over) return 'Game over';
    if (!vsBot) return engine.sideToMove == black ? 'Black to move' : 'White to move';
    if (botThinking || engine.sideToMove == white) return 'Bot thinking…';
    return 'Your move';
  }

  Future<void> start() async {
    engine.reset();
    over = false;
    winner = null;
    lastFlips = [];
    lastPlaced = -1;
    passMessage = null;
    botThinking = false;
    startedAt = DateTime.now();
    await AudioService.I.gameStart();
    notifyListeners();
    _maybeBotMove();
  }

  /// Player taps a cell. Handles placement, invalid feedback, passes,
  /// bot replies and game end.
  Future<void> tapCell(int index) async {
    if (over || paused) return;
    if (!humanTurn) return;

    final outcome = engine.play(index);
    if (outcome == null) {
      // Illegal placement: gentle shake + soft low thock (gallery calm).
      invalidCell = index;
      invalidNonce++;
      AudioService.I.invalid();
      AudioService.I.invalidHaptic();
      notifyListeners();
      return;
    }

    lastPlaced = index;
    lastFlips = outcome.flips;
    flipEpoch++;
    passMessage =
        outcome.opponentPassed ? '${_sideName(opponentOf(engine.sideToMove))} has no moves — passes' : null;
    AudioService.I.place();
    AudioService.I.moveHaptic();
    if (outcome.flips.isNotEmpty) {
      AudioService.I.flips(outcome.flips.length);
    }
    if (outcome.opponentPassed) {
      // Small beat so the pass registers before play continues.
      await Future.delayed(const Duration(milliseconds: 350));
      AudioService.I.pass();
    }
    notifyListeners();

    if (outcome.gameOver) {
      _finish();
      return;
    }
    _maybeBotMove();
  }

  void _maybeBotMove() {
    if (!vsBot || over || paused || engine.sideToMove != white) return;
    botThinking = true;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 750), () async {
      if (over || paused) {
        botThinking = false;
        notifyListeners();
        return;
      }
      final moves = engine.legalMoves(white);
      if (moves.isEmpty) {
        botThinking = false;
        notifyListeners();
        return; // engine auto-passes; nothing to do
      }
      final choice =
          chooseBotMove(engine, white, difficulty, seed: gameSeed + engine.moveNumber);
      final outcome = engine.play(choice);
      botThinking = false;
      if (outcome == null) {
        notifyListeners();
        return; // should never happen; AI only picks legal moves
      }
      engine.markBotMove();
      lastPlaced = choice;
      lastFlips = outcome.flips;
      flipEpoch++;
      passMessage = outcome.opponentPassed
          ? '${_sideName(opponentOf(engine.sideToMove))} has no moves — passes'
          : null;
      AudioService.I.place();
      if (outcome.flips.isNotEmpty) {
        AudioService.I.flips(outcome.flips.length);
      }
      if (outcome.opponentPassed) {
        await Future.delayed(const Duration(milliseconds: 350));
        AudioService.I.pass();
      }
      notifyListeners();
      if (outcome.gameOver) {
        _finish();
        return;
      }
      if (outcome.opponentPassed) {
        // Human had no legal move and passed — the bot moves again.
        _maybeBotMove();
      }
    });
  }

  /// Undo: in vs-bot mode pops a full round (bot + human) so it is the
  /// human's turn again; in 2-player mode pops a single move.
  void undo() {
    if (over || botThinking || !engine.canUndo) return;
    AudioService.I.click();
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
    passMessage = null;
    notifyListeners();
  }

  void setPaused(bool value) {
    paused = value;
    if (value) {
      AudioService.I.pauseMusic();
    } else {
      AudioService.I.resumeMusic();
      _maybeBotMove();
    }
    notifyListeners();
  }

  void _finish() {
    over = true;
    final r = engine.result;
    winner = r.winner;
    settings.recordResult(vsBot: vsBot, winner: winner!);
    if (winner == 0) {
      AudioService.I.lose();
    } else if (!vsBot || winner == black) {
      AudioService.I.win();
    } else {
      AudioService.I.lose();
    }
    notifyListeners();
  }

  Duration get duration => DateTime.now().difference(startedAt);

  String _sideName(int side) => side == black ? 'Black' : 'White';
}
