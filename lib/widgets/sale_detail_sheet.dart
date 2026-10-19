import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/sale_store.dart';
import '../models/sale.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'ui.dart';

typedef SaleCallback = void Function(Sale sale);

/// Detail page of one account (opens when a card is tapped):
/// big profit, tags, key / value rows, credentials with copy buttons.
class SaleDetailSheet extends StatefulWidget {
  const SaleDetailSheet({super.key, required this.store, required this.saleId, required this.onEdit, required this.onSell});

  final SaleStore store;
  final String saleId;
  final SaleCallback onEdit;
  final SaleCallback onSell;

  @override
  State<SaleDetailSheet> createState() => _SaleDetailSheetState();
}

class _SaleDetailSheetState extends State<SaleDetailSheet> {
  bool _reveal = false;
  String? _copied; // which value was just copied: 'aid' | 'email' | 'pass'

  Sale? get _sale {
    for (final s in widget.store.sales) {
      if (s.id == widget.saleId) return s;
    }
    return null;
  }

  Future<void> _copy(String key, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _copied = key);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _copied == key) setState(() => _copied = null);
    });
  }

  Future<void> _delete(Sale s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1A171F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('ລຶບລາຍການນີ້?', style: sans(size: 18, weight: FontWeight.w600)),
        content: Text(s.game, style: sans(color: AppColors.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text('ຍົກເລີກ', style: sans(color: AppColors.muted))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.loss, foregroundColor: const Color(0xFF2A0610)),
            onPressed: () => Navigator.pop(c, true),
            child: Text('ລຶບ', style: sans(weight: FontWeight.w600, color: const Color(0xFF2A0610))),
          ),
        ],
      ),
    );
    if (ok == true) {
      await widget.store.remove(s.id);
      if (mounted) Navigator.pop(context);
    }
  }

  Widget _miniBtn(IconData icon, String tip, VoidCallback onTap, {bool done = false}) {
    return Tooltip(
      message: tip,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.glass,
            border: Border.all(color: AppColors.line),
          ),
          child: Icon(done ? Icons.check_rounded : icon, size: 17, color: done ? AppColors.butter : AppColors.text),
        ),
      ),
    );
  }

  Widget _credRow(String label, String value, List<Widget> actions) {
    return KvRow(
      label,
      trailing: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(child: Text(value, textAlign: TextAlign.right, style: mono(size: 13))),
          const SizedBox(width: 8),
          ...actions,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final s = _sale;
        if (s == null) return const SizedBox(height: 120);
        final cur = widget.store.currency;
        final sold = s.isSold;
        final p = s.profit;
        final r = roi(s.cost, p);

        final rows = <Widget>[
          KvRow('ສະຖານະ', value: s.status.label),
          if (s.accountId.isNotEmpty)
            _credRow('ໄອດີ', s.accountId, [
              _miniBtn(Icons.copy_rounded, 'ຄັດລອກໄອດີ', () => _copy('aid', s.accountId), done: _copied == 'aid'),
            ]),
          if (s.email.isNotEmpty)
            _credRow('ອີເມລ', s.email, [
              _miniBtn(Icons.copy_rounded, 'ຄັດລອກອີເມລ', () => _copy('email', s.email), done: _copied == 'email'),
            ]),
          if (s.password.isNotEmpty)
            _credRow('ລະຫັດຜ່ານ', _reveal ? s.password : '••••••••', [
              _miniBtn(_reveal ? Icons.visibility_off_outlined : Icons.visibility_outlined, _reveal ? 'ເຊື່ອງ' : 'ສະແດງ',
                  () => setState(() => _reveal = !_reveal)),
              const SizedBox(width: 6),
              _miniBtn(Icons.copy_rounded, 'ຄັດລອກລະຫັດຜ່ານ', () => _copy('pass', s.password), done: _copied == 'pass'),
            ]),
          KvRow('ຕົ້ນທຶນ', value: money(s.cost, cur)),
          if (sold) KvRow('ລາຄາຂາຍ', value: money(s.price, cur)),
          if (s.channel.isNotEmpty) KvRow('ຊ່ອງທາງຂາຍ', value: s.channel),
          if (s.buyer.isNotEmpty) KvRow('ຜູ້ຊື້', value: s.buyer),
          if (sold && s.soldAt != null) KvRow('ວັນທີຂາຍ', value: fmtDate(s.soldAt!)),
          if (sold || s.status == SaleStatus.reserved)
            KvRow('ການຮັບເງິນ', trailing: Text(s.paid ? 'ຮັບເງິນແລ້ວ' : 'ຄ້າງຈ່າຍ', textAlign: TextAlign.right, style: sans(weight: FontWeight.w500, color: s.paid ? AppColors.text : AppColors.loss))),
          if (s.note.isNotEmpty) KvRow('ໝາຍເຫດ', value: s.note),
        ];

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 20 + MediaQuery.of(context).padding.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  RoundButton(onTap: () => Navigator.pop(context), tooltip: 'ກັບຄືນ', child: const Icon(Icons.arrow_back_rounded, size: 22)),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Coin(s.game, size: 34, logoUrl: widget.store.logoUrl(s.game)),
                        const SizedBox(width: 10),
                        Flexible(child: Text(s.game, overflow: TextOverflow.ellipsis, style: sans(size: 19, weight: FontWeight.w500))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
                child: Text(sold ? 'ກຳໄລ' : 'ຕົ້ນທຶນ', style: sans(size: 17)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: AmountText(sold ? p : s.cost, cur, signed: sold, size: 46, weight: FontWeight.w300, color: sold && p < 0 ? AppColors.loss : AppColors.text),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (sold && r != null) ButterChip(pctText(r), negative: p < 0),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 14, 4, 18),
                child: Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusTag(s.status),
                    if (s.demo) Text('ຕົວຢ່າງ', style: sans(size: 11, color: AppColors.muted)),
                  ],
                ),
              ),
              DarkPanel(children: rows),
              const SizedBox(height: 18),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.magenta,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: const StadiumBorder(),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  widget.onSell(s);
                },
                child: Text(sold ? 'ແກ້ໄຂການຂາຍ' : 'ຂາຍ', style: sans(size: 16, weight: FontWeight.w600, color: Colors.white)),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: const StadiumBorder(),
                  side: const BorderSide(color: AppColors.line),
                  backgroundColor: AppColors.glass2,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  widget.onEdit(s);
                },
                child: Text('ແກ້ໄຂຂໍ້ມູນໄອດີ', style: sans(size: 16, weight: FontWeight.w500)),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => _delete(s),
                  child: Text('ລຶບລາຍການນີ້', style: sans(color: AppColors.loss, weight: FontWeight.w500)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
