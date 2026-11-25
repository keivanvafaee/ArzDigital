import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme.dart';
import 'data.dart';
import 'common.dart';

class Candle {
  double o, h, l, c, v;
  Candle(this.o, this.h, this.l, this.c, this.v);
}

List<Candle> genCandles(Coin coin, String tf, {int n = 60}) {
  int seed = coin.symbol.codeUnits.fold<int>(7, (a, b) => (a * 31 + b) & 0x7fffffff);
  seed = tf.codeUnits.fold<int>(seed, (a, b) => (a * 31 + b) & 0x7fffffff);
  final r = math.Random(seed);
  final vol = {'1H': 0.004, '4H': 0.008, '1D': 0.015, '1W': 0.03, '1M': 0.055}[tf] ?? 0.01;
  final trend = (r.nextDouble() - 0.42) * vol * 0.35;
  final list = <Candle>[];
  double p = 1.0;
  for (int i = 0; i < n; i++) {
    final o = p;
    final drift = trend + (r.nextDouble() - 0.5) * vol * 2 * coin.vol;
    final c = o * (1 + drift);
    final h = math.max(o, c) * (1 + r.nextDouble() * vol * 0.6);
    final l = math.min(o, c) * (1 - r.nextDouble() * vol * 0.6);
    list.add(Candle(o, h, l, c, 0.3 + r.nextDouble()));
    p = c;
  }
  final k = coin.price / list.last.c;
  for (final c in list) {
    c.o *= k;
    c.h *= k;
    c.l *= k;
    c.c *= k;
  }
  return list;
}

void _text(Canvas c, String s, Offset o,
    {Color? color, double size = 10, FontWeight w = FontWeight.w600, bool right = false}) {
  final tp = TextPainter(
    text: TextSpan(text: s, style: TextStyle(color: color ?? C.sub, fontSize: size, fontWeight: w)),
    textDirection: TextDirection.ltr,
  )..layout();
  c.drawParagraphLike(tp, o, right);
}

extension on Canvas {
  void drawParagraphLike(TextPainter tp, Offset o, bool right) {
    tp.paint(this, Offset(right ? o.dx - tp.width : o.dx, o.dy - tp.height / 2));
  }
}

void _dashed(Canvas c, Offset a, Offset b, Paint p, {double dash = 5, double gap = 4}) {
  final total = (b - a).distance;
  if (total == 0) return;
  final dir = (b - a) / total;
  double d = 0;
  while (d < total) {
    final e = math.min(d + dash, total);
    c.drawLine(a + dir * d, a + dir * e, p);
    d += dash + gap;
  }
}

// ───────── Candle / area chart ─────────
class PriceChart extends StatefulWidget {
  final Coin coin;
  final String tf;
  final bool candles;
  final double height;
  final List<double> levels;
  final List<Color> levelColors;
  const PriceChart({
    super.key,
    required this.coin,
    required this.tf,
    required this.candles,
    this.height = 280,
    this.levels = const [],
    this.levelColors = const [],
  });
  @override
  State<PriceChart> createState() => _PriceChartState();
}

