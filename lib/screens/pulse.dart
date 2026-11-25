import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../state.dart';
import '../data.dart';
import '../common.dart';
import 'coin_detail.dart';

// ═════════════════════════ Market Pulse (نبض بازار) ═════════════════════════
// A living "mood orb": colour, glow, particles and trembling follow the fear & greed index.
// Tap the orb for a shockwave, drag the slider (or tap a preset) to morph between moods.

const List<Color> _kMoodStops = <Color>[
  Color(0xFFFF4D6D), // extreme fear
  Color(0xFFFF8A3D), // fear
  Color(0xFFF6D675), // neutral
  Color(0xFF7BE495), // greed
  Color(0xFF14D8A0), // extreme greed
];

Color _moodColor(double v) {
  final x = cl(v, 0, 100) / 100 * (_kMoodStops.length - 1);
  final i = math.min(_kMoodStops.length - 2, x.floor());
  return Color.lerp(_kMoodStops[i], _kMoodStops[i + 1], x - i)!;
}

String _moodLabel(double v) {
  if (v < 20) return 'ترس شدید';
  if (v < 40) return 'ترس';
  if (v < 60) return 'خنثی';
  if (v < 80) return 'طمع';
  return 'طمع شدید';
}

String _moodLine(double v) {
  if (v < 20) return 'بازار در وحشت است؛ فرصت‌ها اغلب همین‌جا پنهان‌اند.';
  if (v < 40) return 'احتیاط غالب است و خریداران دست نگه داشته‌اند.';
  if (v < 60) return 'بازار منتظر جرقه‌ی بعدی است.';
  if (v < 80) return 'خوش‌بینی بالا می‌رود و جریان پول فعال است.';
  return 'هیجان در اوج است؛ مدیریت ریسک را فراموش نکن.';
}

class MoodOrbScreen extends StatefulWidget {
  const MoodOrbScreen({super.key});
  @override
  State<MoodOrbScreen> createState() => _MoodOrbScreenState();
}

class _MoodOrbScreenState extends State<MoodOrbScreen> with TickerProviderStateMixin {
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  late final AnimationController _burst =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  double _mood = 72;
  int _taps = 0;

  @override
  void dispose() {
    _loop.dispose();
    _burst.dispose();
    super.dispose();
  }

  void _tap() {
    HapticFeedback.mediumImpact();
    setState(() => _taps++);
    _burst.forward(from: 0);
  }

