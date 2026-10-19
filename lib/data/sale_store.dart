import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sale.dart';
import '../services/exchange_rate.dart';
import '../services/game_logo.dart';
import '../utils/format.dart';

enum SaleFilter { all, stock, reserved, sold, unpaid }

extension SaleFilterLabel on SaleFilter {
  String get label {
    switch (this) {
      case SaleFilter.all:
        return 'ທັງໝົດ';
      case SaleFilter.stock:
        return 'ພ້ອມຂາຍ';
      case SaleFilter.reserved:
        return 'ຈອງແລ້ວ';
      case SaleFilter.sold:
        return 'ຂາຍແລ້ວ';
      case SaleFilter.unpaid:
        return 'ຄ້າງຈ່າຍ';
    }
  }
}

class Summary {
  const Summary({
    required this.soldCount,
    required this.revenue,
    required this.cost,
    required this.stockCount,
    required this.stockCost,
    required this.unpaidCount,
    required this.unpaidSum,
  });

  final int soldCount;
  final double revenue;
  final double cost;
  final int stockCount;
  final double stockCost;
  final int unpaidCount;
  final double unpaidSum;

  double get profit => revenue - cost;
  double get average => soldCount == 0 ? 0 : profit / soldCount;
}

enum ChartPeriod { week, month, year }

extension ChartPeriodInfo on ChartPeriod {
  String get label => const {ChartPeriod.week: '1 ອາທິດ', ChartPeriod.month: '1 ເດືອນ', ChartPeriod.year: '1 ປີ'}[this]!;
  String get note => const {ChartPeriod.week: '7 ວັນຫຼ້າສຸດ', ChartPeriod.month: '30 ວັນຫຼ້າສຸດ', ChartPeriod.year: '12 ເດືອນຫຼ້າສຸດ'}[this]!;
}

class MonthBar {
  const MonthBar(this.label, this.value, this.isNow, {this.title = '', this.sub = '', this.count = 0, this.revenue = 0});
  final String label; // short label under the bar
  final double value; // profit
  final bool isNow;
  final String sub; // optional 2nd line under the label (year)
  final String title; // long label for the tooltip
  final int count; // accounts sold in this bucket
  final double revenue;
}

/// Keeps every sale on the device (SharedPreferences, as one JSON string).
class SaleStore extends ChangeNotifier {
  /// [suffix] is empty for guest mode (the original ledger) or the account uid.
  SaleStore({String suffix = ''}) : _key = suffix.isEmpty ? 'game-id-ledger-v1' : 'game-id-ledger-v1-$suffix';

  final String _key;

  SharedPreferences? _prefs;
  List<Sale> _sales = [];
  String _currency = 'LAK';
  List<String> _games = []; // games used before, most recent first
  List<String> _channels = []; // sales channels used before, most recent first
  final Map<String, String> _logos = {}; // lower-case game name -> icon url ('' = none found)
  final Set<String> _fetching = {};
  String _rateNote = ''; // e.g. "1 THB = 650.12 LAK · 13/10/2026"

  String get rateNote => _rateNote;

  static const defaultChannels = ['Facebook', 'TikTok', 'WhatsApp', 'Telegram', 'Discord', 'Line'];

  List<String> get knownGames => List.unmodifiable(_games);

  /// Channels used before first, then the default ones not used yet.
  List<String> get knownChannels => [
        ..._channels,
        for (final c in defaultChannels)
          if (!_channels.any((e) => e.toLowerCase() == c.toLowerCase())) c,
      ];

  static String _k(String g) => g.trim().toLowerCase();

  List<String> _bump(List<String> list, String v) {
    final t = v.trim();
    if (t.isEmpty) return list;
    return [t, ...list.where((e) => _k(e) != _k(t))];
  }

  /// Icon url for a game, or null. Starts a background lookup the first time
  /// a name is seen, and the result is saved so it is not fetched again.
  String? logoUrl(String game) {
    final k = _k(game);
    if (k.isEmpty) return null;
    final c = _logos[k];
    if (c != null) return c.isEmpty ? null : c;
    if (_fetching.add(k)) {
      GameLogoService.find(game).then((url) {
        _fetching.remove(k);
        if (url != null) _logos[k] = url; // failures are not cached, so they retry next launch
        if (url != null) _persist();
      });
    }
    return null;
  }

