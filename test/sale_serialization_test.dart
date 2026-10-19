import 'package:flutter_test/flutter_test.dart';
import 'package:game_id_ledger/models/sale.dart';

void main() {
  test('sale records survive the local and Firestore JSON round trip', () {
    final original = Sale(
      id: 'sale-1',
      game: 'Free Fire',
      accountId: 'FF-123',
      email: 'player@example.com',
      password: 'secret',
      status: SaleStatus.sold,
      cost: 100,
      price: 150,
      channel: 'Facebook',
      buyer: 'buyer',
      paid: true,
      soldAt: DateTime(2026, 10, 19),
      note: 'sold',
      createdAt: DateTime(2026, 10, 18, 12, 30),
    );

    final restored = Sale.fromJson(original.toJson());

    expect(restored.id, original.id);
    expect(restored.game, original.game);
    expect(restored.accountId, original.accountId);
    expect(restored.email, original.email);
    expect(restored.password, original.password);
    expect(restored.status, original.status);
    expect(restored.cost, original.cost);
    expect(restored.price, original.price);
    expect(restored.channel, original.channel);
    expect(restored.buyer, original.buyer);
    expect(restored.paid, original.paid);
    expect(restored.soldAt, original.soldAt);
    expect(restored.note, original.note);
    expect(restored.createdAt, original.createdAt);
  });
}
