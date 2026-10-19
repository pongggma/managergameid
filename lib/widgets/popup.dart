import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum PopupKind { success, error, warning, info }

extension on PopupKind {
  Color get color {
    switch (this) {
      case PopupKind.success:
        return AppColors.mint;
      case PopupKind.error:
        return AppColors.loss;
      case PopupKind.warning:
        return AppColors.butter;
      case PopupKind.info:
        return AppColors.magentaText;
    }
  }

  IconData get icon {
    switch (this) {
      case PopupKind.success:
        return Icons.check_rounded;
      case PopupKind.error:
        return Icons.wifi_off_rounded;
      case PopupKind.warning:
        return Icons.priority_high_rounded;
      case PopupKind.info:
        return Icons.info_outline_rounded;
    }
  }
}

/// Frosted dialog route: blurred background, card pops in with a small bounce.
Future<T?> _showCard<T>(BuildContext context, WidgetBuilder builder, {bool dismissible = true}) {
  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: dismissible,
    barrierLabel: 'popup',
    barrierColor: const Color(0x99050308),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (ctx, _, __) => Center(child: Material(type: MaterialType.transparency, child: builder(ctx))),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 7 * anim.value, sigmaY: 7 * anim.value),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(scale: Tween(begin: .86, end: 1.0).animate(curved), child: child),
        ),
      );
    },
  );
}

BoxDecoration _cardDecoration() => BoxDecoration(
      borderRadius: BorderRadius.circular(32),
      border: Border.all(color: const Color(0x24FFFFFF)),
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2A1B3A), Color(0xFF130E1C)]),
      boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 40, offset: Offset(0, 18))],
    );

/// Popup for a result or a question.
/// Returns true when the main button is pressed, false for the second button,
/// null when it is dismissed (or auto-closed).
///
///   await showAppPopup(context, kind: PopupKind.error, title: '...', message: '...',
///       primaryLabel: 'ລອງໃໝ່', secondaryLabel: 'ປິດ');   // true = retry
Future<bool?> showAppPopup(
  BuildContext context, {
  required PopupKind kind,
  required String title,
  String? message,
  String primaryLabel = 'ຕົກລົງ',
  String? secondaryLabel,
  Duration? autoClose,
  bool destructive = false,
}) {
  return _showCard<bool>(
    context,
    (ctx) => _PopupCard(
      kind: kind,
      title: title,
      message: message,
      primaryLabel: primaryLabel,
      secondaryLabel: secondaryLabel,
      autoClose: autoClose,
      destructive: destructive,
    ),
  );
}

/// Ask yes / no. Returns true only when confirmed.
Future<bool> confirmPopup(
  BuildContext context, {
  required String title,
  String? message,
  String confirmLabel = 'ຕົກລົງ',
  String cancelLabel = 'ຍົກເລີກ',
  bool destructive = false,
}) async {
  final r = await showAppPopup(
    context,
    kind: destructive ? PopupKind.warning : PopupKind.info,
    title: title,
    message: message,
    primaryLabel: confirmLabel,
    secondaryLabel: cancelLabel,
    destructive: destructive,
  );
  return r == true;
}

/// Short success popup that closes by itself.
Future<void> successPopup(BuildContext context, String title, {String? message}) {
  return showAppPopup(context, kind: PopupKind.success, title: title, message: message, autoClose: const Duration(milliseconds: 2200)).then((_) {});
}

/// Network / API problem popup with a "try again" button. Returns true to retry.
Future<bool> problemPopup(BuildContext context, {String? message}) async {
  final r = await showAppPopup(
    context,
    kind: PopupKind.error,
    title: 'ເຊື່ອມຕໍ່ມີບັນຫາ',
    message: message ?? 'ເນັດຊ້າ ຫຼື ລະບົບບໍ່ຕອບສະໜອງ ກະລຸນາລອງໃໝ່',
    primaryLabel: 'ລອງໃໝ່',
    secondaryLabel: 'ປິດ',
  );
  return r == true;
}

class _PopupCard extends StatefulWidget {
  const _PopupCard({
    required this.kind,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.autoClose,
    required this.destructive,
  });

  final PopupKind kind;
  final String title;
  final String? message;
  final String primaryLabel;
  final String? secondaryLabel;
  final Duration? autoClose;
  final bool destructive;

  @override
  State<_PopupCard> createState() => _PopupCardState();
}