class _PriceChartState extends State<PriceChart> with SingleTickerProviderStateMixin {
  late final AnimationController _in =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450))..forward();
  late List<Candle> _d = genCandles(widget.coin, widget.tf);
  int? _sel;

  @override
  void didUpdateWidget(PriceChart old) {
    super.didUpdateWidget(old);
    if (old.coin.symbol != widget.coin.symbol || old.tf != widget.tf) {
      _d = genCandles(widget.coin, widget.tf);
      _sel = null;
      _in.forward(from: 0);
    } else if (old.candles != widget.candles) {
      _in.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  void _pick(double dx, double w) {
    final idx = (dx / (w / _d.length)).floor();
    setState(() => _sel = math.max(0, math.min(_d.length - 1, idx)));
  }

  @override
  Widget build(BuildContext context) {
    final last = _d.last;
    final price = widget.coin.price;
    last.c = price;
    last.h = math.max(last.h, price);
    last.l = math.min(last.l, price);
    final sel = _sel == null ? null : _d[_sel!];
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(builder: (ctx, cons) {
        final w = cons.maxWidth - 54;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (d) => _pick(d.localPosition.dx, w),
          onHorizontalDragUpdate: (d) => _pick(d.localPosition.dx, w),
          onHorizontalDragEnd: (_) => setState(() => _sel = null),
          onLongPressStart: (d) => _pick(d.localPosition.dx, w),
          onLongPressMoveUpdate: (d) => _pick(d.localPosition.dx, w),
          onLongPressEnd: (_) => setState(() => _sel = null),
          child: Stack(children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _in,
                builder: (_, __) => CustomPaint(
                  painter: _ChartPainter(
                    d: _d,
                    candles: widget.candles,
                    sel: _sel,
                    t: Curves.easeOutCubic.transform(_in.value),
                    levels: widget.levels,
                    lc: widget.levelColors,
                    stamp: price,
                  ),
                ),
              ),
            ),
            if (sel != null)
              Positioned(
                top: 0,
                left: 0,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.black.o(.5), borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      'O ${fmtPrice(sel.o)}  H ${fmtPrice(sel.h)}  L ${fmtPrice(sel.l)}  C ${fmtPrice(sel.c)}',
                      style: TextStyle(fontSize: 10, color: C.text, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
          ]),
        );
      }),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<Candle> d;
  final bool candles;
  final int? sel;
  final double t;
  final List<double> levels;
  final List<Color> lc;
  final double stamp;
  _ChartPainter({
    required this.d,
    required this.candles,
    required this.sel,
    required this.t,
    required this.levels,
    required this.lc,
    required this.stamp,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const rp = 54.0;
    final w = size.width - rp;
    final h = size.height;
    final chartH = h * 0.82;
    double lo = d.map((e) => e.l).reduce(math.min);
    double hi = d.map((e) => e.h).reduce(math.max);
    for (final l in levels) {
      lo = math.min(lo, l);
      hi = math.max(hi, l);
    }
    final pad = (hi - lo) * 0.08;
    lo -= pad;
    hi += pad;
    double y(double v) => (hi - v) / (hi - lo) * chartH;

    final grid = Paint()
      ..color = C.ov.o(.06)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final yy = chartH * i / 4;
      canvas.drawLine(Offset(0, yy), Offset(w, yy), grid);
      _text(canvas, fmtPrice(hi - (hi - lo) * i / 4), Offset(w + 6, cl(yy, 6.0, chartH - 4.0)),
          size: 9.5);
    }

    final step = w / d.length;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w * t + 1, h));
    final up = d.last.c >= d.first.o;
    final maxV = d.map((e) => e.v).reduce(math.max);

    // volume
    for (int i = 0; i < d.length; i++) {
      final e = d[i];
      final col = e.c >= e.o ? C.green : C.red;
      final bh = (e.v / maxV) * (h - chartH - 6);
      canvas.drawRect(
        Rect.fromLTWH(step * i + step * 0.2, h - bh, step * 0.6, bh),
        Paint()..color = col.o(.28),
      );
    }

    if (candles) {
      for (int i = 0; i < d.length; i++) {
        final e = d[i];
        final col = e.c >= e.o ? C.green : C.red;
        final x = step * i + step / 2;
        final p = Paint()
          ..color = col
          ..strokeWidth = 1.2;
        canvas.drawLine(Offset(x, y(e.h)), Offset(x, y(e.l)), p);
        final top = y(math.max(e.o, e.c));
        final bot = y(math.min(e.o, e.c));
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(x - step * 0.32, top, x + step * 0.32, math.max(bot, top + 1.5)),
            const Radius.circular(1.5),
          ),
          Paint()..color = col,
        );
      }
    } else {
      final col = up ? C.green : C.red;
      final path = Path();
      for (int i = 0; i < d.length; i++) {
        final x = step * i + step / 2;
        final yy = y(d[i].c);
        if (i == 0) {
          path.moveTo(x, yy);
        } else {
          final px = step * (i - 1) + step / 2;
          final py = y(d[i - 1].c);
          final mx = (px + x) / 2;
          path.cubicTo(mx, py, mx, yy, x, yy);
        }
      }
      final fill = Path.from(path)
        ..lineTo(step * (d.length - 1) + step / 2, chartH)
        ..lineTo(step / 2, chartH)
        ..close();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            colors: [col.o(.35), col.o(0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(0, 0, w, chartH)),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = col
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.restore();

    // levels
    for (int i = 0; i < levels.length; i++) {
      final col = i < lc.length ? lc[i] : C.gold;
      final yy = y(levels[i]);
      _dashed(canvas, Offset(0, yy), Offset(w, yy),
          Paint()
            ..color = col.o(.9)
            ..strokeWidth = 1.3);
      _text(canvas, fmtPrice(levels[i]), Offset(w + 6, yy), color: col, w: FontWeight.w800);
    }

    // last price tag
    final lastC = d.last.c;
    final ly = cl(y(lastC), 8.0, chartH - 8.0);
    final lcol = d.last.c >= d.last.o ? C.green : C.red;
    _dashed(canvas, Offset(0, ly), Offset(w, ly), Paint()
      ..color = lcol.o(.7)
      ..strokeWidth = 1);
    final tag = RRect.fromRectAndRadius(
        Rect.fromLTWH(w + 2, ly - 8, rp - 2, 16), const Radius.circular(5));
    canvas.drawRRect(tag, Paint()..color = lcol);
    _text(canvas, fmtPrice(lastC), Offset(w + 5, ly), color: Colors.white, size: 9, w: FontWeight.w800);

    // crosshair
    if (sel != null) {
      final e = d[sel!];
      final x = step * sel! + step / 2;
      final yy = y(e.c);
      final p = Paint()
        ..color = Colors.white.o(.5)
        ..strokeWidth = 1;
      _dashed(canvas, Offset(x, 0), Offset(x, h), p);
      _dashed(canvas, Offset(0, yy), Offset(w, yy), p);
      canvas.drawCircle(Offset(x, yy), 5, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(x, yy), 9, Paint()..color = C.ov.o(.2));
    }
  }

  @override
  bool shouldRepaint(_ChartPainter o) => true;
}

