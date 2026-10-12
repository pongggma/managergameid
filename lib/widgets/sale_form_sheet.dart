import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/sale_store.dart';
import '../models/sale.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'ui.dart';

/// Add / edit sheet. Only the game name is required;
/// ID, email, password and everything else can stay empty.
class SaleFormSheet extends StatefulWidget {
  const SaleFormSheet({super.key, required this.store, this.sale, this.markSold = false});

  final SaleStore store;
  final Sale? sale;
  final bool markSold;

  @override
  State<SaleFormSheet> createState() => _SaleFormSheetState();
}

class _SaleFormSheetState extends State<SaleFormSheet> {
  static const _channels = ['Facebook', 'TikTok', 'WhatsApp', 'Telegram', 'Discord', 'Line'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _game, _aid, _email, _pass, _cost, _price, _channel, _buyer, _note;
  late SaleStatus _status;
  DateTime? _soldAt;
  bool _paid = false;
  bool _hidePass = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.sale;
    _game = TextEditingController(text: s?.game ?? '');
    _aid = TextEditingController(text: s?.accountId ?? '');
    _email = TextEditingController(text: s?.email ?? '');
    _pass = TextEditingController(text: s?.password ?? '');
    _cost = TextEditingController(text: plainNumber(s?.cost ?? 0));
    _price = TextEditingController(text: plainNumber(s?.price ?? 0));
    _channel = TextEditingController(text: s?.channel ?? '');
    _buyer = TextEditingController(text: s?.buyer ?? '');
    _note = TextEditingController(text: s?.note ?? '');
    _status = s?.status ?? SaleStatus.stock;
    _soldAt = s?.soldAt;
    _paid = s?.paid ?? false;
    if (widget.markSold) {
      _status = SaleStatus.sold;
      _soldAt ??= DateTime.now();
    }
    _cost.addListener(_refresh);
    _price.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    for (final c in [_game, _aid, _email, _pass, _cost, _price, _channel, _buyer, _note]) {
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

  String? _numValidator(String? t) => _num(t ?? '') == null ? 'ຕ້ອງເປັນຕົວເລກບໍ່ຕິດລົບ' : null;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _soldAt ?? now,
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final old = widget.sale;
    final sale = Sale(
      id: old?.id ?? widget.store.newId(),
      game: _game.text.trim(),
      accountId: _aid.text.trim(),
      email: _email.text.trim(),
      password: _pass.text,
      status: _status,
      cost: _num(_cost.text) ?? 0,
      price: _num(_price.text) ?? 0,
      channel: _channel.text.trim(),
      buyer: _buyer.text.trim(),
      paid: _paid,
      soldAt: _status == SaleStatus.sold ? (_soldAt ?? DateTime.now()) : null,
      note: _note.text.trim(),
      createdAt: old?.createdAt ?? DateTime.now(),
    );
    await widget.store.upsert(sale);
    if (mounted) Navigator.pop(context);
  }

  // ---------- small building blocks ----------

  InputDecoration _bare({String? hint, Widget? suffix}) => InputDecoration(
        isDense: true,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        contentPadding: const EdgeInsets.only(top: 4),
        hintText: hint,
        hintStyle: sans(size: 17, color: AppColors.faint),
        suffixIcon: suffix,
        suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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

  Widget _field(
    String label,
    TextEditingController c, {
    bool optional = false,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboard,
    int maxLines = 1,
    String? Function(String?)? validator,
    String? hint,
  }) {
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
            obscureText: obscure,
            keyboardType: keyboard,
            maxLines: obscure ? 1 : maxLines,
            minLines: maxLines > 1 ? maxLines : 1,
            autocorrect: false,
            enableSuggestions: !obscure,
            validator: validator,
            style: sans(size: 17),
            cursorColor: AppColors.butter,
            decoration: _bare(hint: hint, suffix: suffix),
          ),
        ],
      ),
    );
  }

  Widget _currencyPill(String cur) {
    return Container(
      height: 52,
      padding: const EdgeInsets.fromLTRB(8, 0, 18, 0),
      decoration: BoxDecoration(
        color: const Color(0x66000000),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(width: 10),
          Text(cur, style: sans(weight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _moneyCard(String label, TextEditingController c, String cur) {
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
          Text(label, style: sans(size: 15)),
          const SizedBox(height: 10),
          Row(
            children: [
              _currencyPill(cur),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: c,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  validator: _numValidator,
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

  Widget _statusPills() {
    return Row(
      children: [
        for (final s in SaleStatus.values)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: s == SaleStatus.sold ? 0 : 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => setState(() {
                  _status = s;
                  if (s == SaleStatus.sold) _soldAt ??= DateTime.now();
                }),
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _status == s ? AppColors.magenta : AppColors.glass,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _status == s ? AppColors.magenta : AppColors.line),
                  ),
                  child: Text(s.label, style: sans(weight: FontWeight.w500, color: _status == s ? Colors.white : AppColors.muted)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cur = widget.store.currency;
    final cost = _num(_cost.text) ?? 0;
    final profit = (_num(_price.text) ?? 0) - cost;
    final r = roi(cost, profit);
    final isEdit = widget.sale != null;
    final title = isEdit ? (widget.markSold ? 'ໝາຍວ່າຂາຍແລ້ວ' : 'ແກ້ໄຂໄອດີ') : 'ເພີ່ມໄອດີ';
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
                        Expanded(child: Text(title, textAlign: TextAlign.center, style: sans(size: 19, weight: FontWeight.w500))),
                        const SizedBox(width: 44),
                      ],
                    ),
                    gap,
                    _field('ເກມ', _game, validator: (v) => (v == null || v.trim().isEmpty) ? 'ກະລຸນາໃສ່ຊື່ເກມ' : null),
                    gap,
                    _field('ໄອດີ / ຊື່ບັນຊີ', _aid, optional: true),
                    gap,
                    _field('ອີເມລ', _email, optional: true, keyboard: TextInputType.emailAddress),
                    gap,
                    _field(
                      'ລະຫັດຜ່ານ',
                      _pass,
                      optional: true,
                      obscure: _hidePass,
                      suffix: IconButton(
                        icon: Icon(_hidePass ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: AppColors.muted),
                        tooltip: _hidePass ? 'ສະແດງ' : 'ເຊື່ອງ',
                        onPressed: () => setState(() => _hidePass = !_hidePass),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Column(
                          children: [
                            _moneyCard('ຕົ້ນທຶນ', _cost, cur),
                            const SizedBox(height: 14),
                            _moneyCard('ລາຄາຂາຍ', _price, cur),
                          ],
                        ),
                        Positioned.fill(
                          child: Center(
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [BoxShadow(color: Color(0xEB0B0A0E), spreadRadius: 8)],
                              ),
                              child: const Icon(Icons.swap_vert_rounded, size: 28, color: Color(0xFF14101A)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 18, 6, 4),
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
                    const SizedBox(height: 14),
                    _glassBox(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ສະຖານະ', style: sans(size: 12, color: AppColors.muted)),
                          const SizedBox(height: 8),
                          _statusPills(),
                        ],
                      ),
                    ),
                    if (_status == SaleStatus.sold) ...[
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
                                    Text(fmtDate(_soldAt ?? DateTime.now()), style: sans(size: 17)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.event_rounded, color: AppColors.muted),
                            ],
                          ),
                        ),
                      ),
                    ],
                    gap,
                    _glassBox(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ຊ່ອງທາງຂາຍ', style: sans(size: 12, color: AppColors.muted)),
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
                              for (final c in _channels)
                                ActionChip(
                                  label: Text(c, style: sans(size: 13, color: AppColors.muted)),
                                  backgroundColor: AppColors.glass,
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
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xEB08070B),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.magenta,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 56),
                        padding: const EdgeInsets.symmetric(horizontal: 38),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: _saving ? null : _save,
                      child: Text('ບັນທຶກ', style: sans(size: 17, weight: FontWeight.w600, color: Colors.white)),
                    ),
                    const Spacer(),
                    Text('›››', style: sans(size: 26, color: AppColors.faint, letterSpacing: -2)),
                    const SizedBox(width: 22),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
