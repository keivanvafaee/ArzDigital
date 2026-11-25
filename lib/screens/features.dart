import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../data.dart';
import '../state.dart';
import '../common.dart';
import '../charts.dart';
import 'tools.dart';
import 'pulse.dart';

const String kEmail = 'keyvanVafaeeWeb@gmail.com';
const String kSite = 'https://keivanVafaee.ir';
const String kDemoNote = 'این اپلیکیشن به عنوان دمو طراحی شده و هدف دیگری ندارد.';

// ═════════════════════════ Contact us ═════════════════════════
class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});
  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _subject = TextEditingController();
  final _msg = TextEditingController();

  @override
  void dispose() {
    _subject.dispose();
    _msg.dispose();
    super.dispose();
  }

  Widget _contactRow(IconData icon, String title, String value, VoidCallback open, VoidCallback copy) {
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(14),
      onTap: open,
      child: Row(children: [
        IconBox(icon, size: 46),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: C.sub, fontSize: 12)),
            const SizedBox(height: 2),
            Text(value,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.start,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
          ]),
        ),
        IconButton(
          icon: Icon(Icons.copy_rounded, color: C.primary, size: 20),
          onPressed: copy,
        ),
      ]),
    );
  }

  void _copy(String v, String what) {
    Clipboard.setData(ClipboardData(text: v));
    toast(context, '$what کپی شد', icon: Icons.copy_rounded, bottom: 24);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'تماس با ما',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 30),
        children: [
          Appear(
            child: GoldBorderCard(
              child: Column(children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    gradient: C.grad,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: C.primary.o(.5), blurRadius: 26)],
                  ),
                  child: const Icon(Icons.support_agent_rounded, color: Colors.black, size: 40),
                ),
                const SizedBox(height: 12),
                const Text('با ما در تماس باشید',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text('نظر، پیشنهاد یا همکاری؟ خوشحال می‌شویم بشنویم.',
                    textAlign: TextAlign.center, style: TextStyle(color: C.sub, height: 1.7)),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Appear(
            delay: 100,
            child: _contactRow(
              Icons.mail_rounded,
              'ایمیل',
              kEmail,
              () => openUrl(context, Uri.parse('mailto:$kEmail'), copyFallback: kEmail),
              () => _copy(kEmail, 'ایمیل'),
            ),
          ),
          const SizedBox(height: 10),
          Appear(
            delay: 160,
            child: _contactRow(
              Icons.language_rounded,
              'وب‌سایت',
              kSite,
              () => openUrl(context, Uri.parse(kSite), copyFallback: kSite),
              () => _copy(kSite, 'آدرس سایت'),
            ),
          ),
          const SizedBox(height: 14),
          Appear(
            delay: 220,
            child: GlassCard(
              glow: C.gold,
              gradient: LinearGradient(colors: [C.gold.o(.16), C.ov.o(.03)]),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_rounded, color: C.gold),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$kDemoNote\nتمام قیمت‌ها، تحلیل‌ها، کاربران و موجودی‌ها فرضی هستند و فقط برای تست نمایش داده می‌شوند.',
                    style: TextStyle(height: 1.9, fontSize: 13),
                  ),
                ),
              ]),
            ),
          ),
          const SectionTitle('ارسال پیام'),
          GlassCard(
            child: Column(children: [
              TextField(
                controller: _subject,
                decoration: InputDecoration(
                    hintText: 'موضوع', prefixIcon: Icon(Icons.title_rounded, color: C.sub)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _msg,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'متن پیام...'),
              ),
              const SizedBox(height: 14),
              GradientButton(
                label: 'ارسال از طریق ایمیل',
                icon: Icons.send_rounded,
                onTap: () {
                  final s = Uri.encodeComponent(_subject.text.trim().isEmpty ? 'تماس از اپ نوا ترید' : _subject.text.trim());
                  final b = Uri.encodeComponent(_msg.text.trim());
                  openUrl(context, Uri.parse('mailto:$kEmail?subject=$s&body=$b'), copyFallback: kEmail);
                },
              ),
            ]),
          ),
          const SectionTitle('سوالات متداول'),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: Column(children: [
              for (final f in const [
                ('این اپ واقعی است؟', 'خیر. نوا ترید یک اپلیکیشن دموست و هیچ معامله یا واریز واقعی انجام نمی‌دهد.'),
                ('اطلاعات بازار از کجا می‌آید؟', 'همه داده‌ها داخل خود اپ و به‌صورت شبیه‌سازی تولید می‌شوند.'),
                ('چطور می‌توانم گزارش مشکل بدهم؟', 'از فرم بالا یا ایمیل اعلام‌شده استفاده کنید.'),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    radius: 18,
                    padding: EdgeInsets.zero,
                    child: ExpansionTile(
                      iconColor: C.primary,
                      collapsedIconColor: C.sub,
                      title: Text(f.$1, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: [Text(f.$2, style: TextStyle(color: C.sub, height: 1.8, fontSize: 13))],
                    ),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 10),
          Center(child: Text('Nova Trade · نسخه دمو 2.0', style: TextStyle(color: C.sub, fontSize: 11.5))),
        ],
      ),
    );
  }
}