  List<Sale> get sales => List.unmodifiable(_sales);
  String get currency => _currency;
  bool get hasDemo => _sales.any((s) => s.demo);

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final cur = data['currency'] as String?;
      if (cur != null && currencySymbols.containsKey(cur)) _currency = cur;
      _sales = ((data['sales'] as List?) ?? [])
          .map((e) => Sale.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _games = ((data['games'] as List?) ?? []).whereType<String>().toList();
      _channels = ((data['channels'] as List?) ?? []).whereType<String>().toList();
      _rateNote = (data['rateNote'] as String?) ?? '';
      final logos = data['logos'];
      if (logos is Map) {
        logos.forEach((k, v) {
          if (k is String && v is String && v.isNotEmpty) _logos[k] = v;
        });
      }
    } catch (_) {
      _sales = [];
    }
    // Make sure games from older saved data are remembered too.
    for (final s in sorted().reversed) {
      _games = _bump(_games, s.game);
      _channels = _bump(_channels, s.channel);
    }
  }

  Future<void> _persist() async {
    notifyListeners();
    await _prefs?.setString(
      _key,
      jsonEncode({
        'currency': _currency,
        'sales': _sales.map((s) => s.toJson()).toList(),
        'rateNote': _rateNote,
        'games': _games,
        'channels': _channels,
        // keep icons only for games that are remembered
        'logos': {
          for (final g in _games)
            if ((_logos[_k(g)] ?? '').isNotEmpty) _k(g): _logos[_k(g)],
        },
      }),
    );
  }

  String newId() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${Random().nextInt(1 << 20).toRadixString(36)}';

  Future<void> upsert(Sale sale) async {
    _games = _bump(_games, sale.game);
    _channels = _bump(_channels, sale.channel);
    final i = _sales.indexWhere((s) => s.id == sale.id);
    if (i >= 0) {
      _sales[i] = sale;
    } else {
      _sales.add(sale);
    }
    await _persist();
  }

  Future<void> remove(String id) async {
    _sales.removeWhere((s) => s.id == id);
    await _persist();
  }

  /// Switch currency and convert every cost and price at today's rate.
  /// Returns null on success, or an error message (nothing is changed then).
  Future<String?> changeCurrency(String to) async {
    final from = _currency;
    if (to == from) return null;
    final ExchangeRates rates;
    try {
      rates = await ExchangeRates.fetch([from, to]);
    } catch (_) {
      return 'ດຶງອັດຕາແລກປ່ຽນບໍ່ໄດ້ ກວດອິນເຕີເນັດແລ້ວລອງໃໝ່';
    }
    final f = rates.factor(from, to);
    _sales = _sales
        .map((s) => Sale(
              id: s.id,
              game: s.game,
              accountId: s.accountId,
              email: s.email,
              password: s.password,
              status: s.status,
              cost: roundFor(s.cost * f, to),
              price: roundFor(s.price * f, to),
              channel: s.channel,
              buyer: s.buyer,
              paid: s.paid,
              soldAt: s.soldAt,
              note: s.note,
              createdAt: s.createdAt,
              demo: s.demo,
            ))
        .toList();
    _currency = to;
    final rate = f >= 100 ? f.toStringAsFixed(0) : f.toStringAsFixed(f >= 1 ? 2 : 4);
    _rateNote = '1 $from = $rate $to  ·  ${fmtDate(rates.updated)}';
    await _persist();
    return null;
  }

  // ---------- queries ----------

  DateTime _sortDate(Sale s) => s.soldAt ?? s.createdAt;

  List<Sale> sorted() {
    final list = [..._sales];
    list.sort((a, b) {
      final c = _sortDate(b).compareTo(_sortDate(a));
      return c != 0 ? c : b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  List<Sale> visible(SaleFilter filter, String query) {
    var list = sorted();
    switch (filter) {
      case SaleFilter.all:
        break;
      case SaleFilter.unpaid:
        list = list.where((s) => s.isSold && !s.paid).toList();
      case SaleFilter.stock:
        list = list.where((s) => s.status == SaleStatus.stock).toList();
      case SaleFilter.reserved:
        list = list.where((s) => s.status == SaleStatus.reserved).toList();
      case SaleFilter.sold:
        list = list.where((s) => s.isSold).toList();
    }
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((s) {
        final hay = [s.game, s.accountId, s.email, s.buyer, s.channel, s.note]
            .join(' ')
            .toLowerCase();
        return hay.contains(q);
      }).toList();
    }
    return list;
  }

  int count(SaleFilter filter) {
    switch (filter) {
      case SaleFilter.all:
        return _sales.length;
      case SaleFilter.unpaid:
        return _sales.where((s) => s.isSold && !s.paid).length;
      case SaleFilter.stock:
        return _sales.where((s) => s.status == SaleStatus.stock).length;
      case SaleFilter.reserved:
        return _sales.where((s) => s.status == SaleStatus.reserved).length;
      case SaleFilter.sold:
        return _sales.where((s) => s.isSold).length;
    }
  }

  Summary summary({required bool thisMonth}) {
    final now = DateTime.now();
    final sold = _sales.where((s) {
      if (!s.isSold) return false;
      if (!thisMonth) return true;
      final d = s.soldAt;
      return d != null && d.year == now.year && d.month == now.month;
    }).toList();
    final stock = _sales.where((s) => !s.isSold).toList();
    final unpaid = _sales.where((s) => s.isSold && !s.paid).toList();
    double sum(Iterable<Sale> l, double Function(Sale) f) =>
        l.fold(0.0, (t, s) => t + f(s));
    return Summary(
      soldCount: sold.length,
      revenue: sum(sold, (s) => s.price),
      cost: sum(sold, (s) => s.cost),
      stockCount: stock.length,
      stockCost: sum(stock, (s) => s.cost),
      unpaidCount: unpaid.length,
      unpaidSum: sum(unpaid, (s) => s.price),
    );
  }

  static const _weekdays = ['ຈັນ', 'ອັງຄານ', 'ພຸດ', 'ພະຫັດ', 'ສຸກ', 'ເສົາ', 'ອາທິດ'];

  /// Profit of sold accounts per bucket:
  /// 1 week = the last 7 days (one bar per day),
  /// 1 month = the last 30 days (one bar per day),
  /// 1 year = the last 12 months (one bar per month).
  List<MonthBar> bars(ChartPeriod period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Each bucket: label, [start, end) range, tooltip title, second label line
    final buckets = <(String, DateTime, DateTime, String, String)>[];
    switch (period) {
      case ChartPeriod.week:
      case ChartPeriod.month:
        final n = period == ChartPeriod.week ? 7 : 30;
        for (var i = n - 1; i >= 0; i--) {
          final d = DateTime(today.year, today.month, today.day - i);
          final show = period == ChartPeriod.week || i % 5 == 0; // 30 bars: label every 5th day
          buckets.add((
            show ? '${d.day}/${d.month}' : '',
            d,
            DateTime(d.year, d.month, d.day + 1),
            'ວັນ${_weekdays[d.weekday - 1]} ${d.day}/${d.month}/${d.year}',
            '',
          ));
        }
      case ChartPeriod.year:
        for (var i = 11; i >= 0; i--) {
          final st = DateTime(now.year, now.month - i, 1);
          buckets.add((
            '${st.month}',
            st,
            DateTime(st.year, st.month + 1, 1),
            '${laoMonths[st.month - 1]} ${st.year}',
            (i == 11 || st.month == 1) ? '${st.year}' : '',
          ));
        }
    }
    return [
      for (var i = 0; i < buckets.length; i++)
        () {
          final inB = _sales
              .where((s) => s.isSold && s.soldAt != null && !s.soldAt!.isBefore(buckets[i].$2) && s.soldAt!.isBefore(buckets[i].$3))
              .toList();
          return MonthBar(
            buckets[i].$1,
            inB.fold(0.0, (t, s) => t + s.profit),
            i == buckets.length - 1,
            title: buckets[i].$4,
            sub: buckets[i].$5,
            count: inB.length,
            revenue: inB.fold(0.0, (t, s) => t + s.price),
          );
        }(),
    ];
  }

  List<MonthBar> monthly() => bars(ChartPeriod.month);

  // ---------- export / demo ----------

  String _csvCell(String v) {
    var s = v;
    if (RegExp(r'^[=+\-@\t\r]').hasMatch(s)) s = "'$s";
    if (s.contains(RegExp(r'[",\n\r]'))) s = '"${s.replaceAll('"', '""')}"';
    return s;
  }

  /// CSV of every sale. Passwords are left out on purpose.
  String exportCsv() {
    final head = [
      'ເກມ', 'ໄອດີ', 'ອີເມລ', 'ສະຖານະ', 'ຕົ້ນທຶນ', 'ລາຄາຂາຍ', 'ກຳໄລ',
      'ຮັບເງິນແລ້ວ', 'ວັນທີຂາຍ', 'ຊ່ອງທາງຂາຍ', 'ຜູ້ຊື້', 'ໝາຍເຫດ',
    ];
    final rows = sorted().map((s) {
      return [
        s.game,
        s.accountId,
        s.email,
        s.status.label,
        plainNumber(s.cost),
        plainNumber(s.price),
        s.isSold ? s.profit.round().toString() : '',
        s.paid ? 'ແມ່ນ' : 'ບໍ່',
        s.soldAt == null ? '' : dateKey(s.soldAt!),
        s.channel,
        s.buyer,
        s.note,
      ].map(_csvCell).join(',');
    });
    return [head.map(_csvCell).join(','), ...rows].join('\r\n');
  }

  Future<void> addDemo() async {
    final now = DateTime.now();
    DateTime ago(int n) => DateTime(now.year, now.month, now.day - n);
    Sale make({
      required String game,
      required String accountId,
      required SaleStatus status,
      required double cost,
      required double price,
      required int daysAgo,
      String email = '',
      String password = '',
      String channel = '',
      String buyer = '',
      bool paid = false,
      String note = '',
    }) {
      final d = ago(daysAgo);
      return Sale(
        id: newId(),
        game: game,
        accountId: accountId,
        email: email,
        password: password,
        status: status,
        cost: cost,
        price: price,
        channel: channel,
        buyer: buyer,
        paid: paid,
        soldAt: status == SaleStatus.sold ? d : null,
        note: note,
        createdAt: d,
        demo: true,
      );
    }

    _sales.addAll([
      make(game: 'Free Fire', accountId: 'FF-48210937', email: 'demo.seller1@example.com', password: 'demo-pass-1', status: SaleStatus.sold, cost: 180000, price: 350000, daysAgo: 2, channel: 'Facebook', buyer: '@boom_vt', paid: true, note: 'ເລເວນ 62, ສກິນປືນ 14 ອັນ'),
      make(game: 'PUBG Mobile', accountId: 'PM-90322417', status: SaleStatus.sold, cost: 250000, price: 420000, daysAgo: 4, channel: 'TikTok', buyer: 'ນ້ອງແກ້ວ', note: 'ຍັງລໍຖ້າໂອນເງິນ'),
      make(game: 'Mobile Legends', accountId: 'ML-5521098', status: SaleStatus.sold, cost: 300000, price: 520000, daysAgo: 38, channel: 'Telegram', buyer: '@kham_pro', paid: true, note: 'Mythic, 80 ຮີໂຣ່'),
      make(game: 'Genshin Impact', accountId: 'GI-80441275', status: SaleStatus.sold, cost: 450000, price: 410000, daysAgo: 66, channel: 'Discord', buyer: 'ພີ່ນ້ອງ', paid: true, note: 'ຂາຍຂາດທຶນ ເພື່ອປິດສະຕັອກ'),
      make(game: 'Valorant', accountId: 'VL-treeshot', status: SaleStatus.reserved, cost: 380000, price: 650000, daysAgo: 1, channel: 'Facebook', buyer: '@noi_gamer', note: 'ມັດຈຳແລ້ວ ລໍຖ້າຮັບບັນຊີ'),
      make(game: 'ROV', accountId: 'RV-1209384', password: 'demo-pass-2', status: SaleStatus.stock, cost: 120000, price: 260000, daysAgo: 3, note: 'ເລເວນ 30, ຍັງບໍ່ໄດ້ລົງຂາຍ'),
      make(game: 'Free Fire', accountId: 'FF-77310452', status: SaleStatus.stock, cost: 90000, price: 200000, daysAgo: 6),
    ]);
    await _persist();
  }

  Future<void> clearDemo() async {
    _sales.removeWhere((s) => s.demo);
    await _persist();
  }
}
