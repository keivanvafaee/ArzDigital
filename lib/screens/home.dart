import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../theme.dart';
import '../data.dart';
import '../state.dart';
import '../common.dart';
import '../charts.dart';
import 'coin_detail.dart';
import 'tools.dart';
import 'features.dart';
import 'pulse.dart';
import '../portfolio_card.dart';
import 'analysis.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _seg = 0;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    var list = s.coins.where((c) {
      final q = _q.trim().toLowerCase();
      if (q.isNotEmpty && !(c.symbol.toLowerCase().contains(q) || c.name.contains(q))) {
        return false;
      }
      if (_seg == 3) return s.favorites.contains(c.symbol);
      return true;
    }).toList();
    if (_seg == 1) list.sort((a, b) => b.change.compareTo(a.change));
    if (_seg == 2) list.sort((a, b) => a.change.compareTo(b.change));
    final trending = [...s.coins]..sort((a, b) => b.change.compareTo(a.change));

    return SafeArea(
      bottom: false,
      child: ListView(
        key: const PageStorageKey('home'),
        padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 120),
        children: [
          Appear(child: _header(context, s)),
          const SizedBox(height: 16),
          Appear(delay: 80, child: _hero(context, s)),
          const SizedBox(height: 16),
          Appear(delay: 160, child: _quick(context)),
          const SizedBox(height: 14),
          Appear(delay: 220, child: _Ticker(coins: s.coins)),
          const SectionTitle('احساس بازار'),
          Appear(delay: 100, child: _sentiment(s)),
          SectionTitle('داغ‌ترین‌ها 🔥', trailing: Pill('۲۴ ساعت', C.gold)),
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 6,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _trendCard(context, trending[i]),
            ),
          ),
          const SectionTitle('نقشه حرارتی بازار'),
          _heatmap(context, s),
          SectionTitle('قیمت زنده بازار', trailing: Row(children: [
            PulseDot(),
            SizedBox(width: 6),
            Text('LIVE', style: TextStyle(color: C.red, fontWeight: FontWeight.w900, fontSize: 12)),
          ])),
          TextField(
            onChanged: (v) => setState(() => _q = v),
            decoration: InputDecoration(
              hintText: 'جستجوی ارز دیجیتال...',
              prefixIcon: Icon(Icons.search_rounded, color: C.sub),
            ),
          ),
          const SizedBox(height: 12),
          Seg(
              items: const ['همه', 'صعودی‌ها', 'نزولی‌ها', '⭐ نشان‌شده'],
              index: _seg,
              onChanged: (i) => setState(() => _seg = i)),
          const SizedBox(height: 12),
          if (list.isEmpty)
            Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: Text('موردی پیدا نشد', style: TextStyle(color: C.sub))),
            ),
          for (final c in list)
            Padding(padding: const EdgeInsets.only(bottom: 10), child: _row(context, s, c)),
          SectionTitle('آخرین اخبار', trailing: _more(context, const NewsScreen())),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _newsCard(context, s, kNews[i]),
            ),
          ),
          SectionTitle('تحلیلگران برتر', trailing: _more(context, const MoreScreen())),
          SizedBox(
            height: 164,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: s.analysts.where((a) => a.verified).length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _analystCard(context, s.analysts.where((a) => a.verified).toList()[i]),
            ),
          ),
          const SectionTitle('یاد بگیر و کسب سود کن'),
          Row(children: [
            Expanded(child: _promo(context, Icons.school_rounded, 'آکادمی نوا', 'درس بخوان، امتیاز بگیر', const AcademyScreen())),
            const SizedBox(width: 12),
            Expanded(child: _promo(context, Icons.card_giftcard_rounded, 'دعوت دوستان', '۱۵ USDT جایزه', const ReferralScreen())),
          ]),
          const SizedBox(height: 16),
          const ContactMiniCard(),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, AppState s) {
    return Row(children: [
      Pressable(
        onTap: () => go(context, const ProfileScreen()),
        child: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: C.grad,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.o(.3), width: 2),
            boxShadow: [BoxShadow(color: C.primary.o(.5), blurRadius: 14)],
          ),
          child: Text(s.userName[0],
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: Colors.black)),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('سلام، ${s.userName} 👋',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          Text('بازار امروز در فاز طمع است',
              style: TextStyle(color: C.sub, fontSize: 12)),
        ]),
      ),
      const ThemeToggle(),
      Pressable(
        onTap: () => go(context, const MoreScreen()),
        child: Container(
          width: 44,
          height: 44,
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: C.ov.o(.07),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: C.primary.o(.4)),
          ),
          child: Icon(Icons.apps_rounded, color: C.primary),
        ),
      ),
      Pressable(
        onTap: () => go(context, const AlertsScreen()),
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: C.ov.o(.07),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: C.ov.o(.08)),
            ),
            child: const Icon(Icons.notifications_rounded),
          ),
          if (s.activeAlerts > 0)
            Positioned(
              top: -4,
              left: -4,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: C.red, shape: BoxShape.circle),
                child: Text('${s.activeAlerts}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            ),
        ]),
      ),
    ]);
  }

  Widget _hero(BuildContext context, AppState s) {
    return PortfolioCard(
      s: s,
      actions: [
        (Icons.add_chart_rounded, 'خرید', () => go(context, const CoinDetailScreen(symbol: 'BTC'))),
        (Icons.swap_horiz_rounded, 'تبدیل', () => go(context, const SwapScreen())),
        (Icons.savings_rounded, 'استیک', () => go(context, const StakingScreen())),
        (Icons.bolt_rounded, 'سیگنال', () => go(context, const SignalsScreen())),
      ],
    );
  }

  Widget _quick(BuildContext context) {
    final items = <(IconData, String, Gradient, Widget)>[
      (Icons.auto_awesome_rounded, 'نبض بازار', C.gradGold, const MoodOrbScreen()),
      (Icons.swap_horiz_rounded, 'تبدیل', C.grad, const SwapScreen()),
      (Icons.bolt_rounded, 'سیگنال', C.gradGold, const SignalsScreen()),
      (Icons.newspaper_rounded, 'اخبار', C.grad, const NewsScreen()),
      (Icons.savings_rounded, 'استیکینگ', C.gradGreen, const StakingScreen()),
      (Icons.autorenew_rounded, 'DCA', C.gradGold, const DcaScreen()),
      (Icons.leaderboard_rounded, 'کپی ترید', C.grad, const LeaderboardScreen()),
      (Icons.notifications_active_rounded, 'هشدار', C.gradGold, const AlertsScreen()),
      (Icons.casino_rounded, 'گردونه', C.gradRed, const RewardScreen()),
      (Icons.smart_toy_rounded, 'دستیار AI', C.gradGreen, const AiScreen()),
      (Icons.school_rounded, 'آکادمی', C.grad, const AcademyScreen()),
      (Icons.calculate_rounded, 'ماشین‌حساب', C.gradGold, const CalcScreen()),
      (Icons.card_giftcard_rounded, 'دعوت', C.gradGreen, const ReferralScreen()),
    ];
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => Pressable(
          onTap: () => go(context, items[i].$4),
          child: SizedBox(
            width: 74,
            child: Column(children: [
              IconBox(items[i].$1, gradient: items[i].$3, size: 56),
              const SizedBox(height: 8),
              Text(items[i].$2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _sentiment(AppState s) {
    final btc = s.coin('BTC');
    return Row(children: [
      Expanded(
        flex: 5,
        child: GlassCard(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          child: Column(children: [
            Text('شاخص ترس و طمع', style: TextStyle(color: C.sub, fontSize: 12)),
            const SizedBox(height: 6),
            const SizedBox(height: 86, width: double.infinity, child: Gauge(value: 72)),
            Text('72 · طمع',
                style: TextStyle(color: C.green, fontWeight: FontWeight.w900, fontSize: 16)),
          ]),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        flex: 4,
        child: GlassCard(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('تسلط بیت‌کوین', style: TextStyle(color: C.sub, fontSize: 12)),
            const SizedBox(height: 4),
            const Text('54.2%', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text('حجم کل بازار', style: TextStyle(color: C.sub, fontSize: 12)),
            Text('\$${fmtCompact(s.coins.fold<double>(0, (a, c) => a + c.volume))}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Row(children: [
              Text('BTC ', style: TextStyle(color: C.sub, fontSize: 11)),
              Text(fmtPct(btc.change),
                  style: TextStyle(
                      color: btc.change >= 0 ? C.green : C.red,
                      fontWeight: FontWeight.w800,
                      fontSize: 12)),
            ]),
          ]),
        ),
      ),
    ]);
  }

  Widget _trendCard(BuildContext context, Coin c) {
    final col = c.change >= 0 ? C.green : C.red;
    return SizedBox(
      width: 168,
      child: GlassCard(
        glow: col,
        padding: const EdgeInsets.all(14),
        onTap: () => go(context, CoinDetailScreen(symbol: c.symbol)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CoinAvatar(c, size: 34),
            const SizedBox(width: 8),
            Text(c.symbol, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            const Spacer(),
            Icon(Icons.local_fire_department_rounded, color: C.gold, size: 20),
          ]),
          const SizedBox(height: 8),
          FlashText(
              value: c.price,
              text: fmtUsd(c.price),
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: C.text)),
          const SizedBox(height: 4),
          ChangeChip(c.change),
          const SizedBox(height: 6),
          Expanded(child: Sparkline(data: c.spark, color: col)),
        ]),
      ),
    );
  }

  Widget _heatmap(BuildContext context, AppState s) {
    return LayoutBuilder(builder: (ctx, cons) {
      final w = (cons.maxWidth - 18) / 4;
      return Wrap(spacing: 6, runSpacing: 6, children: [
        for (final c in s.coins)
          Pressable(
            onTap: () => go(context, CoinDetailScreen(symbol: c.symbol)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: w,
              height: w * 0.82,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    (c.change >= 0 ? C.green : C.red).o(.25 + cl(c.change.abs() / 8, 0, .6)),
                    (c.change >= 0 ? C.green : C.red).o(.10 + cl(c.change.abs() / 16, 0, .3)),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: C.ov.o(.08)),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(c.symbol, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                const SizedBox(height: 2),
                Text(fmtPct(c.change),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
              ]),
            ),
          ),
      ]);
    });
  }

  Widget _more(BuildContext context, Widget to) => Pressable(
        onTap: () => go(context, to),
        child: Text('مشاهده همه', style: TextStyle(color: C.primary, fontWeight: FontWeight.w800, fontSize: 12.5)),
      );

  Widget _newsCard(BuildContext context, AppState s, NewsItem n) {
    final c = s.coin(n.sym);
    return SizedBox(
      width: 250,
      child: GlassCard(
        radius: 22,
        onTap: () => go(context, const NewsScreen()),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CoinAvatar(c, size: 28),
            const SizedBox(width: 8),
            Pill(n.bull ? 'مثبت' : 'منفی', n.bull ? C.green : C.red),
            const Spacer(),
            Text(n.ago, style: TextStyle(color: C.sub, fontSize: 10.5)),
          ]),
          const SizedBox(height: 10),
          Expanded(
            child: Text(n.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, height: 1.6)),
          ),
          Text(n.source, style: TextStyle(color: C.sub, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _analystCard(BuildContext context, Analyst a) {
    return SizedBox(
      width: 132,
      child: GlassCard(
        radius: 22,
        glow: a.c1,
        padding: const EdgeInsets.all(12),
        onTap: () => go(context, AnalystProfileScreen(id: a.id)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnalystAvatar(a, size: 54),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Flexible(
                child: Text(a.name.split(' ').first,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13))),
            const SizedBox(width: 3),
            const VerifiedBadge(size: 15),
          ]),
          const SizedBox(height: 4),
          RatingBadge(a.rating),
          const SizedBox(height: 4),
          Text('موفقیت ${a.winRate}%', style: TextStyle(color: C.green, fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  Widget _promo(BuildContext context, IconData i, String t, String sub, Widget to) {
    return GlassCard(
      radius: 22,
      glow: C.primary,
      onTap: () => go(context, to),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        IconBox(i, size: 42),
        const SizedBox(height: 10),
        Text(t, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5)),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(color: C.sub, fontSize: 11.5)),
      ]),
    );
  }

  Widget _row(BuildContext context, AppState s, Coin c) {
    final col = c.change >= 0 ? C.green : C.red;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      radius: 20,
      blur: 8,
      onTap: () => go(context, CoinDetailScreen(symbol: c.symbol)),
      child: Row(children: [
        CoinAvatar(c, size: 42),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.symbol, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            Text(c.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: C.sub, fontSize: 11.5)),
          ]),
        ),
        SizedBox(width: 62, height: 30, child: Sparkline(data: c.spark, color: col, stroke: 1.8)),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            FlashText(
                value: c.price,
                text: fmtUsd(c.price),
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: C.text)),
            const SizedBox(height: 3),
            ChangeChip(c.change),
          ]),
        ),
        GestureDetector(
          onTap: () => s.toggleFav(c.symbol),
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(
              s.favorites.contains(c.symbol) ? Icons.star_rounded : Icons.star_border_rounded,
              color: s.favorites.contains(c.symbol) ? C.gold : C.sub,
            ),
          ),
        ),
      ]),
    );
  }
}