/// Small card used on the home page / profile.
class ContactMiniCard extends StatelessWidget {
  const ContactMiniCard({super.key});
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glow: C.primary,
      onTap: () => go(context, const ContactScreen()),
      child: Row(children: [
        IconBox(Icons.support_agent_rounded, size: 46),
        SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('تماس با ما', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            SizedBox(height: 2),
            Text(kDemoNote, style: TextStyle(color: C.sub, fontSize: 11.5, height: 1.6)),
          ]),
        ),
        Icon(Icons.chevron_left_rounded, color: C.sub),
      ]),
    );
  }
}

// ═════════════════════════ More hub ═════════════════════════
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, Gradient, Widget)>[
      (Icons.auto_awesome_rounded, 'نبض بازار', C.gradGold, const MoodOrbScreen()),
      (Icons.newspaper_rounded, 'اخبار کریپتو', C.grad, const NewsScreen()),
      (Icons.bolt_rounded, 'سیگنال و نهنگ‌ها', C.gradGold, const SignalsScreen()),
      (Icons.savings_rounded, 'استیکینگ', C.gradGreen, const StakingScreen()),
      (Icons.autorenew_rounded, 'خرید خودکار DCA', C.grad, const DcaScreen()),
      (Icons.leaderboard_rounded, 'کپی ترید', C.gradGold, const LeaderboardScreen()),
      (Icons.school_rounded, 'آکادمی', C.grad, const AcademyScreen()),
      (Icons.card_giftcard_rounded, 'دعوت دوستان', C.gradGreen, const ReferralScreen()),
      (Icons.swap_horiz_rounded, 'تبدیل ارز', C.grad, const SwapScreen()),
      (Icons.notifications_active_rounded, 'هشدار قیمت', C.gradGold, const AlertsScreen()),
      (Icons.casino_rounded, 'گردونه شانس', C.gradRed, const RewardScreen()),
      (Icons.smart_toy_rounded, 'دستیار هوشمند', C.gradGreen, const AiScreen()),
      (Icons.calculate_rounded, 'ماشین‌حساب ریسک', C.grad, const CalcScreen()),
      (Icons.person_rounded, 'پروفایل', C.gradGold, const ProfileScreen()),
      (Icons.support_agent_rounded, 'تماس با ما', C.grad, const ContactScreen()),
    ];
    return AppScaffold(
      title: 'همه امکانات',
      body: LayoutBuilder(builder: (ctx, cons) {
        final cols = cons.maxWidth >= 520 ? 4 : 3;
        final w = (cons.maxWidth - 32 - (cols - 1) * 12) / cols;
        return ListView(padding: const EdgeInsets.fromLTRB(16, 6, 16, 30), children: [
          Wrap(spacing: 12, runSpacing: 12, children: [
            for (int i = 0; i < items.length; i++)
              Appear(
                delay: 35 * i,
                child: SizedBox(
                  width: w,
                  child: GlassCard(
                    radius: 22,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
                    onTap: () => go(context, items[i].$4),
                    child: Column(children: [
                      IconBox(items[i].$1, gradient: items[i].$3, size: 52),
                      const SizedBox(height: 10),
                      Text(items[i].$2,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, height: 1.4)),
                    ]),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 18),
          const ContactMiniCard(),
        ]);
      }),
    );
  }
}

// ═════════════════════════ News ═════════════════════════
class NewsItem {
  final String id, title, body, source, ago, sym;
  final bool bull;
  const NewsItem(this.id, this.title, this.body, this.source, this.ago, this.sym, this.bull);
}

const List<NewsItem> kNews = [
  NewsItem('w1', 'ورود سرمایه نهادی به صندوق‌های بیت‌کوین رکورد زد',
      'گزارش‌ها نشان می‌دهد در هفته گذشته بیشترین جریان ورودی ماه به صندوق‌های قابل معامله بیت‌کوین ثبت شده است. تحلیلگران این روند را نشانه افزایش اعتماد نهادها می‌دانند.', 'CryptoDaily', '۳۰ دقیقه پیش', 'BTC', true),
  NewsItem('w2', 'ارتقای بزرگ شبکه اتریوم؛ کارمزدها کاهش می‌یابد',
      'توسعه‌دهندگان از زمان‌بندی ارتقای جدید خبر دادند که هدفش کاهش هزینه تراکنش‌ها و افزایش ظرفیت شبکه است.', 'ChainNews', '۱ ساعت پیش', 'ETH', true),
  NewsItem('w3', 'سولانا به رکورد جدید تراکنش روزانه رسید',
      'شبکه سولانا در ۲۴ ساعت گذشته بیش از هر زمان دیگری تراکنش پردازش کرده و فعالیت دیفای رشد داشته است.', 'BlockPulse', '۲ ساعت پیش', 'SOL', true),
  NewsItem('w4', 'هشدار تحلیلگران درباره نرخ فاندینگ بالا در بازار آتی',
      'نرخ فاندینگ در چند ارز پرطرفدار به محدوده هشدار رسیده است و احتمال تسویه اجباری پوزیشن‌ها وجود دارد.', 'MarketWatch', '۳ ساعت پیش', 'DOGE', false),
  NewsItem('w5', 'ریپل: همکاری جدید با شبکه‌های پرداخت بین‌المللی',
      'اعلام همکاری جدید می‌تواند تقاضا برای بسترهای پرداخت بر پایه بلاکچین را افزایش دهد.', 'FinTech Today', '۵ ساعت پیش', 'XRP', true),
  NewsItem('w6', 'تون‌کوین با رشد کاربران تلگرام جهش کرد',
      'تعداد کیف پول‌های فعال شبکه تون در ماه گذشته به‌طور محسوس افزایش یافته است.', 'CryptoDaily', '۷ ساعت پیش', 'TON', true),
  NewsItem('w7', 'نگرانی از اصلاح؛ شاخص ترس و طمع وارد محدوده طمع شد',
      'با بالا رفتن شاخص طمع، برخی کارشناسان نسبت به ورود دیرهنگام هشدار می‌دهند و رعایت مدیریت سرمایه را توصیه می‌کنند.', 'Analyst Hub', '۱۰ ساعت پیش', 'BTC', false),
  NewsItem('w8', 'چین‌لینک از قابلیت جدید انتقال بین‌زنجیره‌ای رونمایی کرد',
      'پروتکل CCIP با پشتیبانی از شبکه‌های بیشتر، کاربردهای نهادی را گسترش می‌دهد.', 'ChainNews', 'دیروز', 'LINK', true),
];

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});
  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  int _seg = 0;
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final list = kNews.where((n) => _seg == 0 || s.bookmarks.contains(n.id)).toList();
    return AppScaffold(
      title: 'اخبار کریپتو',
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 6, 16, 30), children: [
        Seg(items: const ['همه اخبار', '🔖 نشان‌شده'], index: _seg, onChanged: (i) => setState(() => _seg = i)),
        const SizedBox(height: 14),
        if (list.isEmpty)
          Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: Text('خبری نشان نکرده‌اید', style: TextStyle(color: C.sub)))),
        for (int i = 0; i < list.length; i++)
          Appear(
            key: ValueKey<String>(list[i].id),
            delay: 40 * i,
            child: Padding(padding: const EdgeInsets.only(bottom: 12), child: _card(context, s, list[i])),
          ),
      ]),
    );
  }

  Widget _card(BuildContext context, AppState s, NewsItem n) {
    final c = s.coin(n.sym);
    final col = n.bull ? C.green : C.red;
    final saved = s.bookmarks.contains(n.id);
    return GlassCard(
      radius: 22,
      onTap: () => sheet<void>(
        context,
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CoinAvatar(c, size: 34),
            const SizedBox(width: 8),
            Pill(n.bull ? 'تاثیر مثبت' : 'تاثیر منفی', col),
            const Spacer(),
            Text('${n.source} · ${n.ago}', style: TextStyle(color: C.sub, fontSize: 11.5)),
          ]),
          const SizedBox(height: 14),
          Text(n.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, height: 1.6)),
          const SizedBox(height: 10),
          Text(n.body, style: TextStyle(color: C.text2, height: 1.9, fontSize: 13.5)),
        ]),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [c.color.o(.5), Colors.black.o(.3)]),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.color.o(.5)),
          ),
          child: Text(c.glyph, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: c.color)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(n.title, maxLines: 3, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, height: 1.6)),
            const SizedBox(height: 8),
            Row(children: [
              Pill(n.sym, C.primary),
              const SizedBox(width: 6),
              Pill(n.bull ? 'مثبت' : 'منفی', col),
              const Spacer(),
              Text(n.ago, style: TextStyle(color: C.sub, fontSize: 11)),
            ]),
          ]),
        ),
        GestureDetector(
          onTap: () => s.toggleBookmark(n.id),
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: saved ? C.primary : C.sub),
          ),
        ),
      ]),
    );
  }
}

