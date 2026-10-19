import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'ui.dart';

/// Six original characters, drawn in code. They are inspired by classic game
/// archetypes (knight, mage, ninja, robot, fox spirit, baby dragon) but are
/// not taken from any game. Profile pictures can only be picked from these.
class AvatarSpec {
  const AvatarSpec(this.name, this.top, this.bottom);
  final String name;
  final Color top;
  final Color bottom;
}

const avatarSpecs = [
  AvatarSpec('ນັກຮົບ', Color(0xFF6A7BFF), Color(0xFF181B54)),
  AvatarSpec('ນັກເວດ', Color(0xFFC25BFF), Color(0xFF2A0F55)),
  AvatarSpec('ນິນຈາ', Color(0xFFFF5C7A), Color(0xFF3A0716)),
  AvatarSpec('ຫຸ່ນຍົນ', Color(0xFF2FE0CB), Color(0xFF063B4A)),
  AvatarSpec('ຈິ້ງຈອກ', Color(0xFFFFB04D), Color(0xFF5A1B00)),
  AvatarSpec('ມັງກອນນ້ອຍ', Color(0xFF7DFFC4), Color(0xFF063B2C)),
];

/// Round avatar for [index] (0..5).
class Avatar extends StatelessWidget {
  const Avatar(this.index, {super.key, this.size = 48, this.ring = false});

  final int index;
  final double size;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final i = index.clamp(0, avatarSpecs.length - 1);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring ? AppColors.magenta : const Color(0x33FFFFFF), width: ring ? 3 : 1),
        boxShadow: [BoxShadow(color: avatarSpecs[i].top.withOpacity(.35), blurRadius: size * .35, offset: Offset(0, size * .12))],
      ),
      child: ClipOval(child: CustomPaint(size: Size.square(size), painter: _AvatarPainter(i))),
    );
  }
}

/// Bottom sheet to edit the profile: display name + one of the six characters.
Future<void> showProfileEditor(BuildContext context, AuthService auth) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xB8050308),
    builder: (ctx) => SheetShell(child: _ProfileSheet(auth: auth)),
  );
}

class _ProfileSheet extends StatefulWidget {
  const _ProfileSheet({required this.auth});

