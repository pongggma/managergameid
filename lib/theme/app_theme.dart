import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colours taken from the night-sky fintech look: warm brown top, violet middle,
/// magenta glow at the bottom, butter-yellow for gains.
class AppColors {
  static const page = Color(0xFF08070B);
  static const text = Color(0xFFF5F2F8);
  static const muted = Color(0xFFA39CAD);
  static const faint = Color(0xFF756E80);
  static const glass = Color(0x12FFFFFF); // 7%
  static const glass2 = Color(0x1FFFFFFF); // 12%
  static const line = Color(0x17FFFFFF); // 9%
  static const magenta = Color(0xFFFF14F0);
  static const magentaSoft = Color(0x2EFF14F0); // 18%
  static const magentaText = Color(0xFFFF86F8);
  static const butter = Color(0xFFEBD86A);
  static const butterInk = Color(0xFF1C1704);
  static const loss = Color(0xFFFF7F9E);
  static const mint = Color(0xFF7DFFC4);
  static const navBar = Color(0xEB141119);
}

/// Lao glyphs come from the phone's own Lao font.
const _laoFallback = ['Noto Sans Lao', 'Noto Sans Lao UI', 'Lao Sangam MN', 'Leelawadee UI'];

const _tabular = [FontFeature.tabularFigures()];

/// Plus Jakarta Sans for Latin text and numbers.
TextStyle sans({
  double size = 15,
  FontWeight weight = FontWeight.w400,
  Color color = AppColors.text,
  double? height,
  double? letterSpacing,
}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    fontFeatures: _tabular,
  ).copyWith(fontFamilyFallback: _laoFallback);
}

/// IBM Plex Mono for account IDs, emails and passwords.
TextStyle mono({
  double size = 13,
  FontWeight weight = FontWeight.w400,
  Color color = AppColors.text,
}) {
  return GoogleFonts.ibmPlexMono(
    fontSize: size,
    fontWeight: weight,
    color: color,
    fontFeatures: _tabular,
  ).copyWith(fontFamilyFallback: _laoFallback);
}

Color goodColor() => AppColors.butter;
Color badColor() => AppColors.loss;

ThemeData buildTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.transparent,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.magenta,
      onPrimary: Colors.white,
      secondary: AppColors.butter,
      onSecondary: AppColors.butterInk,
      surface: Color(0xFF15131A),
      onSurface: AppColors.text,
      error: AppColors.loss,
    ),
  );
  return base.copyWith(
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
      fontFamilyFallback: _laoFallback,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xF51E1A26),
      contentTextStyle: sans(size: 14),
      shape: const StadiumBorder(),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Warm brown -> violet -> magenta night sky with a few stars.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: const [
        ColoredBox(color: AppColors.page),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -1.18),
              radius: 1.1,
              colors: [Color(0xF29E7640), Color(0xC75C4024), Color(0x00281C14)],
              stops: [0, 0.42, 1],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.3, 0.2),
              radius: 0.95,
              colors: [Color(0xCC6C2C92), Color(0x006C2C92)],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, 1.3),
              radius: 0.95,
              colors: [Color(0xE6FF14F0), Color(0x00FF14F0)],
            ),
          ),
        ),
        CustomPaint(painter: _StarsPainter()),
      ],
    );
  }
}

class _StarsPainter extends CustomPainter {
  const _StarsPainter();

  static const _stars = [
    [0.08, 0.12, 1.0, 0.6],
    [0.22, 0.30, 1.0, 0.4],
    [0.36, 0.08, 1.4, 0.5],
    [0.58, 0.22, 1.0, 0.45],
    [0.74, 0.10, 1.0, 0.55],
    [0.90, 0.26, 1.4, 0.4],
    [0.14, 0.52, 1.0, 0.35],
    [0.84, 0.48, 1.0, 0.4],
    [0.46, 0.64, 1.0, 0.3],
    [0.06, 0.80, 1.0, 0.35],
    [0.94, 0.72, 1.0, 0.3],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in _stars) {
      final paint = Paint()..color = Colors.white.withAlpha((s[3] * 255).round());
      canvas.drawCircle(Offset(size.width * s[0], size.height * s[1]), s[2], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
