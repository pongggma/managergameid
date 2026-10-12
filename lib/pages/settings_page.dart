import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/sale_store.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Currency, CSV copy, storage notes and demo data.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.store});

  final SaleStore store;

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
      onTap: () => store.setCurrency(code),
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
        _section('ສະກຸນເງິນ', [
          Wrap(spacing: 8, runSpacing: 8, children: [
            _currencyPill('LAK', '₭ ກີບ'),
            _currencyPill('THB', '฿ ບາດ'),
            _currencyPill('USD', r'$ ໂດລາ'),
          ]),
          _note('ປ່ຽນສະເພາະສັນຍາລັກທີ່ສະແດງ ບໍ່ໄດ້ແປງຕົວເລກ.'),
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
