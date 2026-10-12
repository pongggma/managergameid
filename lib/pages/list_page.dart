import 'package:flutter/material.dart';

import '../data/sale_store.dart';
import '../models/sale.dart';
import '../theme/app_theme.dart';
import '../widgets/sale_item.dart';

/// All accounts: search pill, status chips, cards.
class ListPage extends StatefulWidget {
  const ListPage({
    super.key,
    required this.store,
    required this.filter,
    required this.onFilterChanged,
    required this.onOpenDetail,
    required this.onAdd,
  });

  final SaleStore store;
  final SaleFilter filter;
  final void Function(SaleFilter filter) onFilterChanged;
  final void Function(Sale sale) onOpenDetail;
  final VoidCallback onAdd;

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  String _query = '';

  Widget _chip(SaleFilter f) {
    final on = widget.filter == f;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => widget.onFilterChanged(f),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: on ? AppColors.magenta : AppColors.glass,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: on ? AppColors.magenta : AppColors.line),
          ),
          child: Text.rich(TextSpan(children: [
            TextSpan(text: f.label, style: sans(size: 14, weight: on ? FontWeight.w600 : FontWeight.w400, color: on ? Colors.white : AppColors.muted)),
            TextSpan(text: '  ${widget.store.count(f)}', style: sans(size: 12, color: on ? Colors.white70 : AppColors.faint)),
          ])),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final list = store.visible(widget.filter, _query);

    Widget body;
    if (store.sales.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ຍັງບໍ່ມີລາຍການ', style: sans(size: 19, weight: FontWeight.w500)),
              const SizedBox(height: 14),
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
            ],
          ),
        ),
      );
    } else if (list.isEmpty) {
      body = Center(child: Text('ບໍ່ພົບລາຍການທີ່ຕົງກັບການຄົ້ນຫາ', style: sans(color: AppColors.muted)));
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 140),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final s = list[i];
          return SaleItem(
            key: ValueKey(s.id),
            sale: s,
            currency: store.currency,
            onTap: () => widget.onOpenDetail(s),
          );
        },
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: AppColors.glass,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppColors.muted, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    style: sans(size: 16),
                    cursorColor: AppColors.butter,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'ຄົ້ນຫາເກມ, ໄອດີ, ຜູ້ຊື້…',
                      hintStyle: sans(size: 16, color: AppColors.faint),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 62,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            children: [for (final f in SaleFilter.values) _chip(f)],
          ),
        ),
        Expanded(child: body),
      ],
    );
  }
}