// ═════════════════════════ Signals & whales ═════════════════════════
class SignalsScreen extends StatefulWidget {
  const SignalsScreen({super.key});
  @override
  State<SignalsScreen> createState() => _SignalsScreenState();
}

class _Whale {
  final String sym, text, ago;
  final double usd;
  final bool bull;
  _Whale(this.sym, this.text, this.ago, this.usd, this.bull);
}

class _SignalsScreenState extends State<SignalsScreen> {
  int _seg = 0;
  final List<_Whale> _feed = [];
  final math.Random _r = math.Random();
  Timer? _t;
  int _n = 0;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 6; i++) {
      _feed.add(_gen('${i + 1} دقیقه پیش'));
    }
    _t = Timer.periodic(const Duration(milliseconds: 2600), (_) {
      if (!mounted) return;
      setState(() {
        _n++;
        _feed.insert(0, _gen('همین الان'));
        if (_feed.length > 25) _feed.removeLast();
      });
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  _Whale _gen(String ago) {
    const syms = ['BTC', 'ETH', 'SOL', 'XRP', 'BNB', 'TON', 'DOGE', 'LINK'];
    const acts = [
      ('برداشت از صرافی', true),
      ('انتقال به صرافی', false),
      ('خرید بزرگ', true),
      ('فروش بزرگ', false),
      ('انتقال به کیف پول سرد', true),
    ];
    final a = acts[_r.nextInt(acts.length)];
    final usd = 1e6 * (1 + _r.nextDouble() * 60);
    return _Whale(syms[_r.nextInt(syms.length)], a.$1, ago, usd, a.$2);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return AppScaffold(
      title: 'سیگنال و نهنگ‌ها',
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 6, 16, 30), children: [
        Seg(items: const ['سیگنال‌های لحظه‌ای', '🐋 نهنگ‌ها'], index: _seg, onChanged: (i) => setState(() => _seg = i)),
        const SizedBox(height: 14),
        if (_seg == 0) ..._signals(s) else ..._whales(s),
      ]),
    );
  }

  List<Widget> _signals(AppState s) {
    final list = [...s.coins];
    double score(Coin c) {
      final mean = c.spark.reduce((a, b) => a + b) / c.spark.length;
      return cl(c.change * 9 + (c.price / mean - 1) * 400, -100, 100);
    }

    list.sort((a, b) => score(b).compareTo(score(a)));
    return [
      Row(children: [PulseDot(color: C.green), SizedBox(width: 8), Text('به‌روزرسانی زنده بر اساس قیمت‌ها', style: TextStyle(color: C.sub, fontSize: 12))]),
      const SizedBox(height: 12),
      for (int i = 0; i < list.length; i++) ...[
        Builder(builder: (_) {
          final c = list[i];
          final sc = score(c);
          final (label, col) = sc >= 35
              ? ('خرید قوی', C.green)
              : sc >= 10
                  ? ('خرید', C.light ? const Color(0xFF5FA81E) : const Color(0xFF9BE564))
                  : sc <= -35
                      ? ('فروش قوی', C.red)
                      : sc <= -10
                          ? ('فروش', C.light ? const Color(0xFFE0603F) : const Color(0xFFFF8A6D))
                          : ('نگه‌دار', C.gold);
          return Appear(
            delay: 30 * i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                radius: 20,
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  CoinAvatar(c, size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(c.symbol, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                        const SizedBox(width: 8),
                        Pill(label, col),
                      ]),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(end: (sc.abs() / 100)),
                          duration: const Duration(milliseconds: 300),
                          builder: (_, v, __) => LinearProgressIndicator(
                              value: v, minHeight: 7, color: col, backgroundColor: C.ov.o(.08)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('قدرت سیگنال ${sc.abs().round()}٪', style: TextStyle(color: C.sub, fontSize: 11)),
                    ]),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(width: 64, height: 36, child: Sparkline(data: c.spark, color: col)),
                ]),
              ),
            ),
          );
        }),
      ],
      Text('⚠️ سیگنال‌ها صرفاً دمو هستند و توصیه مالی نیستند.', style: TextStyle(color: C.gold, fontSize: 11.5)),
    ];
  }

  List<Widget> _whales(AppState s) {
    return [
      const Row(children: [
        PulseDot(),
        SizedBox(width: 8),
        Text('تراکنش‌های بزرگ در لحظه', style: TextStyle(fontWeight: FontWeight.w800)),
      ]),
      const SizedBox(height: 12),
      for (int i = 0; i < _feed.length; i++)
        Appear(
          key: ValueKey<String>('${_n}_${_feed.length - i}_${_feed[i].sym}_${_feed[i].usd.round()}'),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              radius: 18,
              blur: 6,
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                const Text('🐋', style: TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${_feed[i].text} ${_feed[i].sym}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                    Text(_feed[i].ago, style: TextStyle(color: C.sub, fontSize: 11)),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('\$${fmtCompact(_feed[i].usd)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  Pill(_feed[i].bull ? 'صعودی' : 'نزولی', _feed[i].bull ? C.green : C.red),
                ]),
              ]),
            ),
          ),
        ),
    ];
  }
}

