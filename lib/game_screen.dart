import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Flip Discs — Reversi on an 8x8 board. Trap lines, flip everything.
class FlipDiscsScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;

  const FlipDiscsScreen({super.key, required this.players, required this.callbacks});

  @override
  State<FlipDiscsScreen> createState() => _FlipDiscsScreenState();
}

class _FlipDiscsScreenState extends State<FlipDiscsScreen> {
  static const _dirs = [
    [-1, -1], [-1, 0], [-1, 1],
    [0, -1],           [0, 1],
    [1, -1],  [1, 0],  [1, 1],
  ];

  late List<List<int>> board; // 0 empty, 1 = player0, 2 = player1
  int turn = 0;
  Set<int> legal = {};
  List<int> lastFlipped = [];
  bool over = false;
  String? passNote;

  @override
  void initState() {
    super.initState();
    _reset();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeBotMove());
  }

  void _reset() {
    board = List.generate(8, (_) => List.filled(8, 0));
    board[3][3] = 2; board[3][4] = 1;
    board[4][3] = 1; board[4][4] = 2;
    turn = 0;
    over = false;
    lastFlipped = [];
    passNote = null;
    _recompute();
    widget.callbacks.setActivePlayer(0);
  }

  int get _me => turn + 1;

  /// Cells that would flip if [p] (1/2) played at (r,c). Empty list = illegal.
  List<int> _flips(int r, int c, int p) {
    if (board[r][c] != 0) return const [];
    final foe = p == 1 ? 2 : 1;
    final out = <int>[];
    for (final d in _dirs) {
      final line = <int>[];
      int rr = r + d[0], cc = c + d[1];
      while (rr >= 0 && rr < 8 && cc >= 0 && cc < 8 && board[rr][cc] == foe) {
        line.add(rr * 8 + cc);
        rr += d[0]; cc += d[1];
      }
      if (line.isNotEmpty && rr >= 0 && rr < 8 && cc >= 0 && cc < 8 && board[rr][cc] == p) {
        out.addAll(line);
      }
    }
    return out;
  }

  void _recompute() {
    legal = {};
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (_flips(r, c, _me).isNotEmpty) legal.add(r * 8 + c);
      }
    }
    _updateScores();
  }

  void _updateScores() {
    int a = 0, b = 0;
    for (final row in board) {
      for (final v in row) {
        if (v == 1) a++;
        if (v == 2) b++;
      }
    }
    widget.players[0].score = a;
    widget.players[1].score = b;
    widget.callbacks.refreshHud();
  }

  void _tap(int i) {
    if (over || widget.players[turn].isBot) return;
    final r = i ~/ 8, c = i % 8;
    final f = _flips(r, c, _me);
    if (f.isEmpty) return;
    _play(r, c, f);
  }

  void _play(int r, int c, List<int> flips) {
    setState(() {
      board[r][c] = _me;
      for (final i in flips) {
        board[i ~/ 8][i % 8] = _me;
      }
      lastFlipped = flips;
      passNote = null;
    });
    if (flips.length >= 5) {
      Sfx.win();
    } else {
      Sfx.move();
    }
    _nextTurn();
  }

  void _nextTurn() {
    final next = (turn + 1) % 2;
    final nextLegal = _legalFor(next);
    if (nextLegal.isEmpty) {
      // Opponent stuck: do I get another go?
      final myLegal = _legalFor(turn);
      if (myLegal.isEmpty) {
        _endGame();
        return;
      }
      setState(() {
        passNote = '${widget.players[next].name} has no moves — passes! 😅';
        legal = myLegal.toSet();
      });
      _maybeBotMove();
      return;
    }
    setState(() {
      turn = next;
      legal = nextLegal.toSet();
    });
    widget.callbacks.setActivePlayer(turn);
    _maybeBotMove();
  }

  Set<int> _legalFor(int t) {
    final p = t + 1;
    final s = <int>{};
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (_flips(r, c, p).isNotEmpty) s.add(r * 8 + c);
      }
    }
    return s;
  }

  void _maybeBotMove() {
    if (over || !widget.players[turn].isBot) return;
    Future.delayed(const Duration(milliseconds: 750), () {
      if (!mounted || over) return;
      final move = _botChoice();
      if (move == null) return;
      final r = move ~/ 8, c = move % 8;
      _play(r, c, _flips(r, c, _me));
    });
  }

  /// Greedy bot: most flips wins, corners break ties.
  int? _botChoice() {
    if (legal.isEmpty) return null;
    final corners = {0, 7, 56, 63};
    int? best;
    int bestFlips = -1;
    for (final i in legal) {
      final f = _flips(i ~/ 8, i % 8, _me).length;
      if (f > bestFlips || (f == bestFlips && corners.contains(i))) {
        bestFlips = f;
        best = i;
      }
    }
    return best;
  }

  void _endGame() {
    setState(() => over = true);
    _updateScores();
    final a = widget.players[0].score;
    final b = widget.players[1].score;
    if (a == b) {
      Sfx.lose();
      widget.callbacks.finish(
        headline: "It's a $a–$a tie! 🤝",
        subline: 'The discs refuse to pick a winner.',
      );
    } else {
      final w = a > b ? widget.players[0] : widget.players[1];
      Sfx.win();
      widget.callbacks.finish(
        winner: w,
        headline: '${w.name} wins $a–$b! 🏆',
        subline: 'Total disc domination.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    final current = widget.players[turn];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          ScoreChips(players: widget.players, activeIndex: over ? -1 : turn),
          const SizedBox(height: 10),
          if (!over)
            TurnBanner(
              player: current,
              action: current.isBot ? ' is plotting… 🤖' : ', trap those discs! 👆',
            ),
          if (passNote != null && !over) ...[
            const SizedBox(height: 6),
            Text(passNote!, style: TextStyle(color: t.muted, fontSize: 13, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: t.radius,
                    boxShadow: [
                      BoxShadow(
                        color: t.primary.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                      mainAxisSpacing: 3,
                      crossAxisSpacing: 3,
                    ),
                    itemCount: 64,
                    itemBuilder: (_, i) => _cell(i, t),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Corners are forever — grab them early! 💎',
            style: TextStyle(color: t.muted, fontSize: 13),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _cell(int i, GameTheme t) {
    final r = i ~/ 8, c = i % 8;
    final v = board[r][c];
    final isLegal = legal.contains(i) && !over && !widget.players[turn].isBot;
    final justFlipped = lastFlipped.contains(i);
    return GestureDetector(
      onTap: () => _tap(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: t.background,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: v == 0
            ? (isLegal
                ? Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.players[turn].color.withValues(alpha: 0.55),
                    ),
                  )
                : const SizedBox.shrink())
            : TweenAnimationBuilder<double>(
                tween: Tween(begin: justFlipped ? 0.2 : 1.0, end: 1.0),
                duration: const Duration(milliseconds: 260),
                curve: Curves.elasticOut,
                builder: (_, s, child) => Transform.scale(
                  scale: s,
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(-0.35, -0.35),
                        colors: [
                          widget.players[v - 1].color.withValues(alpha: 0.95),
                          widget.players[v - 1].color,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.players[v - 1].color.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
