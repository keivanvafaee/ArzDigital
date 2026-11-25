import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';
import '../data.dart';
import '../state.dart';
import '../common.dart';
import 'auth.dart';
import 'features.dart';

// ───────── coin picker ─────────
Future<String?> pickCoin(BuildContext context, {bool usdt = false, bool allowAll = false}) {
  final s = AppScope.read(context);
  return sheet<String>(
    context,
    Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('انتخاب ارز', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
      const SizedBox(height: 12),
      if (allowAll)
        ListTile(
          leading: Icon(Icons.public_rounded, color: C.cyan),
          title: const Text('کل بازار', style: TextStyle(fontWeight: FontWeight.w800)),
          onTap: () => Navigator.pop(context, 'ALL'),
        ),
      if (usdt)
        ListTile(
          leading: const CircleAvatar(
              backgroundColor: Color(0xFF26A17B), child: Text('₮', style: TextStyle(fontWeight: FontWeight.w900))),
          title: const Text('USDT', style: TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text('تتر', style: TextStyle(color: C.sub)),
          onTap: () => Navigator.pop(context, 'USDT'),
        ),
      for (final c in s.coins)
        ListTile(
          leading: CoinAvatar(c, size: 38),
          title: Text(c.symbol, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(c.name, style: TextStyle(color: C.sub, fontSize: 12)),
          trailing: Text(fmtUsd(c.price), style: TextStyle(color: C.sub)),
          onTap: () => Navigator.pop(context, c.symbol),
        ),
    ]),
  );
}

// ───────── Swap ─────────
class SwapScreen extends StatefulWidget {
  const SwapScreen({super.key});
  @override
  State<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen> with SingleTickerProviderStateMixin {
  String _from = 'USDT', _to = 'BTC';
  final _amt = TextEditingController();
  late final AnimationController _rot =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450));

  @override
  void dispose() {
    _amt.dispose();
    _rot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final amt = double.tryParse(_amt.text.trim()) ?? 0;
    final usd = amt * s.priceOf(_from);
    final got = usd * 0.998 / s.priceOf(_to);
    return AppScaffold(
      title: 'تبدیل ارز',
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _box(context, s, 'از', _from, true),
        Center(
          child: Pressable(
            onTap: () {
              _rot.forward(from: 0);
              setState(() {
                final t = _from;
                _from = _to;
                _to = t;
              });
            },
            child: RotationTransition(
              turns: Tween<double>(begin: 0, end: 0.5).animate(CurvedAnimation(parent: _rot, curve: Curves.easeOutBack)),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    gradient: C.grad, shape: BoxShape.circle, boxShadow: [BoxShadow(color: C.primary.o(.5), blurRadius: 16)]),
                child: const Icon(Icons.swap_vert_rounded, color: Colors.black),
              ),
            ),
          ),
        ),
        _box(context, s, 'به', _to, false, shown: got),
        const SizedBox(height: 16),
        GlassCard(
          radius: 18,
          child: Column(children: [
            _kv('نرخ تبدیل',
                '1 $_from = ${fmtQty(s.priceOf(_from) / s.priceOf(_to))} $_to'),
            const SizedBox(height: 8),
            _kv('کارمزد', '0.2%'),
            const SizedBox(height: 8),
            _kv('ارزش', fmtUsd(usd)),
          ]),
        ),
        const SizedBox(height: 18),
        GradientButton(
          label: 'تبدیل کن',
          icon: Icons.bolt_rounded,
          onTap: () {
            if (_from == _to) {
              toast(context, 'ارزهای مبدا و مقصد یکسان است', color: C.red, icon: Icons.error_rounded, bottom: 20);
              return;
            }
            if (s.swap(_from, _to, amt)) {
              _amt.clear();
              showSuccess(context, 'تبدیل انجام شد', '${fmtQty(got)} $_to به کیف پول شما اضافه شد');
            } else {
              toast(context, 'مقدار نامعتبر یا موجودی ناکافی', color: C.red, icon: Icons.error_rounded, bottom: 20);
            }
          },
        ),
      ]),
    );
  }

  Widget _kv(String k, String v) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(k, style: TextStyle(color: C.sub, fontSize: 12.5)),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
      ]);

  Widget _box(BuildContext context, AppState s, String label, String sym, bool isFrom, {double? shown}) {
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label, style: TextStyle(color: C.sub)),
          const Spacer(),
          Text('موجودی: ${fmtQty(s.balanceOf(sym))}', style: TextStyle(color: C.sub, fontSize: 12)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Pressable(
            onTap: () async {
              final r = await pickCoin(context, usdt: true);
              if (r != null) setState(() => isFrom ? _from = r : _to = r);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: C.ov.o(.08), borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                if (sym == 'USDT')
                  const CircleAvatar(
                      radius: 14,
                      backgroundColor: Color(0xFF26A17B),
                      child: Text('₮', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)))
                else
                  CoinAvatar(s.coin(sym), size: 28),
                const SizedBox(width: 8),
                Text(sym, style: const TextStyle(fontWeight: FontWeight.w900)),
                Icon(Icons.expand_more_rounded, color: C.sub),
              ]),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: isFrom
                ? TextField(
                    controller: _amt,
                    onChanged: (_) => setState(() {}),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.end,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                    decoration: const InputDecoration(
                        hintText: '0.0', filled: false, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
                  )
                : Text(fmtQty(shown ?? 0),
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: C.cyan)),
          ),
        ]),
        if (isFrom)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(children: [
              for (final p in const [0.25, 0.5, 1.0])
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Pressable(
                    onTap: () => setState(() => _amt.text = (s.balanceOf(sym) * p).toStringAsFixed(6)),
                    child: Pill(p == 1.0 ? 'همه' : '${(p * 100).round()}%', C.cyan),
                  ),
                ),
            ]),
          ),
      ]),
    );
  }
}

