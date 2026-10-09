/// Flip Discs bot — deterministic evaluation over legal moves (RULES.md §11).
///
/// Easy:   uniform random among legal moves, small bias to max flips (greedy-lite).
/// Medium: 1-ply greedy on immediate gain + positional weights; depth-2
///         minimax when the move list is small (<= 10 legal moves).
/// Hard:   depth-limited alpha-beta minimax (depth 4 mid-game, 6 late) with
///         positional evaluation, mobility, and near-exact endgame search
///         (<= 12 empties). Seeded RNG only for tie-breaking.
///
/// All levels: never play an illegal move, never pass when a move exists.
library;

import 'dart:math';
import 'engine.dart';

enum BotDifficulty { easy, medium, hard }

/// Classic static square weights: corners strongly positive, squares
/// adjacent to corners strongly negative, edges moderately positive.
const List<int> _weights = [
  120, -20, 20, 5, 5, 20, -20, 120,
  -20, -40, -5, -5, -5, -5, -40, -20,
  20, -5, 15, 3, 3, 15, -5, 20,
  5, -5, 3, 3, 3, 3, -5, 5,
  5, -5, 3, 3, 3, 3, -5, 5,
  20, -5, 15, 3, 3, 15, -5, 20,
  -20, -40, -5, -5, -5, -5, -40, -20,
  120, -20, 20, 5, 5, 20, -20, 120,
];

const Set<int> _corners = {0, 7, 56, 63};

/// Squares orthogonally/diagonally adjacent to a corner.
const Map<int, List<int>> _cornerAdjacency = {
  0: [1, 8, 9],
  7: [6, 14, 15],
  56: [48, 49, 57],
  63: [54, 55, 62],
};

bool _cornerEmpty(ReversiEngine e, int corner) => e.board[corner] == empty;

int chooseBotMove(ReversiEngine engine, int side, BotDifficulty difficulty,
    {int seed = 0}) {
  final moves = engine.legalMoves(side);
  assert(moves.isNotEmpty, 'chooseBotMove called with no legal moves');
  final rng = Random(seed);
  switch (difficulty) {
    case BotDifficulty.easy:
      return _chooseEasy(engine, side, moves, rng);
    case BotDifficulty.medium:
      return _chooseMedium(engine, side, moves, rng);
    case BotDifficulty.hard:
      return _chooseHard(engine, side, moves, rng);
  }
}

// ---------------------------------------------------------------- Easy ---
int _chooseEasy(ReversiEngine e, int side, List<int> moves, Random rng) {
  // Greedy-lite: small bias toward the max-flip move, else uniform random.
  if (rng.nextDouble() < 0.35) {
    var best = moves;
    var bestFlips = -1;
    for (final m in moves) {
      final f = e.flipsFor(m, side).length;
      if (f > bestFlips) {
        bestFlips = f;
        best = [m];
      } else if (f == bestFlips) {
        best = [...best, m];
      }
    }
    return best[rng.nextInt(best.length)];
  }
  return moves[rng.nextInt(moves.length)];
}

// --------------------------------------------------------------- Medium ---
int _positionalScore(ReversiEngine e, int move, int side) {
  var s = e.flipsFor(move, side).length * 2 + _weights[move];
  // Never hand the opponent corner access: avoid squares adjacent to an
  // empty corner unless forced.
  for (final entry in _cornerAdjacency.entries) {
    if (entry.value.contains(move) && _cornerEmpty(e, entry.key)) {
      s -= 60;
    }
  }
  if (_corners.contains(move)) s += 80;
  return s;
}

int _chooseMedium(ReversiEngine e, int side, List<int> moves, Random rng) {
  // Corners can never be outflanked once taken: always take a free one.
  final freeCorners =
      moves.where(_corners.contains).toList(growable: false);
  if (freeCorners.isNotEmpty) {
    return freeCorners[rng.nextInt(freeCorners.length)];
  }
  if (moves.length <= 10) {
    // Depth-2 minimax on disc difference + positional nudge.
    var best = moves.first;
    var bestVal = -1 << 30;
    for (final m in _ordered(moves, e, side, rng)) {
      final child = e.clone()..applyQuiet(m, side);
      final val = -_minimaxDisc(child, opponentOf(side), 1, -1 << 28, 1 << 28) +
          _weights[m];
      if (val > bestVal) {
        bestVal = val;
        best = m;
      }
    }
    return best;
  }
  var best = moves;
  var bestScore = -1 << 30;
  for (final m in moves) {
    final s = _positionalScore(e, m, side);
    if (s > bestScore) {
      bestScore = s;
      best = [m];
    } else if (s == bestScore) {
      best = [...best, m];
    }
  }
  return best[rng.nextInt(best.length)];
}

