import 'package:flipdiscs/services/settings.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression tests for the player-name persistence bug (2026-10-09):
///
/// Player names were stored with SharedPreferences.setStringList, which on
/// Android is backed by an UNORDERED StringSet — so after an app restart the
/// two names could come back swapped (Black/White labels assigned to the
/// wrong players). Names are now stored as one order-preserving JSON string.
/// These tests cover the encode/decode round-trip without needing platform
/// channels.
void main() {
  test('names survive an encode/decode round-trip in exact slot order', () {
    const names = ['Wajiha', 'Rival'];
    final decoded = AppSettings.decodePlayerNames(
      AppSettings.encodePlayerNames(names),
    );
    expect(decoded, names);
    // Slot order is what matters: each index must map to the same player.
    for (int i = 0; i < 2; i++) {
      expect(decoded[i], names[i]);
    }
  });

  test('decode falls back to defaults on missing or corrupt data', () {
    expect(AppSettings.decodePlayerNames(null), AppSettings.defaultNames);
    expect(AppSettings.decodePlayerNames('definitely not json'),
        AppSettings.defaultNames);
    expect(AppSettings.decodePlayerNames('["only"]'),
        AppSettings.defaultNames);
    expect(AppSettings.decodePlayerNames('{"a":1}'),
        AppSettings.defaultNames);
  });

  test('blank entries fall back to that slot\'s default name', () {
    final decoded = AppSettings.decodePlayerNames('["Wajiha","  "]');
    expect(decoded, ['Wajiha', 'Bot']);
  });

  test('fresh settings carry the two default names in slot order', () {
    final s = AppSettings.test();
    expect(s.playerName(0), 'You');
    expect(s.playerName(1), 'Bot');
    addTearDown(s.dispose);
  });
}
