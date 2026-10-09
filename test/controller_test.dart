/// Controller state-machine tests: engine-owned turn phases + watchdog.
///
/// Proves (with FakeAsync, so no wall-clock waiting) that:
/// - bot turns move through thinking → placing → flipping with visible
///   narration, never resolving instantly;
/// - a full bot-vs-bot demo game always terminates (no stuck states);
/// - disposing mid-turn (the old Future.delayed crash) is safe;
/// - undo is refused while a turn is being staged.

library;
import 'package:fake_async/fake_async.dart';
import 'package:flipdiscs/game/ai.dart';
import 'package:flipdiscs/game/controller.dart';
import 'package:flipdiscs/game/engine.dart';
import 'package:flipdiscs/services/settings.dart';
import 'package:flutter_test/flutter_test.dart';

int sq(String col, int row) =>
    (8 - row) * 8 + (col.codeUnitAt(0) - 'a'.codeUnitAt(0));

void main() {
  // AudioService touches audioplayers (platform channels) even for no-op
  // calls, so the test binding must exist before any test runs.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('turn state machine', () {
    test('bot turn is staged visibly: thinking → placing → flipping',
        () {
      fakeAsync((fa) {
        final settings = AppSettings.test()
          ..difficulty = BotDifficulty.easy;
        final c =
            GameController(settings: settings, mode: GameMode.demo);
        c.start();
        fa.flushMicrotasks();

        // Demo: black is a bot → opens in the thinking phase.
        expect(c.phase, TurnPhase.thinking);
        expect(c.botThinking, isTrue);
        expect(c.sideNarration(black), contains('thinking'));

        // Thinking beat: 950ms. Nothing resolves instantly.
        fa.elapse(const Duration(milliseconds: 900));
        expect(c.phase, TurnPhase.thinking);

        // Commit → placing phase: the disc visibly lands first.
        fa.elapse(const Duration(milliseconds: 100));
        expect(c.phase, TurnPhase.placing);
        expect(c.lastPlaced, greaterThanOrEqualTo(0));
        expect(c.sideNarration(black), contains('plays'));

        // Placing beat (340ms) → flipping cascade.
        fa.elapse(const Duration(milliseconds: 340));
        expect(c.phase, TurnPhase.flipping);
        expect(c.lastFlips, isNotEmpty);

        // After the cascade the machine advances: the next bot turn
        // begins visibly in its own thinking phase.
        var guard = 0;
        while (!(c.engine.moveNumber == 1 &&
                c.phase == TurnPhase.thinking) &&
            guard < 40) {
          fa.elapse(const Duration(milliseconds: 250));
          fa.flushMicrotasks();
          guard++;
        }
        expect(c.engine.moveNumber, 1);
        expect(c.phase, TurnPhase.thinking); // white's turn, visible
        c.dispose();
      });
    });

    test('human tap stages placing → flipping → bot reply', () {
      fakeAsync((fa) {
        final settings = AppSettings.test()
          ..difficulty = BotDifficulty.easy;
        final c =
            GameController(settings: settings, mode: GameMode.vsBot);
        c.start();
        fa.flushMicrotasks();
        expect(c.humanTurn, isTrue);

        c.tapCell(sq('d', 3));
        fa.flushMicrotasks();
        expect(c.lastPlaced, sq('d', 3));
        expect(c.phase, TurnPhase.placing);

        fa.elapse(const Duration(milliseconds: 400));
        expect(c.phase, TurnPhase.flipping);

        // The bot visibly takes its turn; wait until the full round
        // (human + bot) has settled and it is the human's turn again.
        var guard = 0;
        while (
            !(c.humanTurn && c.engine.moveNumber == 2) && guard < 60) {
          fa.elapse(const Duration(milliseconds: 250));
          fa.flushMicrotasks();
          guard++;
        }
        expect(c.engine.moveNumber, 2); // human + bot both moved
        expect(c.humanTurn, isTrue);
        c.dispose();
      });
    });

    test('illegal tap is rejected with invalid feedback', () {
      fakeAsync((fa) {
        final settings = AppSettings.test();
        final c =
            GameController(settings: settings, mode: GameMode.vsBot);
        c.start();
        fa.flushMicrotasks();
        final before = List.of(c.engine.board);
        c.tapCell(sq('a', 1)); // dead square
        fa.flushMicrotasks();
        expect(c.engine.board, before);
        expect(c.invalidCell, sq('a', 1));
        expect(c.invalidNonce, 1);
        expect(c.humanTurn, isTrue); // still the human's turn
        c.dispose();
      });
    });

    test('undo refused while a turn is staged; works when idle', () {
      fakeAsync((fa) {
        final settings = AppSettings.test()
          ..difficulty = BotDifficulty.easy;
        final c =
            GameController(settings: settings, mode: GameMode.vsBot);
        c.start();
        fa.flushMicrotasks();
        c.tapCell(sq('d', 3));
        fa.flushMicrotasks();
        expect(c.phase, TurnPhase.placing);
        c.undo(); // refused mid-staging
        expect(c.engine.moveNumber, 1);
        // Let the full round settle (human + bot).
        fa.elapse(const Duration(seconds: 6));
        fa.flushMicrotasks();
        expect(c.humanTurn, isTrue);
        expect(c.engine.moveNumber, 2);
        c.undo(); // pops the full round
        expect(c.engine.moveNumber, 0);
        expect(c.engine.sideToMove, black);
        c.dispose();
      });
    });

    test('full bot-vs-bot demo always terminates (no stuck states)', () {
      fakeAsync((fa) {
        final settings = AppSettings.test()
          ..difficulty = BotDifficulty.medium;
        final c =
            GameController(settings: settings, mode: GameMode.demo);
        c.start();
        fa.flushMicrotasks();

        var guard = 0;
        while (!c.over && guard < 2000) {
          fa.elapse(const Duration(milliseconds: 500));
          fa.flushMicrotasks();
          // The machine may only rest in idle on a human turn; in demo
          // mode every side is a bot, so idle is never a resting state.
          expect(
              c.over ||
                  c.phase == TurnPhase.thinking ||
                  c.phase == TurnPhase.placing ||
                  c.phase == TurnPhase.flipping,
              isTrue,
              reason: 'wedged in ${c.phase} at move ${c.engine.moveNumber}');
          guard++;
        }
        expect(c.over, isTrue, reason: 'demo game never finished');
        expect(c.phase, TurnPhase.over);
        expect(c.winner, isNotNull);
        expect(
            c.blackCount + c.whiteCount + c.engine.emptyCount, 64);
        expect(c.engine.moveNumber, greaterThan(0));
        c.dispose();
      });
    });

    test('dispose mid bot-turn never crashes (old Future.delayed bug)',
        () {
      fakeAsync((fa) {
        final settings = AppSettings.test();
        final c =
            GameController(settings: settings, mode: GameMode.demo);
        c.start();
        fa.flushMicrotasks();
        expect(c.phase, TurnPhase.thinking);
        c.dispose(); // pending phase timer + watchdog must die quietly
        fa.elapse(const Duration(seconds: 30));
        fa.flushMicrotasks();
        // Reaching here without throwing is the assertion.
      });
    });

    test('pause freezes the phase timer; resume re-arms the phase', () {
      fakeAsync((fa) {
        final settings = AppSettings.test()
          ..difficulty = BotDifficulty.easy;
        final c =
            GameController(settings: settings, mode: GameMode.demo);
        c.start();
        fa.flushMicrotasks();
        expect(c.phase, TurnPhase.thinking);

        // Pause kills the live phase timer; the watchdog respects pause,
        // so nothing may advance while paused.
        c.setPaused(true);
        fa.elapse(const Duration(seconds: 10));
        fa.flushMicrotasks();
        expect(c.phase, TurnPhase.thinking);
        expect(c.engine.moveNumber, 0);

        // Resume re-arms the current phase through the watchdog path.
        c.setPaused(false);
        fa.flushMicrotasks();
        fa.elapse(const Duration(seconds: 3));
        fa.flushMicrotasks();
        expect(c.engine.moveNumber, greaterThan(0));
        c.dispose();
      });
    });
  });
}
