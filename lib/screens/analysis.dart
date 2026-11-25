import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../data.dart';
import '../state.dart';
import '../common.dart';
import '../charts.dart';
import 'tools.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});
  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  int _tab = 0;
  String? _coin;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return SafeArea(
      bottom: false,
      child: ListView(
        key: PageStorageKey('analysis$_tab'),
        padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 120),
        children: [
          Appear(
            child: Row(children: [
              Text('مرکز تحلیل', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              SizedBox(width: 8),
              Icon(Icons.auto_awesome_rounded, color: C.gold),
            ]),
          ),
          const SizedBox(height: 4),
          Text('تحلیل‌های معتبر از تحلیلگران تاییدشده',
              style: TextStyle(color: C.sub, fontSize: 13)),
          const SizedBox(height: 16),
          Seg(
              items: const ['پرطرفدار', 'رایگان', 'سفارش', 'تحلیلگران'],
              index: _tab,
              onChanged: (i) => setState(() => _tab = i)),
          const SizedBox(height: 16),
          ..._body(context, s),
        ],
      ),
    );
  }

  List<Widget> _body(BuildContext context, AppState s) {
    switch (_tab) {
      case 0:
        final likes = <String, int>{};
        for (final a in s.analyses) {
          likes[a.symbol] = (likes[a.symbol] ?? 0) + a.likes;
        }
        final top = likes.keys.toList()..sort((a, b) => likes[b]!.compareTo(likes[a]!));
        final list = s.analyses.where((a) => _coin == null || a.symbol == _coin).toList()
          ..sort((a, b) => b.likes.compareTo(a.likes));
        return [
          const Text('کوین‌های پرطرفدار',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 10),
          SizedBox(
            height: 86,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: top.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                if (i == 0) {
                  final sel = _coin == null;
                  return Pressable(
                    onTap: () => setState(() => _coin = null),
                    child: Container(
                      width: 70,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: sel ? C.grad : null,
                        color: sel ? null : C.ov.o(.06),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('همه',
                          style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  );
                }
                final sym = top[i - 1];
                final c = s.coin(sym);
                final sel = _coin == sym;
                return Pressable(
                  onTap: () => setState(() => _coin = sel ? null : sym),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 82,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: sel ? c.color.o(.22) : C.ov.o(.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? c.color : C.ov.o(.08)),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      CoinAvatar(c, size: 30),
                      const SizedBox(height: 4),
                      Text(c.symbol,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5)),
                      Text('🔥 ${fmtCompact(likes[sym]!.toDouble())}',
                          style: TextStyle(color: C.gold, fontSize: 10.5)),
                    ]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < list.length; i++)
            Appear(
              delay: 40 * i,
              child: Padding(padding: const EdgeInsets.only(bottom: 12), child: AnalysisCard(list[i])),
            ),
        ];
      case 1:
        final free = s.analyses.where((a) => a.free).toList();
        return [
          GlassCard(
            gradient: LinearGradient(colors: [C.green.o(.25), C.cyan.o(.12)]),
            child: Row(children: [
              Icon(Icons.card_giftcard_rounded, color: C.green, size: 30),
              SizedBox(width: 12),
              Expanded(
                child: Text('تحلیل‌های رایگان برای همه کاربران در دسترس است. برای تحلیل‌های اختصاصی‌تر، از بخش سفارش استفاده کنید.',
                    style: TextStyle(height: 1.7, fontSize: 12.5)),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < free.length; i++)
            Appear(
              delay: 40 * i,
              child: Padding(padding: const EdgeInsets.only(bottom: 12), child: AnalysisCard(free[i])),
            ),
        ];
      case 2:
        return [const OrderTab()];
      default:
        return [
          for (int i = 0; i < s.analysts.length; i++)
            Appear(
              delay: 50 * i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AnalystCard(s.analysts[i]),
              ),
            ),
        ];
    }
  }
}

// ───────── Analysis card ─────────
class AnalysisCard extends StatelessWidget {
  final Analysis a;
  const AnalysisCard(this.a, {super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.coin(a.symbol);
    final an = s.analyst(a.analystId);
    final locked = !a.free && !s.unlocked.contains(a.id);
    final col = a.long ? C.green : C.red;
    return GlassCard(
      radius: 24,
      glow: col,
      onTap: () => go(context, AnalysisDetailScreen(id: a.id)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CoinAvatar(c, size: 34),
          const SizedBox(width: 8),
          Text(c.symbol, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(width: 8),
          Pill(a.long ? 'لانگ' : 'شورت', col,
              icon: a.long ? Icons.trending_up_rounded : Icons.trending_down_rounded),
          const Spacer(),
          if (a.free)
            Pill('رایگان', C.cyan, icon: Icons.lock_open_rounded)
          else if (locked)
            Pill('\$${a.price.toStringAsFixed(0)}', C.gold, icon: Icons.lock_rounded)
          else
            Pill('باز شده', C.green, icon: Icons.check_rounded),
        ]),
        const SizedBox(height: 12),
        Text(a.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, height: 1.5)),
        const SizedBox(height: 6),
        Text(a.summary, style: TextStyle(color: C.sub, fontSize: 12.5, height: 1.7)),
        const SizedBox(height: 12),
        Row(children: [
          AnalystAvatar(an, size: 30),
          const SizedBox(width: 8),
          Flexible(
              child: Text(an.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5))),
          if (an.verified) ...[const SizedBox(width: 3), const VerifiedBadge(size: 15)],
          const SizedBox(width: 8),
          RatingBadge(an.rating),
          const Spacer(),
          Icon(Icons.favorite_rounded, size: 15, color: C.pink),
          const SizedBox(width: 3),
          Text('${a.likes}', style: TextStyle(color: C.sub, fontSize: 12)),
          const SizedBox(width: 10),
          Text(a.ago, style: TextStyle(color: C.sub, fontSize: 11)),
        ]),
      ]),
    );
  }
}