// ───────── Alerts ─────────
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return AppScaffold(
      title: 'هشدار قیمت',
      actions: [
        IconButton(
          icon: Icon(Icons.add_alert_rounded, color: C.gold),
          onPressed: () => sheet<void>(context, const _AlertSheet()),
        ),
      ],
      body: ListView(padding: const EdgeInsets.all(16), children: [
        GlassCard(
          gradient: LinearGradient(colors: [C.gold.o(.2), C.pink.o(.08)]),
          child: Row(children: [
            Icon(Icons.notifications_active_rounded, color: C.gold, size: 30),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('وقتی قیمت به عدد دلخواهت رسید، همین‌جا خبرت می‌کنیم. (چند هشدار نزدیک قیمت لحظه‌ای ساخته شده تا در دمو ببینی!)',
                  style: TextStyle(height: 1.7, fontSize: 12.5)),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        if (s.alerts.isEmpty)
          Padding(
              padding: EdgeInsets.all(30), child: Center(child: Text('هشداری ندارید', style: TextStyle(color: C.sub)))),
        for (final a in s.alerts)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Dismissible(
              key: ObjectKey(a),
              direction: DismissDirection.horizontal,
              background: Container(
                decoration: BoxDecoration(color: C.red.o(.3), borderRadius: BorderRadius.circular(20)),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.delete_rounded),
              ),
              onDismissed: (_) => s.removeAlert(a),
              child: GlassCard(
                radius: 20,
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  CoinAvatar(s.coin(a.symbol), size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${a.symbol} ${a.above ? "بالاتر از" : "پایین‌تر از"} ${fmtUsd(a.price)}',
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text('قیمت فعلی ${fmtUsd(s.coin(a.symbol).price)}',
                          style: TextStyle(color: C.sub, fontSize: 11.5)),
                    ]),
                  ),
                  Switch(
                    value: a.active,
                    activeColor: C.green,
                    onChanged: (v) => s.toggleAlert(a, v),
                  ),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

class _AlertSheet extends StatefulWidget {
  const _AlertSheet();
  @override
  State<_AlertSheet> createState() => _AlertSheetState();
}

class _AlertSheetState extends State<_AlertSheet> {
  String _sym = 'BTC';
  bool _above = true;
  final _p = TextEditingController();
  @override
  void dispose() {
    _p.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.coin(_sym);
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('هشدار جدید', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
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
          Text('${c.symbol} · ${fmtUsd(c.price)}', style: const TextStyle(fontWeight: FontWeight.w800)),
          const Spacer(),
          Icon(Icons.expand_more_rounded, color: C.sub),
        ]),
      ),
      const SizedBox(height: 10),
      Seg(items: const ['بالاتر از', 'پایین‌تر از'], index: _above ? 0 : 1, onChanged: (i) => setState(() => _above = i == 0)),
      const SizedBox(height: 10),
      TextField(
        controller: _p,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textDirection: TextDirection.ltr,
        decoration: InputDecoration(
          hintText: 'قیمت هدف',
          prefixIcon: Icon(Icons.attach_money_rounded, color: C.sub),
          suffixIcon: TextButton(
            onPressed: () => _p.text = (c.price * (_above ? 1.002 : 0.998)).toStringAsFixed(c.price > 1 ? 2 : 4),
            child: Text('نزدیک قیمت', style: TextStyle(color: C.cyan, fontSize: 12)),
          ),
        ),
      ),
      const SizedBox(height: 16),
      GradientButton(
        label: 'ساخت هشدار',
        gradient: C.gradGold,
        onTap: () {
          final v = double.tryParse(_p.text.trim());
          if (v == null || v <= 0) {
            toast(context, 'قیمت نامعتبر است', color: C.red, icon: Icons.error_rounded, bottom: 20);
            return;
          }
          s.addAlert(PriceAlert(_sym, _above, v));
          Navigator.pop(context);
        },
      ),
    ]);
  }
}

// ───────── Daily wheel ─────────
class RewardScreen extends StatefulWidget {
  const RewardScreen({super.key});
  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> with SingleTickerProviderStateMixin {
  static const _prizes = <(String, double, int)>[
    ('\$5', 5, 20),
    ('50 XP', 0, 50),
    ('\$10', 10, 30),
    ('20 XP', 0, 20),
    ('\$25', 25, 50),
    ('100 XP', 0, 100),
    ('\$2', 2, 10),
    ('\$50', 50, 100),
  ];
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 4200));
  double _from = 0, _to = 0;
  bool _spinning = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _spin() {
    final s = AppScope.read(context);
    if (_spinning || s.spunToday) return;
    final r = math.Random();
    // weighted: small prizes more likely
    final weights = [20, 22, 14, 22, 6, 8, 25, 2];
    int roll = r.nextInt(weights.reduce((a, b) => a + b)), idx = 0;
    for (int i = 0; i < weights.length; i++) {
      if (roll < weights[i]) {
        idx = i;
        break;
      }
      roll -= weights[i];
    }
    final seg = 2 * math.pi / _prizes.length;
    _from = _to % (2 * math.pi);
    _to = _from + 2 * math.pi * 6 + ((-(idx + 0.5) * seg) - _from) % (2 * math.pi);
    setState(() => _spinning = true);
    _c.forward(from: 0).then((_) {
      if (!mounted) return;
      final p = _prizes[idx];
      s.claimReward(p.$2, p.$3, p.$1);
      setState(() => _spinning = false);
      showSuccess(context, 'تبریک! 🎉', 'جایزه شما: ${p.$1}\n+${p.$3} امتیاز تجربه');
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return AppScaffold(
      title: 'گردونه شانس روزانه',
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.local_fire_department_rounded, color: C.gold),
          const SizedBox(width: 6),
          Text('${s.streak} روز متوالی', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        ]),
        const SizedBox(height: 20),
        Center(
          child: SizedBox(
            width: 300,
            height: 320,
            child: Stack(alignment: Alignment.topCenter, children: [
              Positioned(
                top: 20,
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (_, __) {
                    final t = Curves.easeOutCubic.transform(_c.value);
                    return Transform.rotate(
                      angle: _from + (_to - _from) * t,
                      child: Container(
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, boxShadow: [BoxShadow(color: C.primary.o(.5), blurRadius: 40)]),
                        child: CustomPaint(
                            size: const Size(290, 290), painter: _WheelPainter(_prizes.map((e) => e.$1).toList())),
                      ),
                    );
                  },
                ),
              ),
              Positioned(top: 0, child: Icon(Icons.arrow_drop_down_rounded, color: C.gold, size: 56)),
              Positioned(
                top: 20 + 145 - 28,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: C.gradGold,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(Icons.star_rounded, size: 30, color: Colors.black),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        GradientButton(
          label: s.spunToday ? 'فردا دوباره بیا 🌙' : (_spinning ? 'در حال چرخش...' : 'بچرخون!'),
          gradient: C.gradGold,
          icon: Icons.casino_rounded,
          onTap: s.spunToday || _spinning ? null : _spin,
        ),
        const SizedBox(height: 18),
        GlassCard(
          child: Column(children: [
            Row(children: [
              Text('سطح ${s.level}', style: const TextStyle(fontWeight: FontWeight.w900)),
              const Spacer(),
              Text('${s.xp} XP', style: TextStyle(color: C.sub)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                  value: s.levelProgress, minHeight: 10, color: C.primary, backgroundColor: C.ov.o(.1)),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<String> labels;
  _WheelPainter(this.labels);
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final n = labels.length;
    final seg = 2 * math.pi / n;
    final cols = [C.primary, C.cyan, C.pink, C.green, C.gold, C.blue, C.red, const Color(0xFFFF8A3D)];
    for (int i = 0; i < n; i++) {
      final start = -math.pi / 2 + i * seg;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        start,
        seg,
        true,
        Paint()..color = cols[i % cols.length].o(i.isEven ? .85 : .6),
      );
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        start,
        seg,
        true,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.o(.5),
      );
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(start + seg / 2);
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: TextStyle(color: cols[i % cols.length].computeLuminance() > .4 ? Colors.black : Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(r * 0.62 - tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
    canvas.drawCircle(c, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = Colors.white.o(.8));
  }

  @override
  bool shouldRepaint(_WheelPainter o) => false;
}

// ───────── AI assistant ─────────
class AiScreen extends StatefulWidget {
  const AiScreen({super.key});
  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _Msg {
  final String text;
  final bool me;
  _Msg(this.text, this.me);
}

class _AiScreenState extends State<AiScreen> {
  final List<_Msg> _msgs = [
    _Msg('سلام! من «نوا» هستم، دستیار هوشمند بازار 🤖\nدرباره قیمت، تحلیل، ریسک یا پرتفوی‌ات بپرس.', false),
  ];
  final _t = TextEditingController();
  final _sc = ScrollController();
  bool _typing = false;

  @override
  void dispose() {
    _t.dispose();
    _sc.dispose();
    super.dispose();
  }

  String _answer(AppState s, String q) {
    final l = q.toLowerCase();
    for (final c in s.coins) {
      if (l.contains(c.symbol.toLowerCase()) || q.contains(c.name)) {
        final trend = c.change >= 0 ? 'صعودی' : 'نزولی';
        return '${c.name} (${c.symbol}) الان ${fmtUsd(c.price)} معامله می‌شود و در ۲۴ ساعت گذشته ${fmtPct(c.change)} تغییر داشته.\n'
            'روند کوتاه‌مدت ${trend} است. محدوده حمایت نزدیک ${fmtUsd(c.low24)} و مقاومت نزدیک ${fmtUsd(c.high24)}.\n'
            '⚠️ این فقط یک پاسخ دموست و توصیه مالی نیست.';
      }
    }
    if (q.contains('پرتفو') || q.contains('دارایی') || q.contains('کیف')) {
      final top = s.holdings.keys.toList()
        ..sort((a, b) => (s.holdings[b]!.qty * s.coin(b).price).compareTo(s.holdings[a]!.qty * s.coin(a).price));
      return 'ارزش کل دارایی شما ${fmtUsd(s.total)} است و سود/زیان کل ${fmtPct(s.pnlPct)}.\n'
          'بزرگ‌ترین دارایی شما ${top.first} است. پیشنهاد: تنوع‌بخشی را بررسی کنید و بخشی را به USDT نگه دارید.';
    }
    if (q.contains('ریسک') || q.contains('حد ضرر')) {
      return 'قانون طلایی: در هر معامله بیش از ۱ تا ۲ درصد سرمایه را ریسک نکنید. از «ماشین‌حساب ریسک» در صفحه اصلی استفاده کنید تا حجم پوزیشن را دقیق حساب کند.';
    }
    if (q.contains('ترس') || q.contains('طمع') || q.contains('بازار')) {
      return 'شاخص ترس و طمع روی 72 (طمع) است. در این شرایط معمولاً احتیاط در خرید دنباله‌روی توصیه می‌شود و حد ضرر اهمیت بیشتری دارد.';
    }
    if (q.contains('تحلیل')) {
      final a = ([...s.analyses]..sort((x, y) => y.likes.compareTo(x.likes))).first;
      return 'پرطرفدارترین تحلیل الان: «${a.title}» با ${a.likes} لایک. می‌توانید از تب «تحلیل» آن را ببینید.';
    }
    return 'می‌توانم درباره قیمت ارزها (مثلاً BTC یا اتریوم)، وضعیت پرتفو، مدیریت ریسک و احساس بازار کمکت کنم. سوالت را دقیق‌تر بپرس 🙂';
  }

  void _send(String text) {
    if (text.trim().isEmpty || _typing) return;
    final s = AppScope.read(context);
    setState(() {
      _msgs.add(_Msg(text.trim(), true));
      _typing = true;
    });
    _t.clear();
    _scroll();
    Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _msgs.add(_Msg(_answer(s, text), false));
        _typing = false;
      });
      _scroll();
    });
  }

  void _scroll() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_sc.hasClients) {
        _sc.animateTo(_sc.position.maxScrollExtent + 120,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'دستیار هوشمند نوا',
      body: Column(children: [
        Expanded(
          child: ListView(
            controller: _sc,
            padding: const EdgeInsets.all(16),
            children: [
              for (final m in _msgs)
                Align(
                  alignment: m.me ? Alignment.centerRight : Alignment.centerLeft,
                  child: Appear(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: m.me ? C.grad : null,
                        color: m.me ? null : C.ov.o(.08),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomRight: Radius.circular(m.me ? 4 : 20),
                          bottomLeft: Radius.circular(m.me ? 20 : 4),
                        ),
                      ),
                      child: Text(m.text, style: TextStyle(height: 1.8, fontSize: 13.5, color: m.me ? Colors.black : C.text)),
                    ),
                  ),
                ),
              if (_typing) const Align(alignment: Alignment.centerLeft, child: _Dots()),
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final q in const ['بیت‌کوین چطوره؟', 'وضعیت پرتفوی من', 'مدیریت ریسک', 'احساس بازار', 'بهترین تحلیل'])
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Pressable(onTap: () => _send(q), child: Pill(q, C.cyan)),
                ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _t,
                  onSubmitted: _send,
                  decoration: const InputDecoration(hintText: 'سوالت رو بپرس...'),
                ),
              ),
              const SizedBox(width: 10),
              Pressable(
                onTap: () => _send(_t.text),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(gradient: C.grad, shape: BoxShape.circle),
                  child: const Icon(Icons.send_rounded, color: Colors.black),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Dots extends StatefulWidget {
  const _Dots();
  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: C.ov.o(.08), borderRadius: BorderRadius.circular(18)),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Row(mainAxisSize: MainAxisSize.min, children: [
          for (int i = 0; i < 3; i++)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: C.cyan.o(.3 + .7 * math.max(0, math.sin((_c.value - i * .15) * 2 * math.pi))),
                shape: BoxShape.circle,
              ),
            ),
        ]),
      ),
    );
  }
}

// ───────── Risk calculator ─────────
class CalcScreen extends StatefulWidget {
  const CalcScreen({super.key});
  @override
  State<CalcScreen> createState() => _CalcScreenState();
}

class _CalcScreenState extends State<CalcScreen> {
  final _cap = TextEditingController(text: '10000');
  final _entry = TextEditingController(text: '97000');
  final _stop = TextEditingController(text: '94000');
  final _target = TextEditingController(text: '106000');
  double _risk = 1.5;

  @override
  void dispose() {
    _cap.dispose();
    _entry.dispose();
    _stop.dispose();
    _target.dispose();
    super.dispose();
  }

  Widget _f(String h, TextEditingController c) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          onChanged: (_) => setState(() {}),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(labelText: h, labelStyle: TextStyle(color: C.sub)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final cap = double.tryParse(_cap.text) ?? 0;
    final e = double.tryParse(_entry.text) ?? 0;
    final st = double.tryParse(_stop.text) ?? 0;
    final tg = double.tryParse(_target.text) ?? 0;
    final riskUsd = cap * _risk / 100;
    final dist = (e - st).abs();
    final qty = dist == 0 ? 0.0 : riskUsd / dist;
    final pos = qty * e;
    final reward = qty * (tg - e).abs();
    final rr = riskUsd == 0 ? 0.0 : reward / riskUsd;
    return AppScaffold(
      title: 'ماشین‌حساب ریسک',
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _f('سرمایه (USDT)', _cap),
        _f('قیمت ورود', _entry),
        _f('حد ضرر', _stop),
        _f('هدف قیمتی', _target),
        GlassCard(
          radius: 18,
          child: Column(children: [
            Row(children: [
              Text('ریسک هر معامله', style: TextStyle(color: C.sub)),
              const Spacer(),
              Text('${_risk.toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.w900, color: C.gold)),
            ]),
            Slider(
              value: _risk,
              min: 0.5,
              max: 5,
              divisions: 9,
              activeColor: C.gold,
              inactiveColor: C.ov.o(.1),
              onChanged: (v) => setState(() => _risk = v),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        GlassCard(
          glow: rr >= 2 ? C.green : C.gold,
          child: Column(children: [
            _r('مبلغ ریسک', fmtUsd(riskUsd), C.red),
            _r('حجم پوزیشن', fmtUsd(pos), C.cyan),
            _r('تعداد واحد', fmtQty(qty), C.text),
            _r('سود احتمالی', fmtUsd(reward), C.green),
            _r('ریسک به ریوارد', '1 : ${rr.toStringAsFixed(2)}', rr >= 2 ? C.green : C.gold),
          ]),
        ),
        const SizedBox(height: 10),
        Text(rr >= 2 ? '✅ نسبت ریسک به ریوارد مناسب است.' : '⚠️ بهتر است نسبت ریوارد حداقل ۲ برابر ریسک باشد.',
            style: TextStyle(color: rr >= 2 ? C.green : C.gold, fontSize: 12.5)),
      ]),
    );
  }

  Widget _r(String k, String v, Color c) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Text(k, style: TextStyle(color: C.sub)),
          const Spacer(),
          Text(v, style: TextStyle(fontWeight: FontWeight.w900, color: c, fontSize: 15)),
        ]),
      );
}

// ───────── Profile ─────────
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return AppScaffold(
      title: 'پروفایل',
      body: ListView(padding: const EdgeInsets.all(16), children: [
        GlassCard(
          radius: 28,
          glow: C.primary,
          child: Column(children: [
            Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: C.grad,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.o(.4), width: 3),
                boxShadow: [BoxShadow(color: C.primary.o(.5), blurRadius: 24)],
              ),
              child: Text(s.userName[0], style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.black)),
            ),
            const SizedBox(height: 10),
            Text(s.userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            Text(s.email, style: TextStyle(color: C.sub)),
            const SizedBox(height: 14),
            Row(children: [
              Text('سطح ${s.level}', style: TextStyle(fontWeight: FontWeight.w900, color: C.gold)),
              const Spacer(),
              Text('${s.xp} XP', style: TextStyle(color: C.sub, fontSize: 12)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                  value: s.levelProgress, minHeight: 9, color: C.gold, backgroundColor: C.ov.o(.1)),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        Row(children: [
          _st('دارایی', fmtUsd(s.total), C.green),
          const SizedBox(width: 10),
          _st('دنبال‌شده', '${s.following.length}', C.cyan),
          const SizedBox(width: 10),
          _st('سری روزانه', '${s.streak} 🔥', C.gold),
        ]),
        const SectionTitle('دستاوردها'),
        _badges(s),
        const SectionTitle('تنظیمات'),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(children: [
            SwitchListTile(
              value: s.notif,
              onChanged: s.setNotif,
              activeColor: C.green,
              title: const Text('اعلان هشدار قیمت'),
              secondary: Icon(Icons.notifications_rounded, color: C.gold),
            ),
            SwitchListTile(
              value: s.biometric,
              onChanged: s.setBiometric,
              activeColor: C.green,
              title: const Text('ورود با اثر انگشت'),
              secondary: Icon(Icons.fingerprint_rounded, color: C.cyan),
            ),
            ListTile(
              leading: Icon(Icons.casino_rounded, color: C.pink),
              title: const Text('گردونه شانس روزانه'),
              trailing: Icon(Icons.chevron_left_rounded, color: C.sub),
              onTap: () => go(context, const RewardScreen()),
            ),
            ListTile(
              leading: Icon(Icons.smart_toy_rounded, color: C.green),
              title: const Text('دستیار هوشمند'),
              trailing: Icon(Icons.chevron_left_rounded, color: C.sub),
              onTap: () => go(context, const AiScreen()),
            ),
            ListTile(
              leading: Icon(Icons.apps_rounded, color: C.primary),
              title: const Text('همه امکانات'),
              trailing: Icon(Icons.chevron_left_rounded, color: C.sub),
              onTap: () => go(context, const MoreScreen()),
            ),
            ListTile(
              leading: Icon(Icons.support_agent_rounded, color: C.primary),
              title: const Text('تماس با ما'),
              subtitle: Text('ایمیل و وب‌سایت توسعه‌دهنده', style: TextStyle(color: C.sub, fontSize: 11.5)),
              trailing: Icon(Icons.chevron_left_rounded, color: C.sub),
              onTap: () => go(context, const ContactScreen()),
            ),
          ]),
        ),
        const SizedBox(height: 18),
        GradientButton(
          label: 'خروج از حساب',
          gradient: C.gradRed,
          icon: Icons.logout_rounded,
          onTap: () {
            s.logout();
            Navigator.of(context).pushAndRemoveUntil(
              PageRouteBuilder<void>(
                pageBuilder: (_, __, ___) => const AuthScreen(),
                transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
              ),
              (r) => false,
            );
          },
        ),
        const SizedBox(height: 14),
        Center(child: Text('Nova Trade · نسخه دمو 1.0', style: TextStyle(color: C.sub, fontSize: 11.5))),
      ]),
    );
  }

  Widget _badges(AppState s) {
    final items = <(IconData, String, bool)>[
      (Icons.shopping_bag_rounded, 'اولین خرید', s.txs.any((t) => t.type == 'buy')),
      (Icons.account_balance_rounded, 'سرمایه‌دار', s.total > 20000),
      (Icons.school_rounded, 'دانشجو', s.doneLessons.length >= 3),
      (Icons.people_rounded, 'اجتماعی', s.following.length >= 2),
      (Icons.savings_rounded, 'استیکر', s.stakes.isNotEmpty),
      (Icons.copy_all_rounded, 'کپی‌تریدر', s.copying.isNotEmpty),
      (Icons.casino_rounded, 'شانسی', s.spunToday),
      (Icons.workspace_premium_rounded, 'VIP', s.xp >= 2000),
    ];
    return Wrap(spacing: 10, runSpacing: 10, children: [
      for (final b in items)
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 76,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: b.$3 ? C.primary.o(.16) : C.ov.o(.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: b.$3 ? C.primary : C.ov.o(.08)),
            boxShadow: b.$3 ? [BoxShadow(color: C.primary.o(.35), blurRadius: 16)] : null,
          ),
          child: Column(children: [
            Icon(b.$1, color: b.$3 ? C.primary : C.sub.o(.6), size: 26),
            const SizedBox(height: 6),
            Text(b.$2,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: b.$3 ? C.text : C.sub)),
          ]),
        ),
    ]);
  }

  Widget _st(String t, String v, Color c) => Expanded(
        child: GlassCard(
          radius: 18,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(children: [
            Text(v, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: c)),
            const SizedBox(height: 2),
            Text(t, style: TextStyle(color: C.sub, fontSize: 11)),
          ]),
        ),
      );
}