// ═════════════════════════ Staking ═════════════════════════
class StakingScreen extends StatelessWidget {
  const StakingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    double staked = 0, earned = 0;
    for (final p in s.stakes) {
      staked += p.qty * s.coin(p.symbol).price;
      earned += p.earned * s.coin(p.symbol).price;
    }
    final avail = s.holdings.keys.toList();
    return AppScaffold(
      title: 'استیکینگ و کسب سود',
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 6, 16, 30), children: [
        Appear(
          child: GoldBorderCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('مجموع استیک‌شده', style: TextStyle(color: C.sub)),
              const SizedBox(height: 4),
              AnimatedCount(value: staked, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: C.primary)),
              const SizedBox(height: 10),
              Row(children: [
                Icon(Icons.trending_up_rounded, color: C.green, size: 20),
                const SizedBox(width: 6),
                Text('پاداش کسب‌شده: ', style: TextStyle(color: C.sub, fontSize: 13)),
                AnimatedCount(value: earned, decimals: 4, style: TextStyle(color: C.green, fontWeight: FontWeight.w900)),
              ]),
            ]),
          ),
        ),
        const SectionTitle('استیک‌های فعال'),
        if (s.stakes.isEmpty)
          Padding(padding: EdgeInsets.all(20), child: Center(child: Text('استیک فعالی ندارید', style: TextStyle(color: C.sub)))),
        for (final p in [...s.stakes])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              radius: 22,
              child: Column(children: [
                Row(children: [
                  CoinAvatar(s.coin(p.symbol), size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${fmtQty(p.qty)} ${p.symbol}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                      Text('سود سالانه ${p.apy}٪', style: TextStyle(color: C.green, fontSize: 12, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('پاداش', style: TextStyle(color: C.sub, fontSize: 11)),
                    Text('+${p.earned.toStringAsFixed(6)}', style: TextStyle(color: C.green, fontWeight: FontWeight.w900, fontSize: 13)),
                  ]),
                ]),
                const SizedBox(height: 12),
                GradientButton(
                  label: 'برداشت (Unstake)',
                  height: 44,
                  gradient: C.gradDark,
                  onTap: () {
                    s.unstake(p);
                    toast(context, 'دارایی و پاداش به کیف پول برگشت', bottom: 24);
                  },
                ),
              ]),
            ),
          ),
        const SectionTitle('دارایی‌های قابل استیک'),
        if (avail.isEmpty) Text('دارایی‌ای ندارید', style: TextStyle(color: C.sub)),
        for (final sym in avail)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              radius: 20,
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                CoinAvatar(s.coin(sym), size: 38),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(sym, style: const TextStyle(fontWeight: FontWeight.w900)),
                    Text('موجودی ${fmtQty(s.holdings[sym]!.qty)}', style: TextStyle(color: C.sub, fontSize: 11.5)),
                  ]),
                ),
                Pressable(
                  onTap: () => sheet<void>(context, _StakeSheet(sym: sym)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(gradient: C.grad, borderRadius: BorderRadius.circular(14)),
                    child: const Text('استیک', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
                  ),
                ),
              ]),
            ),
          ),
        const SizedBox(height: 6),
        Text('⚠️ نسخه دمو؛ پاداش‌ها برای نمایش، سریع‌تر از واقعیت محاسبه می‌شوند.', style: TextStyle(color: C.gold, fontSize: 11.5)),
      ]),
    );
  }
}

