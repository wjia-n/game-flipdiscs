/// Flip Discs PRO: Free-vs-Pro comparison, real purchase, restore, tip jar.
/// All prices come from the store — never hardcoded, never placeholders.

library;
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../services/audio.dart';
import '../services/iap_service.dart';
import '../services/settings.dart';
import '../theme/gallery.dart';
import 'tokens.dart';
import 'widgets.dart';

class ProScreen extends StatefulWidget {
  final AppSettings settings;
  final StoreService store;

  const ProScreen({
    super.key,
    required this.settings,
    required this.store,
  });

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  @override
  void initState() {
    super.initState();
    widget.store.proPurchased.addListener(_onPro);
    widget.store.lastThanks.addListener(_onThanks);
  }

  void _onPro() {
    if (widget.store.proPurchased.value && mounted) {
      widget.settings.setPro(true);
      AudioService.I.win();
      final t = widget.settings.gallery;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PRO unlocked — enjoy the full gallery!',
              style: t.body.copyWith(color: t.bg)),
          backgroundColor: t.ink,
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.store.proPurchased.value = false;
    }
  }

  void _onThanks() {
    final msg = widget.store.lastThanks.value;
    if (msg == null || !mounted) return;
    AudioService.I.win();
    final t = widget.settings.gallery;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: t.body.copyWith(color: t.bg)),
        backgroundColor: t.ink,
        behavior: SnackBarBehavior.floating,
      ),
    );
    widget.store.lastThanks.value = null;
  }

  @override
  void dispose() {
    widget.store.proPurchased.removeListener(_onPro);
    widget.store.lastThanks.removeListener(_onThanks);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.settings.gallery;
    final s = widget.settings;
    final store = widget.store;
    return GalleryScope(
      theme: t,
      child: GalleryBackdrop(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: GalleryTopBar(
                    title: 'FLIP DISCS PRO',
                    subtitle: 'THE FULL GALLERY',
                    onBack: () {
                      AudioService.I.click();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                Expanded(
                  child: ListenableBuilder(
                    listenable: s,
                    builder: (_, _) => SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                          24, 12, 24, 16),
                      child: Column(
                        children: [
                          _ComparisonCard(
                              theme: t, isPro: s.isPro),
                          const SizedBox(height: 14),
                          _BuyCard(
                            theme: t,
                            settings: s,
                            store: store,
                          ),
                          const SizedBox(height: 14),
                          _TipsCard(
                            theme: t,
                            store: store,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Free vs Pro comparison table — buyers see the big difference.
class _ComparisonCard extends StatelessWidget {
  final GalleryThemeDef theme;
  final bool isPro;
  const _ComparisonCard({required this.theme, required this.isPro});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    const rows = [
      ('Complete Flip Discs game', true, true),
      ('All official rules', true, true),
      ('Easy & Medium bots', true, true),
      ('2-player pass-and-play', true, true),
      ('Watch demo (bot vs bot)', true, true),
      ('Renameable players', true, true),
      ('Music & sound effects', true, true),
      ('Gallery themes', '4', '14 + custom'),
      ('Disc styles', '3', '10'),
      ('Board accents', '2', '8'),
      ('Custom theme creator', false, true),
      ('Hard bot', false, true),
    ];
    return FrostedCard(
      child: Column(
        children: [
          Text('Free vs PRO', style: t.headline.copyWith(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            'One purchase. Yours forever.',
            style: t.body.copyWith(fontSize: 13, color: t.muted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(flex: 5, child: SizedBox()),
              Expanded(
                  flex: 2,
                  child: Text('FREE',
                      style: t.labelCaps(size: 11),
                      textAlign: TextAlign.center)),
              Expanded(
                  flex: 2,
                  child: Text('PRO',
                      style: t.labelCaps(
                          size: 11, color: t.accent),
                      textAlign: TextAlign.center)),
            ],
          ),
          const SizedBox(height: 6),
          const Hairline(),
          for (final r in rows) ...[
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(r.$1,
                        style: t.body.copyWith(fontSize: 13)),
                  ),
                  Expanded(
                      flex: 2, child: _Cell(value: r.$2, theme: t)),
                  Expanded(
                      flex: 2, child: _Cell(value: r.$3, theme: t)),
                ],
              ),
            ),
            const Hairline(),
          ],
          if (isPro)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: t.accent.withValues(alpha: 0.18),
                  border: Border.all(color: t.accent),
                ),
                child: Text('✦ PRO ACTIVE ✦',
                    style: t.labelCaps(
                        size: 13, color: t.ink)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final Object value; // bool | String
  final GalleryThemeDef theme;
  const _Cell({required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    if (value is bool) {
      final v = value as bool;
      return Text(
        v ? '✓' : '—',
        style: t.body.copyWith(
            fontSize: 15,
            color: v ? t.accent : t.muted.withValues(alpha: 0.5)),
        textAlign: TextAlign.center,
      );
    }
    return Text(
      value as String,
      style: t.labelCaps(size: 11, color: t.ink),
      textAlign: TextAlign.center,
    );
  }
}

// ---------------------------------------------------------------------------
class _BuyCard extends StatelessWidget {
  final GalleryThemeDef theme;
  final AppSettings settings;
  final StoreService store;
  const _BuyCard({
    required this.theme,
    required this.settings,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final pro = store.proProduct;
    return FrostedCard(
      child: Column(
        children: [
          Text('Unlock PRO', style: t.headline.copyWith(fontSize: 24)),
          const SizedBox(height: 8),
          if (settings.isPro)
            Text('You already own PRO — thank you!',
                style: t.body.copyWith(fontSize: 14),
                textAlign: TextAlign.center)
          else if (!store.storeReady)
            Text(
              store.error ?? 'Available after store setup.',
              style: t.body.copyWith(
                  fontSize: 14, color: t.muted),
              textAlign: TextAlign.center,
            )
          else if (pro != null) ...[
            Text(
                pro.description.isNotEmpty
                    ? pro.description
                    : 'Unlock the full gallery, forever.',
                style: t.body.copyWith(fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ValueListenableBuilder<bool>(
              valueListenable: store.purchaseInProgress,
              builder: (_, busy, _) => SizedBox(
                width: double.infinity,
                child: DarkButton(
                  label: busy ? 'Working…' : 'Get PRO — ${pro.price}',
                  onTap: busy
                      ? () {}
                      : () {
                          AudioService.I.click();
                          store.buyPro();
                        },
                ),
              ),
            ),
          ],
          ValueListenableBuilder<String?>(
            valueListenable: store.purchaseError,
            builder: (_, err, _) => err == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(err,
                        style: t.body.copyWith(
                            fontSize: 13,
                            color: const Color(0xFFB3261E)),
                        textAlign: TextAlign.center),
                  ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () {
              AudioService.I.click();
              store.restore();
            },
            child: Text('Restore purchases',
                style: t.labelCaps(size: 12, color: t.sub)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Consumable tips — pure support, with real store prices.
class _TipsCard extends StatelessWidget {
  final GalleryThemeDef theme;
  final StoreService store;
  const _TipsCard({required this.theme, required this.store});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final tips = [
      store.coffeeProduct,
      store.chocolateProduct,
    ].whereType<ProductDetails>().toList();
    return FrostedCard(
      child: Column(
        children: [
          Text('Tip the Maker', style: t.headline.copyWith(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            'Flip Discs is free forever. A small tip keeps new games coming!',
            style: t.body.copyWith(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (!store.storeReady)
            Text(
              store.error ?? 'Available after store setup.',
              style: t.body.copyWith(
                  fontSize: 13, color: t.muted),
              textAlign: TextAlign.center,
            )
          else if (tips.isEmpty)
            Text('Tips coming soon.',
                style: t.body.copyWith(
                    fontSize: 13, color: t.muted))
          else
            Wrap(
              spacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (final p in tips)
                  _TipChip(
                    theme: t,
                    label:
                        '${p.id == StoreService.chocolateId ? '🍫' : '☕'} ${p.price}',
                    onTap: () {
                      AudioService.I.click();
                      store.buyTip(p);
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TipChip extends StatelessWidget {
  final GalleryThemeDef theme;
  final String label;
  final VoidCallback onTap;
  const _TipChip(
      {required this.theme, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin:
            const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: t.ink.withValues(alpha: 0.05),
          border:
              Border.all(color: t.accent.withValues(alpha: 0.6), width: 1.5),
        ),
        child: Text(label, style: t.labelCaps(size: 13, color: t.ink)),
      ),
    );
  }
}
