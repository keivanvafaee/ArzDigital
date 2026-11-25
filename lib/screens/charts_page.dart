import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';
import '../data.dart';
import '../state.dart';
import '../common.dart';
import '../charts.dart';
import 'coin_detail.dart';

class ChartsPage extends StatefulWidget {
  const ChartsPage({super.key});
  @override
  State<ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> {
  String _sym = 'BTC';
  final Set<String> _cmp = {'BTC', 'ETH', 'SOL'};
  int _type = 0; // 0 candles 1 line 2 compare
  int _tf = 2;
  static const _tfs = ['1H', '4H', '1D', '1W', '1M'];

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.coin(_sym);
    final col = c.change >= 0 ? C.green : C.red;
    return SafeArea(
      bottom: false,
      child: ListView(
        key: const PageStorageKey('charts'),
        padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 120),
        children: [
          Appear(
            child: Row(children: [
              Text('نمودارها', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              SizedBox(width: 8),
              Icon(Icons.stacked_line_chart_rounded, color: C.cyan),
            ]),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: s.coins.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final k = s.coins[i];
                final sel = _type == 2 ? _cmp.contains(k.symbol) : _sym == k.symbol;
                return Pressable(
                  onTap: () => setState(() {
                    if (_type == 2) {
                      if (_cmp.contains(k.symbol)) {
                        if (_cmp.length > 1) _cmp.remove(k.symbol);
                      } else if (_cmp.length < 5) {
                        _cmp.add(k.symbol);
                      }
                    } else {
                      _sym = k.symbol;
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: sel ? k.color.o(.25) : C.ov.o(.06),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: sel ? k.color : C.ov.o(.08)),
                    ),
                    child: Row(children: [
                      CoinAvatar(k, size: 24),
                      const SizedBox(width: 6),
                      Text(k.symbol,
                          style: TextStyle(
                              fontWeight: FontWeight.w800, color: sel ? C.text : C.sub)),
                    ]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Seg(
              items: const ['کندل استیک', 'خطی', 'مقایسه'],
              index: _type,
              onChanged: (i) => setState(() => _type = i)),
          const SizedBox(height: 12),
          Appear(
            key: ValueKey<int>(_type == 2 ? 1 : 0),
            child: GlassCard(
              glow: _type == 2 ? C.primary : col,
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (_type != 2)
                  Row(children: [
                    CoinAvatar(c, size: 36),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${c.symbol}/USDT',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                        FlashText(
                            value: c.price,
                            text: fmtUsd(c.price),
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 18, color: C.text)),
                      ]),
                    ),
                    ChangeChip(c.change),
                  ])
                else
                  Row(children: [
                    Icon(Icons.compare_arrows_rounded, color: C.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('مقایسه بازدهی (درصد) — تا ۵ ارز را انتخاب کنید',
                          style: TextStyle(color: C.sub, fontSize: 12)),
                    ),
                  ]),
                const SizedBox(height: 12),
                Seg(
                    items: const ['۱س', '۴س', '۱ر', '۱هفته', '۱ماه'],
                    index: _tf,
                    onChanged: (i) => setState(() => _tf = i)),
                const SizedBox(height: 14),
                if (_type == 2)
                  CompareChart(
                      coins: s.coins.where((k) => _cmp.contains(k.symbol)).toList(),
                      tf: _tfs[_tf],
                      height: 300)
                else
                  PriceChart(coin: c, tf: _tfs[_tf], candles: _type == 0, height: 300),
              ]),
            ),
          ),
          if (_type != 2) ...[
            const SectionTitle('اندیکاتورها'),
            _indicators(c),
            const SectionTitle('دفتر سفارشات زنده'),
            _orderBook(c),
            const SizedBox(height: 14),
            GradientButton(
              label: 'معامله ${c.symbol}',
              icon: Icons.swap_vert_rounded,
              onTap: () => go(context, CoinDetailScreen(symbol: c.symbol)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _indicators(Coin c) {
    final d = genCandles(c, _tfs[_tf]);
    final closes = d.map((e) => e.c).toList();
    // RSI(14)
    double g = 0, l = 0;
    for (int i = closes.length - 14; i < closes.length; i++) {
      final diff = closes[i] - closes[i - 1];
      if (diff >= 0) {
        g += diff;
      } else {
        l -= diff;
      }
    }
    final rsi = l == 0 ? 100.0 : 100 - 100 / (1 + g / l);
    // MA20
    final ma = closes.sublist(closes.length - 20).reduce((a, b) => a + b) / 20;
    // MACD (EMA12 - EMA26)
    double ema(int n) {
      final k = 2 / (n + 1);
      double e = closes.first;
      for (final v in closes) {
        e = v * k + e * (1 - k);
      }
      return e;
    }

    final macd = ema(12) - ema(26);
    String sig(bool buy, bool sell) => buy ? 'خرید' : (sell ? 'فروش' : 'خنثی');
    Color sc(String s) => s == 'خرید' ? C.green : (s == 'فروش' ? C.red : C.gold);
    final items = [
      ('RSI (14)', rsi.toStringAsFixed(1), sig(rsi < 40, rsi > 65), rsi / 100),
      ('MA 20', fmtPrice(ma), sig(c.price > ma * 1.005, c.price < ma * 0.995),
          cl(c.price / ma - 0.9, 0, 0.2) / 0.2),
      ('MACD', macd.toStringAsFixed(2), sig(macd > 0, macd < 0), macd > 0 ? 0.75 : 0.25),
    ];
    return Row(children: [
      for (int i = 0; i < items.length; i++) ...[
        if (i > 0) const SizedBox(width: 10),
        Expanded(
          child: GlassCard(
            radius: 18,
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(items[i].$1, style: TextStyle(color: C.sub, fontSize: 11.5)),
              const SizedBox(height: 4),
              Text(items[i].$2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: items[i].$4,
                  minHeight: 6,
                  color: sc(items[i].$3),
                  backgroundColor: C.ov.o(.1),
                ),
              ),
              const SizedBox(height: 8),
              Pill(items[i].$3, sc(items[i].$3)),
            ]),
          ),
        ),
      ],
    ]);
  }

  Widget _orderBook(Coin c) {
    final seed = (c.price * 100).round();
    final r = math.Random(seed);
    final asks = <(double, double)>[];
    final bids = <(double, double)>[];
    for (int i = 0; i < 6; i++) {
      asks.add((c.price * (1 + 0.0006 * (6 - i)), 0.2 + r.nextDouble() * 4));
      bids.add((c.price * (1 - 0.0006 * (i + 1)), 0.2 + r.nextDouble() * 4));
    }
    final maxQ = [...asks, ...bids].map((e) => e.$2).reduce(math.max);
    Widget row((double, double) e, Color col) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Stack(children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: e.$2 / maxQ,
                  child: Container(
                    decoration: BoxDecoration(
                        color: col.o(.16), borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(fmtPrice(e.$1),
                    style: TextStyle(color: col, fontWeight: FontWeight.w800, fontSize: 12)),
                Text(e.$2.toStringAsFixed(3),
                    style: TextStyle(color: C.sub, fontSize: 12)),
              ]),
            ),
          ]),
        );
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(children: [
            Text('خرید (Bid)', style: TextStyle(color: C.green, fontWeight: FontWeight.w800, fontSize: 12)),
            const SizedBox(height: 6),
            for (final e in bids) row(e, C.green),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(children: [
            Text('فروش (Ask)', style: TextStyle(color: C.red, fontWeight: FontWeight.w800, fontSize: 12)),
            const SizedBox(height: 6),
            for (final e in asks) row(e, C.red),
          ]),
        ),
      ]),
    );
  }
}
