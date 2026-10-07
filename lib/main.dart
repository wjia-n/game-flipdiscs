import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const FlipDiscsApp());

class FlipDiscsApp extends StatelessWidget {
  const FlipDiscsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Flip Discs',
      tagline: 'Outflank and flip your rival\'s discs on the 8x8 board!',
      emoji: '🔄',
      slug: 'flipdiscs',
      howToPlay:
          '• Black moves first. Tap a glowing dot to place your disc.\n• You must trap a line of rival discs between yours — every trapped disc flips to your color!\n• No legal moves? You pass automatically. Brutal.\n• When the board is full (or nobody can move), most discs wins. Corners are gold. 🏆',
      playerOptions: const [1, 2],
      supportsBots: true,
      gameBuilder: (ctx, players, cb) => FlipDiscsScreen(players: players, callbacks: cb),
    );
  }
}
