import 'package:flutter/material.dart';

import '../models/sale.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'ui.dart';

/// One account as a dark rounded card: round badge, name, status and profit.
class SaleItem extends StatelessWidget {
  const SaleItem({super.key, required this.sale, required this.currency, required this.onTap});

  final Sale sale;
  final String currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = sale;
    final sold = s.isSold;
    final p = s.profit;
    final r = roi(s.cost, p);
    final sub = s.accountId.isNotEmpty
        ? s.accountId
        : [s.channel, s.buyer].where((e) => e.isNotEmpty).join(' · ');

    final meta = <Widget>[];
    if (sold || s.price > 0) {
      meta.add(Text(pctText(r), style: sans(size: 12, color: p < 0 ? AppColors.loss : AppColors.butter)));
    }
    if (sold && !s.paid) {
      meta.add(Text('ຄ້າງຈ່າຍ', style: sans(size: 12, color: AppColors.loss)));
    }
    if (s.status == SaleStatus.reserved && s.paid) {
      meta.add(Text('ມັດຈຳແລ້ວ', style: sans(size: 12, color: AppColors.muted)));
    }

    final Color amountColor = sold ? (p < 0 ? AppColors.loss : AppColors.butter) : AppColors.muted;
    final double amountValue = (sold || s.price > 0) ? p : s.cost;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.line),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A181F), Color(0xFF121016)],
            ),
          ),
          child: Row(
            children: [
              Coin(s.game),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(text: s.game, style: sans(size: 17, weight: FontWeight.w500)),
                        if (s.demo) TextSpan(text: '  ຕົວຢ່າງ', style: sans(size: 11, color: AppColors.muted)),
                      ]),
                    ),
                    if (sub.isNotEmpty)
                      Text(sub, style: s.accountId.isNotEmpty ? mono(size: 13, color: AppColors.muted) : sans(size: 13, color: AppColors.muted)),
                    if (meta.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Wrap(spacing: 10, children: meta),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusTag(s.status),
                  const SizedBox(height: 6),
                  AmountText(amountValue, currency, signed: sold || s.price > 0, size: 15, weight: FontWeight.w600, color: amountColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
