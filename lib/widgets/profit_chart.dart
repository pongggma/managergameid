import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/sale_store.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Profit chart: three summary tiles (total, average, best) above rounded bars.
/// Tap or drag across the chart to pick a bar; a tooltip shows the full period,
/// exact profit and how many accounts were sold. The current period is marked
/// with a dot, the dashed line is the average.
class ProfitChart extends StatefulWidget {
  const ProfitChart({super.key, required this.bars, required this.currency});

  final List<MonthBar> bars;
  final String currency;

  @override
  State<ProfitChart> createState() => _ProfitChartState();
}

class _ProfitChartState extends State<ProfitChart> {
  static const double height = 262;
  late int _sel = widget.bars.length - 1;

  void _pick(double dx, double width) {
    final n = widget.bars.length;
    final slot = (width - _ChartPainter.left - _ChartPainter.right) / n;
    final i = ((dx - _ChartPainter.left) / slot).floor().clamp(0, n - 1);
    if (i != _sel) setState(() => _sel = i);
  }

  Widget _tile(String label, String value, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: AppColors.glass,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: sans(size: 11, color: AppColors.muted)),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: sans(size: 15, weight: FontWeight.w600, color: color ?? AppColors.text)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bars = widget.bars;
    final cur = widget.currency;
    if (_sel >= bars.length) _sel = bars.length - 1;
    final total = bars.fold(0.0, (t, b) => t + b.value);
    final avg = total / bars.length;
    MonthBar? best;
    for (final b in bars) {
      if (b.value > 0 && (best == null || b.value > best.value)) best = b;
    }

