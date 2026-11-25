import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../state.dart';
import '../common.dart';
import 'home.dart';
import 'analysis.dart';
import 'charts_page.dart';
import 'wallet.dart';
import 'community.dart';

/// Turns a raw event string (starts with an emoji) into a title / icon / colour / body for the banner.
(String, IconData, Color, String) _eventStyle(String m) {
  final body = m.replaceFirst(RegExp(r'^[^\u0600-\u06FFA-Za-z0-9]+'), '').trim();
  if (m.startsWith('🔔')) {
    return ('هشدار قیمت', Icons.notifications_active_rounded, C.gold, body.replaceFirst('هشدار: ', ''));
  }
  if (m.startsWith('🔁')) {
    return ('خرید خودکار DCA', Icons.autorenew_rounded, C.primary, '${body.replaceFirst('خرید خودکار DCA: ', '')} خریداری شد');
  }
  if (m.startsWith('✅')) {
    return ('تحلیل شما آماده است', Icons.task_alt_rounded, C.green, body);
  }
  return ('اعلان', Icons.notifications_active_rounded, C.gold, body);
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _i = 0;
  StreamSubscription<String>? _sub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sub ??= AppScope.read(context).events.listen((m) {
      if (!mounted) return;
      final e = _eventStyle(m);
      toast(context, e.$4, title: e.$1, icon: e.$2, color: e.$3);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  static const _items = [
    (Icons.candlestick_chart_rounded, 'بازار'),
    (Icons.psychology_alt_rounded, 'تحلیل'),
    (Icons.show_chart_rounded, 'نمودار'),
    (Icons.account_balance_wallet_rounded, 'کیف پول'),
    (Icons.forum_rounded, 'جامعه'),
  ];

  Widget _page(int i) {
    switch (i) {
      case 0:
        return const HomePage();
      case 1:
        return const AnalysisPage();
      case 2:
        return const ChartsPage();
      case 3:
        return const WalletPage();
      default:
        return const CommunityPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Aurora(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(a),
              child: child,
            ),
          ),
          child: KeyedSubtree(key: ValueKey<int>(_i), child: _page(_i)),
        ),
        bottomNavigationBar: _nav(),
      ),
    );
  }

  Widget _nav() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: GlassCard(
          radius: 34,
          blur: 24,
          padding: const EdgeInsets.all(6),
          glow: C.primary,
          gradient: LinearGradient(colors: [
            C.navA,
            C.navB,
          ]),
          child: LayoutBuilder(builder: (ctx, cons) {
            final total = cons.maxWidth;
            final selW = total * 0.36;
            final other = (total - selW) / (_items.length - 1);
            return Row(children: [
              for (int k = 0; k < _items.length; k++)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _i = k),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: k == _i ? selW : other,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: _i == k ? C.grad : null,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: _i == k ? [BoxShadow(color: C.primary.o(.5), blurRadius: 18)] : null,
                    ),
                    child: ClipRect(
                      child: Center(
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(_items[k].$1, size: 24, color: _i == k ? Colors.black : C.sub),
                          if (_i == k) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(_items[k].$2,
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                  softWrap: false,
                                  style: const TextStyle(
                                      fontSize: 12.5, fontWeight: FontWeight.w900, color: Colors.black)),
                            ),
                          ],
                        ]),
                      ),
                    ),
                  ),
                ),
            ]);
          }),
        ),
      ),
    );
  }
}