class _PopupCardState extends State<_PopupCard> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    if (widget.autoClose != null) {
      _t = Timer(widget.autoClose!, () {
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
      });
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.kind.color;
    final nav = Navigator.of(context, rootNavigator: true);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
        decoration: _cardDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // icon that pops in with a glow
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 520),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v.clamp(0.0, 1.3), child: child),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(.16),
                  border: Border.all(color: color.withOpacity(.5), width: 1.5),
                  boxShadow: [BoxShadow(color: color.withOpacity(.35), blurRadius: 28)],
                ),
                child: Icon(widget.kind.icon, color: color, size: 36),
              ),
            ),
            const SizedBox(height: 18),
            Text(widget.title, textAlign: TextAlign.center, style: sans(size: 20, weight: FontWeight.w600)),
            if (widget.message != null) ...[
              const SizedBox(height: 8),
              Text(widget.message!, textAlign: TextAlign.center, style: sans(size: 15, color: AppColors.muted, height: 1.45)),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                if (widget.secondaryLabel != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: const StadiumBorder(),
                        side: const BorderSide(color: AppColors.line),
                        backgroundColor: AppColors.glass2,
                      ),
                      onPressed: () => nav.pop(false),
                      child: Text(widget.secondaryLabel!, style: sans(weight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.destructive ? AppColors.loss : AppColors.magenta,
                      foregroundColor: widget.destructive ? const Color(0xFF2A0610) : Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => nav.pop(true),
                    child: Text(widget.primaryLabel, style: sans(weight: FontWeight.w600, color: widget.destructive ? const Color(0xFF2A0610) : Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Runs [task] while a loading animation covers the screen.
/// After [slowAfter] the text changes to tell the person the network is slow.
/// The loader always closes, even when [task] throws (the error is rethrown).
Future<T> runWithLoading<T>(
  BuildContext context,
  Future<T> Function() task, {
  String message = 'ກຳລັງໂຫຼດ…',
  Duration slowAfter = const Duration(seconds: 4),
}) async {
  final nav = Navigator.of(context, rootNavigator: true);
  var open = true;
  _showCard<void>(context, (ctx) => _LoadingCard(message: message, slowAfter: slowAfter), dismissible: false).whenComplete(() => open = false);
  try {
    return await task();
  } finally {
    if (open && nav.mounted) nav.pop();
  }
}

class _LoadingCard extends StatefulWidget {
  const _LoadingCard({required this.message, required this.slowAfter});

  final String message;
  final Duration slowAfter;

  @override
  State<_LoadingCard> createState() => _LoadingCardState();
}

class _LoadingCardState extends State<_LoadingCard> {
  Timer? _t;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    _t = Timer(widget.slowAfter, () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Container(
        width: 250,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: _cardDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLoader(size: 64),
            const SizedBox(height: 20),
            Text(widget.message, textAlign: TextAlign.center, style: sans(size: 16, weight: FontWeight.w500)),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              child: _slow
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('ເນັດຊ້າກວ່າປົກກະຕິ ກະລຸນາລໍຖ້າສັກຄູ່…', textAlign: TextAlign.center, style: sans(size: 13, color: AppColors.butter, height: 1.4)),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading animation: a magenta-to-butter arc spinning around a pulsing dot.
class AppLoader extends StatefulWidget {
  const AppLoader({super.key, this.size = 48});

  final double size;

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(animation: _c, builder: (_, __) => CustomPaint(painter: _LoaderPainter(_c.value))),
    );
  }
}

class _LoaderPainter extends CustomPainter {
  _LoaderPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 4;
    // faint track
    canvas.drawCircle(c, r, Paint()..style = PaintingStyle.stroke..strokeWidth = 5..color = const Color(0x1FFFFFFF));
    // spinning arc
    final start = t * 2 * math.pi;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawArc(
      rect,
      start,
      math.pi * 1.25,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(startAngle: start, endAngle: start + math.pi * 1.25, colors: const [AppColors.magenta, AppColors.butter], transform: GradientRotation(start)).createShader(rect),
    );
    // pulsing centre dot
    final pulse = .5 + .5 * math.sin(t * 2 * math.pi * 2);
    canvas.drawCircle(c, size.width * (.10 + .05 * pulse), Paint()..color = AppColors.magenta.withOpacity(.55 + .4 * pulse));
  }

  @override
  bool shouldRepaint(covariant _LoaderPainter old) => old.t != t;
}