  Widget _mini(BuildContext context, String title, Coin c) {
    final col = c.change >= 0 ? C.green : C.red;
    return GlassCard(
      glow: col,
      padding: const EdgeInsets.all(14),
      onTap: () => go(context, CoinDetailScreen(symbol: c.symbol)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: C.sub, fontSize: 11.5)),
        const SizedBox(height: 10),
        Row(children: [
          CoinAvatar(c, size: 34),
          const SizedBox(width: 8),
          Expanded(
            child: Text(c.symbol, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          ),
        ]),
        const SizedBox(height: 10),
        ChangeChip(c.change),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final sorted = [...s.coins]..sort((a, b) => b.change.compareTo(a.change));
    final best = sorted.first;
    final worst = sorted.last;
    const presets = <(String, double)>[
      ('ترس شدید', 10),
      ('ترس', 30),
      ('خنثی', 50),
      ('طمع', 72),
      ('طمع شدید', 92),
    ];

    return AppScaffold(
      title: 'نبض بازار',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 30),
        children: [
          Appear(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: _mood),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) {
                final col = _moodColor(v);
                return Column(children: [
                  SizedBox(
                    height: 340,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _tap,
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_loop, _burst]),
                        builder: (_, __) => CustomPaint(
                          size: Size.infinite,
                          painter: _OrbPainter(
                            t: _loop.value,
                            burst: _burst.value,
                            mood: v,
                            color: col,
                            light: C.light,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    _moodLabel(v),
                    style: TextStyle(
                      color: col,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      shadows: [Shadow(color: col.o(.5), blurRadius: 18)],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${v.round()} / 100', style: TextStyle(color: C.sub, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(_moodLine(v),
                        textAlign: TextAlign.center, style: TextStyle(color: C.text2, height: 1.8, fontSize: 13)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _taps == 0 ? '✨ روی گوی بزن' : '⚡ انرژی جمع‌شده: $_taps',
                    style: TextStyle(color: col.o(.9), fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ]);
              },
            ),
          ),
          const SizedBox(height: 14),
          Appear(
            delay: 120,
            child: GlassCard(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('حال‌وهوای بازار را تغییر بده', style: TextStyle(color: C.sub, fontSize: 12)),
                const SizedBox(height: 4),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    activeTrackColor: _moodColor(_mood),
                    thumbColor: _moodColor(_mood),
                    inactiveTrackColor: C.ov.o(.12),
                    overlayColor: _moodColor(_mood).o(.18),
                  ),
                  child: Slider(
                    value: _mood,
                    min: 0,
                    max: 100,
                    onChanged: (x) => setState(() => _mood = x),
                  ),
                ),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final p in presets)
                    Pressable(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _mood = p.$2);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _moodLabel(_mood) == p.$1 ? _moodColor(p.$2).o(.2) : C.ov.o(.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: _moodLabel(_mood) == p.$1 ? _moodColor(p.$2) : C.ov.o(.1)),
                        ),
                        child: Text(p.$1,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _moodLabel(_mood) == p.$1 ? _moodColor(p.$2) : C.sub,
                            )),
                      ),
                    ),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          Appear(
            delay: 200,
            child: Row(children: [
              Expanded(child: _mini(context, 'بیشترین رشد امروز', best)),
              const SizedBox(width: 12),
              Expanded(child: _mini(context, 'بیشترین افت امروز', worst)),
            ]),
          ),
          const SizedBox(height: 16),
          Appear(
            delay: 260,
            child: GradientButton(
              label: 'ثبت حال بازار',
              icon: Icons.auto_awesome_rounded,
              onTap: () => toast(
                context,
                'حال بازار روی «${_moodLabel(_mood)}» ثبت شد',
                title: 'نبض بازار',
                icon: Icons.auto_awesome_rounded,
                color: C.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'نمایش گرافیکی دمو بر پایه‌ی شاخص ترس و طمع',
            textAlign: TextAlign.center,
            style: TextStyle(color: C.sub, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

double _kick(double b) => (b <= 0 || b >= 1) ? 0.0 : math.sin(b * math.pi) * (1 - b);

class _OrbPainter extends CustomPainter {
  final double t, burst, mood;
  final Color color;
  final bool light;
  _OrbPainter({
    required this.t,
    required this.burst,
    required this.mood,
    required this.color,
    required this.light,
  });

  // angle, orbit factor, speed (whole turns per loop -> seamless), size, twinkle phase, squash
  static final List<List<double>> _dust = () {
    final r = math.Random(7);
    return List.generate(46, (_) {
      final sp = ((r.nextInt(3) + 1) * (r.nextBool() ? 1 : -1)).toDouble();
      return <double>[
        r.nextDouble() * math.pi * 2,
        1.25 + r.nextDouble() * 1.15,
        sp,
        1.0 + r.nextDouble() * 2.4,
        r.nextDouble() * math.pi * 2,
        0.55 + r.nextDouble() * 0.45,
      ];
    });
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final tau = math.pi * 2;
    // fear = the orb trembles
    final shake = mood < 30 ? (30 - mood) / 30 * 2.2 : 0.0;
    final c = size.center(Offset.zero) + Offset(math.sin(t * tau * 37) * shake, math.cos(t * tau * 29) * shake);
    final base = math.min(size.width * .27, size.height * .30);
    final r = base * (1 + 0.035 * math.sin(t * tau * 6)) * (1 + 0.10 * _kick(burst));

    // outer glow
    canvas.drawCircle(
      c,
      r * 2.3,
      Paint()
        ..shader = RadialGradient(colors: [color.o(light ? .30 : .42), color.o(0)])
            .createShader(Rect.fromCircle(center: c, radius: r * 2.3)),
    );

    // orbit rings (+ satellites drawn later)
    final sats = <Offset>[];
    for (int i = 0; i < 3; i++) {
      final dir = i.isEven ? 1.0 : -1.0;
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(t * tau * dir + i * 1.05);
      final rx = r * (1.55 + i * .22);
      final ry = r * (0.52 + i * .10);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = color.o(.38 - i * .08),
      );
      final a = t * tau * (2 + i) * dir;
      final local = Offset(math.cos(a) * rx, math.sin(a) * ry);
      // rotate the local point by the same transform to get canvas space
      final ang = t * tau * dir + i * 1.05;
      sats.add(c +
          Offset(local.dx * math.cos(ang) - local.dy * math.sin(ang),
              local.dx * math.sin(ang) + local.dy * math.cos(ang)));
      canvas.restore();
    }

    // orb body
    final rect = Rect.fromCircle(center: c, radius: r);
    final hi = Color.lerp(color, Colors.white, .62)!;
    final lo = Color.lerp(color, Colors.black, light ? .45 : .62)!;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.38, -.45),
          radius: 1.1,
          colors: [hi, color, lo],
          stops: const [0, .5, 1],
        ).createShader(rect),
    );

    // swirling light inside the orb
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));
    for (int k = 0; k < 4; k++) {
      final dir = k.isEven ? 1.0 : -1.0;
      final a = t * tau * dir * (1 + k ~/ 2) + k * 1.7;
      final off = Offset(math.cos(a) * r * .5, math.sin(a * (k.isEven ? 1 : 2)) * r * .45);
      final sc = c + off;
      final sr = r * (0.55 + 0.1 * k);
      canvas.drawCircle(
        sc,
        sr,
        Paint()
          ..shader = RadialGradient(colors: [Colors.white.o(k.isEven ? .28 : .16), Colors.white.o(0)])
              .createShader(Rect.fromCircle(center: sc, radius: sr)),
      );
    }
    final shadeC = c + Offset(r * .25, r * .55);
    canvas.drawCircle(
      shadeC,
      r * .9,
      Paint()
        ..shader = RadialGradient(colors: [Colors.black.o(.28), Colors.black.o(0)])
            .createShader(Rect.fromCircle(center: shadeC, radius: r * .9)),
    );
    canvas.restore();

    // rim + specular highlight
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.o(.35),
    );
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(-r * .38, -r * .48), width: r * .55, height: r * .30),
      Paint()
        ..color = Colors.white.o(.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // satellites
    for (final p in sats) {
      canvas.drawCircle(
        p,
        7,
        Paint()
          ..color = color.o(.75)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(p, 3, Paint()..color = Colors.white);
    }

    // floating dust
    for (final q in _dust) {
      final a = q[0] + t * tau * q[2];
      final rr = r * q[1] * (1 + 0.06 * math.sin(t * tau * 4 + q[4]));
      final p = c + Offset(math.cos(a) * rr, math.sin(a) * rr * q[5]);
      final tw = .35 + .65 * (.5 + .5 * math.sin(t * tau * 3 + q[4]));
      canvas.drawCircle(p, q[3], Paint()..color = color.o(.85 * tw));
    }

    // tap shockwave
    if (burst > 0 && burst < 1) {
      for (int i = 0; i < 3; i++) {
        final p = cl((burst - i * .12) / (1 - i * .12), 0, 1);
        if (p <= 0) continue;
        final e = Curves.easeOutCubic.transform(p);
        canvas.drawCircle(
          c,
          r * (1.05 + e * 1.7),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5 + (1 - p) * 5
            ..color = color.o((1 - p) * .65),
        );
      }
      const rays = 20;
      final e2 = Curves.easeOutCubic.transform(burst);
      for (int k = 0; k < rays; k++) {
        final a = k / rays * tau + .2;
        final r0 = r * (1.08 + e2 * .9);
        final r1 = r0 + r * .28 * (1 - burst);
        canvas.drawLine(
          c + Offset(math.cos(a) * r0, math.sin(a) * r0),
          c + Offset(math.cos(a) * r1, math.sin(a) * r1),
          Paint()
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round
            ..color = color.o((1 - burst) * .9),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_OrbPainter o) => true;
}
