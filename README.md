# Flip Discs

A gallery-minimalist Reversi game by Wajiha. Outflank rival discs, flip them
to your colour, finish with the majority.

- Package: `com.gameswajiha.flipdiscs`
- Rules source of truth: `~/workspace/game-factory/stitch-batch2/flipdiscs/RULES.md`
- Design source of truth: `~/workspace/game-factory/stitch-batch2/flipdiscs/DESIGN.md`
  ("Gallery Exhibition Reversi" — frosted glass, matte black, brass accent,
  Newsreader + Manrope)

## Architecture

```
lib/
  main.dart            — bootstrap: settings load, audio init, lifecycle
  game/
    engine.dart        — deterministic Reversi rules (pure Dart, no Flutter)
    ai.dart            — Easy / Medium / Hard bot (RULES.md §11)
    controller.dart    — state management (ChangeNotifier)
  services/
    settings.dart      — local persistence via shared_preferences
    audio.dart         — procedural audio via audioplayers
  ui/
    tokens.dart        — gallery design tokens (palette, typography)
    widgets.dart       — frosted glass cards/buttons, physical toggles/sliders
    disc.dart          — physical disc rendering + pseudo-3D flip animation
    board.dart         — matte board, etched grid, brass hint rings
    menu_screen.dart   — main menu (Play / Archive / Rules)
    game_screen.dart   — board screen + pause overlay
    game_over.dart     — victory exhibition screen
    settings_screen.dart
tool/
  gen_audio.dart       — synthesizes all WAV assets (dart tool/gen_audio.dart)
assets/
  audio/               — generated SFX + music loops (10 files)
  fonts/               — Newsreader (Light/Regular/Italic) + Manrope
test/
  engine_test.dart     — RULES.md §13 test cases + AI legality
```

## Checks

```sh
flutter pub get
flutter analyze   # must be clean
flutter test      # 15 engine/rules tests
```

Debug APKs cannot be built in this sandbox (no Android SDK/Gradle access);
signed release builds run on CI.
