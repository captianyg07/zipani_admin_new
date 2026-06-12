import 'package:flutter/material.dart';

import '../design/design_tokens.dart';
import '../design/typography.dart';

/// One plotted point: an x-axis label and a value (raw; the chart normalizes).
class ChartPoint {
  const ChartPoint({required this.label, required this.value});
  final String label;
  final double value;
}

/// Smooth gradient area + line chart (no external chart package).
class AreaChart extends StatelessWidget {
  const AreaChart({
    super.key,
    required this.points,
    required this.color,
    this.height = 200,
  });

  final List<ChartPoint> points;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final maxV = points.fold<double>(
        0, (m, p) => p.value > m ? p.value : m);
    return SizedBox(
      height: height,
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) => CustomPaint(
                size: Size(c.maxWidth, c.maxHeight),
                painter: _Painter(
                  fractions: points
                      .map((p) => maxV <= 0 ? 0.0 : p.value / maxV)
                      .toList(),
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: DS.s8),
          Row(
            children: [
              for (final p in points)
                Expanded(
                  child: Text(p.label,
                      textAlign: TextAlign.center,
                      style: AppType.small.copyWith(fontSize: 11)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Painter extends CustomPainter {
  _Painter({required this.fractions, required this.color});
  final List<double> fractions;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (fractions.isEmpty) return;
    const pad = 8.0;
    final h = size.height - pad;
    final n = fractions.length;
    final dx = n == 1 ? 0.0 : size.width / (n - 1);

    Offset at(int i) {
      final x = n == 1 ? size.width / 2 : dx * i;
      final y = pad + h * (1 - fractions[i].clamp(0.0, 1.0));
      return Offset(x, y);
    }

    final line = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 0; i < n - 1; i++) {
      final p0 = at(i), p1 = at(i + 1);
      final midX = (p0.dx + p1.dx) / 2;
      line.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    final area = Path.from(line)
      ..lineTo(at(n - 1).dx, size.height)
      ..lineTo(at(0).dx, size.height)
      ..close();

    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.26), color.withOpacity(0.01)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final fill = Paint()..color = Colors.white;
    final ring = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    for (var i = 0; i < n; i++) {
      canvas.drawCircle(at(i), 3.5, fill);
      canvas.drawCircle(at(i), 3.5, ring);
    }
  }

  @override
  bool shouldRepaint(covariant _Painter old) =>
      old.fractions != fractions || old.color != color;
}
