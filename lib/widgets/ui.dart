import 'package:flutter/material.dart';

import '../models/sale.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

void showToast(BuildContext context, String msg) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(
    SnackBar(
      content: Text(msg, textAlign: TextAlign.center),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 112),
      duration: const Duration(seconds: 2),
    ),
  );
}

/// Big light number with a small currency symbol: 1,250,000 ₭ / $8,502.
class AmountText extends StatelessWidget {
  const AmountText(
    this.value,
    this.currency, {
    super.key,
    this.signed = false,
    this.size = 16,
    this.weight = FontWeight.w500,
    this.color = AppColors.text,
  });

  final double value;
  final String currency;
  final bool signed;
  final double size;
  final FontWeight weight;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final r = value.round();
    final sign = r < 0 ? '-' : (signed && r > 0 ? '+' : '');
    final digits = groupInt(r.abs());
    final sym = currencySymbols[currency] ?? '';
    final main = sans(
      size: size,
      weight: weight,
      color: color,
      letterSpacing: size > 30 ? -size * 0.02 : null,
    );
    final small = sans(size: size * 0.5, color: AppColors.muted);
    final spans = currency == 'LAK'
        ? [
            TextSpan(text: '$sign$digits', style: main),
            TextSpan(text: ' $sym', style: small),
          ]
        : [
            TextSpan(text: sign, style: main),
            TextSpan(text: '$sym ', style: small),
            TextSpan(text: digits, style: main),
          ];
    return Text.rich(TextSpan(children: spans));
  }
}

/// Butter-yellow percentage pill (rose when negative).
class ButterChip extends StatelessWidget {
  const ButterChip(this.text, {super.key, this.negative = false, this.small = false});

  final String text;
  final bool negative;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: small
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 3)
          : const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: negative ? AppColors.loss : AppColors.butter,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: sans(
          size: small ? 13 : 16,
          weight: FontWeight.w600,
          color: negative ? const Color(0xFF2A0610) : AppColors.butterInk,
        ),
      ),
    );
  }
}

class StatusTag extends StatelessWidget {
  const StatusTag(this.status, {super.key});

  final SaleStatus status;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    switch (status) {
      case SaleStatus.stock:
        bg = AppColors.glass2;
        fg = AppColors.text;
      case SaleStatus.reserved:
        bg = const Color(0x29EBD86A);
        fg = AppColors.butter;
      case SaleStatus.sold:
        bg = AppColors.magentaSoft;
        fg = AppColors.magentaText;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(status.label, style: sans(size: 12, weight: FontWeight.w600, color: fg)),
    );
  }
}

/// Round game badge with initials on a coloured disc.
class Coin extends StatelessWidget {
  const Coin(this.game, {super.key, this.size = 60});

  final String game;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = coinColors(game);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.4, -0.5),
          radius: 1.0,
          colors: [Color(0xFF2A2731), Color(0xFF0D0B11)],
        ),
        border: Border.all(color: const Color(0x12FFFFFF)),
        boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Center(
        child: Container(
          width: size * 0.7,
          height: size * 0.7,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: c,
            ),
          ),
          child: Text(
            initials(game),
            style: sans(size: size * 0.235, weight: FontWeight.w700, color: const Color(0xFF150F20)),
          ),
        ),
      ),
    );
  }
}

/// Frosted dark card.
class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.line),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x17FFFFFF), Color(0x0AFFFFFF)],
        ),
      ),
      child: child,
    );
  }
}

/// Near-black panel that holds key / value rows.
class DarkPanel extends StatelessWidget {
  const DarkPanel({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) rows.add(const Divider(height: 1, thickness: 1, color: AppColors.line));
      rows.add(children[i]);
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xD1040306),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(children: rows),
    );
  }
}

class KvRow extends StatelessWidget {
  const KvRow(this.label, {super.key, this.value, this.trailing, this.sub});

  final String label;
  final String? value;
  final Widget? trailing;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: sans(color: AppColors.muted)),
          const SizedBox(width: 16),
          Expanded(
            child: trailing ??
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(value ?? '', textAlign: TextAlign.right, style: sans(weight: FontWeight.w500)),
                    if (sub != null) Text(sub!, style: sans(size: 12, color: AppColors.muted)),
                  ],
                ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.note, this.actionLabel, this.onAction});

  final String title;
  final String? note;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 34, bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: sans(size: 22)),
          if (note != null) Text(note!, style: sans(size: 13, color: AppColors.muted)),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(actionLabel!, style: sans(size: 14, weight: FontWeight.w500, color: AppColors.magentaText)),
            ),
        ],
      ),
    );
  }
}

/// Round translucent icon button (header, back, actions).
class RoundButton extends StatelessWidget {
  const RoundButton({super.key, required this.child, required this.onTap, this.size = 44, this.filled = false, this.tooltip});

  final Widget child;
  final VoidCallback onTap;
  final double size;
  final bool filled;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: filled ? AppColors.glass2 : Colors.transparent,
      shape: CircleBorder(side: filled ? const BorderSide(color: AppColors.line) : BorderSide.none),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: size, height: size, child: Center(child: child)),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

/// The 2x2 hollow circles icon used for the menu button.
class DotsIcon extends StatelessWidget {
  const DotsIcon({super.key, this.size = 22, this.color = AppColors.text});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size(size, size), painter: _DotsPainter(color));
}

class _DotsPainter extends CustomPainter {
  _DotsPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7;
    final r = size.width * 0.095;
    for (final dx in [0.29, 0.71]) {
      for (final dy in [0.29, 0.71]) {
        canvas.drawCircle(Offset(size.width * dx, size.height * dy), r, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotsPainter old) => old.color != color;
}

/// Bottom sheet frame with the warm-to-violet gradient and a drag handle.
class SheetShell extends StatelessWidget {
  const SheetShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFF0B0A0E),
          gradient: RadialGradient(
            center: Alignment(0, -1.12),
            radius: 1.15,
            colors: [Color(0xE69E7640), Color(0x8C46301C), Color(0x0014100C)],
            stops: [0, 0.45, 1],
          ),
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.4, 0.55),
              radius: 0.9,
              colors: [Color(0x8C6C2C92), Color(0x006C2C92)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: const Color(0x3DFFFFFF), borderRadius: BorderRadius.circular(2)),
              ),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
