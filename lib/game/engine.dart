/// Flip Discs — deterministic Reversi engine.
///
/// Pure Dart: no Flutter imports. Board is a flat 64-cell list:
/// 0 = empty, 1 = Black, 2 = White. Black (1) moves first.
///
/// Initial layout (RULES.md §2): Black on d5/e4, White on d4/e5, where
/// columns a–h run left→right and rows 1–8 run bottom→top. Row index 0 is
/// the top of the screen, so algebraic row = 8 - rowIndex:
///   d5 -> index 27 = Black, e5 -> index 28 = White,
///   d4 -> index 35 = White, e4 -> index 36 = Black.
library;

const int boardSize = 8;
const int cellCount = 64;
const int empty = 0;
const int black = 1;
const int white = 2;

const List<List<int>> _dirs = [
  [-1, -1], [-1, 0], [-1, 1],
  [0, -1],           [0, 1],
  [1, -1],  [1, 0],  [1, 1],
];

int opponentOf(int side) => side == black ? white : black;

/// Outcome of a committed move.
class MoveOutcome {
  /// Discs flipped by the move (cell indices).
  final List<int> flips;

  /// True when the opponent had no legal move and the turn passed back.
  final bool opponentPassed;

  /// True when the game ended as a result of this move.
  final bool gameOver;

  const MoveOutcome({
    required this.flips,
    required this.opponentPassed,
    required this.gameOver,
  });
}

class _Snapshot {
  final List<int> board;
  final int sideToMove;
  final int moveNumber;
  final bool botJustMoved;

  _Snapshot(this.board, this.sideToMove, this.moveNumber, this.botJustMoved);
}

/// Result of a finished game.
class GameResult {
  final int blackCount;
  final int whiteCount;

  const GameResult(this.blackCount, this.whiteCount);

  /// 0 = draw, 1 = Black wins, 2 = White wins.
  int get winner => blackCount == whiteCount
      ? 0
      : (blackCount > whiteCount ? black : white);
}

class ReversiEngine {
  List<int> board = List.filled(cellCount, empty);
  int sideToMove = black;
  int moveNumber = 0; // completed moves (placements)
  final List<_Snapshot> _history = [];

  /// Number of consecutive passes still undoable etc. — history covers it.
  bool botJustMoved = false;

  ReversiEngine() {
    reset();
  }

  /// Fresh standard setup (RULES.md §2).
  void reset() {
    board = List.filled(cellCount, empty);
    // (row, col) with row 0 at top: algebraic row = 8 - rowIndex.
    board[3 * 8 + 3] = black; // d5
    board[3 * 8 + 4] = white; // e5
    board[4 * 8 + 3] = white; // d4
    board[4 * 8 + 4] = black; // e4
    sideToMove = black;
    moveNumber = 0;
    botJustMoved = false;
    _history.clear();
  }

  static int rowOf(int i) => i ~/ boardSize;
  static int colOf(int i) => i % boardSize;

  /// Cells that would flip if [side] played at [index]. Empty = illegal.
  List<int> flipsFor(int index, int side) {
    if (board[index] != empty) return const [];
    final foe = opponentOf(side);
    final r0 = rowOf(index), c0 = colOf(index);
    final out = <int>[];
    for (final d in _dirs) {
      final line = <int>[];
      var r = r0 + d[0], c = c0 + d[1];
      while (r >= 0 && r < boardSize && c >= 0 && c < boardSize &&
          board[r * 8 + c] == foe) {
        line.add(r * 8 + c);
        r += d[0];
        c += d[1];
      }
      if (line.isNotEmpty &&
          r >= 0 && r < boardSize && c >= 0 && c < boardSize &&
          board[r * 8 + c] == side) {
        out.addAll(line);
      }
    }
    return out;
  }

  /// All legal moves for [side] (defaults to side to move).
  List<int> legalMoves([int? side]) {
    final s = side ?? sideToMove;
    final moves = <int>[];
    for (var i = 0; i < cellCount; i++) {
      if (flipsFor(i, s).isNotEmpty) moves.add(i);
    }
    return moves;
  }

  int countOf(int side) {
    var n = 0;
    for (final v in board) {
      if (v == side) n++;
    }
    return n;
  }

  int get emptyCount => cellCount - countOf(black) - countOf(white);

  /// True when neither side has a legal move.
  bool get isGameOver =>
      legalMoves(black).isEmpty && legalMoves(white).isEmpty;

  GameResult get result => GameResult(countOf(black), countOf(white));

  bool get canUndo => _history.isNotEmpty;

  /// Commits a legal move at [index] for the side to move.
  /// Returns null when the move is illegal (state unchanged).
  /// Handles the forced-pass rule automatically (RULES.md §3, §7).
  MoveOutcome? play(int index) {
    final side = sideToMove;
    final flips = flipsFor(index, side);
    if (flips.isEmpty) return null; // illegal: occupied or dead square

    _history.add(_Snapshot(List.of(board), sideToMove, moveNumber, botJustMoved));

    board[index] = side;
    for (final f in flips) {
      board[f] = side;
    }
    moveNumber++;

    var next = opponentOf(side);
    var passed = false;
    if (legalMoves(next).isEmpty) {
      if (legalMoves(side).isEmpty) {
        sideToMove = next; // game over; turn value no longer matters
        return MoveOutcome(flips: flips, opponentPassed: false, gameOver: true);
      }
      // Forced pass: opponent loses their turn, side moves again.
      passed = true;
      next = side;
    }
    sideToMove = next;
    botJustMoved = false;
    return MoveOutcome(
        flips: flips, opponentPassed: passed, gameOver: false);
  }

  /// Marks that the last committed move was made by the bot (used by
  /// undo UX to pop a full round in vs-bot games).
  void markBotMove() => botJustMoved = true;

  /// Restores the exact prior state (RULES.md §12.11), including passes.
  /// Returns false when there is nothing to undo.
  bool undo() {
    if (_history.isEmpty) return false;
    final s = _history.removeLast();
    board = s.board;
    sideToMove = s.sideToMove;
    moveNumber = s.moveNumber;
    botJustMoved = s.botJustMoved;
    return true;
  }

  /// Applies a move without touching undo history (for AI search).
  /// Handles forced passes. Returns the flipped cells, or an empty
  /// list when the move is illegal (state unchanged).
  List<int> applyQuiet(int index, int side) {
    final flips = flipsFor(index, side);
    if (flips.isEmpty) return const [];
    board[index] = side;
    for (final f in flips) {
      board[f] = side;
    }
    var next = opponentOf(side);
    if (legalMoves(next).isEmpty && legalMoves(side).isNotEmpty) {
      next = side; // forced pass
    }
    sideToMove = next;
    return flips;
  }

  /// Deep copy for AI search.
  ReversiEngine clone() {
    final e = ReversiEngine();
    e.board = List.of(board);
    e.sideToMove = sideToMove;
    e.moveNumber = moveNumber;
    return e;
  }
}
