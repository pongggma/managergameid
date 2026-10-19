import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/sale_store.dart';
import '../models/sale.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'popup.dart';
import 'ui.dart';

/// Opens from the "ຂາຍ" button after an account was added.
/// Collects the selling details: price, date, channel, buyer, paid, note.
class SaleSellSheet extends StatefulWidget {
  const SaleSellSheet({super.key, required this.store, required this.sale});

  final SaleStore store;
  final Sale sale;

  @override
  State<SaleSellSheet> createState() => _SaleSellSheetState();
}

class _SaleSellSheetState extends State<SaleSellSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _price, _channel, _buyer, _note;
  late DateTime _soldAt;
  late bool _paid;
  bool _saving = false;

  Sale get _s => widget.sale;

  @override
  void initState() {
    super.initState();
    _price = TextEditingController(text: plainNumber(_s.price));
    _channel = TextEditingController(text: _s.channel);
    _buyer = TextEditingController(text: _s.buyer);
    _note = TextEditingController(text: _s.note);
    _soldAt = _s.soldAt ?? DateTime.now();
    _paid = _s.paid;
    _price.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [_price, _channel, _buyer, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(String t) {
    final x = t.replaceAll(',', '').trim();
    if (x.isEmpty) return 0;
    final v = double.tryParse(x);
    return (v == null || v < 0) ? null : v;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _soldAt,
      firstDate: DateTime(2015),
      lastDate: now.add(const Duration(days: 1)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.magenta, onPrimary: Colors.white, surface: Color(0xFF1A171F)),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _soldAt = d);
  }

  Future<bool> _confirm() async {
    if (!_formKey.currentState!.validate()) return false;
    setState(() => _saving = true);
    final o = _s;
    await widget.store.upsert(Sale(
      id: o.id,
      game: o.game,
      accountId: o.accountId,
      email: o.email,
      password: o.password,
      status: SaleStatus.sold,
      cost: o.cost,
      price: _num(_price.text) ?? 0,
      channel: _channel.text.trim(),
      buyer: _buyer.text.trim(),
      paid: _paid,
      soldAt: _soldAt,
      note: _note.text.trim(),
      createdAt: o.createdAt,
      demo: o.demo,
    ));
    if (!mounted) return true;
    final root = Navigator.of(context, rootNavigator: true).context;
    final profit = (_num(_price.text) ?? 0) - o.cost;
    final cur = widget.store.currency;
    Navigator.pop(context);
    successPopup(root, 'ບັນທຶກການຂາຍແລ້ວ', message: '${o.game} · ກຳໄລ ${money(profit, cur, signed: true)}');
    return true;
  }

  /// Undo a sale: back to "ພ້ອມຂາຍ", selling details cleared.
  Future<void> _undo() async {
    final o = _s;
    await widget.store.upsert(Sale(
      id: o.id,
      game: o.game,
      accountId: o.accountId,
      email: o.email,
      password: o.password,
      status: SaleStatus.stock,
      cost: o.cost,
      createdAt: o.createdAt,
      demo: o.demo,
    ));
    if (!mounted) return;
    final root = Navigator.of(context, rootNavigator: true).context;
    Navigator.pop(context);
    successPopup(root, 'ຍົກເລີກການຂາຍແລ້ວ', message: o.game);
  }

  InputDecoration _bare({String? hint}) => InputDecoration(
        isDense: true,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        contentPadding: const EdgeInsets.only(top: 4),
        hintText: hint,
        hintStyle: sans(size: 17, color: AppColors.faint),
      );

  Widget _glassBox({required Widget child, EdgeInsets padding = const EdgeInsets.fromLTRB(18, 10, 18, 12)}) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: child,
    );
  }

  Widget _field(String label, TextEditingController c, {bool optional = true, int maxLines = 1, String? hint}) {
    return _glassBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(TextSpan(children: [
            TextSpan(text: label, style: sans(size: 12, color: AppColors.muted)),
            if (optional) TextSpan(text: '   ບໍ່ບັງຄັບ', style: sans(size: 12, color: AppColors.faint)),
          ])),
          TextFormField(
            controller: c,
            maxLines: maxLines,
            minLines: maxLines,
            style: sans(size: 17),
            cursorColor: AppColors.butter,
            decoration: _bare(hint: hint),
          ),
        ],
      ),
    );
  }

  Widget _priceCard(String cur) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.line),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x1CFFFFFF), Color(0x0AFFFFFF)]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ລາຄາຂາຍ', style: sans(size: 15)),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFE27A), Color(0xFFE69A00)]),
                ),
                child: Text(currencySymbols[cur] ?? '', style: sans(size: 16, weight: FontWeight.w700, color: const Color(0xFF1C1204))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _price,
                  autofocus: !_s.isSold,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  validator: (t) => _num(t ?? '') == null ? 'ຕ້ອງເປັນຕົວເລກບໍ່ຕິດລົບ' : null,
                  textAlign: TextAlign.right,
                  cursorColor: AppColors.butter,
                  style: sans(size: 30, weight: FontWeight.w300),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    hintText: '0',
                    hintStyle: sans(size: 30, weight: FontWeight.w300, color: AppColors.faint),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cur = widget.store.currency;
    final profit = (_num(_price.text) ?? 0) - _s.cost;
    final r = roi(_s.cost, profit);
    final channels = widget.store.knownChannels.take(10).toList();
    const gap = SizedBox(height: 12);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        RoundButton(onTap: () => Navigator.pop(context), tooltip: 'ປິດ', child: const Icon(Icons.arrow_back_rounded, size: 22)),
                        Expanded(child: Text(_s.isSold ? 'ແກ້ໄຂການຂາຍ' : 'ຂາຍໄອດີ', textAlign: TextAlign.center, style: sans(size: 19, weight: FontWeight.w500))),
                        const SizedBox(width: 44),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // which account is being sold
                    _glassBox(
                      padding: const EdgeInsets.fromLTRB(12, 10, 18, 10),
                      child: Row(
                        children: [
                          Coin(_s.game, size: 48, logoUrl: widget.store.logoUrl(_s.game)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_s.game, style: sans(size: 17, weight: FontWeight.w500)),
                                if (_s.accountId.isNotEmpty) Text(_s.accountId, style: mono(size: 13, color: AppColors.muted)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('ຕົ້ນທຶນ', style: sans(size: 12, color: AppColors.muted)),
                              Text(money(_s.cost, cur), style: sans(size: 15, weight: FontWeight.w500)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    gap,
                    _priceCard(cur),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 16, 6, 4),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          Text('ກຳໄລ', style: sans(size: 14, color: AppColors.muted)),
                          const Icon(Icons.arrow_forward_rounded, size: 20, color: AppColors.muted),
                          Text(
                            money(profit, cur, signed: true),
                            style: sans(size: 20, weight: FontWeight.w500, color: profit < 0 ? AppColors.loss : (profit > 0 ? AppColors.butter : AppColors.text)),
                          ),
                          if (r != null) ButterChip(pctText(r), negative: profit < 0, small: true),
                        ],
                      ),
                    ),
                    gap,
                    InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: _pickDate,
                      child: _glassBox(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ວັນທີຂາຍ', style: sans(size: 12, color: AppColors.muted)),
                                  const SizedBox(height: 4),
                                  Text(fmtDate(_soldAt), style: sans(size: 17)),
                                ],
                              ),
                            ),
                            const Icon(Icons.event_rounded, color: AppColors.muted),
                          ],
                        ),
                      ),
                    ),
                    gap,
                    _glassBox(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(TextSpan(children: [
                            TextSpan(text: 'ຊ່ອງທາງຂາຍ', style: sans(size: 12, color: AppColors.muted)),
                            TextSpan(text: '   ບໍ່ບັງຄັບ', style: sans(size: 12, color: AppColors.faint)),
                          ])),
                          TextFormField(
                            controller: _channel,
                            style: sans(size: 17),
                            cursorColor: AppColors.butter,
                            decoration: _bare(),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final c in channels)
                                ActionChip(
                                  label: Text(c, style: sans(size: 13, color: c.toLowerCase() == _channel.text.trim().toLowerCase() ? Colors.white : AppColors.muted)),
                                  backgroundColor: c.toLowerCase() == _channel.text.trim().toLowerCase() ? AppColors.magenta : AppColors.glass,
                                  side: const BorderSide(color: AppColors.line),
                                  shape: const StadiumBorder(),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => setState(() => _channel.text = c),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    gap,
                    _field('ຜູ້ຊື້', _buyer),
                    gap,
                    _glassBox(
                      padding: const EdgeInsets.fromLTRB(18, 8, 12, 8),
                      child: Row(
                        children: [
                          Expanded(child: Text('ຮັບເງິນແລ້ວ', style: sans(size: 16))),
                          Switch(
                            value: _paid,
                            onChanged: (v) => setState(() => _paid = v),
                            thumbColor: const WidgetStatePropertyAll(Colors.white),
                            trackColor: WidgetStateProperty.resolveWith(
                              (s) => s.contains(WidgetState.selected) ? AppColors.magenta : const Color(0x29FFFFFF),
                            ),
                            trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
                          ),
                        ],
                      ),
                    ),
                    gap,
                    _field('ໝາຍເຫດ', _note, maxLines: 3, hint: 'ເລເວນ, ສກິນ, ເງື່ອນໄຂການຮັບປະກັນ…'),
                    if (_s.isSold)
                      Center(
                        child: TextButton(
                          onPressed: _undo,
                          child: Text('ຍົກເລີກການຂາຍ (ກັບໄປພ້ອມຂາຍ)', style: sans(color: AppColors.loss, weight: FontWeight.w500)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: SlideToSave(label: 'ເລື່ອນເພື່ອຢືນຢັນການຂາຍ', busy: _saving, onConfirm: _confirm),
            ),
          ),
        ],
      ),
    );
  }
}
