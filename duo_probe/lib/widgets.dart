import 'package:flutter/material.dart';

import 'theme.dart';

class PaddingDiagram extends StatelessWidget {
  const PaddingDiagram({super.key, required this.padding, required this.label});

  final EdgeInsets padding;
  final String label;

  @override
  Widget build(BuildContext context) {
    final asymmetric = padding.left != padding.right;
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: kPanelAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 74, vertical: 28),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: asymmetric ? kBad : kAccent,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontFamily: kMono,
                      fontSize: 10,
                      color: kMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
          _edge(Alignment.topCenter, padding.top, 'top'),
          _edge(Alignment.bottomCenter, padding.bottom, 'bottom'),
          _edge(Alignment.centerLeft, padding.left, 'left'),
          _edge(Alignment.centerRight, padding.right, 'right'),
        ],
      ),
    );
  }

  Widget _edge(Alignment alignment, double value, String name) {
    final highlight = (name == 'left' || name == 'right') &&
        padding.left != padding.right;
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Text(
          '$name ${value.toStringAsFixed(1)}',
          style: TextStyle(
            fontFamily: kMono,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: highlight ? kBad : (value > 0 ? kAccent : kMuted),
          ),
        ),
      ),
    );
  }
}

class RulerStripe extends StatelessWidget {
  const RulerStripe({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(painter: _RulerPainter(), child: const SizedBox.expand()),
    );
  }
}

class _RulerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1F6FEB), Color(0xFF45D9EC), Color(0xFFFF6B6B)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);

    final tick = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += 25) {
      final major = x % 100 == 0;
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x, size.height - (major ? size.height * 0.55 : size.height * 0.28)),
        tick,
      );
      if (major && x > 0) {
        final painter = TextPainter(
          text: TextSpan(
            text: x.toInt().toString(),
            style: const TextStyle(
              fontFamily: kMono,
              fontSize: 8,
              color: Colors.black87,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        painter.paint(canvas, Offset(x + 2, 1));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) => false;
}

class ConditionBanner extends StatelessWidget {
  const ConditionBanner({
    super.key,
    required this.controller,
    required this.rebuilds,
  });

  final TextEditingController controller;
  final int rebuilds;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: const BoxDecoration(
        color: kPanelAlt,
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: kAccent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'DUO PROBE',
              style: TextStyle(
                fontFamily: kMono,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: kBg,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(
                fontFamily: kMono,
                fontSize: 12,
                color: kText,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'condition label for this screenshot',
                hintStyle: TextStyle(
                  fontFamily: kMono,
                  fontSize: 12,
                  color: kMuted,
                ),
              ),
            ),
          ),
          StatusPill('build $rebuilds', tone: Tone.neutral),
        ],
      ),
    );
  }
}