// ───────── Multi-line compare chart ─────────
class CompareChart extends StatefulWidget {
  final List<Coin> coins;
  final String tf;
  final double height;
  const CompareChart({super.key, required this.coins, required this.tf, this.height = 260});
  @override
  State<CompareChart> createState() => _CompareChartState();
}

class _CompareChartState extends State<CompareChart> with SingleTickerProviderStateMixin {
  late final AnimationController _in =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
  @override
  void didUpdateWidget(CompareChart old) {
    super.didUpdateWidget(old);
    if (old.tf != widget.tf || old.coins.length != widget.coins.length) _in.forward(from: 0);
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final series = <List<double>>[];
    for (final c in widget.coins) {
      final cs = genCandles(c, widget.tf);
      series.add(cs.map((e) => (e.c / cs.first.o - 1) * 100).toList());
    }
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _in,
        builder: (_, __) => CustomPaint(
          painter: _MultiPainter(
            series,
            widget.coins.map((e) => e.color).toList(),
            widget.coins.map((e) => e.symbol).toList(),
            Curves.easeOutCubic.transform(_in.value),
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _MultiPainter extends CustomPainter {
  final List<List<double>> s;
  final List<Color> cols;
  final List<String> names;
  final double t;
  _MultiPainter(this.s, this.cols, this.names, this.t);
  @override
  void paint(Canvas canvas, Size size) {
    if (s.isEmpty) return;
    const rp = 58.0;
    final w = size.width - rp;
    final h = size.height;
    double lo = 0, hi = 0;
    for (final l in s) {
      for (final v in l) {
        lo = math.min(lo, v);
        hi = math.max(hi, v);
      }
    }
    final pad = (hi - lo) * 0.1 + 0.5;
    lo -= pad;
    hi += pad;
    double y(double v) => (hi - v) / (hi - lo) * h;
    final grid = Paint()
      ..color = C.ov.o(.06)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final yy = h * i / 4;
      canvas.drawLine(Offset(0, yy), Offset(w, yy), grid);
      _text(canvas, '${(hi - (hi - lo) * i / 4).toStringAsFixed(1)}%',
          Offset(w + 6, cl(yy, 6.0, h - 6.0)), size: 9.5);
    }
    _dashed(canvas, Offset(0, y(0)), Offset(w, y(0)), Paint()
      ..color = Colors.white.o(.3)
      ..strokeWidth = 1);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w * t + 1, h));
    for (int k = 0; k < s.length; k++) {
      final l = s[k];
      final step = w / (l.length - 1);
      final path = Path();
      for (int i = 0; i < l.length; i++) {
        final x = step * i;
        if (i == 0) {
          path.moveTo(x, y(l[i]));
        } else {
          final px = step * (i - 1);
          final mx = (px + x) / 2;
          path.cubicTo(mx, y(l[i - 1]), mx, y(l[i]), x, y(l[i]));
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = cols[k]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.restore();
    for (int k = 0; k < s.length; k++) {
      _text(canvas, names[k], Offset(w + 6, cl(y(s[k].last), 8.0, h - 8.0)),
          color: cols[k], w: FontWeight.w800, size: 10);
    }
  }

  @override
  bool shouldRepaint(_MultiPainter o) => true;
}

// ───────── Sparkline ─────────
class Sparkline extends StatelessWidget {
  final List<double> data;
  final Color color;
  final bool fill;
  final double stroke;
  const Sparkline({super.key, required this.data, required this.color, this.fill = true, this.stroke = 2});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _SparkPainter(data, color, fill, stroke), size: Size.infinite);
}

class _SparkPainter extends CustomPainter {
  final List<double> d;
  final Color col;
  final bool fill;
  final double stroke;
  _SparkPainter(this.d, this.col, this.fill, this.stroke);
  @override
  void paint(Canvas canvas, Size size) {
    if (d.length < 2) return;
    final lo = d.reduce(math.min), hi = d.reduce(math.max);
    final range = (hi - lo) == 0 ? 1.0 : hi - lo;
    final step = size.width / (d.length - 1);
    double y(double v) => size.height - 3 - (v - lo) / range * (size.height - 6);
    final path = Path()..moveTo(0, y(d[0]));
    for (int i = 1; i < d.length; i++) {
      final px = step * (i - 1), x = step * i;
      final mx = (px + x) / 2;
      path.cubicTo(mx, y(d[i - 1]), mx, y(d[i]), x, y(d[i]));
    }
    if (fill) {
      final f = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        f,
        Paint()
          ..shader = LinearGradient(
            colors: [col.o(.3), col.o(0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Offset.zero & size),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = col
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SparkPainter o) => true;
}

// ───────── Donut ─────────
class Donut extends StatelessWidget {
  final List<double> values;
  final List<Color> colors;
  final double stroke;
  final Widget? center;
  const Donut({super.key, required this.values, required this.colors, this.stroke = 18, this.center});
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
      builder: (_, t, __) => CustomPaint(
        painter: _DonutPainter(values, colors, stroke, t),
        child: Center(child: center),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> v;
  final List<Color> cols;
  final double stroke, t;
  _DonutPainter(this.v, this.cols, this.stroke, this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final total = v.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: math.min(size.width, size.height) / 2 - stroke / 2,
    );
    double start = -math.pi / 2;
    for (int i = 0; i < v.length; i++) {
      final sweep = v[i] / total * 2 * math.pi * t;
      final s = sweep - 0.07;
      if (s > 0) {
        canvas.drawArc(
          rect,
          start + 0.035,
          s,
          false,
          Paint()
            ..color = cols[i % cols.length]
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..strokeCap = StrokeCap.round,
        );
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter o) => o.t != t || o.v != v;
}

// ───────── Gauge (Fear & Greed) ─────────
class Gauge extends StatelessWidget {
  final double value; // 0..100
  const Gauge({super.key, required this.value});
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => CustomPaint(painter: _GaugePainter(v), size: Size.infinite),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double v;
  _GaugePainter(this.v);
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height - 6);
    final r = math.min(size.width / 2, size.height) - 10;
    final rect = Rect.fromCircle(center: c, radius: r);
    final cols = [C.red, const Color(0xFFFF8A3D), C.gold, const Color(0xFFA3E635), C.green];
    for (int i = 0; i < 5; i++) {
      canvas.drawArc(
        rect,
        math.pi + i * math.pi / 5 + 0.03,
        math.pi / 5 - 0.06,
        false,
        Paint()
          ..color = cols[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round,
      );
    }
    final ang = math.pi + (cl(v, 0.0, 100.0) / 100) * math.pi;
    final tip = c + Offset(math.cos(ang), math.sin(ang)) * (r - 22);
    canvas.drawLine(
        c, tip,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(c, 7, Paint()..color = Colors.white);
    canvas.drawCircle(c, 12, Paint()..color = C.ov.o(.2));
  }

  @override
  bool shouldRepaint(_GaugePainter o) => o.v != v;
}

// ───────── QR-like pattern ─────────
class QrPattern extends StatelessWidget {
  final String seed;
  final double size;
  const QrPattern({super.key, required this.seed, this.size = 170});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size), painter: _QrPainter(seed));
}

class _QrPainter extends CustomPainter {
  final String seed;
  _QrPainter(this.seed);
  @override
  void paint(Canvas canvas, Size size) {
    const n = 25;
    final m = size.width / n;
    final r = math.Random(seed.codeUnits.fold<int>(3, (a, b) => (a * 31 + b) & 0x7fffffff));
    final p = Paint()..color = Colors.black;
    bool finder(int x, int y) {
      bool inBox(int ox, int oy) => x >= ox && x < ox + 7 && y >= oy && y < oy + 7;
      return inBox(0, 0) || inBox(n - 7, 0) || inBox(0, n - 7);
    }

    for (int x = 0; x < n; x++) {
      for (int y = 0; y < n; y++) {
        if (finder(x, y)) continue;
        if (r.nextDouble() > 0.52) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(x * m, y * m, m * 0.92, m * 0.92), Radius.circular(m * .2)),
            p,
          );
        }
      }
    }
    void box(int ox, int oy) {
      canvas.drawRect(Rect.fromLTWH(ox * m, oy * m, 7 * m, 7 * m), p);
      canvas.drawRect(Rect.fromLTWH((ox + 1) * m, (oy + 1) * m, 5 * m, 5 * m),
          Paint()..color = Colors.white);
      canvas.drawRect(Rect.fromLTWH((ox + 2) * m, (oy + 2) * m, 3 * m, 3 * m), p);
    }

    box(0, 0);
    box(n - 7, 0);
    box(0, n - 7);
  }

  @override
  bool shouldRepaint(_QrPainter o) => false;
}