    return Column(
      children: [
        Row(
          children: [
            _tile('ລວມກຳໄລ', compact(total), color: total < 0 ? AppColors.loss : AppColors.butter),
            const SizedBox(width: 8),
            _tile('ສະເລ່ຍ', compact(avg), color: avg < 0 ? AppColors.loss : null),
            const SizedBox(width: 8),
            _tile('ດີທີ່ສຸດ', best == null ? '–' : best.title),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.line),
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x14FFFFFF), Color(0x06FFFFFF)]),
          ),
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
          child: LayoutBuilder(builder: (context, c) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _pick(d.localPosition.dx, c.maxWidth),
              onHorizontalDragUpdate: (d) => _pick(d.localPosition.dx, c.maxWidth),
              child: SizedBox(
                height: height,
                width: c.maxWidth,
                child: CustomPaint(painter: _ChartPainter(bars, cur, _sel)),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.bars, this.currency, this.sel);

  static const double left = 42, right = 10, top = 70, bottom = 34;
  final List<MonthBar> bars;
  final String currency;
  final int sel;

  void _text(Canvas canvas, String text, double cx, double cy,
      {Color color = AppColors.muted, double size = 10, FontWeight weight = FontWeight.w400, bool alignRight = false, bool alignLeft = false}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: sans(size: size, weight: weight, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = alignRight ? cx - tp.width : (alignLeft ? cx : cx - tp.width / 2);
    tp.paint(canvas, Offset(dx, cy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final x0 = left, x1 = w - right;
    final plotH = h - top - bottom;
    final n = bars.length;
    final slot = (x1 - x0) / n;
    final vals = bars.map((b) => b.value).toList();
    final hasData = vals.any((v) => v != 0);
    final gridPaint = Paint()..color = const Color(0x12FFFFFF)..strokeWidth = 1;

    // ----- axes / empty state -----
    final ticks = hasData
        ? niceTicks(math.min(0.0, vals.reduce(math.min)), math.max(0.0, vals.reduce(math.max)), 4)
        : [0.0, 1.0];
    final minV = ticks.first, maxV = ticks.last;
    double y(double v) => top + (maxV - v) / (maxV - minV) * plotH;
    final y0 = y(0);

    for (final t in ticks) {
      final yy = y(t);
      if (t == 0) {
        canvas.drawLine(Offset(x0, yy), Offset(x1, yy), Paint()..color = const Color(0x40FFFFFF)..strokeWidth = 1.2);
      } else {
        for (var x = x0; x < x1; x += 8) {
          canvas.drawLine(Offset(x, yy), Offset(math.min(x + 3, x1), yy), gridPaint);
        }
      }
      if (hasData) _text(canvas, compact(t), x0 - 8, yy, alignRight: true, size: 10);
    }

    if (!hasData) {
      _text(canvas, 'ຍັງບໍ່ມີຂໍ້ມູນການຂາຍ', (x0 + x1) / 2, top + plotH / 2, size: 13);
    }

    // ----- bars -----
    final barW = math.min(30.0, slot * 0.56);
    for (var i = 0; i < n; i++) {
      final b = bars[i];
      final cx = x0 + slot * (i + 0.5);
      final isSel = i == sel;

      if (isSel) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTRB(cx - slot / 2 + 2, top - 4, cx + slot / 2 - 2, h - bottom + 4), const Radius.circular(14)),
          Paint()..color = const Color(0x0DFFFFFF),
        );
      }

      if (b.value == 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, y0), width: barW, height: 3), const Radius.circular(2)),
          Paint()..color = const Color(0x26FFFFFF),
        );
      } else {
        final bh = math.max((y(b.value) - y0).abs(), 6.0);
        final ry = b.value >= 0 ? y0 - bh : y0;
        final rect = Rect.fromLTWH(cx - barW / 2, ry, barW, bh);
        final List<Color> cols = b.value < 0
            ? [const Color(0xFFFFA9BF), const Color(0xFFFF7F9E)]
            : isSel
                ? [const Color(0xFFF8EDA6), const Color(0xFFEBD86A)]
                : [const Color(0xFFFF6CF7), const Color(0xFFB200B0)];
        final paint = Paint()
          ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: cols).createShader(rect);
        final rr = RRect.fromRectAndCorners(
          rect,
          topLeft: Radius.circular(b.value >= 0 ? barW / 2.4 : 3),
          topRight: Radius.circular(b.value >= 0 ? barW / 2.4 : 3),
          bottomLeft: Radius.circular(b.value < 0 ? barW / 2.4 : 3),
          bottomRight: Radius.circular(b.value < 0 ? barW / 2.4 : 3),
        );
        if (isSel) {
          canvas.drawRRect(rr, Paint()..color = cols.last.withOpacity(.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
        }
        canvas.drawRRect(rr, paint);
      }

      // label (+ year line) and "now" dot
      if (b.label.isNotEmpty) {
        _text(canvas, b.label, cx, h - bottom + 14,
            size: n > 12 ? 9 : (n > 6 ? 10 : 11), color: isSel ? AppColors.text : AppColors.muted, weight: isSel ? FontWeight.w600 : FontWeight.w400);
      }
      if (b.sub.isNotEmpty) {
        _text(canvas, b.sub, cx, h - bottom + 26, size: 8, color: AppColors.faint);
      } else if (b.isNow) {
        canvas.drawCircle(Offset(cx, h - bottom + 27), 2.2, Paint()..color = AppColors.butter);
      }
    }

    // ----- average line -----
    if (hasData) {
      final avg = vals.reduce((a, b) => a + b) / n;
      final ya = y(avg);
      final dash = Paint()..color = const Color(0x99FFFFFF)..strokeWidth = 1;
      for (var x = x0; x < x1; x += 7) {
        canvas.drawLine(Offset(x, ya), Offset(math.min(x + 3.5, x1), ya), dash);
      }
      _text(canvas, 'ສະເລ່ຍ ${compact(avg)}', x1, ya - 8, alignRight: true, size: 9, color: const Color(0xB3FFFFFF));
    }

    // ----- tooltip for the selected bar -----
    final b = bars[sel];
    final cx = x0 + slot * (sel + 0.5);
    final valueText = money(b.value, currency, signed: true);
    final countText = b.count == 0 ? 'ບໍ່ມີການຂາຍ' : 'ຂາຍ ${b.count} ໄອດີ';
    final titleTp = TextPainter(text: TextSpan(text: b.title, style: sans(size: 10, color: AppColors.muted)), textDirection: TextDirection.ltr)..layout();
    final valTp = TextPainter(
      text: TextSpan(
        text: valueText,
        style: sans(size: 15, weight: FontWeight.w600, color: b.value < 0 ? AppColors.loss : (b.value > 0 ? AppColors.butter : AppColors.text)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final cntTp = TextPainter(text: TextSpan(text: countText, style: sans(size: 10, color: AppColors.muted)), textDirection: TextDirection.ltr)..layout();
    final tw = math.max(math.max(titleTp.width, valTp.width), cntTp.width) + 28;
    const th = 60.0;
    final tx = (cx - tw / 2).clamp(4.0, w - tw - 4);
    final trect = Rect.fromLTWH(tx, 4, tw, th);
    final trr = RRect.fromRectAndRadius(trect, const Radius.circular(16));
    // pointer line down to the bar
    final barTop = b.value > 0 ? y(b.value) - 6 : y0 - 6;
    canvas.drawLine(Offset(cx, trect.bottom), Offset(cx, math.max(barTop, trect.bottom + 4)),
        Paint()..color = const Color(0x40FFFFFF)..strokeWidth = 1);
    canvas.drawRRect(trr, Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF3B1F52), Color(0xFF1C0F2A)]).createShader(trect));
    canvas.drawRRect(trr, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = const Color(0x2EFFFFFF));
    titleTp.paint(canvas, Offset(trect.center.dx - titleTp.width / 2, trect.top + 8));
    valTp.paint(canvas, Offset(trect.center.dx - valTp.width / 2, trect.top + 22));
    cntTp.paint(canvas, Offset(trect.center.dx - cntTp.width / 2, trect.top + 43));
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => true;
}