// ───────── Analysis detail ─────────
class AnalysisDetailScreen extends StatelessWidget {
  final String id;
  const AnalysisDetailScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final a = s.analyses.firstWhere((x) => x.id == id);
    final c = s.coin(a.symbol);
    final an = s.analyst(a.analystId);
    final locked = !a.free && !s.unlocked.contains(a.id);
    final col = a.long ? C.green : C.red;
    final entry = c.basePrice * a.e, target = c.basePrice * a.t, stop = c.basePrice * a.s;
    final rr = (target - entry).abs() / ((entry - stop).abs() == 0 ? 1 : (entry - stop).abs());

    final content = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GlassCard(
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
        child: PriceChart(
          coin: c,
          tf: a.tf,
          candles: true,
          height: 240,
          levels: [entry, target, stop],
          levelColors: [C.cyan, C.green, C.red],
        ),
      ),
      const SizedBox(height: 12),
      Row(children: [
        _lvl('ورود', fmtUsd(entry), C.cyan),
        const SizedBox(width: 8),
        _lvl('هدف', fmtUsd(target), C.green),
        const SizedBox(width: 8),
        _lvl('حد ضرر', fmtUsd(stop), C.red),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            radius: 18,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('نسبت ریسک به ریوارد', style: TextStyle(color: C.sub, fontSize: 11.5)),
              const SizedBox(height: 4),
              Text('1 : ${rr.toStringAsFixed(1)}',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: C.gold)),
            ]),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            radius: 18,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('اطمینان تحلیلگر · ${a.conf}%',
                  style: TextStyle(color: C.sub, fontSize: 11.5)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: a.conf / 100),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => LinearProgressIndicator(
                      value: v, minHeight: 9, color: col, backgroundColor: C.ov.o(.1)),
                ),
              ),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 14),
      GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('متن تحلیل', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 8),
          Text(a.body, style: TextStyle(height: 1.9, fontSize: 13.5, color: C.text2)),
        ]),
      ),
    ]);

    return AppScaffold(
      title: 'جزئیات تحلیل',
      actions: [
        IconButton(
          icon: Icon(s.likedAnalyses.contains(a.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: C.pink),
          onPressed: () => s.likeAnalysis(a),
        ),
        IconButton(
          icon: const Icon(Icons.share_rounded),
          onPressed: () => toast(context, 'لینک تحلیل کپی شد', icon: Icons.link_rounded, bottom: 20),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
        children: [
          Row(children: [
            CoinAvatar(c, size: 38),
            const SizedBox(width: 10),
            Pill(a.long ? 'لانگ' : 'شورت', col),
            const SizedBox(width: 6),
            Pill(a.tf, C.primary),
            const Spacer(),
            Text(a.ago, style: TextStyle(color: C.sub, fontSize: 12)),
          ]),
          const SizedBox(height: 12),
          Text(a.title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, height: 1.5)),
          const SizedBox(height: 6),
          Text(a.summary, style: TextStyle(color: C.sub, height: 1.7)),
          const SizedBox(height: 14),
          GlassCard(
            radius: 20,
            padding: const EdgeInsets.all(12),
            onTap: () => go(context, AnalystProfileScreen(id: an.id)),
            child: Row(children: [
              AnalystAvatar(an, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(
                        child: Text(an.name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5))),
                    if (an.verified) ...[const SizedBox(width: 4), const VerifiedBadge()],
                  ]),
                  const SizedBox(height: 2),
                  Row(children: [
                    RatingBadge(an.rating, reviews: an.reviews),
                    const SizedBox(width: 10),
                    Text('موفقیت ${an.winRate}%',
                        style: TextStyle(color: C.green, fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ]),
                ]),
              ),
              Icon(Icons.chevron_left_rounded, color: C.sub),
            ]),
          ),
          const SizedBox(height: 14),
          if (locked)
            Stack(children: [
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
                child: IgnorePointer(child: content),
              ),
              Positioned.fill(
                child: Center(
                  child: GlassCard(
                    radius: 26,
                    glow: C.gold,
                    padding: const EdgeInsets.all(22),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.lock_rounded, color: C.gold, size: 38),
                      const SizedBox(height: 8),
                      const Text('این تحلیل پولی است',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('موجودی شما: ${fmtUsd(s.usdt)}',
                          style: TextStyle(color: C.sub, fontSize: 12)),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: 220,
                        child: GradientButton(
                          label: 'باز کردن با \$${a.price.toStringAsFixed(0)}',
                          gradient: C.gradGold,
                          icon: Icons.lock_open_rounded,
                          onTap: () {
                            if (s.unlock(a)) {
                              toast(context, 'تحلیل با موفقیت باز شد 🎉', bottom: 20);
                            } else {
                              toast(context, 'موجودی کافی نیست', color: C.red, icon: Icons.error_rounded, bottom: 20);
                            }
                          },
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ])
          else
            content,
        ],
      ),
    );
  }

  Widget _lvl(String t, String v, Color c) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: c.o(.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.o(.4)),
        ),
        child: Column(children: [
          Text(t, style: TextStyle(color: c, fontSize: 11.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
        ]),
      ),
    );
  }
}

