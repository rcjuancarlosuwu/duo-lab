import 'package:flutter/material.dart';
import 'package:foldable/foldable.dart';

import 'theme.dart';

const _body =
    'A paragraph of ordinary running text, the kind every app puts on screen '
    'without thinking twice about it. On a normal phone it reflows and nobody '
    'notices. On this device a forty logical pixel band of hardware crosses '
    'the screen, and Flutter never mentions it, because '
    'MediaQuery.displayFeatures is empty on iOS.';

class HingeDemoPage extends StatefulWidget {
  const HingeDemoPage({super.key});

  @override
  State<HingeDemoPage> createState() => _HingeDemoPageState();
}

class _HingeDemoPageState extends State<HingeDemoPage> {
  final _pageKey = GlobalKey();
  Offset _pageOrigin = Offset.zero;

  void _syncOrigin() {
    final box = _pageKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final origin = box.localToGlobal(Offset.zero);
    if (origin != _pageOrigin) setState(() => _pageOrigin = origin);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncOrigin());

    return StreamBuilder<FoldableData>(
      stream: Foldable.changes,
      builder: (context, snapshot) {
        final fold = _foldRect(snapshot.data);
        final horizontal = fold != null && fold.width > fold.height;

        return Stack(
          key: _pageKey,
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 150),
              children: [
                Panel(
                  title: 'naive layout — ignores the hinge',
                  accent: kBad,
                  trailing: const StatusPill('BROKEN', tone: Tone.bad),
                  children: [NaiveLayout(horizontal: horizontal)],
                ),
                Panel(
                  title: 'hinge aware — uses the foldable region',
                  accent: kGood,
                  trailing: const StatusPill('AVOIDS FOLD', tone: Tone.good),
                  children: [AwareLayout(fold: fold, horizontal: horizontal)],
                ),
                Panel(
                  title: 'fold region',
                  children: [
                    MetricRow(
                      'division rect',
                      fold == null ? 'none reported' : '$fold',
                      tone: fold == null ? Tone.bad : Tone.accent,
                    ),
                    MetricRow(
                      'band runs',
                      fold == null
                          ? '-'
                          : horizontal
                          ? 'horizontally, ${fold.height} lp tall'
                          : 'vertically, ${fold.width} lp wide',
                      tone: Tone.accent,
                    ),
                    MetricRow(
                      'MediaQuery.displayFeatures',
                      '${MediaQuery.of(context).displayFeatures.length} (EMPTY)',
                      tone: Tone.bad,
                    ),
                  ],
                ),
              ],
            ),
            if (fold != null) FoldOverlay(fold: fold.shift(-_pageOrigin)),
          ],
        );
      },
    );
  }

  static Rect? _foldRect(FoldableData? data) {
    if (data == null) return null;
    for (final region in data.regions) {
      if (region.kind == ReservedRegionKind.division) return region.bounds;
    }
    return null;
  }
}

class NaiveLayout extends StatelessWidget {
  const NaiveLayout({super.key, required this.horizontal});

  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final panes = [
      const Pane(label: 'PANE A'),
      Container(
        width: horizontal ? null : 2,
        height: horizontal ? 2 : null,
        color: kAccent,
      ),
      const Pane(label: 'PANE B'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (horizontal)
          SizedBox(
            height: 220,
            child: Column(
              children: [
                for (final pane in panes)
                  pane is Pane ? Expanded(child: pane) : pane,
              ],
            ),
          )
        else
          SizedBox(
            height: 120,
            child: Row(
              children: [
                for (final pane in panes)
                  pane is Pane ? Expanded(child: pane) : pane,
              ],
            ),
          ),
        const SizedBox(height: 10),
        const Text(
          _body,
          style: TextStyle(fontSize: 13.5, height: 1.5, color: kText),
        ),
      ],
    );
  }
}

class AwareLayout extends StatelessWidget {
  const AwareLayout({super.key, required this.fold, required this.horizontal});

  final Rect? fold;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    if (fold == null) {
      return const Text(
        'No fold region reported; falling back to a single pane.',
        style: TextStyle(fontSize: 13, color: kMuted),
      );
    }
    final gutter = horizontal ? fold!.height : fold!.width;

    if (horizontal) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 220 + gutter,
            child: Column(
              children: [
                const Expanded(child: Pane(label: 'PANE A')),
                Gutter(extent: gutter, horizontal: true),
                const Expanded(child: Pane(label: 'PANE B')),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            _body,
            style: TextStyle(fontSize: 13.5, height: 1.5, color: kText),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 120,
          child: Row(
            children: [
              const Expanded(child: Pane(label: 'PANE A')),
              Gutter(extent: gutter, horizontal: false),
              const Expanded(child: Pane(label: 'PANE B')),
            ],
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final safeGutter = gutter.clamp(0.0, constraints.maxWidth / 3);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Text(
                    _body,
                    style: TextStyle(fontSize: 13.5, height: 1.5, color: kText),
                  ),
                ),
                Gutter(extent: safeGutter, horizontal: false),
                const Expanded(child: SizedBox()),
              ],
            );
          },
        ),
      ],
    );
  }
}

class Gutter extends StatelessWidget {
  const Gutter({super.key, required this.extent, required this.horizontal});

  final double extent;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: horizontal ? null : extent,
      height: horizontal ? extent : null,
      color: kGood.withValues(alpha: 0.18),
      alignment: Alignment.center,
      child: RotatedBox(
        quarterTurns: horizontal ? 0 : 3,
        child: const Text(
          'hinge gutter',
          style: TextStyle(fontFamily: kMono, fontSize: 9, color: kGood),
        ),
      ),
    );
  }
}

class Pane extends StatelessWidget {
  const Pane({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kPanelAlt,
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: kMono,
          fontSize: 11,
          letterSpacing: 1,
          color: kMuted,
        ),
      ),
    );
  }
}

class FoldOverlay extends StatelessWidget {
  const FoldOverlay({super.key, required this.fold});

  final Rect fold;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fromRect(
            rect: fold,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: kBad.withValues(alpha: 0.20),
                border: Border.all(color: kBad),
              ),
              child: const Center(
                child: Text(
                  'HINGE',
                  style: TextStyle(
                    fontFamily: kMono,
                    fontSize: 10,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w700,
                    color: kBad,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
