import 'dart:convert';

import 'package:http/http.dart' as http;

/// Today's exchange rates from open.er-api.com (free, no API key).
/// All rates are quoted against USD: 1 USD = rates['LAK'] kip, etc.
class ExchangeRates {
  const ExchangeRates(this.perUsd, this.updated);

  final Map<String, double> perUsd;
  final DateTime updated;

  /// Multiply an amount in [from] by this to get the amount in [to].
  double factor(String from, String to) => perUsd[to]! / perUsd[from]!;

  /// Throws if the request fails or a currency is missing.
  static Future<ExchangeRates> fetch(Iterable<String> codes) async {
    final res = await http.get(Uri.https('open.er-api.com', '/v6/latest/USD')).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    if (j['result'] != 'success') throw Exception('bad response');
    final rates = <String, double>{};
    final raw = Map<String, dynamic>.from(j['rates'] as Map);
    for (final c in codes) {
      final v = raw[c];
      if (v is! num || v <= 0) throw Exception('no rate for $c');
      rates[c] = v.toDouble();
    }
    final t = (j['time_last_update_unix'] as num?)?.toInt();
    return ExchangeRates(rates, t == null ? DateTime.now() : DateTime.fromMillisecondsSinceEpoch(t * 1000));
  }
}
