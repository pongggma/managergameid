import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/sale_store.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Monthly profit as rounded magenta bars (current month in butter yellow),
/// with a y axis, a dashed average line and a floating average bubble.
/// Everything is drawn on a fixed 360 x 214 canvas and scaled to the width.
class ProfitChart extends StatelessWidget {
  const ProfitChart({super.key, required this.bars});

  final List<MonthBar> bars;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _ChartPainter.w / _ChartPainter.h,
      child: CustomPaint(painter: _ChartPainter(bars)),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.bars);

  static const double w = 360, h = 214;
  final List<MonthBar> bars;

  void _text(Canvas canvas, String text, double cx, double cy,
      {Color color = AppColors.muted, double size = 10, FontWeight weight = FontWeight.w400, bool right = false}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: sans(size: size, weight: weight, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = right ? cx - tp.width : cx - tp.width / 2;
    tp.paint(canvas, Offset(dx, cy - tp.height / 2));
  }

  Paint _grad(Rect r, Color a, Color b) =>
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [a, b]).createShader(r);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / w);

    const top = 16.0, bot = 28.0, x0 = 50.0, x1 = w - 6;
    const plotH = h - top - bot;
    final vals = bars.map((b) => b.value).toList();
    final hasData = vals.any((v) => v != 0);
    final axis = Paint()..color = const Color(0x24FFFFFF)..strokeWidth = 1;
    final grid = Paint()..color = const Color(0x0DFFFFFF)..strokeWidth = 1;
    final slot = (x1 - x0) / bars.length;

    canvas.drawLine(const Offset(x0, top), const Offset(x0, h - bot), axis);

    if (!hasData) {
      canvas.drawLine(const Offset(x0, h - bot), const Offset(x1, h - bot), grid);
      _text(canvas, 'ຍັງບໍ່ມີຂໍ້ມູນການຂາຍ', (x0 + x1) / 2, h / 2, size: 12);
      for (var i = 0; i < bars.length; i++) {
        _text(canvas, bars[i].label, x0 + slot * (i + 0.5), h - 12);
      }
      canvas.restore();
      return;
    }

    final ticks = niceTicks(math.min(0.0, vals.reduce(math.min)), math.max(0.0, vals.reduce(math.max)), 4);
    final minV = ticks.first, maxV = ticks.last;
    double y(double v) => top + (maxV - v) / (maxV - minV) * plotH;
    final y0 = y(0);

    for (final t in ticks) {
      canvas.drawLine(Offset(x0, y(t)), Offset(x1, y(t)), grid);
      canvas.drawCircle(Offset(x0, y(t)), 1.8, Paint()..color = AppColors.mint);
      _text(canvas, compact(t), x0 - 8, y(t), right: true);
    }

    for (var i = 0; i < bars.length; i++) {
      final b = bars[i];
      final cx = x0 + slot * (i + 0.5);
      if (b.value != 0) {
        final bh = math.max((y(b.value) - y0).abs(), 4.0);
        final ry = b.value >= 0 ? y0 - bh : y0;
        final rect = Rect.fromLTWH(cx - 7, ry, 14, bh);
        final paint = b.value < 0
            ? _grad(rect, const Color(0xFFFF9DB5), const Color(0xFFFF7F9E))
            : b.isNow
                ? _grad(rect, const Color(0xFFF6EA9A), const Color(0xFFEBD86A))
                : _grad(rect, const Color(0xFFFF6CF7), const Color(0xFFFF14F0));
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(7)), paint);
        final ty = b.value >= 0 ? ry - 9 : ry + bh + 8;
        _text(canvas, compact(b.value), cx, ty,
            size: 9, color: b.isNow ? AppColors.butter : AppColors.muted, weight: b.isNow ? FontWeight.w600 : FontWeight.w400);
      }
      _text(canvas, b.label, cx, h - 12);
    }

    // dashed average line + bubble
    final avg = vals.reduce((a, b) => a + b) / vals.length;
    final ya = y(avg);
    final dash = Paint()..color = const Color(0xBFFFFFFF)..strokeWidth = 1;
    for (var x = x0; x < x1; x += 6) {
      canvas.drawLine(Offset(x, ya), Offset(math.min(x + 3, x1), ya), dash);
    }
    final bubble = Rect.fromLTWH(x0 + 6, ya - 10, 46, 20);
    final rr = RRect.fromRectAndRadius(bubble, const Radius.circular(10));
    canvas.drawRRect(
      rr,
      Paint()..shader = const LinearGradient(colors: [Color(0xFF4A2563), Color(0xFF241033)]).createShader(bubble),
    );
    canvas.drawRRect(rr, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = const Color(0x24FFFFFF));
    _text(canvas, compact(avg), bubble.center.dx, bubble.center.dy, color: Colors.white);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => true;
}
