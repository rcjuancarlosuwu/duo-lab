import 'package:flutter/material.dart';

const kBg = Color(0xFF0A0E14);
const kPanel = Color(0xFF141B24);
const kPanelAlt = Color(0xFF1B242F);
const kBorder = Color(0xFF26333F);
const kMuted = Color(0xFF7E92A8);
const kText = Color(0xFFE8EFF7);
const kAccent = Color(0xFF45D9EC);
const kGood = Color(0xFF4ADE80);
const kWarn = Color(0xFFFBBF24);
const kBad = Color(0xFFFF6B6B);

const kMono = 'Menlo';

ThemeData buildProbeTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: kBg,
    colorScheme: base.colorScheme.copyWith(
      primary: kAccent,
      surface: kPanel,
      onPrimary: kBg,
    ),
    textTheme: base.textTheme.apply(bodyColor: kText, displayColor: kText),
    dividerColor: kBorder,
  );
}

enum Tone { neutral, good, warn, bad, accent }

Color toneColor(Tone tone) => switch (tone) {
  Tone.good => kGood,
  Tone.warn => kWarn,
  Tone.bad => kBad,
  Tone.accent => kAccent,
  Tone.neutral => kMuted,
};

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
    this.accent = kAccent,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: kBorder)),
            ),
            child: Row(
              children: [
                Container(width: 3, height: 14, color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: kMuted,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class MetricRow extends StatelessWidget {
  const MetricRow(this.label, this.value, {super.key, this.tone = Tone.neutral});

  final String label;
  final String value;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final valueColor = tone == Tone.neutral ? kText : toneColor(tone);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: kMono,
                fontSize: 11.5,
                color: kMuted,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: kMono,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.text, {super.key, this.tone = Tone.neutral});

  final String text;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final color = toneColor(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: kMono,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: color,
        ),
      ),
    );
  }
}

class BigStat extends StatelessWidget {
  const BigStat({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.tone = Tone.accent,
  });

  final String label;
  final String value;
  final String? unit;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kPanelAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: kMuted,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontFamily: kMono,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: toneColor(tone),
                  ),
                ),
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(
                      fontFamily: kMono,
                      fontSize: 10,
                      color: kMuted,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
