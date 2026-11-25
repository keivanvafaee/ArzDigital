import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'state.dart';
import 'common.dart';
import 'screens/auth.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ThemeCtl.applyChrome();
  runApp(const NovaApp());
}

class NovaApp extends StatefulWidget {
  const NovaApp({super.key});
  @override
  State<NovaApp> createState() => _NovaAppState();
}

class _NovaAppState extends State<NovaApp> {
  final AppState _state = AppState();

  @override
  void initState() {
    super.initState();
    _state.start();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeCtl.isLight,
      builder: (context, isLight, _) => MaterialApp(
        title: 'Nova Trade',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        themeAnimationDuration: Duration.zero,
        builder: (ctx, child) {
          final mq = MediaQuery.of(ctx);
          return MediaQuery(
            data: mq.copyWith(textScaler: mq.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.1)),
            child: AppScope(
              state: _state,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Material(
                  type: MaterialType.transparency,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      RepaintBoundary(
                        key: ThemeCtl.boundaryKey,
                        child: ColoredBox(
                          color: C.bg,
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 620),
                              child: child!,
                            ),
                          ),
                        ),
                      ),
                      ValueListenableBuilder<ThemeReveal?>(
                        valueListenable: ThemeCtl.reveal,
                        builder: (_, rv, __) => rv == null
                            ? const SizedBox.shrink()
                            : Positioned.fill(
                                child: IgnorePointer(
                                  child: _ThemeRevealOverlay(key: ObjectKey(rv), reveal: rv),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        home: const SplashScreen(),
      ),
    );
  }
}

/// Old-theme screenshot with a growing circular hole (golden ring on the edge) -> reveals the new theme.
class _ThemeRevealOverlay extends StatefulWidget {
  final ThemeReveal reveal;
  const _ThemeRevealOverlay({super.key, required this.reveal});
  @override
  State<_ThemeRevealOverlay> createState() => _ThemeRevealOverlayState();
}

class _ThemeRevealOverlayState extends State<_ThemeRevealOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 820));

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(() {
      if (mounted) ThemeCtl.revealDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.reveal.origin;
    return LayoutBuilder(builder: (ctx, cons) {
      final size = Size(cons.maxWidth, cons.maxHeight);
      final far = math.max(
        math.max((o - Offset.zero).distance, (o - Offset(size.width, 0)).distance),
        math.max((o - Offset(0, size.height)).distance, (o - Offset(size.width, size.height)).distance),
      );
      return AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final r = Curves.easeInOutCubic.transform(_c.value) * (far + 40);
          return Stack(fit: StackFit.expand, children: [
            ClipPath(
              clipper: _HoleClipper(o, r),
              child: RawImage(image: widget.reveal.image, fit: BoxFit.fill),
            ),
            CustomPaint(painter: _RingPainter(o, r, 1 - _c.value)),
          ]);
        },
      );
    });
  }
}

class _HoleClipper extends CustomClipper<Path> {
  final Offset c;
  final double r;
  _HoleClipper(this.c, this.r);
  @override
  Path getClip(Size size) => Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addOval(Rect.fromCircle(center: c, radius: r)),
      );
  @override
  bool shouldReclip(_HoleClipper o) => o.r != r || o.c != c;
}

class _RingPainter extends CustomPainter {
  final Offset c;
  final double r, fade;
  _RingPainter(this.c, this.r, this.fade);
  @override
  void paint(Canvas canvas, Size size) {
    if (r <= 0) return;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 + 7 * fade
        ..color = C.primary.o(.75 * fade)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 + 8 * fade),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = C.cyan.o(.9 * fade),
    );
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.r != r || o.fade != fade;
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => const AuthScreen(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      ));
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // NOTE: a Scaffold (Material) is required here, otherwise Text falls back to the
    // framework's debug style (big red text with yellow underline).
    return Aurora(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(children: [
            const Spacer(flex: 3),
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(alignment: Alignment.center, children: [
                const Positioned.fill(child: _Ripples()),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutBack,
                  builder: (_, v, child) => Transform.scale(scale: cl(v, 0.0, 1.25), child: child),
                  child: const NovaLogo(size: 104),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            const Appear(
              delay: 250,
              child: GoldShader(
                child: Text('NOVA TRADE',
                    style: TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 7, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 6),
            Appear(
              delay: 400,
              child: Text('نوا ترید', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: C.text)),
            ),
            const SizedBox(height: 10),
            Appear(
              delay: 550,
              child: Text('معامله هوشمند · آینده‌ی مالی شما',
                  style: TextStyle(color: C.sub, fontSize: 13.5, letterSpacing: .3)),
            ),
            const Spacer(flex: 3),
            SizedBox(
              width: 150,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1400),
                curve: Curves.easeInOut,
                builder: (_, v, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                      value: v, minHeight: 3, color: C.primary, backgroundColor: C.ov.o(.1)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text('نسخه دمو · 2.0', style: TextStyle(color: C.sub, fontSize: 11.5)),
            const SizedBox(height: 22),
          ]),
        ),
      ),
    );
  }
}

class _Ripples extends StatefulWidget {
  const _Ripples();
  @override
  State<_Ripples> createState() => _RipplesState();
}

class _RipplesState extends State<_Ripples> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(painter: _RipplePainter(_c.value)),
      );
}

class _RipplePainter extends CustomPainter {
  final double t;
  _RipplePainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (int i = 0; i < 3; i++) {
      final p = (t + i / 3) % 1.0;
      canvas.drawCircle(
        c,
        54 + p * 56,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = C.primary.o((1 - p) * .55),
      );
    }
  }

  @override
  bool shouldRepaint(_RipplePainter o) => o.t != t;
}
