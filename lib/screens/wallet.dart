import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../data.dart';
import '../state.dart';
import '../common.dart';
import '../charts.dart';
import 'coin_detail.dart';
import 'tools.dart';
import '../portfolio_card.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final syms = s.holdings.keys.toList()
      ..sort((a, b) => (s.holdings[b]!.qty * s.coin(b).price)
          .compareTo(s.holdings[a]!.qty * s.coin(a).price));
    final values = <double>[s.usdt, for (final k in syms) s.holdings[k]!.qty * s.coin(k).price];
    final colors = <Color>[const Color(0xFF26A17B), for (final k in syms) s.coin(k).color];
    final up = s.pnl >= 0;

    return SafeArea(
      bottom: false,
      child: ListView(
        key: const PageStorageKey('wallet'),
        padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 120),
        children: [
          Appear(
            child: Row(children: [
              Text('کیف پول من', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              SizedBox(width: 8),
              Icon(Icons.account_balance_wallet_rounded, color: C.primary),
            ]),
          ),
          const SizedBox(height: 14),
          Appear(
            delay: 80,
            child: PortfolioCard(
              s: s,
              actions: [
                (Icons.south_west_rounded, 'واریز', () => sheet<void>(context, const _DepositSheet())),
                (Icons.north_east_rounded, 'برداشت', () => sheet<void>(context, const _WithdrawSheet())),
                (Icons.swap_horiz_rounded, 'تبدیل', () => go(context, const SwapScreen())),
                (Icons.add_chart_rounded, 'خرید', () => go(context, const CoinDetailScreen(symbol: 'BTC'))),
              ],
            ),
          ),
          const SectionTitle('توزیع دارایی'),
          GlassCard(
            child: Row(children: [
              SizedBox(
                width: 150,
                height: 150,
                child: Donut(
                  values: values,
                  colors: colors,
                  center: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('دارایی', style: TextStyle(color: C.sub, fontSize: 11)),
                    Text('${syms.length + 1}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  ]),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(children: [
                  _legend('USDT', s.usdt / s.total, colors[0]),
                  for (int i = 0; i < syms.length && i < 5; i++)
                    _legend(syms[i], values[i + 1] / s.total, colors[i + 1]),
                ]),
              ),
            ]),
          ),
          const SectionTitle('کوین‌های من'),
          GlassCard(
            radius: 20,
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              const CircleAvatar(
                  radius: 20, backgroundColor: Color(0xFF26A17B), child: Text('₮', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18))),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('USDT', style: TextStyle(fontWeight: FontWeight.w900)),
                Text('تتر', style: TextStyle(color: C.sub, fontSize: 11.5)),
              ])),
              Text(fmtUsd(s.usdt), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            ]),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < syms.length; i++)
            Appear(
              delay: 40 * i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _holdRow(context, s, syms[i]),
              ),
            ),
          const SectionTitle('تاریخچه تراکنش‌ها'),
          for (final t in s.txs.take(10))
            Padding(padding: const EdgeInsets.only(bottom: 8), child: _tx(t)),
        ],
      ),
    );
  }

  Widget _act(BuildContext context, IconData i, String t, VoidCallback f) => Expanded(
        child: Pressable(
          onTap: f,
          child: Column(children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: C.ov.o(.16),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: C.ov.o(.2)),
              ),
              child: Icon(i, size: 26),
            ),
            const SizedBox(height: 6),
            Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ),
      );

  Widget _legend(String t, double frac, Color c) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
          const Spacer(),
          Text('${(frac * 100).toStringAsFixed(1)}%', style: TextStyle(color: C.sub, fontSize: 12)),
        ]),
      );

  Widget _holdRow(BuildContext context, AppState s, String sym) {
    final h = s.holdings[sym]!;
    final c = s.coin(sym);
    final val = h.qty * c.price;
    final pnl = (c.price / h.avg - 1) * 100;
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(14),
      onTap: () => go(context, CoinDetailScreen(symbol: sym)),
      child: Row(children: [
        CoinAvatar(c, size: 42),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(sym, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            Text('${fmtQty(h.qty)} ${c.symbol}', style: TextStyle(color: C.sub, fontSize: 11.5)),
          ]),
        ),
        SizedBox(width: 56, height: 28, child: Sparkline(data: c.spark, color: pnl >= 0 ? C.green : C.red)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(fmtUsd(val), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 3),
          ChangeChip(pnl),
        ]),
      ]),
    );
  }

  Widget _tx(Tx t) {
    final map = <String, (IconData, Color)>{
      'buy': (Icons.add_shopping_cart_rounded, C.green),
      'sell': (Icons.sell_rounded, C.red),
      'deposit': (Icons.south_west_rounded, C.cyan),
      'withdraw': (Icons.north_east_rounded, C.gold),
      'swap': (Icons.swap_horiz_rounded, C.primary),
      'analysis': (Icons.psychology_alt_rounded, C.pink),
      'reward': (Icons.card_giftcard_rounded, C.gold),
    };
    final m = map[t.type] ?? (Icons.receipt_rounded, C.sub);
    final plus = t.type == 'deposit' || t.type == 'sell' || t.type == 'reward';
    return GlassCard(
      radius: 18,
      blur: 6,
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: m.$2.o(.16), borderRadius: BorderRadius.circular(14)),
          child: Icon(m.$1, color: m.$2, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            Text(t.ago, style: TextStyle(color: C.sub, fontSize: 11)),
          ]),
        ),
        Text('${plus ? "+" : "-"}${fmtUsd(t.usd)}',
            style: TextStyle(color: plus ? C.green : C.text, fontWeight: FontWeight.w800, fontSize: 13)),
      ]),
    );
  }
}