// ───────── Analysts ─────────
class AnalystCard extends StatelessWidget {
  final Analyst a;
  const AnalystCard(this.a, {super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final f = s.following.contains(a.id);
    return GlassCard(
      radius: 24,
      glow: a.verified ? a.c1 : null,
      onTap: () => go(context, AnalystProfileScreen(id: a.id)),
      child: Column(children: [
        Row(children: [
          AnalystAvatar(a, size: 58),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                    child: Text(a.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
                const SizedBox(width: 5),
                if (a.verified) const VerifiedBadge(size: 20),
              ]),
              Text(a.handle, style: TextStyle(color: C.sub, fontSize: 12)),
              const SizedBox(height: 4),
              RatingBadge(a.rating, reviews: a.reviews),
            ]),
          ),
          Pressable(
            onTap: () => s.toggleFollow(a.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: f ? null : C.grad,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: f ? Colors.white.o(.25) : Colors.transparent),
              ),
              child: Text(f ? 'دنبال شده' : 'دنبال کن',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 6, runSpacing: 6, children: [for (final t in a.tags) Pill(t, a.c2)]),
        const SizedBox(height: 12),
        Row(children: [
          _mini('موفقیت', '${a.winRate}%', C.green),
          _mini('دنبال‌کننده', '${a.followers}K', C.cyan),
          _mini('تحلیل', '${a.analysesCount}', C.primary),
        ]),
        if (!a.verified) ...[
          const SizedBox(height: 10),
          Pill('در انتظار تایید توسط نوا ترید', C.gold, icon: Icons.hourglass_top_rounded),
        ],
      ]),
    );
  }

  Widget _mini(String t, String v, Color c) => Expanded(
        child: Column(children: [
          Text(v, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: c)),
          Text(t, style: TextStyle(color: C.sub, fontSize: 11)),
        ]),
      );
}