  final AuthService auth;

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.auth.profileName);
  late int _pick = widget.auth.avatar;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.auth.setAvatar(_pick);
    final err = await widget.auth.setName(_name.text);
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) return showToast(context, err);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.auth.account?.email ?? '';
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Text('ແກ້ໄຂໂປຣໄຟລ໌', style: sans(size: 19, weight: FontWeight.w500))),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
              decoration: BoxDecoration(color: AppColors.glass, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.line)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ຊື່ທີ່ສະແດງ', style: sans(size: 12, color: AppColors.muted)),
                  TextField(
                    controller: _name,
                    maxLength: 30,
                    textCapitalization: TextCapitalization.words,
                    style: sans(size: 17),
                    cursorColor: AppColors.butter,
                    decoration: InputDecoration(
                      isDense: true,
                      counterText: '',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.only(top: 4),
                      hintText: email.isNotEmpty ? email : 'ໃສ່ຊື່ຂອງທ່ານ',
                      hintStyle: sans(size: 17, color: AppColors.faint),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Text(email.isNotEmpty ? 'ຖ້າເວັ້ນວ່າງ ຈະສະແດງອີເມລແທນ' : 'ເວັ້ນວ່າງໄດ້', style: sans(size: 12, color: AppColors.faint)),
            ),
            const SizedBox(height: 22),
            Text('ເລືອກຕົວລະຄອນ', style: sans(size: 12, color: AppColors.muted)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 12,
              childAspectRatio: .86,
              children: [
                for (var i = 0; i < avatarSpecs.length; i++)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _pick = i),
                    child: Column(
                      children: [
                        Expanded(child: LayoutBuilder(builder: (_, c) => Avatar(i, size: math.min(c.maxWidth, c.maxHeight) - 6, ring: _pick == i))),
                        const SizedBox(height: 6),
                        Text(avatarSpecs[i].name, style: sans(size: 13, weight: _pick == i ? FontWeight.w600 : FontWeight.w400, color: _pick == i ? AppColors.text : AppColors.muted)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.magenta,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                shape: const StadiumBorder(),
              ),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : Text('ບັນທຶກ', style: sans(size: 17, weight: FontWeight.w600, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  _AvatarPainter(this.i);
  final int i;

  // ---- helpers (all drawing uses a 100 x 100 canvas) ----
  Paint _fill(Color c) => Paint()..color = c;
  Paint _grad(Rect r, Color a, Color b, {bool horizontal = false}) => Paint()
    ..shader = LinearGradient(
      begin: horizontal ? Alignment.centerLeft : Alignment.topCenter,
      end: horizontal ? Alignment.centerRight : Alignment.bottomCenter,
      colors: [a, b],
    ).createShader(r);
  Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void _shoulders(Canvas c, Color a, Color b) {
    final r = Rect.fromCenter(center: const Offset(50, 104), width: 76, height: 56);
    c.drawOval(r, _grad(r, a, b));
  }

  void _eye(Canvas c, Offset o, double rx, double ry, Color color, {bool glint = true}) {
    c.drawOval(Rect.fromCenter(center: o, width: rx * 2, height: ry * 2), _fill(color));
    if (glint) c.drawCircle(o.translate(-rx * .3, -ry * .3), math.min(rx, ry) * .32, _fill(Colors.white));
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    final spec = avatarSpecs[i];
    const full = Rect.fromLTWH(0, 0, 100, 100);
    canvas.drawRect(full, Paint()..shader = RadialGradient(center: const Alignment(0, -.5), radius: 1.1, colors: [spec.top, spec.bottom]).createShader(full));
    // soft light spot
    canvas.drawCircle(const Offset(28, 22), 22, Paint()..color = const Color(0x14FFFFFF));
    switch (i) {
      case 0:
        _knight(canvas);
      case 1:
        _mage(canvas);
      case 2:
        _ninja(canvas);
      case 3:
        _robot(canvas);
      case 4:
        _fox(canvas);
      default:
        _dragon(canvas);
    }
  }

  // 1. Knight: steel helmet, glowing visor, magenta plume
  void _knight(Canvas c) {
    _shoulders(c, const Color(0xFF8E98B8), const Color(0xFF3B4160));
    // plume
    final plume = Path()
      ..moveTo(50, 14)
      ..cubicTo(70, 6, 86, 20, 76, 40)
      ..cubicTo(70, 30, 60, 28, 52, 30)
      ..close();
    c.drawPath(plume, _grad(const Rect.fromLTWH(50, 6, 36, 34), const Color(0xFFFF6CF7), const Color(0xFFB200B0)));
    // helmet
    final helm = RRect.fromRectAndCorners(const Rect.fromLTWH(28, 24, 44, 52),
        topLeft: const Radius.circular(22), topRight: const Radius.circular(22), bottomLeft: const Radius.circular(10), bottomRight: const Radius.circular(10));
    c.drawRRect(helm, _grad(helm.outerRect, const Color(0xFFE4E8F6), const Color(0xFF8590B4), horizontal: true));
    c.drawRRect(helm, _stroke(const Color(0x66FFFFFF), 1.2));
    // center ridge
    c.drawLine(const Offset(50, 24), const Offset(50, 44), _stroke(const Color(0x55303A60), 2));
    // visor
    final visor = RRect.fromRectAndRadius(const Rect.fromLTWH(33, 44, 34, 11), const Radius.circular(5));
    c.drawRRect(visor, _fill(const Color(0xFF14172E)));
    c.drawCircle(const Offset(43, 49.5), 2.4, _fill(const Color(0xFFEBD86A)));
    c.drawCircle(const Offset(57, 49.5), 2.4, _fill(const Color(0xFFEBD86A)));
    // breath holes
    for (var k = 0; k < 3; k++) {
      c.drawCircle(Offset(42 + k * 8.0, 66), 1.4, _fill(const Color(0xFF4A5380)));
    }
  }

  // 2. Mage: starry hat, calm face, white beard
  void _mage(Canvas c) {
    _shoulders(c, const Color(0xFF7B3FD6), const Color(0xFF2A0F55));
    // face
    c.drawCircle(const Offset(50, 56), 16, _grad(const Rect.fromLTWH(34, 40, 32, 32), const Color(0xFFFFE0C8), const Color(0xFFE8B592)));
    // beard
    final beard = Path()
      ..moveTo(34, 58)
      ..quadraticBezierTo(36, 86, 50, 90)
      ..quadraticBezierTo(64, 86, 66, 58)
      ..quadraticBezierTo(50, 70, 34, 58)
      ..close();
    c.drawPath(beard, _grad(const Rect.fromLTWH(34, 58, 32, 32), Colors.white, const Color(0xFFCFC8E8)));
    // closed happy eyes
    c.drawArc(const Rect.fromLTWH(40, 52, 7, 6), math.pi, math.pi, false, _stroke(const Color(0xFF3B2410), 1.8));
    c.drawArc(const Rect.fromLTWH(53, 52, 7, 6), math.pi, math.pi, false, _stroke(const Color(0xFF3B2410), 1.8));
    // hat
    final hat = Path()
      ..moveTo(26, 44)
      ..quadraticBezierTo(44, 40, 46, 14)
      ..quadraticBezierTo(50, 4, 62, 10)
      ..quadraticBezierTo(56, 26, 74, 44)
      ..quadraticBezierTo(50, 36, 26, 44)
      ..close();
    c.drawPath(hat, _grad(const Rect.fromLTWH(26, 4, 48, 40), const Color(0xFF9B4DFF), const Color(0xFF45208F)));
    // brim
    final brim = Rect.fromCenter(center: const Offset(50, 44), width: 58, height: 10);
    c.drawOval(brim, _grad(brim, const Color(0xFF8B45F2), const Color(0xFF3A1A7A)));
    // star on hat
    _star(c, const Offset(52, 28), 6, const Color(0xFFEBD86A));
    c.drawCircle(const Offset(44, 16), 1.3, _fill(Colors.white70));
  }

  void _star(Canvas c, Offset o, double r, Color col) {
    final p = Path();
    for (var k = 0; k < 10; k++) {
      final rr = k.isEven ? r : r * .45;
      final a = -math.pi / 2 + k * math.pi / 5;
      final pt = Offset(o.dx + rr * math.cos(a), o.dy + rr * math.sin(a));
      k == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    p.close();
    c.drawPath(p, _fill(col));
  }

  // 3. Ninja: dark hood, eye slit, red headband with tails
  void _ninja(Canvas c) {
    _shoulders(c, const Color(0xFF2A2F4A), const Color(0xFF0E1020));
    c.drawCircle(const Offset(50, 52), 25, _grad(const Rect.fromLTWH(25, 27, 50, 50), const Color(0xFF3A4066), const Color(0xFF12142A)));
    // eye band
    final band = RRect.fromRectAndRadius(const Rect.fromLTWH(30, 43, 40, 15), const Radius.circular(8));
    c.drawRRect(band, _grad(band.outerRect, const Color(0xFFFFE0C8), const Color(0xFFE8B592)));
    // eyes
    for (final dx in [41.0, 59.0]) {
      c.save();
      c.translate(dx, 50.5);
      c.rotate(dx < 50 ? .18 : -.18);
      c.drawOval(Rect.fromCenter(center: Offset.zero, width: 8, height: 5), _fill(const Color(0xFF15111E)));
      c.drawCircle(const Offset(-1, -1), 1.1, _fill(Colors.white));
      c.restore();
    }
    // headband + tails
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(26, 34, 48, 7), const Radius.circular(3)), _fill(const Color(0xFFFF3B5C)));
    final tail1 = Path()
      ..moveTo(70, 36)
      ..quadraticBezierTo(84, 34, 90, 46)
      ..quadraticBezierTo(80, 42, 70, 41)
      ..close();
    final tail2 = Path()
      ..moveTo(70, 38)
      ..quadraticBezierTo(82, 44, 84, 58)
      ..quadraticBezierTo(76, 50, 69, 42)
      ..close();
    c.drawPath(tail1, _fill(const Color(0xFFE02049)));
    c.drawPath(tail2, _fill(const Color(0xFFC21540)));
    // headband plate
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(43, 33, 14, 9), const Radius.circular(2)), _fill(const Color(0xFFC9CFE8)));
  }

  // 4. Robot: square head, cyan visor eyes, antenna
  void _robot(Canvas c) {
    _shoulders(c, const Color(0xFFB9C2D6), const Color(0xFF59647E));
    // antenna
    c.drawLine(const Offset(50, 30), const Offset(50, 17), _stroke(const Color(0xFFB9C2D6), 3));
    c.drawCircle(const Offset(50, 14), 4.5, _grad(const Rect.fromLTWH(45, 9, 10, 10), const Color(0xFFFF6CF7), const Color(0xFFB200B0)));
    // ear bolts
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(20, 44, 8, 16), const Radius.circular(3)), _fill(const Color(0xFF7C86A2)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(72, 44, 8, 16), const Radius.circular(3)), _fill(const Color(0xFF7C86A2)));
    // head
    final head = RRect.fromRectAndRadius(const Rect.fromLTWH(27, 29, 46, 46), const Radius.circular(13));
    c.drawRRect(head, _grad(head.outerRect, const Color(0xFFF2F5FC), const Color(0xFF9AA5C0)));
    // visor
    final visor = RRect.fromRectAndRadius(const Rect.fromLTWH(32, 40, 36, 17), const Radius.circular(8));
    c.drawRRect(visor, _fill(const Color(0xFF0B1B2B)));
    final glow = Paint()..color = const Color(0xFF39F2FF)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2);
    for (final dx in [42.0, 58.0]) {
      c.drawCircle(Offset(dx, 48.5), 4.2, glow);
      c.drawCircle(Offset(dx, 48.5), 3.4, _fill(const Color(0xFF8CFAFF)));
    }
    // mouth grill
    for (var k = 0; k < 4; k++) {
      c.drawLine(Offset(40 + k * 7.0, 63), Offset(40 + k * 7.0, 69), _stroke(const Color(0xFF6C7794), 2));
    }
  }

  // 5. Fox spirit: big ears, white cheeks, amber eyes
  void _fox(Canvas c) {
    _shoulders(c, const Color(0xFFFF8A3D), const Color(0xFF8A2E00));
    // ears
    for (final left in [true, false]) {
      final sx = left ? 1.0 : -1.0;
      Offset p(double x, double y) => Offset(50 + (x - 50) * sx, y);
      final outer = Path()
        ..moveTo(p(28, 50).dx, 50)
        ..lineTo(p(26, 12).dx, 12)
        ..lineTo(p(48, 32).dx, 32)
        ..close();
      final inner = Path()
        ..moveTo(p(31, 42).dx, 42)
        ..lineTo(p(30, 20).dx, 20)
        ..lineTo(p(43, 33).dx, 33)
        ..close();
      c.drawPath(outer, _fill(const Color(0xFFE5671A)));
      c.drawPath(inner, _fill(const Color(0xFF3A1200)));
    }
    // head
    final head = Path()
      ..moveTo(26, 48)
      ..quadraticBezierTo(50, 28, 74, 48)
      ..quadraticBezierTo(80, 62, 62, 76)
      ..quadraticBezierTo(50, 82, 38, 76)
      ..quadraticBezierTo(20, 62, 26, 48)
      ..close();
    c.drawPath(head, _grad(const Rect.fromLTWH(20, 28, 60, 54), const Color(0xFFFFA45C), const Color(0xFFE8681C)));
    // white cheeks
    final cheekL = Path()
      ..moveTo(24, 58)
      ..quadraticBezierTo(38, 58, 50, 70)
      ..quadraticBezierTo(40, 80, 30, 70)
      ..close();
    c.drawPath(cheekL, _fill(const Color(0xFFFFF4E6)));
    c.save();
    c.translate(100, 0);
    c.scale(-1, 1);
    c.drawPath(cheekL, _fill(const Color(0xFFFFF4E6)));
    c.restore();
    // eyes
    for (final dx in [40.0, 60.0]) {
      c.save();
      c.translate(dx, 53);
      c.rotate(dx < 50 ? .22 : -.22);
      c.drawOval(Rect.fromCenter(center: Offset.zero, width: 8, height: 5.4), _fill(const Color(0xFF2A1004)));
      c.drawCircle(const Offset(-1, -1), 1.1, _fill(const Color(0xFFFFE08A)));
      c.restore();
    }
    // nose + mouth
    c.drawOval(Rect.fromCenter(center: const Offset(50, 67), width: 8, height: 5.5), _fill(const Color(0xFF2A1004)));
    c.drawPath(Path()..moveTo(50, 69)..quadraticBezierTo(50, 74, 45, 74), _stroke(const Color(0xFF2A1004), 1.4));
    c.drawPath(Path()..moveTo(50, 69)..quadraticBezierTo(50, 74, 55, 74), _stroke(const Color(0xFF2A1004), 1.4));
  }

  // 6. Baby dragon: horns, head spikes, yellow slit eyes, tiny fangs
  void _dragon(Canvas c) {
    _shoulders(c, const Color(0xFF3FD99B), const Color(0xFF0B5A44));
    // horns
    for (final left in [true, false]) {
      final sx = left ? 1.0 : -1.0;
      double x(double v) => 50 + (v - 50) * sx;
      final horn = Path()
        ..moveTo(x(34), 40)
        ..quadraticBezierTo(x(22), 22, x(28), 8)
        ..quadraticBezierTo(x(40), 20, x(44), 36)
        ..close();
      c.drawPath(horn, _grad(const Rect.fromLTWH(20, 8, 30, 32), const Color(0xFFFFF1C9), const Color(0xFFE0B25E)));
    }
    // head spikes
    final spikes = Path()
      ..moveTo(44, 34)
      ..lineTo(50, 18)
      ..lineTo(56, 34)
      ..close();
    c.drawPath(spikes, _fill(const Color(0xFF1FA877)));
    // head
    final head = Rect.fromCenter(center: const Offset(50, 56), width: 52, height: 46);
    c.drawOval(head, _grad(head, const Color(0xFF8CFFD0), const Color(0xFF1FB57F)));
    // snout
    final snout = Rect.fromCenter(center: const Offset(50, 68), width: 30, height: 18);
    c.drawOval(snout, _grad(snout, const Color(0xFFB8FFE2), const Color(0xFF4BD8A0)));
    c.drawCircle(const Offset(44, 67), 1.6, _fill(const Color(0xFF0B3B2C)));
    c.drawCircle(const Offset(56, 67), 1.6, _fill(const Color(0xFF0B3B2C)));
    // eyes
    for (final dx in [38.0, 62.0]) {
      c.drawOval(Rect.fromCenter(center: Offset(dx, 52), width: 11, height: 9), _fill(const Color(0xFFFFE45C)));
      c.drawOval(Rect.fromCenter(center: Offset(dx, 52), width: 3.4, height: 8), _fill(const Color(0xFF0B1B12)));
    }
    // brow ridge
    c.drawLine(const Offset(31, 45), const Offset(43, 47), _stroke(const Color(0xFF138A60), 2.4));
    c.drawLine(const Offset(69, 45), const Offset(57, 47), _stroke(const Color(0xFF138A60), 2.4));
    // fangs
    final fang = Path()..moveTo(43, 74)..lineTo(45, 80)..lineTo(47, 74)..close();
    c.drawPath(fang, _fill(Colors.white));
    final fang2 = Path()..moveTo(53, 74)..lineTo(55, 80)..lineTo(57, 74)..close();
    c.drawPath(fang2, _fill(Colors.white));
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter old) => old.i != i;
}