/// Auto-scrolling price ticker.
class _Ticker extends StatefulWidget {
  final List<Coin> coins;
  const _Ticker({required this.coins});
  @override
  State<_Ticker> createState() => _TickerState();
}

class _TickerState extends State<_Ticker> with SingleTickerProviderStateMixin {
  final ScrollController _sc = ScrollController();
  late final Ticker _tk;
  Duration _last = Duration.zero;
  @override
  void initState() {
    super.initState();
    // frame-synced (vsync) instead of a 30ms Timer; speed is time-based so it is smooth at any fps
    _tk = createTicker((el) {
      final dt = (el - _last).inMicroseconds / 1e6;
      _last = el;
      if (!_sc.hasClients) return;
      final max = _sc.position.maxScrollExtent;
      if (max <= 0) return;
      var o = _sc.offset + 28 * dt;
      if (o >= max / 2) o -= max / 2;
      _sc.jumpTo(o);
    })..start();
  }

  @override
  void dispose() {
    _tk.dispose();
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = [...widget.coins, ...widget.coins];
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: C.ov.o(.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.ov.o(.07)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: RepaintBoundary(child: ListView.builder(
          controller: _sc,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final c = items[i];
            final col = c.change >= 0 ? C.green : C.red;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: [
                Text(c.symbol, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                const SizedBox(width: 6),
                Text(fmtPrice(c.price), style: TextStyle(fontSize: 12, color: C.sub)),
                const SizedBox(width: 4),
                Icon(c.change >= 0 ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                    color: col),
                Text(c.change.abs().toStringAsFixed(2),
                    style: TextStyle(color: col, fontSize: 11.5, fontWeight: FontWeight.w800)),
              ]),
            );
          },
        )),
      ),
    );
  }
}
