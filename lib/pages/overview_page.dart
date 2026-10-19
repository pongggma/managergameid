import 'package:flutter/material.dart';

import '../data/sale_store.dart';
import '../models/sale.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/profit_chart.dart';
import '../widgets/sale_item.dart';
import '../widgets/ui.dart';

/// Home page: profit hero number, quick actions, monthly chart, key figures, latest accounts.
class OverviewPage extends StatefulWidget {
  const OverviewPage({
    super.key,
    required this.store,
    required this.onAdd,
    required this.onOpenDetail,
    required this.onSeeAll,
    required this.onGo,
  });

  final SaleStore store;
  final VoidCallback onAdd;
  final void Function(Sale sale) onOpenDetail;
  final VoidCallback onSeeAll;
  final void Function(SaleFilter filter) onGo;

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  bool _thisMonth = false;
  ChartPeriod _chart = ChartPeriod.month;

  Widget _periodToggle() {
    Widget item(String label, bool value) {
      final on = _thisMonth == value;
      return GestureDetector(
        onTap: () => setState(() => _thisMonth = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: on ? AppColors.glass2 : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(label, style: sans(size: 13, weight: on ? FontWeight.w600 : FontWeight.w400, color: on ? AppColors.text : AppColors.muted)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [item('ທັງໝົດ', false), item('ເດືອນນີ້', true)]),
    );
  }

  Widget _chartToggle() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          for (final p in ChartPeriod.values)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _chart = p),
                child: Container(
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _chart == p ? AppColors.magenta : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(p.label, style: sans(size: 14, weight: _chart == p ? FontWeight.w600 : FontWeight.w400, color: _chart == p ? Colors.white : AppColors.muted)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _action(IconData icon, String label, String tip, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Column(
        children: [
          RoundButton(size: 56, filled: true, tooltip: tip, onTap: onTap, child: Icon(icon, size: 22)),
          const SizedBox(height: 6),
          Text(label, style: sans(size: 11, color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget _empty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Text('ຍັງບໍ່ມີລາຍການ', style: sans(size: 19, weight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(
            'ເລີ່ມບັນທຶກໄອດີເກມທຳອິດຂອງທ່ານ. ຕົ້ນທຶນ ແລະ ລາຄາຂາຍຈະຖືກຄິດເປັນກຳໄລໃຫ້ອັດຕະໂນມັດ.',
            textAlign: TextAlign.center,
            style: sans(color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.magenta,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 52),
              padding: const EdgeInsets.symmetric(horizontal: 28),
              shape: const StadiumBorder(),
            ),
            onPressed: widget.onAdd,
            child: Text('+ ເພີ່ມໄອດີທຳອິດ', style: sans(size: 16, weight: FontWeight.w600, color: Colors.white)),
          ),
          TextButton(
            onPressed: widget.store.addDemo,
            child: Text('ລອງໃສ່ຂໍ້ມູນຕົວຢ່າງ', style: sans(color: AppColors.muted)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final cur = store.currency;
    final sum = store.summary(thisMonth: _thisMonth);
    final r = roi(sum.cost, sum.profit);
    final recent = store.sorted().take(5).toList();
    final sym = currencySymbols[cur] ?? '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
      children: [
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ກຳໄລສຸດທິ ($sym)', style: sans(size: 17)),
            _periodToggle(),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: AmountText(sum.profit, cur, signed: true, size: 54, weight: FontWeight.w300, color: sum.profit < 0 ? AppColors.loss : AppColors.text),
              ),
            ),
            const SizedBox(width: 12),
            if (r != null) ButterChip(pctText(r), negative: r < 0),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Material(
                color: AppColors.glass2,
                shape: const StadiumBorder(side: BorderSide(color: AppColors.line)),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: widget.onAdd,
                  child: SizedBox(height: 56, child: Center(child: Text('ເພີ່ມ +', style: sans(size: 17, weight: FontWeight.w500)))),
                ),
              ),
            ),
            _action(Icons.north_east_rounded, 'ຂາຍແລ້ວ', 'ເບິ່ງລາຍການຂາຍແລ້ວ', () => widget.onGo(SaleFilter.sold)),
            _action(Icons.south_rounded, 'ສະຕັອກ', 'ເບິ່ງລາຍການພ້ອມຂາຍ', () => widget.onGo(SaleFilter.stock)),
            _action(Icons.account_balance_wallet_outlined, 'ຄ້າງຈ່າຍ', 'ເບິ່ງລາຍການຄ້າງຈ່າຍ', () => widget.onGo(SaleFilter.unpaid)),
          ],
        ),
        SectionTitle('ກຳໄລ', note: _chart.note),
        _chartToggle(),
        const SizedBox(height: 12),
        ProfitChart(key: ValueKey(_chart), bars: store.bars(_chart), currency: cur),
        const SizedBox(height: 22),
        DarkPanel(children: [
          KvRow('ລາຍຮັບ', value: money(sum.revenue, cur)),
          KvRow('ຕົ້ນທຶນທີ່ຂາຍແລ້ວ', value: money(sum.cost, cur)),
          KvRow('ໃນສະຕັອກ', value: '${sum.stockCount} ໄອດີ', sub: 'ຕົ້ນທຶນ ${money(sum.stockCost, cur)}'),
          KvRow('ຄ້າງຮັບເງິນ', value: money(sum.unpaidSum, cur), sub: '${sum.unpaidCount} ລາຍການ'),
          KvRow('ກຳໄລສະເລ່ຍຕໍ່ໄອດີ', value: money(sum.average, cur)),
        ]),
        SectionTitle('ລາຍການລ່າສຸດ', actionLabel: 'ເບິ່ງທັງໝົດ', onAction: widget.onSeeAll),
        if (recent.isEmpty)
          _empty()
        else
          for (final s in recent) ...[
            SaleItem(sale: s, currency: cur, logoUrl: store.logoUrl(s.game), logoLoading: store.logoLoading(s.game), onTap: () => widget.onOpenDetail(s), onDelete: () => store.remove(s.id)),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}