class _StakeSheet extends StatefulWidget {
  final String sym;
  const _StakeSheet({required this.sym});
  @override
  State<_StakeSheet> createState() => _StakeSheetState();
}

class _StakeSheetState extends State<_StakeSheet> {
  double _pct = 0.5;
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final h = s.holdings[widget.sym];
    final c = s.coin(widget.sym);
    final qty = (h?.qty ?? 0) * _pct;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        CoinAvatar(c, size: 40),
        const SizedBox(width: 10),
        Text('استیک ${c.symbol}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      ]),
      const SizedBox(height: 16),
      Text('${fmtQty(qty)} ${c.symbol}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: C.primary)),
      Text('≈ ${fmtUsd(qty * c.price)}', style: TextStyle(color: C.sub)),
      Slider(value: _pct, min: 0.05, max: 1, divisions: 19, onChanged: (v) => setState(() => _pct = v)),
      const SizedBox(height: 8),
      GradientButton(
        label: 'تایید استیک',
        icon: Icons.lock_clock_rounded,
        onTap: () {
          final ok = s.stake(widget.sym, qty);
          Navigator.pop(context);
          if (ok) toast(context, 'استیک شروع شد 🎉', bottom: 24);
        },
      ),
    ]);
  }
}

// ═════════════════════════ DCA ═════════════════════════
class DcaScreen extends StatelessWidget {
  const DcaScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return AppScaffold(
      title: 'خرید خودکار (DCA)',
      actions: [
        IconButton(icon: Icon(Icons.add_circle_rounded, color: C.primary), onPressed: () => sheet<void>(context, const _DcaSheet())),
      ],
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 6, 16, 30), children: [
        GlassCard(
          gradient: LinearGradient(colors: [C.primary.o(.2), C.ov.o(.03)]),
          child: Row(children: [
            Icon(Icons.autorenew_rounded, color: C.primary, size: 30),
            SizedBox(width: 12),
            Expanded(
              child: Text('با خرید دوره‌ای و ثابت، ریسک زمان‌بندی ورود را کم کنید. در دمو هر چند ثانیه یک‌بار خریدها اجرا می‌شوند تا نتیجه را ببینید.',
                  style: TextStyle(height: 1.8, fontSize: 12.5)),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        if (s.dcaPlans.isEmpty)
          Padding(padding: EdgeInsets.all(30), child: Center(child: Text('برنامه‌ای ندارید', style: TextStyle(color: C.sub)))),
        for (final p in [...s.dcaPlans])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Dismissible(
              key: ObjectKey(p),
              onDismissed: (_) => s.removeDca(p),
              background: Container(
                decoration: BoxDecoration(color: C.red.o(.3), borderRadius: BorderRadius.circular(22)),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.delete_rounded),
              ),
              child: GlassCard(
                radius: 22,
                child: Column(children: [
                  Row(children: [
                    CoinAvatar(s.coin(p.symbol), size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${fmtUsd(p.amount)} ${p.freq} در ${p.symbol}', style: const TextStyle(fontWeight: FontWeight.w800)),
                        Text('${p.runs} بار اجرا · مجموع ${fmtUsd(p.invested)}', style: TextStyle(color: C.sub, fontSize: 11.5)),
                      ]),
                    ),
                    Switch(value: p.active, onChanged: (v) => s.toggleDca(p, v)),
                  ]),
                  const SizedBox(height: 10),
                  GradientButton(
                    label: 'اجرای همین الان',
                    icon: Icons.play_arrow_rounded,
                    height: 44,
                    gradient: C.gradGold,
                    onTap: () {
                      if (s.runDca(p)) {
                        toast(context, 'خرید ${p.symbol} انجام شد', bottom: 24);
                      } else {
                        toast(context, 'موجودی USDT کافی نیست', color: C.red, icon: Icons.error_rounded, bottom: 24);
                      }
                    },
                  ),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

class _DcaSheet extends StatefulWidget {
  const _DcaSheet();
  @override
  State<_DcaSheet> createState() => _DcaSheetState();
}

class _DcaSheetState extends State<_DcaSheet> {
  String _sym = 'BTC';
  int _f = 1;
  final _a = TextEditingController(text: '50');
  static const _fs = ['روزانه', 'هفتگی', 'ماهانه'];
  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.coin(_sym);
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('برنامه خرید خودکار جدید', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 14),
      GlassCard(
        radius: 16,
        padding: const EdgeInsets.all(12),
        onTap: () async {
          final r = await pickCoin(context);
          if (r != null) setState(() => _sym = r);
        },
        child: Row(children: [
          CoinAvatar(c, size: 32),
          const SizedBox(width: 10),
          Text(c.symbol, style: const TextStyle(fontWeight: FontWeight.w800)),
          const Spacer(),
          Icon(Icons.expand_more_rounded, color: C.sub),
        ]),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _a,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textDirection: TextDirection.ltr,
        decoration: InputDecoration(hintText: 'مبلغ هر خرید (USDT)', prefixIcon: Icon(Icons.attach_money_rounded, color: C.sub)),
      ),
      const SizedBox(height: 10),
      Seg(items: _fs, index: _f, onChanged: (i) => setState(() => _f = i)),
      const SizedBox(height: 16),
      GradientButton(
        label: 'ساخت برنامه',
        onTap: () {
          final v = double.tryParse(_a.text.trim());
          if (v == null || v <= 0) {
            toast(context, 'مبلغ نامعتبر است', color: C.red, icon: Icons.error_rounded, bottom: 24);
            return;
          }
          s.addDca(DcaPlan(_sym, v, _fs[_f]));
          Navigator.pop(context);
        },
      ),
    ]);
  }
}

// ═════════════════════════ Leaderboard / copy trading ═════════════════════════
class _Trader {
  final String id, name, handle, risk;
  final double profit, followers;
  final int win;
  const _Trader(this.id, this.name, this.handle, this.profit, this.win, this.followers, this.risk);
}

const List<_Trader> _traders = [
  _Trader('t1', 'آرش کیهانی', '@arash_tech', 187.4, 78, 24.6, 'متوسط'),
  _Trader('t2', 'مهسا آریا', '@mahsa_fund', 164.9, 80, 21.4, 'کم'),
  _Trader('t3', 'سارا مرادی', '@sara_onchain', 142.2, 74, 18.2, 'متوسط'),
  _Trader('t4', 'نیما رضوی', '@nima_waves', 118.7, 71, 12.9, 'متوسط'),
  _Trader('t5', 'لیلا نوری', '@leila_defi', 96.3, 69, 8.7, 'زیاد'),
  _Trader('t6', 'رضا اسکالپ', '@reza_scalp', 77.8, 64, 5.2, 'زیاد'),
];

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    const medals = ['🥇', '🥈', '🥉'];
    return AppScaffold(
      title: 'کپی ترید و رتبه‌بندی',
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 6, 16, 30), children: [
        GlassCard(
          gradient: LinearGradient(colors: [C.primary.o(.2), C.ov.o(.03)]),
          child: Row(children: [
            Icon(Icons.emoji_events_rounded, color: C.gold, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Text('بهترین معامله‌گران ماه. با «کپی» کردن، معاملات آن‌ها در حساب دمو شما شبیه‌سازی می‌شود.',
                  style: TextStyle(height: 1.8, fontSize: 12.5)),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        for (int i = 0; i < _traders.length; i++)
          Appear(
            delay: 50 * i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _row(context, s, _traders[i], i < 3 ? medals[i] : '${i + 1}'),
            ),
          ),
      ]),
    );
  }

  Widget _row(BuildContext context, AppState s, _Trader t, String rank) {
    final on = s.copying.contains(t.id);
    final riskCol = t.risk == 'کم' ? C.green : (t.risk == 'زیاد' ? C.red : C.gold);
    return GlassCard(
      radius: 24,
      glow: on ? C.green : null,
      child: Column(children: [
        Row(children: [
          Text(rank, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(width: 12),
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: const BoxDecoration(gradient: C.grad, shape: BoxShape.circle),
            child: Text(t.name[0], style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(t.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900))),
                const SizedBox(width: 4),
                const VerifiedBadge(size: 16),
              ]),
              Text(t.handle, style: TextStyle(color: C.sub, fontSize: 11.5)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('+${t.profit}%', style: TextStyle(color: C.green, fontWeight: FontWeight.w900, fontSize: 17)),
            Text('سود ۹۰ روز', style: TextStyle(color: C.sub, fontSize: 10.5)),
          ]),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Text('موفقیت ${t.win}٪', style: TextStyle(fontSize: 12, color: C.sub))),
          Expanded(child: Text('${t.followers}K کپی‌کننده', style: TextStyle(fontSize: 12, color: C.sub))),
          Pill('ریسک ${t.risk}', riskCol),
        ]),
        const SizedBox(height: 12),
        GradientButton(
          label: on ? 'در حال کپی ✓' : 'کپی معاملات',
          height: 44,
          gradient: on ? C.gradGreen : C.grad,
          icon: on ? Icons.check_circle_rounded : Icons.copy_all_rounded,
          onTap: () {
            s.toggleCopy(t.id);
            toast(context, on ? 'کپی ${t.name} متوقف شد' : 'کپی‌ترید ${t.name} فعال شد', bottom: 24);
          },
        ),
      ]),
    );
  }
}