class AnalystProfileScreen extends StatelessWidget {
  final String id;
  const AnalystProfileScreen({super.key, required this.id});

  static const _reviews = [
    ('Nazanin.T', 5, 'تحلیل‌ها دقیق و با مدیریت ریسک کامل بود. ممنون!'),
    ('مهدی_کریپتو', 5, 'سیگنال بیت‌کوینشون دقیقاً به هدف خورد، عالی.'),
    ('سینا۹۸', 4, 'خوب توضیح میده و سریع جواب میده.'),
  ];

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final a = s.analyst(id);
    final f = s.following.contains(a.id);
    final list = s.analyses.where((x) => x.analystId == a.id).toList();
    return AppScaffold(
      title: 'پروفایل تحلیلگر',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
        children: [
          Appear(
            child: GlassCard(
              radius: 30,
              glow: a.c1,
              padding: const EdgeInsets.all(20),
              gradient: LinearGradient(
                colors: [a.c1.o(.3), a.c2.o(.12)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              child: Column(children: [
                AnalystAvatar(a, size: 92),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(a.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  if (a.verified) ...[const SizedBox(width: 6), const VerifiedBadge(size: 24)],
                ]),
                Text(a.handle, style: TextStyle(color: C.sub)),
                const SizedBox(height: 6),
                if (a.verified)
                  const Pill('تایید شده توسط نوا ترید', C.blue, icon: Icons.verified_rounded)
                else
                  Pill('در انتظار تایید', C.gold, icon: Icons.hourglass_top_rounded),
                const SizedBox(height: 12),
                Text(a.bio,
                    textAlign: TextAlign.center,
                    style: TextStyle(height: 1.8, fontSize: 13, color: C.text2)),
                const SizedBox(height: 14),
                Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [for (final t in a.tags) Pill(t, Colors.white)]),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          Row(children: [
            _stat('امتیاز', a.rating.toStringAsFixed(1), C.gold, Icons.star_rounded),
            const SizedBox(width: 10),
            _stat('موفقیت', '${a.winRate}%', C.green, Icons.emoji_events_rounded),
            const SizedBox(width: 10),
            _stat('دنبال‌کننده', '${a.followers}K', C.cyan, Icons.people_rounded),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: GradientButton(
                label: f ? 'دنبال شده ✓' : 'دنبال کردن',
                gradient: f ? const LinearGradient(colors: [Color(0xFF3A3626), Color(0xFF26231A)]) : C.grad,
                onTap: () => s.toggleFollow(a.id),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GradientButton(
                label: 'سفارش تحلیل',
                gradient: C.gradGold,
                icon: Icons.edit_note_rounded,
                onTap: () => go(context, OrderScreen(analystId: a.id)),
              ),
            ),
          ]),
          const SectionTitle('تحلیل‌های اخیر'),
          if (list.isEmpty)
            Text('تحلیلی ثبت نشده', style: TextStyle(color: C.sub)),
          for (final x in list)
            Padding(padding: const EdgeInsets.only(bottom: 10), child: AnalysisCard(x)),
          SectionTitle('نظرات کاربران (${a.reviews})'),
          for (final r in _reviews)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                radius: 18,
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(r.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const Spacer(),
                    for (int i = 0; i < 5; i++)
                      Icon(i < r.$2 ? Icons.star_rounded : Icons.star_border_rounded,
                          color: C.gold, size: 16),
                  ]),
                  const SizedBox(height: 6),
                  Text(r.$3, style: TextStyle(color: C.sub, height: 1.7, fontSize: 12.5)),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stat(String t, String v, Color c, IconData i) => Expanded(
        child: GlassCard(
          radius: 18,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(children: [
            Icon(i, color: c),
            const SizedBox(height: 4),
            Text(v, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: c)),
            Text(t, style: TextStyle(color: C.sub, fontSize: 11)),
          ]),
        ),
      );
}

// ───────── Order analysis ─────────
class OrderScreen extends StatelessWidget {
  final String analystId;
  const OrderScreen({super.key, required this.analystId});
  @override
  Widget build(BuildContext context) => AppScaffold(
        title: 'سفارش تحلیل',
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
          children: [OrderTab(initialAnalyst: analystId)],
        ),
      );
}

class OrderTab extends StatefulWidget {
  final String? initialAnalyst;
  const OrderTab({super.key, this.initialAnalyst});
  @override
  State<OrderTab> createState() => _OrderTabState();
}

class _OrderTabState extends State<OrderTab> {
  late String _an = widget.initialAnalyst ?? 'a1';
  String _sym = 'BTC';
  int _kind = 0, _tf = 1, _urg = 0;
  final _note = TextEditingController();
  static const _kinds = ['تکنیکال', 'بنیادی', 'ترکیبی'];
  static const _kindMul = [1.0, 1.3, 1.6];
  static const _tfs = ['4H', '1D', '1W'];
  static const _urgs = ['۲۴ ساعته', '۱۲ ساعته', 'فوری (۲س)'];
  static const _urgMul = [1.0, 1.4, 2.0];

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final an = s.analyst(_an);
    final price = (an.price * _kindMul[_kind] * _urgMul[_urg]).roundToDouble();
    final c = s.coin(_sym);
    final orders = s.orders;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('۱. تحلیلگر را انتخاب کنید',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
      const SizedBox(height: 10),
      SizedBox(
        height: 108,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: s.analysts.where((x) => x.verified).length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final x = s.analysts.where((x) => x.verified).toList()[i];
            final sel = x.id == _an;
            return Pressable(
              onTap: () => setState(() => _an = x.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 106,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: sel ? x.c1.o(.22) : C.ov.o(.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? x.c1 : C.ov.o(.08), width: sel ? 1.6 : 1),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  AnalystAvatar(x, size: 40),
                  const SizedBox(height: 6),
                  Text(x.name.split(' ').first,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                  Text('از \$${x.price.toStringAsFixed(0)}',
                      style: TextStyle(color: C.gold, fontSize: 11)),
                ]),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 18),
      const Text('۲. ارز و نوع تحلیل', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
      const SizedBox(height: 10),
      GlassCard(
        radius: 18,
        padding: const EdgeInsets.all(12),
        onTap: () async {
          final r = await pickCoin(context);
          if (r != null) setState(() => _sym = r);
        },
        child: Row(children: [
          CoinAvatar(c, size: 34),
          const SizedBox(width: 10),
          Text('${c.name} (${c.symbol})', style: const TextStyle(fontWeight: FontWeight.w800)),
          const Spacer(),
          Text(fmtUsd(c.price), style: TextStyle(color: C.sub)),
          Icon(Icons.expand_more_rounded, color: C.sub),
        ]),
      ),
      const SizedBox(height: 10),
      Seg(items: _kinds, index: _kind, onChanged: (i) => setState(() => _kind = i)),
      const SizedBox(height: 10),
      Row(children: [
        Text('تایم‌فریم', style: TextStyle(color: C.sub, fontSize: 12.5)),
        const SizedBox(width: 12),
        Expanded(
            child: Seg(
                items: const ['۴ ساعته', 'روزانه', 'هفتگی'],
                index: _tf,
                onChanged: (i) => setState(() => _tf = i))),
      ]),
      const SizedBox(height: 18),
      const Text('۳. زمان تحویل', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
      const SizedBox(height: 10),
      Seg(items: _urgs, index: _urg, onChanged: (i) => setState(() => _urg = i)),
      const SizedBox(height: 18),
      const Text('۴. توضیحات (اختیاری)',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
      const SizedBox(height: 10),
      TextField(
        controller: _note,
        maxLines: 3,
        decoration: const InputDecoration(hintText: 'مثلاً: سطوح ورود و خروج برای سرمایه‌گذاری میان‌مدت...'),
      ),
      const SizedBox(height: 16),
      GlassCard(
        glow: C.gold,
        gradient: LinearGradient(colors: [C.gold.o(.18), C.pink.o(.08)]),
        child: Row(children: [
          Icon(Icons.receipt_long_rounded, color: C.gold),
          const SizedBox(width: 10),
          const Text('هزینه سفارش', style: TextStyle(fontWeight: FontWeight.w700)),
          const Spacer(),
          AnimatedCount(
              value: price,
              decimals: 0,
              prefix: '',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: C.gold)),
          Text(' USDT', style: TextStyle(color: C.sub, fontSize: 12)),
        ]),
      ),
      const SizedBox(height: 14),
      GradientButton(
        label: 'ثبت سفارش تحلیل',
        icon: Icons.send_rounded,
        onTap: () {
          final ok = s.placeOrder(an, _sym, _kinds[_kind], _tfs[_tf], _note.text.trim(), _urgs[_urg], price);
          if (ok) {
            _note.clear();
            showSuccess(context, 'سفارش ثبت شد',
                '${an.name} تحلیل ${c.symbol} شما را آماده می‌کند.\nوضعیت را در پایین همین صفحه دنبال کنید.');
          } else {
            toast(context, 'موجودی USDT کافی نیست', color: C.red, icon: Icons.error_rounded, bottom: 20);
          }
        },
      ),
      if (orders.isNotEmpty) ...[
        const SectionTitle('سفارش‌های من'),
        for (final o in orders) Padding(padding: const EdgeInsets.only(bottom: 10), child: _OrderCard(o)),
      ],
    ]);
  }
}

class _OrderCard extends StatelessWidget {
  final OrderReq o;
  const _OrderCard(this.o);
  static const _steps = ['ثبت شد', 'پذیرفته شد', 'در حال تحلیل', 'تحویل شد'];
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final an = s.analyst(o.analystId);
    return GlassCard(
      radius: 22,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AnalystAvatar(an, size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('تحلیل ${o.symbol} · ${o.kind}',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              Text('${an.name} · ${o.urgency}', style: TextStyle(color: C.sub, fontSize: 11.5)),
            ]),
          ),
          Text('\$${o.price.toStringAsFixed(0)}',
              style: TextStyle(color: C.gold, fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          for (int i = 0; i < 4; i++) ...[
            Expanded(
              child: Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: i <= o.stage ? C.gradGreen : null,
                    color: i <= o.stage ? null : C.ov.o(.08),
                  ),
                  child: Icon(i <= o.stage ? Icons.check_rounded : Icons.circle,
                      size: i <= o.stage ? 16 : 6, color: i <= o.stage ? Colors.white : C.sub),
                ),
                const SizedBox(height: 4),
                Text(_steps[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 10, color: i <= o.stage ? C.text : C.sub, fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
        ]),
        if (o.stage == 3 && o.analysisId != null) ...[
          const SizedBox(height: 12),
          GradientButton(
            label: 'مشاهده تحلیل',
            height: 44,
            onTap: () => go(context, AnalysisDetailScreen(id: o.analysisId!)),
          ),
        ] else
          Padding(
            padding: EdgeInsets.only(top: 10),
            child: LinearProgressIndicator(minHeight: 3, color: C.cyan),
          ),
      ]),
    );
  }
}
