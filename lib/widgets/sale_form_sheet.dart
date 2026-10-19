import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/sale_store.dart';
import '../models/sale.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'popup.dart';
import 'ui.dart';

/// Add / edit sheet for the account itself: game, ID, email, password, cost.
/// Only the game name is required. Selling details (price, buyer, paid, note)
/// live in the separate sell sheet that opens from the "ຂາຍ" button afterwards.
class SaleFormSheet extends StatefulWidget {
  const SaleFormSheet({super.key, required this.store, this.sale});

  final SaleStore store;
  final Sale? sale;

  @override
  State<SaleFormSheet> createState() => _SaleFormSheetState();
}

class _SaleFormSheetState extends State<SaleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _game, _aid, _email, _pass, _cost;
  late SaleStatus _status;
  bool _hidePass = true;
  bool _saving = false;
  String _logoName = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final s = widget.sale;
    _game = TextEditingController(text: s?.game ?? '');
    _aid = TextEditingController(text: s?.accountId ?? '');
    _email = TextEditingController(text: s?.email ?? '');
    _pass = TextEditingController(text: s?.password ?? '');
    _cost = TextEditingController(text: plainNumber(s?.cost ?? 0));
    _status = s?.status ?? SaleStatus.stock;
    _logoName = s?.game ?? '';
    _game.addListener(_onGameChanged);
    widget.store.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _onGameChanged() {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _logoName = _game.text.trim());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.store.removeListener(_refresh);
    for (final c in [_game, _aid, _email, _pass, _cost]) {
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

  Future<bool> _save() async {
    if (!_formKey.currentState!.validate()) return false;
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
      price: old?.price ?? 0,
      channel: old?.channel ?? '',
      buyer: old?.buyer ?? '',
      paid: old?.paid ?? false,
      soldAt: old?.soldAt,
      note: old?.note ?? '',
      createdAt: old?.createdAt ?? DateTime.now(),
      demo: old?.demo ?? false,
    );
    await widget.store.upsert(sale);
    if (!mounted) return true;
    final root = Navigator.of(context, rootNavigator: true).context;
    final wasEdit = old != null;
    Navigator.pop(context);
    successPopup(root, wasEdit ? 'ບັນທຶກການແກ້ໄຂແລ້ວ' : 'ເພີ່ມໄອດີແລ້ວ', message: sale.game);
    return true;
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
        for (final s in const [SaleStatus.stock, SaleStatus.reserved])
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: s == SaleStatus.reserved ? 0 : 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => setState(() => _status = s),
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

  Widget _gameField() {
    final typed = _game.text.trim();
    final logo = _logoName.isEmpty ? null : widget.store.logoUrl(_logoName);
    final known = widget.store.knownGames;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _glassBox(
          padding: const EdgeInsets.fromLTRB(12, 10, 18, 12),
          child: Row(
            children: [
              Coin(typed.isEmpty ? '?' : typed, size: 48, logoUrl: logo, loading: _logoName.isNotEmpty && widget.store.logoLoading(_logoName)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ເກມ', style: sans(size: 12, color: AppColors.muted)),
                    TextFormField(
                      controller: _game,
                      autocorrect: false,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'ກະລຸນາໃສ່ຊື່ເກມ' : null,
                      style: sans(size: 17),
                      cursorColor: AppColors.butter,
                      decoration: _bare(hint: 'ເຊັ່ນ Free Fire'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (known.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 0, 6),
            child: Text('ເລືອກເກມທີ່ເຄີຍໃຊ້', style: sans(size: 12, color: AppColors.muted)),
          ),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: known.length > 15 ? 15 : known.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final g = known[i];
                final on = g.toLowerCase() == typed.toLowerCase();
                return InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () {
                    _debounce?.cancel();
                    _game.text = g;
                    setState(() => _logoName = g);
                  },
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(5, 0, 14, 0),
                    decoration: BoxDecoration(
                      color: on ? AppColors.magenta : AppColors.glass,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: on ? AppColors.magenta : AppColors.line),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Coin(g, size: 32, logoUrl: widget.store.logoUrl(g)),
                        const SizedBox(width: 8),
                        Text(g, style: sans(size: 14, weight: FontWeight.w500, color: on ? Colors.white : AppColors.text)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cur = widget.store.currency;
    final isEdit = widget.sale != null;
    final isSold = widget.sale?.isSold ?? false;
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
                        Expanded(child: Text(isEdit ? 'ແກ້ໄຂໄອດີ' : 'ເພີ່ມໄອດີ', textAlign: TextAlign.center, style: sans(size: 19, weight: FontWeight.w500))),
                        const SizedBox(width: 44),
                      ],
                    ),
                    gap,
                    _gameField(),
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
                    _moneyCard('ຕົ້ນທຶນ', _cost, cur),
                    if (!isSold) ...[
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
                    ],
                    if (!isEdit)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 14, 8, 0),
                        child: Text('ຂໍ້ມູນການຂາຍ (ລາຄາ, ຜູ້ຊື້, ຮັບເງິນ, ໝາຍເຫດ) ໃສ່ຕອນກົດ "ຂາຍ" ຫຼັງຈາກບັນທຶກແລ້ວ.', style: sans(size: 13, color: AppColors.faint)),
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
              child: SlideToSave(label: 'ເລື່ອນເພື່ອບັນທຶກ', busy: _saving, onConfirm: _save),
            ),
          ),
        ],
      ),
    );
  }
}
