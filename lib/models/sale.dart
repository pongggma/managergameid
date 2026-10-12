import '../utils/format.dart';

enum SaleStatus { stock, reserved, sold }

extension SaleStatusLabel on SaleStatus {
  String get label {
    switch (this) {
      case SaleStatus.stock:
        return 'ພ້ອມຂາຍ';
      case SaleStatus.reserved:
        return 'ຈອງແລ້ວ';
      case SaleStatus.sold:
        return 'ຂາຍແລ້ວ';
    }
  }
}

/// One game account (ID) you buy and sell.
/// Only [game] is required; email, password and the rest are optional.
class Sale {
  const Sale({
    required this.id,
    required this.game,
    required this.createdAt,
    this.accountId = '',
    this.email = '',
    this.password = '',
    this.status = SaleStatus.stock,
    this.cost = 0,
    this.price = 0,
    this.channel = '',
    this.buyer = '',
    this.paid = false,
    this.soldAt,
    this.note = '',
    this.demo = false,
  });

  final String id;
  final String game;
  final String accountId;
  final String email;
  final String password;
  final SaleStatus status;
  final double cost;
  final double price;
  final String channel;
  final String buyer;
  final bool paid;
  final DateTime? soldAt;
  final String note;
  final DateTime createdAt;
  final bool demo;

  double get profit => price - cost;
  bool get isSold => status == SaleStatus.sold;

  Map<String, dynamic> toJson() => {
        'id': id,
        'game': game,
        'accountId': accountId,
        'email': email,
        'password': password,
        'status': status.name,
        'cost': cost,
        'price': price,
        'channel': channel,
        'buyer': buyer,
        'paid': paid,
        'soldAt': soldAt == null ? '' : dateKey(soldAt!),
        'note': note,
        'createdAt': createdAt.toIso8601String(),
        'demo': demo,
      };

  factory Sale.fromJson(Map<String, dynamic> j) {
    return Sale(
      id: j['id'] as String,
      game: (j['game'] as String?) ?? '',
      accountId: (j['accountId'] as String?) ?? '',
      email: (j['email'] as String?) ?? '',
      password: (j['password'] as String?) ?? '',
      status: SaleStatus.values.firstWhere(
        (s) => s.name == j['status'],
        orElse: () => SaleStatus.stock,
      ),
      cost: (j['cost'] as num?)?.toDouble() ?? 0,
      price: (j['price'] as num?)?.toDouble() ?? 0,
      channel: (j['channel'] as String?) ?? '',
      buyer: (j['buyer'] as String?) ?? '',
      paid: (j['paid'] as bool?) ?? false,
      soldAt: DateTime.tryParse((j['soldAt'] as String?) ?? ''),
      note: (j['note'] as String?) ?? '',
      createdAt: DateTime.tryParse((j['createdAt'] as String?) ?? '') ??
          DateTime.now(),
      demo: (j['demo'] as bool?) ?? false,
    );
  }
}
