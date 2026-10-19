import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/sale_store.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar.dart';
import '../widgets/ui.dart';

/// Currency, CSV copy, storage notes and demo data.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.store, required this.auth});

  final SaleStore store;
  final AuthService auth;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  SaleStore get store => widget.store;

  Widget _accountCard() {
    final a = widget.auth.account;
    final name = widget.auth.displayLabel;
    final hasName = widget.auth.profileName.isNotEmpty;
    final sub = a == null ? 'ຂໍ້ມູນເກັບໃນເຄື່ອງນີ້ເທົ່ານັ້ນ' : [if (a.email.isNotEmpty && hasName) a.email, if (a.providerLabel.isNotEmpty) 'ເຂົ້າດ້ວຍ ${a.providerLabel}'].join(' · ');
    return _section('ບັນຊີ', [
      Row(
        children: [
          GestureDetector(
            onTap: () => showProfileEditor(context, widget.auth),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Avatar(widget.auth.avatar, size: 60),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.magenta, border: Border.all(color: AppColors.page, width: 2)),
                    child: const Icon(Icons.edit_rounded, size: 13, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: sans(size: 17, weight: FontWeight.w500)),
                if (sub.isNotEmpty) Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: sans(size: 13, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: const StadiumBorder(),
          side: const BorderSide(color: AppColors.line),
          backgroundColor: AppColors.glass2,
        ),
        onPressed: () => showProfileEditor(context, widget.auth),
        child: Text('ແກ້ໄຂຊື່ ແລະ ຮູບ', style: sans(weight: FontWeight.w500)),
      ),
      const SizedBox(height: 10),
      OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: const StadiumBorder(),
          side: const BorderSide(color: AppColors.line),
          backgroundColor: AppColors.glass2,
        ),
        onPressed: widget.auth.signOut,
        child: Text(a == null ? 'ເຂົ້າສູ່ລະບົບ' : 'ອອກຈາກລະບົບ', style: sans(weight: FontWeight.w500, color: a == null ? AppColors.text : AppColors.loss)),
      ),
    ]);
  }
  bool _converting = false;

  Future<void> _switch(String code) async {
    if (code == store.currency || _converting) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1A171F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('ປ່ຽນເປັນ $code?', style: sans(size: 18, weight: FontWeight.w600)),
        content: Text('ຕົ້ນທຶນ ແລະ ລາຄາຂາຍທັງໝົດຈະຖືກແປງຕາມອັດຕາແລກປ່ຽນຂອງມື້ນີ້ (${store.currency} → $code).', style: sans(color: AppColors.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text('ຍົກເລີກ', style: sans(color: AppColors.muted))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.magenta),
            onPressed: () => Navigator.pop(c, true),
            child: Text('ປ່ຽນ', style: sans(weight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _converting = true);
    final err = await store.changeCurrency(code);
    if (!mounted) return;
    setState(() => _converting = false);
    showToast(context, err ?? 'ແປງເປັນ $code ແລ້ວ');
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: sans(size: 18, weight: FontWeight.w500)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _note(String text) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(text, style: sans(size: 14, color: AppColors.muted)),
      );

  Widget _currencyPill(String code, String label) {
    final on = store.currency == code;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => _switch(code),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? AppColors.magenta : AppColors.glass,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? AppColors.magenta : AppColors.line),
        ),
        child: Text(label, style: sans(weight: FontWeight.w500, color: on ? Colors.white : AppColors.muted)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
      children: [
        _accountCard(),
        _section('ສະກຸນເງິນ', [
          Wrap(spacing: 8, runSpacing: 8, children: [
            _currencyPill('LAK', '₭ ກີບ'),
            _currencyPill('THB', '฿ ບາດ'),
            _currencyPill('USD', r'$ ໂດລາ'),
          ]),
          if (_converting)
            const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator(color: AppColors.magenta, backgroundColor: AppColors.glass)),
          _note('ເມື່ອປ່ຽນ ຕົວເລກທັງໝົດຈະຖືກແປງຕາມອັດຕາແລກປ່ຽນຂອງມື້ນີ້ (ດຶງຈາກ open.er-api.com ຕ້ອງມີອິນເຕີເນັດ).'),
          if (store.rateNote.isNotEmpty) _note('ອັດຕາຄັ້ງຫຼ້າສຸດ: ${store.rateNote}'),
        ]),
        _section('ສຳຮອງຂໍ້ມູນ', [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
              shape: const StadiumBorder(),
              side: const BorderSide(color: AppColors.line),
              backgroundColor: AppColors.glass2,
            ),
            icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.text),
            label: Text('ຄັດລອກເປັນ CSV', style: sans(weight: FontWeight.w500)),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: store.exportCsv()));
              if (!context.mounted) return;
              showToast(context, 'ຄັດລອກ CSV ແລ້ວ ເອົາໄປວາງໃນ Google Sheets ຫຼື Excel ໄດ້');
            },
          ),
          _note('CSV ມີຂໍ້ມູນທຸກຢ່າງ ຍົກເວັ້ນລະຫັດຜ່ານ.'),
        ]),
        _section('ການເກັບຂໍ້ມູນ', [
          Text('ຂໍ້ມູນເກັບໄວ້ໃນໂທລະສັບເຄື່ອງນີ້ເທົ່ານັ້ນ. ຖ້າລຶບແອັບ ຂໍ້ມູນຈະຫາຍ.', style: sans(size: 14, color: AppColors.muted)),
          _note('ອີເມລ ແລະ ລະຫັດຜ່ານທີ່ບັນທຶກຍັງບໍ່ໄດ້ເຂົ້າລະຫັດ. ບັນທຶກສະເພາະບັນຊີທີ່ທ່ານຍອມຮັບຄວາມສ່ຽງໄດ້.'),
        ]),
        if (store.hasDemo)
          _section('ຂໍ້ມູນຕົວຢ່າງ', [
            Text('ລາຍການທີ່ມີປ້າຍ "ຕົວຢ່າງ" ຖືກໃສ່ໄວ້ເພື່ອທົດລອງ.', style: sans(size: 14, color: AppColors.muted)),
            const SizedBox(height: 12),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                shape: const StadiumBorder(),
                backgroundColor: AppColors.glass2,
                foregroundColor: AppColors.text,
              ),
              onPressed: store.clearDemo,
              child: Text('ລຶບຕົວຢ່າງທັງໝົດ', style: sans(weight: FontWeight.w500)),
            ),
          ]),
      ],
    );
  }
}