// ═════════════════════════ Academy ═════════════════════════
class _Lesson {
  final String id, title, body, q;
  final List<String> options;
  final int answer;
  const _Lesson(this.id, this.title, this.body, this.q, this.options, this.answer);
}

class _Course {
  final String title;
  final IconData icon;
  final List<_Lesson> lessons;
  const _Course(this.title, this.icon, this.lessons);
}

const List<_Course> _courses = [
  _Course('شروع کریپتو', Icons.rocket_launch_rounded, [
    _Lesson('l1', 'بلاکچین چیست؟', 'بلاکچین یک دفتر کل توزیع‌شده است که تراکنش‌ها را در بلوک‌های به‌هم‌پیوسته ذخیره می‌کند و تغییر آن عملاً غیرممکن است.', 'بلاکچین چه نوع دفتری است؟', ['متمرکز', 'توزیع‌شده', 'خصوصی'], 1),
    _Lesson('l2', 'کیف پول و کلید خصوصی', 'کلید خصوصی دسترسی شما به دارایی است. هرگز آن را با کسی به اشتراک نگذارید و از عبارت بازیابی نسخه پشتیبان آفلاین بگیرید.', 'کلید خصوصی را با چه کسی به اشتراک می‌گذاریم؟', ['دوستان', 'پشتیبانی صرافی', 'هیچ‌کس'], 2),
    _Lesson('l3', 'سفارش بازار و محدود', 'سفارش بازار بلافاصله با قیمت فعلی اجرا می‌شود؛ سفارش محدود فقط در قیمتی که شما تعیین کرده‌اید.', 'کدام سفارش فوراً اجرا می‌شود؟', ['بازار', 'محدود', 'هیچ‌کدام'], 0),
  ]),
  _Course('تحلیل تکنیکال', Icons.candlestick_chart_rounded, [
    _Lesson('l4', 'حمایت و مقاومت', 'حمایت ناحیه‌ای است که خریداران قدرت می‌گیرند و مقاومت ناحیه‌ای که فروشندگان غالب می‌شوند.', 'مقاومت یعنی؟', ['ناحیه غلبه فروشندگان', 'ناحیه غلبه خریداران', 'قیمت ثابت'], 0),
    _Lesson('l5', 'اندیکاتور RSI', 'RSI قدرت روند را بین ۰ تا ۱۰۰ نشان می‌دهد. مقادیر بالای ۷۰ معمولاً اشباع خرید و زیر ۳۰ اشباع فروش است.', 'RSI بالای ۷۰ معمولاً یعنی؟', ['اشباع فروش', 'اشباع خرید', 'بدون معنی'], 1),
    _Lesson('l6', 'الگوهای کندلی', 'کندل پوشای صعودی نشانه‌ای از بازگشت قدرت خریداران است، به‌ویژه در ناحیه حمایت.', 'کندل پوشای صعودی نشانه چیست؟', ['قدرت خریداران', 'قدرت فروشندگان', 'ثبات بازار'], 0),
  ]),
  _Course('مدیریت ریسک', Icons.shield_rounded, [
    _Lesson('l7', 'قانون ۲ درصد', 'در هر معامله بیش از ۱ تا ۲ درصد کل سرمایه را ریسک نکنید تا چند ضرر پیاپی حساب شما را از بین نبرد.', 'حداکثر ریسک پیشنهادی هر معامله؟', ['۲٪', '۲۵٪', '۵۰٪'], 0),
    _Lesson('l8', 'حد ضرر', 'حد ضرر از قبل تعیین می‌شود تا احساسات روی تصمیم‌ها اثر نگذارد.', 'حد ضرر را کی تعیین می‌کنیم؟', ['بعد از ضرر', 'قبل از ورود', 'هیچ‌وقت'], 1),
    _Lesson('l9', 'تنوع پرتفو', 'سرمایه را بین چند دارایی با همبستگی کم تقسیم کنید.', 'تنوع پرتفو چه کمکی می‌کند؟', ['کاهش ریسک', 'حذف سود', 'افزایش کارمزد'], 0),
  ]),
];

