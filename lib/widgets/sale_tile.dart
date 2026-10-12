import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/sale_store.dart';
import '../models/sale.dart';
import '../utils/format.dart';

const monoStyle = TextStyle(
  fontFamily: 'monospace',
  fontFeatures: [FontFeature.tabularFigures()],
);

Color goodColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF4CD59A)
        : const Color(0xFF0B7F50);

Color badColor(BuildContext context) =>
    Theme.of(context).colorScheme.error;

/// One account in the list: game, credentials (optional), money and actions.
class SaleTile extends StatefulWidget {
  const SaleTile({
    super.key,
    required this.sale,
    required this.store,
    required this.onEdit,
    required this.onSell,
  });

  final Sale sale;
  final SaleStore store;
  final VoidCallback onEdit;
  final VoidCallback onSell;

  @override
  State<SaleTile> createState() => _SaleTileState();
}

class _SaleTileState extends State<SaleTile> {
  bool _reveal = false;

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('ຄັດລອກແລ້ວ'), duration: Duration(seconds: 2)));
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('ລຶບລາຍການນີ້?'),
        content: Text(widget.sale.game),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('ຍົກເລີກ')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('ລຶບ')),
        ],
      ),
    );
    if (ok == true) await widget.store.remove(widget.sale.id);
  }

  Widget _chip(BuildContext context, String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _kv(BuildContext context, String k, String v, {Color? color, bool bold = false}) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: TextStyle(color: muted)),
          Text(v, style: monoStyle.copyWith(color: color, fontWeight: bold ? FontWeight.w600 : FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sale;
    final cs = Theme.of(context).colorScheme;
    final cur = widget.store.currency;
    final good = goodColor(context);
    final bad = badColor(context);

    final statusChip = switch (s.status) {
      SaleStatus.stock => _chip(context, s.status.label, cs.primaryContainer, cs.onPrimaryContainer),
      SaleStatus.reserved => _chip(context, s.status.label, cs.tertiaryContainer, cs.onTertiaryContainer),
      SaleStatus.sold => _chip(context, s.status.label, good.withAlpha(36), good),
    };

    final meta = <String>[
      if (s.channel.isNotEmpty) s.channel,
      if (s.buyer.isNotEmpty) s.buyer,
      if (s.isSold && s.soldAt != null) fmtDate(s.soldAt!),
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(s.game, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                Wrap(spacing: 6, children: [
                  statusChip,
                  if (s.isSold || s.status == SaleStatus.reserved)
                    if (s.paid)
                      _chip(context, 'ຮັບເງິນແລ້ວ', cs.surfaceContainerHighest, cs.onSurfaceVariant)
                    else if (s.isSold)
                      _chip(context, 'ຄ້າງຈ່າຍ', cs.errorContainer, cs.onErrorContainer),
                  if (s.demo) _chip(context, 'ຕົວຢ່າງ', cs.surfaceContainerHighest, cs.onSurfaceVariant),
                ]),
              ],
            ),
            if (s.accountId.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(s.accountId, style: monoStyle.copyWith(color: cs.onSurfaceVariant, fontSize: 13)),
              ),
            if (s.email.isNotEmpty || s.password.isNotEmpty) ...[
              const SizedBox(height: 8),
              if (s.email.isNotEmpty)
                _credRow(context, 'ອີເມລ', s.email, [
                  _mini(Icons.copy, 'ຄັດລອກອີເມລ', () => _copy(s.email)),
                ]),
              if (s.password.isNotEmpty)
                _credRow(context, 'ລະຫັດ', _reveal ? s.password : '••••••••', [
                  _mini(_reveal ? Icons.visibility_off : Icons.visibility, _reveal ? 'ເຊື່ອງ' : 'ສະແດງ',
                      () => setState(() => _reveal = !_reveal)),
                  _mini(Icons.copy, 'ຄັດລອກລະຫັດຜ່ານ', () => _copy(s.password)),
                ]),
            ],
            if (meta.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(meta.join(' · '), style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
              ),
            if (s.note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(s.note, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
              ),
            const SizedBox(height: 12),
            _kv(context, 'ຕົ້ນທຶນ', money(s.cost, cur)),
            _kv(context, 'ລາຄາຂາຍ', s.price > 0 ? money(s.price, cur) : '–'),
            if (s.isSold)
              _kv(context, 'ກຳໄລ', money(s.profit, cur, signed: true),
                  color: s.profit < 0 ? bad : good, bold: true)
            else if (s.price > 0)
              _kv(context, 'ຄາດວ່າກຳໄລ', money(s.profit, cur, signed: true), color: cs.onSurfaceVariant),
            const SizedBox(height: 8),
            Row(
              children: [
                if (!s.isSold)
                  Expanded(child: OutlinedButton(onPressed: widget.onSell, child: const Text('ໝາຍຂາຍ'))),
                if (!s.isSold) const SizedBox(width: 8),
                Expanded(child: OutlinedButton(onPressed: widget.onEdit, child: const Text('ແກ້ໄຂ'))),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _delete,
                    style: OutlinedButton.styleFrom(foregroundColor: bad),
                    child: const Text('ລຶບ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _credRow(BuildContext context, String k, String v, List<Widget> actions) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(width: 48, child: Text(k, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13))),
        Expanded(child: Text(v, style: monoStyle.copyWith(fontSize: 13))),
        ...actions,
      ],
    );
  }

  Widget _mini(IconData icon, String tip, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tip,
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
    );
  }
}
