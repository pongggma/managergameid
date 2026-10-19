import 'dart:math' as math;
import 'dart:ui' show Color;

const laoMonths = [
  'ມັງກອນ',
  'ກຸມພາ',
  'ມີນາ',
  'ເມສາ',
  'ພຶດສະພາ',
  'ມິຖຸນາ',
  'ກໍລະກົດ',
  'ສິງຫາ',
  'ກັນຍາ',
  'ຕຸລາ',
  'ພະຈິກ',
  'ທັນວາ',
];

const currencySymbols = {'LAK': '₭', 'THB': '฿', 'USD': r'$'};

String _two(int n) => n.toString().padLeft(2, '0');

/// 12/10/2026
String fmtDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

/// 2026-10-12 (used for storage)
String dateKey(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

String groupInt(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return (n < 0 ? '-' : '') + b.toString();
}

/// Digits of a positive amount: USD keeps cents (1,234.50), others are whole numbers.
String digitsFor(double abs, String currency) {
  if (currency == 'USD') {
    final cents = (abs * 100).round();
    final whole = groupInt(cents ~/ 100);
    final frac = (cents % 100).toString().padLeft(2, '0');
    return '$whole.$frac';
  }
  return groupInt(abs.round());
}

/// Sign for an amount, based on what is actually shown (so -0.001 shows no sign).
String signFor(double v, String currency, {bool signed = false}) {
  final shown = currency == 'USD' ? (v * 100).round() : v.round();
  return shown < 0 ? '-' : (signed && shown > 0 ? '+' : '');
}

/// LAK shows the symbol after the number (1,200,000 ₭); THB/USD before it.
String money(double v, String currency, {bool signed = false}) {
  final sym = currencySymbols[currency] ?? '';
  final sign = signFor(v, currency, signed: signed);
  final a = digitsFor(v.abs(), currency);
  return currency == 'LAK' ? '$sign$a $sym' : '$sign$sym$a';
}

/// Round an amount the way [currency] is shown (cents for USD, whole units otherwise).
double roundFor(double v, String currency) => currency == 'USD' ? (v * 100).round() / 100 : v.roundToDouble();

String compact(double v) {
  final a = v.abs();
  final s = v < 0 ? '-' : '';
  String trim(double x) => x.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
  if (a >= 1e9) return '$s${trim(a / 1e9)}B';
  if (a >= 1e6) return '$s${trim(a / 1e6)}M';
  if (a >= 1e3) return '$s${trim(a / 1e3)}k';
  return '$s${a.round()}';
}

/// Number for a text field: whole numbers without decimals.
String plainNumber(double v) {
  if (v == 0) return '';
  return v == v.roundToDouble() ? v.round().toString() : v.toString();
}

/// Return on cost in percent, or null when there is no cost.
double? roi(double cost, double profit) => cost > 0 ? profit / cost * 100 : null;

String pctText(double? v) {
  if (v == null) return '–';
  return '${v > 0 ? '+' : ''}${v.toStringAsFixed(1)}%';
}

/// Round axis values that cover [min]..[max] (about [n] steps).
List<double> niceTicks(double min, double max, int n) {
  final span = max - min;
  final raw = span / n;
  final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  final f = raw / mag;
  final step = (f <= 1 ? 1 : f <= 2 ? 2 : f <= 5 ? 5 : 10) * mag;
  final lo = (min / step).floor() * step;
  final hi = (max / step).ceil() * step;
  final ticks = <double>[];
  for (var v = lo; v <= hi + step / 2; v += step) {
    ticks.add((v * 1e6).round() / 1e6);
  }
  return ticks;
}

/// Two letters for the round game badge: "Free Fire" -> FF, "Valorant" -> VA.
String initials(String game) {
  final words = game.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '?';
  String first(String w) => String.fromCharCode(w.runes.first);
  if (words.length >= 2) return (first(words[0]) + first(words[1])).toUpperCase();
  final r = words[0].runes.toList();
  return String.fromCharCodes(r.take(2)).toUpperCase();
}

const _coinPalette = [
  [Color(0xFFFFE27A), Color(0xFFE69A00)],
  [Color(0xFF8FF5D6), Color(0xFF1FA68A)],
  [Color(0xFFFF8BF8), Color(0xFFC000C0)],
  [Color(0xFFC4A6FF), Color(0xFF5A3FD6)],
];

/// Stable gradient colours for a game name.
List<Color> coinColors(String game) {
  var h = 0;
  for (final c in game.codeUnits) {
    h = (h * 31 + c) & 0x7FFFFFFF;
  }
  return _coinPalette[h % _coinPalette.length];
}