class AcademyScreen extends StatelessWidget {
  const AcademyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final total = _courses.fold<int>(0, (a, c) => a + c.lessons.length);
    return AppScaffold(
      title: 'آکادمی نوا',
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 6, 16, 30), children: [
        GoldBorderCard(
          child: Row(children: [
            SizedBox(
              width: 70,
              height: 70,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(
                  value: s.doneLessons.length / total,
                  strokeWidth: 7,
                  color: C.primary,
                  backgroundColor: C.ov.o(.1),
                ),
                Text('${s.doneLessons.length}/$total', style: const TextStyle(fontWeight: FontWeight.w900)),
              ]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('پیشرفت یادگیری', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                SizedBox(height: 4),
                Text('هر درس + آزمون = ۳۰ امتیاز تجربه', style: TextStyle(color: C.sub, fontSize: 12.5)),
              ]),
            ),
          ]),
        ),
        for (final c in _courses) ...[
          SectionTitle(c.title),
          for (final l in c.lessons)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                radius: 20,
                padding: const EdgeInsets.all(14),
                onTap: () => sheet<void>(context, _LessonSheet(lesson: l)),
                child: Row(children: [
                  IconBox(c.icon, size: 42),
                  const SizedBox(width: 12),
                  Expanded(child: Text(l.title, style: const TextStyle(fontWeight: FontWeight.w800))),
                  if (s.doneLessons.contains(l.id))
                    Icon(Icons.check_circle_rounded, color: C.green)
                  else
                    Icon(Icons.play_circle_fill_rounded, color: C.primary),
                ]),
              ),
            ),
        ],
      ]),
    );
  }
}

