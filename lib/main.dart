import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/sale_store.dart';
import 'models/sale.dart';
import 'pages/list_page.dart';
import 'pages/overview_page.dart';
import 'pages/settings_page.dart';
import 'theme/app_theme.dart';
import 'widgets/sale_detail_sheet.dart';
import 'widgets/sale_form_sheet.dart';
import 'widgets/ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  final store = SaleStore();
  await store.load();
  runApp(LedgerApp(store: store));
}

class LedgerApp extends StatelessWidget {
  const LedgerApp({super.key, required this.store});

  final SaleStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ບັນຊີໄອດີເກມ',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: buildTheme(),
      theme: buildTheme(),
      home: HomeShell(store: store),
    );
  }
}

/// Pages: 0 overview, 1 all accounts, 2 settings (opened from the menu icon in the header).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.store});

  final SaleStore store;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _page = 0;
  SaleFilter _filter = SaleFilter.all;

  void _openForm({Sale? sale, bool markSold = false}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SheetShell(child: SaleFormSheet(store: widget.store, sale: sale, markSold: markSold)),
    );
  }

  void _openDetail(Sale sale) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SheetShell(
        child: SaleDetailSheet(
          store: widget.store,
          saleId: sale.id,
          onEdit: (s, {bool markSold = false}) => _openForm(sale: s, markSold: markSold),
        ),
      ),
    );
  }

  void _goList(SaleFilter f) => setState(() {
        _filter = f;
        _page = 1;
      });

  Widget _header() {
    if (_page == 0) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFF5CF6), Color(0xFF7B21D6)]),
                boxShadow: const [BoxShadow(color: Color(0x47FF14F0), blurRadius: 22, offset: Offset(0, 8))],
              ),
              child: const Icon(Icons.sports_esports_outlined, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('User pingpong', style: sans(size: 17, weight: FontWeight.w500)),
                  Text('ບັນຊີເກມ', style: sans(size: 12, color: AppColors.muted)),
                ],
              ),
            ),
            RoundButton(onTap: () => setState(() => _page = 2), tooltip: 'ຕັ້ງຄ່າ', child: const DotsIcon()),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 4),
      child: Row(
        children: [
          RoundButton(onTap: () => setState(() => _page = 0), tooltip: 'ກັບຄືນ', child: const Icon(Icons.arrow_back_rounded, size: 22)),
          Expanded(
            child: Text(_page == 1 ? 'ໄອດີທັງໝົດ' : 'ຕັ້ງຄ່າ', textAlign: TextAlign.center, style: sans(size: 19, weight: FontWeight.w500)),
          ),
          _page == 2
              ? const SizedBox(width: 44)
              : RoundButton(onTap: () => setState(() => _page = 2), tooltip: 'ຕັ້ງຄ່າ', child: const DotsIcon()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackground()),
          ListenableBuilder(
            listenable: widget.store,
            builder: (context, _) {
              return SafeArea(
                bottom: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      children: [
                        _header(),
                        Expanded(
                          child: IndexedStack(
                            index: _page,
                            children: [
                              OverviewPage(
                                store: widget.store,
                                onAdd: () => _openForm(),
                                onOpenDetail: _openDetail,
                                onSeeAll: () => _goList(SaleFilter.all),
                                onGo: _goList,
                              ),
                              ListPage(
                                store: widget.store,
                                filter: _filter,
                                onFilterChanged: (f) => setState(() => _filter = f),
                                onOpenDetail: _openDetail,
                                onAdd: () => _openForm(),
                              ),
                              SettingsPage(store: widget.store),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _FloatingNav(
              page: _page,
              onSelect: (i) => setState(() => _page = i),
              onAdd: () => _openForm(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating rounded tab bar with a raised magenta add button in the middle.
class _FloatingNav extends StatelessWidget {
  const _FloatingNav({required this.page, required this.onSelect, required this.onAdd});

  final int page;
  final void Function(int index) onSelect;
  final VoidCallback onAdd;

  Widget _item(int index, IconData icon, String label) {
    final on = page == index;
    final color = on ? AppColors.text : AppColors.faint;
    return InkWell(
      borderRadius: BorderRadius.circular(36),
      onTap: () => onSelect(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 3),
          Text(label, style: sans(size: 11, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: SizedBox(
            height: 70,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.navBar,
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(color: AppColors.line),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Row(
                    children: [
                      Expanded(child: _item(0, Icons.grid_view_rounded, 'ພາບລວມ')),
                      const SizedBox(width: 92),
                      Expanded(child: _item(1, Icons.format_list_bulleted_rounded, 'ໄອດີທັງໝົດ')),
                    ],
                  ),
                ),
                Positioned(
                  top: -26,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Tooltip(
                      message: 'ເພີ່ມໄອດີ',
                      child: GestureDetector(
                        onTap: onAdd,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.magenta,
                            boxShadow: [
                              BoxShadow(color: AppColors.navBar, spreadRadius: 7),
                              BoxShadow(color: Color(0xA6FF14F0), blurRadius: 34),
                            ],
                          ),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
