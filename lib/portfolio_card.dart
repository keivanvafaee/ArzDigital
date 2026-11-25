import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme.dart';
import 'state.dart';
import 'common.dart';
import 'charts.dart';

/// Premium "gold card" showing the total portfolio value, used on Home & Wallet.
class PortfolioCard extends StatelessWidget {
  final AppState s;
  final List<(IconData, String, VoidCallback)> actions;
  const PortfolioCard({super.key, required this.s, required this.actions});

  @override
  Widget build(BuildContext context) {
    final up = s.dayChange >= 0;
    final pnlUp = s.pnl >= 0;
    return GoldBorderCard(
      radius: 30,
      padding: EdgeInsets.zero,
      child: Stack(children: [
        const Positioned.fill(child: CustomPaint(painter: _CardArtPainter())),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const _Chip(),
              const SizedBox(width: 10),
              Icon(Icons.wifi_rounded, color: C.primary.o(.7), size: 20),
              const Spacer(),
              Icon(Icons.workspace_premium_rounded, color: C.primary, size: 18),
              const SizedBox(width: 6),
              GoldShader(
                child: const Text('NOVA GOLD',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2.5, fontSize: 12)),
              ),
            ]),
            const SizedBox(height: 18),
            Text('ارزش کل دارایی', style: TextStyle(color: C.sub, fontSize: 12.5)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: GoldShader(
                child: AnimatedCount(
                  value: s.total,
                  style: const TextStyle(
                      fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: .5),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(children: [
              ChangeChip(s.dayPct),
              const SizedBox(width: 8),
              Flexible(
                child: Text('${up ? "+" : "-"}${fmtUsd(s.dayChange.abs())} امروز',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: up ? C.green : C.red, fontWeight: FontWeight.w800, fontSize: 12.5)),
              ),
            ]),
            const SizedBox(height: 10),
            SizedBox(
              height: 58,
              width: double.infinity,
              child: Sparkline(data: s.pfSeries, color: up ? C.green : C.primary, stroke: 2.4),
            ),
            const SizedBox(height: 10),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [C.primary.o(0), C.primary.o(.5), C.primary.o(0)]),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              _stat('موجودی USDT', fmtUsd(s.usdt), C.text),
              _stat('سود/زیان کل', '${pnlUp ? "+" : "-"}${fmtUsd(s.pnl.abs())}', pnlUp ? C.green : C.red),
              _stat('دارایی‌ها', '${s.holdings.length + 1}', C.primary),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              for (final a in actions)
                Expanded(
                  child: Pressable(
                    onTap: a.$3,
                    child: Column(children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [C.primary.o(.28), C.primary.o(.06)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          border: Border.all(color: C.primary.o(.55)),
                          boxShadow: [BoxShadow(color: C.primary.o(.25), blurRadius: 14)],
                        ),
                        child: Icon(a.$1, color: C.primary, size: 24),
                      ),
                      const SizedBox(height: 6),
                      Text(a.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _stat(String t, String v, Color c) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t, style: TextStyle(color: C.sub, fontSize: 10.5)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(v, style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 13.5)),
          ),
        ]),
      );
}

class _Chip extends StatelessWidget {
  const _Chip();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 30,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE9A6), Color(0xFFC9971C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      child: CustomPaint(painter: _ChipPainter()),
    );
  }
}

class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.black.o(.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), p);
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), p);
    canvas.drawLine(Offset(size.width * 2 / 3, 0), Offset(size.width * 2 / 3, size.height), p);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(size.width / 3, size.height / 4, size.width / 3, size.height / 2),
            const Radius.circular(3)),
        p);
  }

  @override
  bool shouldRepaint(_ChipPainter o) => false;
}

class _CardArtPainter extends CustomPainter {
  const _CardArtPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final c = Offset(size.width * 0.95, size.height * 0.12);
    for (int i = 1; i <= 7; i++) {
      ring.color = C.primary.o(.10 - i * .01);
      canvas.drawCircle(c, 26.0 * i, ring);
    }
    // soft gold glow in the corner
    canvas.drawCircle(
      c,
      size.width * .55,
      Paint()
        ..shader = RadialGradient(colors: [C.primary.o(.22), C.primary.o(0)])
            .createShader(Rect.fromCircle(center: c, radius: size.width * .55)),
    );
    // fine diagonal guilloche lines
    final line = Paint()
      ..color = C.primary.o(.045)
      ..strokeWidth = 1;
    for (double x = -size.height; x < size.width; x += 14) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height * math.tan(0.5), 0), line);
    }
  }

  @override
  bool shouldRepaint(_CardArtPainter o) => false;
}