class _LessonSheet extends StatefulWidget {
  final _Lesson lesson;
  const _LessonSheet({required this.lesson});
  @override
  State<_LessonSheet> createState() => _LessonSheetState();
}

class _LessonSheetState extends State<_LessonSheet> {
  int? _pick;
  @override
  Widget build(BuildContext context) {
    final l = widget.lesson;
    final s = AppScope.read(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(l.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
      const SizedBox(height: 10),
      Text(l.body, style: TextStyle(color: C.text2, height: 1.9, fontSize: 13.5)),
      const SizedBox(height: 18),
      Text('آزمون: ${l.q}', style: TextStyle(fontWeight: FontWeight.w800, color: C.primary)),
      const SizedBox(height: 10),
      for (int i = 0; i < l.options.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Pressable(
            onTap: () {
              if (_pick != null && _pick == l.answer) return;
              setState(() => _pick = i);
              if (i == l.answer) {
                s.completeLesson(l.id, 30);
                toast(context, 'آفرین! +۳۰ امتیاز', bottom: 24);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _pick == i ? (i == l.answer ? C.green.o(.18) : C.red.o(.18)) : C.ov.o(.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _pick == i ? (i == l.answer ? C.green : C.red) : C.ov.o(.08)),
              ),
              child: Row(children: [
                Expanded(child: Text(l.options[i], style: const TextStyle(fontWeight: FontWeight.w700))),
                if (_pick == i) Icon(i == l.answer ? Icons.check_circle_rounded : Icons.cancel_rounded, color: i == l.answer ? C.green : C.red),
              ]),
            ),
          ),
        ),
    ]);
  }
}

// ═════════════════════════ Referral ═════════════════════════
class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    const code = 'NOVA-7K2Q';
    return AppScaffold(
      title: 'دعوت دوستان',
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 6, 16, 30), children: [
        GoldBorderCard(
          child: Column(children: [
            Icon(Icons.card_giftcard_rounded, color: C.primary, size: 48),
            const SizedBox(height: 8),
            const Text('دوستانتان را دعوت کنید', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19)),
            const SizedBox(height: 4),
            Text('به ازای هر دوست ۱۵ USDT جایزه (دمو)', style: TextStyle(color: C.sub)),
            const SizedBox(height: 16),
            Pressable(
              onTap: () {
                Clipboard.setData(const ClipboardData(text: code));
                toast(context, 'کد دعوت کپی شد', icon: Icons.copy_rounded, bottom: 24);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.black.o(.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: C.primary.o(.6)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(code, textDirection: TextDirection.ltr, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3, color: C.primary)),
                  SizedBox(width: 12),
                  Icon(Icons.copy_rounded, color: C.primary),
                ]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _st('دعوت‌شده', '${s.referrals}', Icons.group_add_rounded, C.primary)),
          const SizedBox(width: 10),
          Expanded(child: _st('درآمد', fmtUsd(s.referralEarn), Icons.savings_rounded, C.green)),
        ]),
        const SizedBox(height: 14),
        GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('مرحله بعد: طلایی (۱۰ دعوت)', style: TextStyle(fontWeight: FontWeight.w800, color: C.gold.o(.95))),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: s.referrals / 10, minHeight: 10, color: C.primary, backgroundColor: C.ov.o(.1)),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        GradientButton(
          label: 'شبیه‌سازی دعوت یک دوست',
          icon: Icons.person_add_alt_1_rounded,
          onTap: () {
            s.referrals++;
            s.referralEarn += 15;
            s.deposit(15);
            toast(context, '۱۵ USDT جایزه دعوت دریافت شد', bottom: 24);
          },
        ),
      ]),
    );
  }

  Widget _st(String t, String v, IconData i, Color c) => GlassCard(
        radius: 20,
        child: Column(children: [
          Icon(i, color: c),
          const SizedBox(height: 6),
          Text(v, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: c)),
          Text(t, style: TextStyle(color: C.sub, fontSize: 11.5)),
        ]),
      );
}
