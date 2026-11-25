import 'package:flutter/material.dart';
import '../theme.dart';
import '../data.dart';
import '../state.dart';
import '../common.dart';
import '../charts.dart';
import 'analysis.dart';

class CoinDetailScreen extends StatefulWidget {
  final String symbol;
  const CoinDetailScreen({super.key, required this.symbol});
  @override
  State<CoinDetailScreen> createState() => _CoinDetailScreenState();
}

class _CoinDetailScreenState extends State<CoinDetailScreen> {
  int _tf = 2;
  bool _candles = true;
  static const _tfs = ['1H', '4H', '1D', '1W', '1M'];

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.coin(widget.symbol);
    final col = c.change >= 0 ? C.green : C.red;
    final h = s.holdings[c.symbol];
    final related = s.analyses.where((a) => a.symbol == c.symbol).toList();
    final cmts = s.comments.where((m) => m.symbol == c.symbol).toList();

    return AppScaffold(
      title: '${c.name} (${c.symbol})',
      actions: [
        IconButton(
          icon: Icon(s.favorites.contains(c.symbol) ? Icons.star_rounded : Icons.star_border_rounded,
              color: s.favorites.contains(c.symbol) ? C.gold : C.sub),
          onPressed: () => s.toggleFav(c.symbol),
        ),
      ],
      bottom: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Row(children: [
            Expanded(
                child: GradientButton(
                    label: 'خرید',
                    icon: Icons.arrow_downward_rounded,
                    gradient: C.gradGreen,
                    onTap: () => showTrade(context, c.symbol, true))),
            const SizedBox(width: 12),
            Expanded(
                child: GradientButton(
                    label: 'فروش',
                    icon: Icons.arrow_upward_rounded,
                    gradient: C.gradRed,
                    onTap: () => showTrade(context, c.symbol, false))),
          ]),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        children: [
          Appear(
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              CoinAvatar(c, size: 54),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  FlashText(
                      value: c.price,
                      text: fmtUsd(c.price),
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: C.text)),
                  Row(children: [
                    ChangeChip(c.change),
                    const SizedBox(width: 8),
                    Text('رتبه #${c.rank}', style: TextStyle(color: C.sub, fontSize: 12)),
                  ]),
                ]),
              ),
              PulseDot(color: C.green),
            ]),
          ),
          const SizedBox(height: 16),
          Appear(
            delay: 100,
            child: GlassCard(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              glow: col,
              child: Column(children: [
                Row(children: [
                  Expanded(
                    child: Seg(
                        items: const ['۱س', '۴س', '۱ر', '۱هفته', '۱ماه'],
                        index: _tf,
                        onChanged: (i) => setState(() => _tf = i)),
                  ),
                  const SizedBox(width: 10),
                  Pressable(
                    onTap: () => setState(() => _candles = !_candles),
                    child: Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                          color: C.ov.o(.08), borderRadius: BorderRadius.circular(14)),
                      child: Icon(
                          _candles ? Icons.candlestick_chart_rounded : Icons.show_chart_rounded,
                          color: C.cyan),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                PriceChart(coin: c, tf: _tfs[_tf], candles: _candles),
                const SizedBox(height: 4),
                Text('برای مشاهده قیمت دقیق، روی نمودار بکشید',
                    style: TextStyle(color: C.sub, fontSize: 10.5)),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          Row(children: [
            _stat('بیشترین ۲۴س', fmtUsd(c.high24), C.green),
            const SizedBox(width: 10),
            _stat('کمترین ۲۴س', fmtUsd(c.low24), C.red),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _stat('حجم ۲۴س', '\$${fmtCompact(c.volume)}', C.cyan),
            const SizedBox(width: 10),
            _stat('ارزش بازار', '\$${fmtCompact(c.mcap)}', C.primary),
          ]),
          if (h != null) ...[
            const SectionTitle('دارایی من'),
            GlassCard(
              glow: C.primary,
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${fmtQty(h.qty)} ${c.symbol}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    Text('≈ ${fmtUsd(h.qty * c.price)}',
                        style: TextStyle(color: C.sub, fontSize: 12.5)),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  ChangeChip((c.price / h.avg - 1) * 100),
                  const SizedBox(height: 4),
                  Text('میانگین خرید ${fmtUsd(h.avg)}',
                      style: TextStyle(color: C.sub, fontSize: 11)),
                ]),
              ]),
            ),
          ],
          SectionTitle('تحلیل‌های ${c.symbol}'),
          if (related.isEmpty)
            Padding(
                padding: EdgeInsets.all(12),
                child: Text('هنوز تحلیلی ثبت نشده', style: TextStyle(color: C.sub))),
          for (final a in related)
            Padding(padding: const EdgeInsets.only(bottom: 10), child: AnalysisCard(a)),
          if (cmts.isNotEmpty) ...[
            SectionTitle('نظرات کاربران درباره ${c.symbol}'),
            for (final m in cmts)
              Padding(padding: const EdgeInsets.only(bottom: 10), child: CommentCard(m)),
          ],
        ],
      ),
    );
  }

  Widget _stat(String t, String v, Color c) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        radius: 18,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t, style: TextStyle(color: C.sub, fontSize: 11.5)),
          const SizedBox(height: 4),
          Text(v, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: c)),
        ]),
      ),
    );
  }
}