int _minimaxDisc(ReversiEngine e, int side, int depth, int alpha, int beta) {
  final moves = e.legalMoves(side);
  if (moves.isEmpty) {
    if (e.legalMoves(opponentOf(side)).isEmpty) {
      return (e.countOf(side) - e.countOf(opponentOf(side))) * 100;
    }
    return -_minimaxDisc(e, opponentOf(side), depth, -beta, -alpha); // pass
  }
  if (depth == 0) return (e.countOf(side) - e.countOf(opponentOf(side))) * 10;
  var best = -1 << 28;
  for (final m in moves) {
    final child = e.clone()..applyQuiet(m, side);
    final v = -_minimaxDisc(child, opponentOf(side), depth - 1, -beta, -alpha);
    if (v > best) best = v;
    if (best > alpha) alpha = best;
    if (alpha >= beta) break;
  }
  return best;
}

// ----------------------------------------------------------------- Hard ---
int _chooseHard(ReversiEngine e, int side, List<int> moves, Random rng) {
  // Corners can never be outflanked once taken: always take a free one.
  final freeCorners =
      moves.where(_corners.contains).toList(growable: false);
  if (freeCorners.isNotEmpty) {
    return freeCorners[rng.nextInt(freeCorners.length)];
  }
  final empties = e.emptyCount;
  final depth = empties <= 14 ? 6 : 4;
  final search = _HardSearch(rng);
  var best = moves.first;
  var bestVal = -1 << 30;
  var alpha = -1 << 28;
  for (final m in _ordered(moves, e, side, rng)) {
    final child = e.clone()..applyQuiet(m, side);
    final val =
        -search.run(child, opponentOf(side), depth - 1, -1 << 28, -alpha);
    if (val > bestVal) {
      bestVal = val;
      best = m;
    }
    if (val > alpha) alpha = val;
  }
  return best;
}

List<int> _ordered(List<int> moves, ReversiEngine e, int side, Random rng) {
  final scored = moves
      .map((m) => MapEntry(m, _positionalScore(e, m, side)))
      .toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  // Shuffle equal scores deterministically for tie-breaking variety.
  var i = 0;
  while (i < scored.length) {
    var j = i;
    while (j < scored.length && scored[j].value == scored[i].value) {
      j++;
    }
    for (var k = j - 1; k > i; k--) {
      final t = rng.nextInt(k - i + 1) + i;
      final tmp = scored[k];
      scored[k] = scored[t];
      scored[t] = tmp;
    }
    i = j;
  }
  return scored.map((m) => m.key).toList();
}

class _HardSearch {
  final Random rng;
  int nodes = 0;
  static const int nodeBudget = 120000;

  _HardSearch(this.rng);

  int run(ReversiEngine e, int side, int depth, int alpha, int beta) {
    if (++nodes > nodeBudget) return _evaluate(e, side);
    final moves = e.legalMoves(side);
    if (moves.isEmpty) {
      if (e.legalMoves(opponentOf(side)).isEmpty) {
        final d = e.countOf(side) - e.countOf(opponentOf(side));
        return d * 1000 + (d > 0 ? depth : 0);
      }
      return -run(e, opponentOf(side), depth, -beta, -alpha); // pass
    }
    if (depth <= 0) return _evaluate(e, side);
    var best = -1 << 28;
    for (final m in _ordered(moves, e, side, rng)) {
      final child = e.clone()..applyQuiet(m, side);
      final v = -run(child, opponentOf(side), depth - 1, -beta, -alpha);
      if (v > best) best = v;
      if (best > alpha) alpha = best;
      if (alpha >= beta) break;
      if (nodes > nodeBudget) break;
    }
    return best;
  }

  int _evaluate(ReversiEngine e, int side) {
    final foe = opponentOf(side);
    if (e.emptyCount <= 12) {
      // Endgame: disc-parity awareness.
      return (e.countOf(side) - e.countOf(foe)) * 50;
    }
    var pos = 0;
    for (var i = 0; i < cellCount; i++) {
      final v = e.board[i];
      if (v == side) {
        pos += _weights[i];
      } else if (v == foe) {
        pos -= _weights[i];
      }
    }
    // Mobility.
    final myMob = e.legalMoves(side).length;
    final foeMob = e.legalMoves(foe).length;
    // Corner occupancy bonus.
    var cornerBonus = 0;
    for (final c in _corners) {
      if (e.board[c] == side) {
        cornerBonus += 60;
      } else if (e.board[c] == foe) {
        cornerBonus -= 60;
      }
    }
    return pos + (myMob - foeMob) * 12 + cornerBonus;
  }
}
