import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sale.dart';
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

class MonthBar {
  const MonthBar(this.label, this.value, this.isNow);
  final String label;
  final double value;
  final bool isNow;
}

/// Keeps every sale on the device (SharedPreferences, as one JSON string).
class SaleStore extends ChangeNotifier {
  static const _key = 'game-id-ledger-v1';

  SharedPreferences? _prefs;
  List<Sale> _sales = [];
  String _currency = 'LAK';

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
    } catch (_) {
      _sales = [];
    }
  }

  Future<void> _persist() async {
    notifyListeners();
    await _prefs?.setString(
      _key,
      jsonEncode({
        'currency': _currency,
        'sales': _sales.map((s) => s.toJson()).toList(),
      }),
    );
  }

  String newId() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${Random().nextInt(1 << 20).toRadixString(36)}';

  Future<void> upsert(Sale sale) async {
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

  Future<void> setCurrency(String c) async {
    _currency = c;
    await _persist();
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

  /// Profit per month for the last 6 months.
  List<MonthBar> monthly() {
    final now = DateTime.now();
    final bars = <MonthBar>[];
    for (var i = 5; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      var total = 0.0;
      for (final s in _sales) {
        final sd = s.soldAt;
        if (s.isSold && sd != null && sd.year == d.year && sd.month == d.month) {
          total += s.profit;
        }
      }
      bars.add(MonthBar(laoMonths[d.month - 1], total, i == 0));
    }
    return bars;
  }

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