class CommentCard extends StatelessWidget {
  final Comment m;
  const CommentCard(this.m, {super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final liked = s.likedComments.contains(m.id);
    final col = m.bull ? C.green : C.red;
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [col, col.o(.4)]),
            ),
            child: Text(m.user[0], style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.user, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
              Text(m.ago, style: TextStyle(color: C.sub, fontSize: 11)),
            ]),
          ),
          if (m.symbol != null) Pill(m.symbol!, C.cyan),
          const SizedBox(width: 6),
          Pill(m.bull ? 'صعودی' : 'نزولی', col,
              icon: m.bull ? Icons.trending_up_rounded : Icons.trending_down_rounded),
        ]),
        const SizedBox(height: 10),
        Text(m.text, style: const TextStyle(fontSize: 13.5, height: 1.7)),
        const SizedBox(height: 10),
        Row(children: [
          GestureDetector(
            onTap: () => s.likeComment(m),
            child: Row(children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    key: ValueKey<bool>(liked), size: 20, color: liked ? C.pink : C.sub),
              ),
              const SizedBox(width: 5),
              Text('${m.likes}', style: TextStyle(color: C.sub, fontSize: 12.5)),
            ]),
          ),
          const SizedBox(width: 18),
          Icon(Icons.chat_bubble_outline_rounded, size: 18, color: C.sub),
          const SizedBox(width: 5),
          Text('${m.replies}', style: TextStyle(color: C.sub, fontSize: 12.5)),
        ]),
      ]),
    );
  }
}

// ───────── Trade sheet ─────────
void showTrade(BuildContext context, String symbol, bool buy) {
  sheet<void>(context, _TradeSheet(symbol: symbol, buy: buy));
}

class _TradeSheet extends StatefulWidget {
  final String symbol;
  final bool buy;
  const _TradeSheet({required this.symbol, required this.buy});
  @override
  State<_TradeSheet> createState() => _TradeSheetState();
}

class _TradeSheetState extends State<_TradeSheet> {
  late bool _buy = widget.buy;
  double _pct = 0.25;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.coin(widget.symbol);
    final holdQty = s.holdings[c.symbol]?.qty ?? 0;
    final amountUsd = _buy ? s.usdt * _pct : holdQty * c.price * _pct;
    final qty = _buy ? amountUsd * 0.999 / c.price : holdQty * _pct;
    final fee = amountUsd * 0.001;
    final col = _buy ? C.green : C.red;

    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        CoinAvatar(c, size: 40),
        const SizedBox(width: 10),
        Text(c.symbol, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const Spacer(),
        FlashText(
            value: c.price,
            text: fmtUsd(c.price),
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: C.text)),
      ]),
      const SizedBox(height: 16),
      Seg(items: const ['خرید', 'فروش'], index: _buy ? 0 : 1, onChanged: (i) => setState(() => _buy = i == 0)),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(_buy ? 'موجودی USDT' : 'موجودی ${c.symbol}', style: TextStyle(color: C.sub, fontSize: 12.5)),
        Text(_buy ? fmtUsd(s.usdt) : '${fmtQty(holdQty)} ${c.symbol}',
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ]),
      const SizedBox(height: 10),
      Text(fmtUsd(amountUsd),
          style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: col)),
      Text('≈ ${fmtQty(qty)} ${c.symbol}', style: TextStyle(color: C.sub)),
      Slider(
        value: _pct,
        min: 0,
        max: 1,
        divisions: 20,
        activeColor: col,
        inactiveColor: C.ov.o(.1),
        onChanged: (v) => setState(() => _pct = v),
      ),
      Row(children: [
        for (final p in const [0.25, 0.5, 0.75, 1.0])
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Pressable(
                onTap: () => setState(() => _pct = p),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _pct == p ? col.o(.2) : C.ov.o(.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _pct == p ? col : Colors.transparent),
                  ),
                  child: Text('${(p * 100).round()}%',
                      style: TextStyle(fontWeight: FontWeight.w800, color: _pct == p ? col : C.sub)),
                ),
              ),
            ),
          ),
      ]),
      const SizedBox(height: 14),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('کارمزد (۰.۱٪)', style: TextStyle(color: C.sub, fontSize: 12.5)),
        Text(fmtUsd(fee), style: const TextStyle(fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 16),
      GradientButton(
        label: _buy ? 'تایید خرید ${c.symbol}' : 'تایید فروش ${c.symbol}',
        gradient: _buy ? C.gradGreen : C.gradRed,
        onTap: amountUsd <= 0
            ? null
            : () {
                final ok = _buy ? s.buy(c.symbol, amountUsd) : s.sell(c.symbol, holdQty * _pct);
                if (ok) {
                  showSuccess(context, _buy ? 'خرید موفق' : 'فروش موفق',
                          '${fmtQty(qty)} ${c.symbol} ${_buy ? "به کیف پول شما اضافه شد" : "فروخته شد و به USDT تبدیل شد"}\n+۱۵ امتیاز تجربه')
                      .then((_) {
                    if (mounted) Navigator.pop(context);
                  });
                } else {
                  Navigator.pop(context);
                }
              },
      ),
    ]);
  }
}