class _DepositSheet extends StatefulWidget {
  const _DepositSheet();
  @override
  State<_DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends State<_DepositSheet> {
  int _net = 0;
  static const _nets = ['TRC20', 'ERC20', 'BEP20'];
  static const _addr = [
    'TXk8Qm3vNovaDemo9Hq2LpWz7YrB4cD1eF',
    '0x7A3f9c21NovaDemoBd54e0c1aE8f62D9',
    '0xB91c04aeNovaDemo5c77D2f13a98e0Cc',
  ];

  @override
  Widget build(BuildContext context) {
    final s = AppScope.read(context);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('واریز USDT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 14),
      Seg(items: _nets, index: _net, onChanged: (i) => setState(() => _net = i)),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: QrPattern(seed: _addr[_net], size: 170),
      ),
      const SizedBox(height: 14),
      GlassCard(
        radius: 16,
        padding: const EdgeInsets.all(12),
        onTap: () {
          Clipboard.setData(ClipboardData(text: _addr[_net]));
          toast(context, 'آدرس کپی شد', icon: Icons.copy_rounded, bottom: 20);
        },
        child: Row(children: [
          Expanded(
            child: Text(_addr[_net],
                textDirection: TextDirection.ltr,
                style: TextStyle(fontSize: 11.5, color: C.sub)),
          ),
          const SizedBox(width: 8),
          Icon(Icons.copy_rounded, size: 20, color: C.cyan),
        ]),
      ),
      const SizedBox(height: 8),
      Text('⚠️ این یک نسخه دمو است؛ واریز واقعی انجام نمی‌شود.',
          style: TextStyle(color: C.gold, fontSize: 11.5)),
      const SizedBox(height: 14),
      GradientButton(
        label: 'شبیه‌سازی واریز ۱,۰۰۰ USDT',
        icon: Icons.bolt_rounded,
        onTap: () {
          s.deposit(1000);
          Navigator.pop(context);
          toast(context, '۱,۰۰۰ USDT به حساب شما اضافه شد', bottom: 20);
        },
      ),
    ]);
  }
}

class _WithdrawSheet extends StatefulWidget {
  const _WithdrawSheet();
  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final _amt = TextEditingController();
  final _addr = TextEditingController();
  @override
  void dispose() {
    _amt.dispose();
    _addr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('برداشت USDT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      Text('موجودی قابل برداشت: ${fmtUsd(s.usdt)}', style: TextStyle(color: C.sub, fontSize: 12.5)),
      const SizedBox(height: 14),
      TextField(
        controller: _addr,
        textDirection: TextDirection.ltr,
        decoration: InputDecoration(hintText: 'آدرس کیف پول مقصد', prefixIcon: Icon(Icons.qr_code_2_rounded, color: C.sub)),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _amt,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textDirection: TextDirection.ltr,
        decoration: InputDecoration(
          hintText: 'مقدار',
          prefixIcon: Icon(Icons.attach_money_rounded, color: C.sub),
          suffixIcon: TextButton(
            onPressed: () => _amt.text = s.usdt.toStringAsFixed(2),
            child: Text('حداکثر', style: TextStyle(color: C.cyan)),
          ),
        ),
      ),
      const SizedBox(height: 16),
      GradientButton(
        label: 'ثبت درخواست برداشت',
        gradient: C.gradGold,
        onTap: () {
          final v = double.tryParse(_amt.text.trim()) ?? 0;
          if (_addr.text.trim().length < 8) {
            toast(context, 'آدرس معتبر نیست', color: C.red, icon: Icons.error_rounded, bottom: 20);
            return;
          }
          if (!s.withdraw(v)) {
            toast(context, 'مقدار نامعتبر یا بیشتر از موجودی', color: C.red, icon: Icons.error_rounded, bottom: 20);
            return;
          }
          Navigator.pop(context);
          toast(context, 'درخواست برداشت ثبت شد (دمو)', bottom: 20);
        },
      ),
    ]);
  }
}
