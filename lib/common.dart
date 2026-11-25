import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme.dart';
import 'data.dart';

// ───────── formatters ─────────
String commas(String s) {
  final parts = s.split('.');
  final ip = parts[0];
  final b = StringBuffer();
  for (int i = 0; i < ip.length; i++) {
    final rem = ip.length - i;
    b.write(ip[i]);
    if (rem > 1 && rem % 3 == 1 && ip[i] != '-') b.write(',');
  }
  return parts.length > 1 ? '$b.${parts[1]}' : '$b';
}

String fmtPrice(double v) {
  final a = v.abs();
  if (a >= 1000) return commas(v.toStringAsFixed(2));
  if (a >= 1) return v.toStringAsFixed(2);
  if (a >= 0.01) return v.toStringAsFixed(4);
  return v.toStringAsFixed(6);
}

String fmtUsd(double v) => '\$${fmtPrice(v)}';

String fmtCompact(double v) {
  if (v >= 1e12) return '${(v / 1e12).toStringAsFixed(2)}T';
  if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(2)}B';
  if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(2)}M';
  if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
  return v.toStringAsFixed(2);
}

String fmtQty(double v) {
  if (v >= 1000) return commas(v.toStringAsFixed(2));
  if (v >= 1) return v.toStringAsFixed(4);
  return v.toStringAsFixed(6);
}

String fmtPct(double v) => '${v >= 0 ? "+" : ""}${v.toStringAsFixed(2)}%';

// ───────── navigation / toast ─────────
void go(BuildContext c, Widget w) {
  Navigator.of(c).push(PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (_, __, ___) => w,
    transitionsBuilder: (_, a, __, child) => FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ),
  ));
}

_NovaToastState? _activeToast;

String _toastTitle(Color c) {
  if (c == C.green) return 'انجام شد';
  if (c == C.red) return 'خطا';
  if (c == C.gold) return 'اعلان';
  return 'پیام';
}

/// Beautiful floating notification banner (slides from the top, glow, auto progress bar,
/// swipe up / sideways or tap to dismiss). Signature kept compatible with the old SnackBar toast.
void toast(BuildContext c, String msg,
    {Color? color,
    IconData icon = Icons.check_circle_rounded,
    double bottom = 100,
    String? title}) {
  final col = color ?? C.green;
  final overlay = Overlay.maybeOf(c, rootOverlay: true);
  if (overlay == null) return;
  _activeToast?.dismissNow();
  late OverlayEntry entry;
  bool removed = false;
  entry = OverlayEntry(
    builder: (_) => _NovaToast(
      title: title ?? _toastTitle(col),
      msg: msg,
      color: col,
      icon: icon,
      onDone: () {
        if (removed) return;
        removed = true;
        entry.remove();
      },
    ),
  );
  overlay.insert(entry);
}

class _NovaToast extends StatefulWidget {
  final String title, msg;
  final Color color;
  final IconData icon;
  final VoidCallback onDone;
  const _NovaToast(
      {required this.title, required this.msg, required this.color, required this.icon, required this.onDone});
  @override
  State<_NovaToast> createState() => _NovaToastState();
}

class _NovaToastState extends State<_NovaToast> with TickerProviderStateMixin {
  late final AnimationController _in =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late final AnimationController _life =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3600));
  late final AnimationController _glow =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
  bool _closing = false;
  double _drag = 0;

  @override
  void initState() {
    super.initState();
    _activeToast = this;
    HapticFeedback.selectionClick();
    _in.forward();
    _life.addStatusListener((s) {
      if (s == AnimationStatus.completed) _dismiss();
    });
    _life.forward();
  }

  @override
  void dispose() {
    if (identical(_activeToast, this)) _activeToast = null;
    _in.dispose();
    _life.dispose();
    _glow.dispose();
    super.dispose();
  }

  void dismissNow() {
    if (_closing) return;
    _closing = true;
    widget.onDone();
  }

  Future<void> _dismiss() async {
    if (_closing || !mounted) return;
    _closing = true;
    _life.stop();
    try {
      await _in.animateBack(0, duration: const Duration(milliseconds: 260), curve: Curves.easeIn);
    } catch (_) {}
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final col = widget.color;
    final top = MediaQuery.of(context).padding.top + 10;
    final slide = CurvedAnimation(parent: _in, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
    return Positioned(
      top: top,
      left: 14,
      right: 14,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, -1.6), end: Offset.zero).animate(slide),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _in, curve: const Interval(0, .6, curve: Curves.easeOut)),
          child: Transform.translate(
            offset: Offset(0, math.min(0.0, _drag)),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _dismiss,
              onVerticalDragUpdate: (d) => setState(() => _drag += d.delta.dy),
              onVerticalDragEnd: (d) {
                if (_drag < -24 || (d.primaryVelocity ?? 0) < -250) {
                  _dismiss();
                } else {
                  setState(() => _drag = 0);
                }
              },
              onHorizontalDragEnd: (d) {
                if ((d.primaryVelocity ?? 0).abs() > 350) _dismiss();
              },
              child: Material(
                type: MaterialType.transparency,
                child: AnimatedBuilder(
                  animation: _glow,
                  builder: (_, child) => Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: col.o((C.light ? .22 : .30) + .14 * _glow.value),
                            blurRadius: 24 + 10 * _glow.value,
                            spreadRadius: -4,
                            offset: const Offset(0, 8)),
                        BoxShadow(color: Colors.black.o(C.light ? .08 : .35), blurRadius: 14, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: child,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(1.2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: [col.o(.9), col.o(.18), col.o(.55)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22.8),
                      child: Stack(children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(14, 13, 14, 17),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [C.glassA, Color.alphaBlend(col.o(C.light ? .10 : .14), C.glassB)],
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                            ),
                          ),
                          child: Row(children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 750),
                              curve: Curves.elasticOut,
                              builder: (_, v, child) => Transform.scale(scale: cl(v, 0.0, 1.4), child: child),
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [col, Color.lerp(col, Colors.black, .35)!],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [BoxShadow(color: col.o(.55), blurRadius: 14)],
                                ),
                                child: Icon(widget.icon, color: onGrad(LinearGradient(colors: [col, col])), size: 24),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(widget.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: col, fontWeight: FontWeight.w900, fontSize: 13.5)),
                                  const SizedBox(height: 2),
                                  Text(widget.msg,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: C.text, fontSize: 12.8, height: 1.55)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.keyboard_arrow_up_rounded, color: C.sub.o(.7), size: 20),
                          ]),
                        ),
                        // countdown line
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 3.5,
                          child: AnimatedBuilder(
                            animation: _life,
                            builder: (_, __) => Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: FractionallySizedBox(
                                widthFactor: cl(1 - _life.value, 0.0, 1.0),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [col, col.o(.35)]),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ───────── background ─────────
class Aurora extends StatefulWidget {
  final Widget child;
  const Aurora({super.key, required this.child});
  @override
  State<Aurora> createState() => _AuroraState();
}

class _AuroraState extends State<Aurora> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned.fill(child: ColoredBox(color: C.bg)),
      Positioned.fill(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) => CustomPaint(painter: _AuroraPainter(_c.value)),
          ),
        ),
      ),
      Positioned.fill(child: widget.child),
    ]);
  }
}

class _AuroraPainter extends CustomPainter {
  final double t;
  _AuroraPainter(this.t);

  static final List<List<double>> _p = () {
    final r = math.Random(42);
    return List.generate(18, (_) => [r.nextDouble(), r.nextDouble(), 0.4 + r.nextDouble() * 1.2, 0.8 + r.nextDouble() * 2.2, r.nextDouble() * 6.28]);
  }();

  @override
  void paint(Canvas canvas, Size s) {
    void blob(Color c, double fx, double fy, double r, double ph, double a) {
      final ang = t * 2 * math.pi + ph;
      final center = Offset(
          s.width * (fx + 0.12 * math.sin(ang)), s.height * (fy + 0.07 * math.cos(ang * 1.3)));
      final p = Paint()
        ..shader = RadialGradient(colors: [c.o(a), c.o(0)])
            .createShader(Rect.fromCircle(center: center, radius: r));
      canvas.drawCircle(center, r, p);
    }

    final k = C.light ? 0.55 : 1.0;
    blob(C.primary, 0.12, 0.06, s.width * 0.95, 0, .30 * k);
    blob(C.light ? const Color(0xFFE8B24A) : const Color(0xFFB8741A), 1.0, 0.42, s.width * 0.8, 2, .26 * k);
    blob(C.light ? const Color(0xFFD9A441) : const Color(0xFF8A6508), 0.1, 0.92, s.width * 0.95, 4, .30 * k);
    // floating gold dust
    for (final q in _p) {
      final y = ((q[1] - t * q[2] * 0.6) % 1.0 + 1.0) % 1.0;
      final x = q[0] + 0.02 * math.sin(t * 6.28 * 2 + q[4]);
      final tw = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * 6.28 * 3 + q[4]));
      canvas.drawCircle(Offset(x * s.width, y * s.height), q[3],
          Paint()..color = C.primary.o(.55 * tw));
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter o) => o.t != t;
}

class AppScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? bottom;
  const AppScaffold({super.key, this.title, required this.body, this.actions, this.bottom});

  @override
  Widget build(BuildContext context) {
    return Aurora(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: title == null
            ? null
            : AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                surfaceTintColor: Colors.transparent,
                centerTitle: true,
                title: Text(title!,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                actions: actions,
              ),
        body: SafeArea(top: false, child: body),
        bottomNavigationBar: bottom,
      ),
    );
  }
}

// ───────── building blocks ─────────
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const Pressable({super.key, required this.child, this.onTap});
  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 70),
        child: widget.child,
      ),
    );
  }
}

LinearGradient get _kGlassGradient => LinearGradient(
      colors: [C.glassA, C.glassB],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final VoidCallback? onTap;
  final Color? glow;
  final Gradient? gradient;
  final double blur;
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.onTap,
    this.glow,
    this.gradient,
    this.blur = 12,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    Widget card = Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: br,
        gradient: LinearGradient(
          colors: [C.primary.o(.55), C.ov.o(.05), C.primary.o(.16)],
          stops: const [0, .5, 1],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: glow == null
            ? [BoxShadow(color: Colors.black.o(C.light ? .09 : .3), blurRadius: 10, offset: const Offset(0, 4))]
            : [BoxShadow(color: glow!.o(.22), blurRadius: 30, spreadRadius: -6)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(math.max(0, radius - 1)),
        // NOTE: BackdropFilter removed on purpose - it re-blurred the animated
        // background for every card on every frame. A denser gradient looks the same.
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: gradient ?? _kGlassGradient,
          ),
          child: child,
        ),
      ),
    );
    if (onTap != null) card = Pressable(onTap: onTap, child: card);
    return card;
  }
}

class Appear extends StatefulWidget {
  final Widget child;
  final int delay;
  const Appear({super.key, required this.child, this.delay = 0});
  @override
  State<Appear> createState() => _AppearState();
}

class _AppearState extends State<Appear> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
  Timer? _t;
  @override
  void initState() {
    super.initState();
    final d = (widget.delay * 0.35).round();
    if (d <= 0) {
      _c.forward();
    } else {
      _t = Timer(Duration(milliseconds: d), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
        child: widget.child,
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Gradient gradient;
  final bool loading;
  final double height;
  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.gradient = C.grad,
    this.loading = false,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final first = gradient.colors.first;
    final disabled = onTap == null && !loading;
    final fg = disabled ? C.sub : onGrad(gradient);
    final r = BorderRadius.circular(height / 2.8);
    Widget inner = loading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: fg))
        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: fg),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ]);
    Widget box = Container(
      height: height,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        gradient: disabled ? null : gradient,
        color: disabled ? C.ov.o(.08) : null,
        borderRadius: r,
        boxShadow: disabled
            ? null
            : [BoxShadow(color: first.o(.4), blurRadius: 22, offset: const Offset(0, 8))],
      ),
      child: inner,
    );
    if (!disabled) {
      box = Stack(children: [
        box,
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: r,
              child: Stack(children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: height * .5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white.o(.30), C.ov.o(0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                const Positioned.fill(child: ShineSweep()),
              ]),
            ),
          ),
        ),
      ]);
    }
    return Pressable(onTap: loading ? null : onTap, child: box);
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionTitle(this.title, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 26, 2, 14),
      child: Row(children: [
        Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              gradient: C.grad,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [BoxShadow(color: C.primary.o(.7), blurRadius: 8)],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [C.primary.o(.55), C.primary.o(0)],
                begin: AlignmentDirectional.centerStart,
                end: AlignmentDirectional.centerEnd,
              ),
            ),
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ]),
    );
  }
}

class Seg extends StatelessWidget {
  final List<String> items;
  final int index;
  final ValueChanged<int> onChanged;
  final double fontSize;
  const Seg({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
    this.fontSize = 12.5,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: C.ov.o(.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.ov.o(.06)),
      ),
      child: Row(children: [
        for (int i = 0; i < items.length; i++)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: i == index ? C.grad : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: i == index
                      ? [BoxShadow(color: C.primary.o(.35), blurRadius: 14)]
                      : null,
                ),
                child: Text(items[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        color: i == index ? Colors.black : C.sub)),
              ),
            ),
          ),
      ]),
    );
  }
}

class CoinAvatar extends StatelessWidget {
  final Coin coin;
  final double size;
  const CoinAvatar(this.coin, {super.key, this.size = 40});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [coin.color, Color.lerp(coin.color, Colors.black, .45)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: C.ov.o(.22), width: 1.4),
        boxShadow: [BoxShadow(color: coin.color.o(.45), blurRadius: size * .4, spreadRadius: -2)],
      ),
      child: Text(coin.glyph,
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w900, fontSize: size * .46)),
    );
  }
}

class VerifiedBadge extends StatelessWidget {
  final double size;
  const VerifiedBadge({super.key, this.size = 18});
  @override
  Widget build(BuildContext context) => Icon(Icons.verified_rounded,
      color: C.blue, size: size, shadows: [Shadow(color: C.blue.o(.7), blurRadius: 8)]);
}

class AnalystAvatar extends StatelessWidget {
  final Analyst a;
  final double size;
  const AnalystAvatar(this.a, {super.key, this.size = 48});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
                colors: [a.c1, a.c2], begin: Alignment.topLeft, end: Alignment.bottomRight),
            border: Border.all(color: Colors.white.o(.25), width: 2),
            boxShadow: [BoxShadow(color: a.c1.o(.4), blurRadius: 14)],
          ),
          child: Text(a.name[0],
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w900, fontSize: size * .42)),
        ),
        if (a.verified)
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(color: C.bg, shape: BoxShape.circle),
              child: VerifiedBadge(size: size * .36),
            ),
          ),
      ]),
    );
  }
}

class RatingBadge extends StatelessWidget {
  final double rating;
  final int? reviews;
  const RatingBadge(this.rating, {super.key, this.reviews});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.star_rounded, color: C.gold, size: 16),
      const SizedBox(width: 3),
      Text(rating.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
      if (reviews != null)
        Text(' ($reviews)', style: TextStyle(color: C.sub, fontSize: 11)),
    ]);
  }
}

class ChangeChip extends StatelessWidget {
  final double v;
  const ChangeChip(this.v, {super.key});
  @override
  Widget build(BuildContext context) {
    final up = v >= 0;
    final col = up ? C.green : C.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: col.o(.14), borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(up ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
            color: col, size: 18),
        Text('${v.abs().toStringAsFixed(2)}%',
            style: TextStyle(color: col, fontWeight: FontWeight.w800, fontSize: 12)),
      ]),
    );
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const Pill(this.text, this.color, {super.key, this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.o(.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.o(.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 4)],
        Text(text,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class PulseDot extends StatefulWidget {
  final Color? color;
  const PulseDot({super.key, this.color});
  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
        ..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: widget.color ?? C.red,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: (widget.color ?? C.red).o(.3 + .5 * _c.value), blurRadius: 4 + 8 * _c.value)
          ],
        ),
      ),
    );
  }
}

/// Text whose colour flashes green / red when the number changes.
class FlashText extends StatefulWidget {
  final double value;
  final String text;
  final TextStyle style;
  const FlashText({super.key, required this.value, required this.text, required this.style});
  @override
  State<FlashText> createState() => _FlashTextState();
}

class _FlashTextState extends State<FlashText> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..value = 1;
  Color _flash = C.green;
  @override
  void didUpdateWidget(FlashText old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _flash = widget.value >= old.value ? C.green : C.red;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Text(
        widget.text,
        style: widget.style.copyWith(
            color: Color.lerp(_flash, widget.style.color ?? C.text, Curves.easeOut.transform(_c.value))),
      ),
    );
  }
}

class AnimatedCount extends StatelessWidget {
  final double value;
  final String prefix;
  final int decimals;
  final TextStyle style;
  const AnimatedCount({
    super.key,
    required this.value,
    required this.style,
    this.prefix = '\$',
    this.decimals = 2,
  });
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) =>
          Text('$prefix${commas(v.toStringAsFixed(decimals))}', style: style),
    );
  }
}

class IconBox extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final double size;
  const IconBox(this.icon, {super.key, this.gradient = C.grad, this.size = 46});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(size * .34),
        boxShadow: [BoxShadow(color: gradient.colors.first.o(.4), blurRadius: 14)],
      ),
      child: Icon(icon, color: onGrad(gradient), size: size * .5),
    );
  }
}

Future<void> showSuccess(BuildContext context, String title, String sub) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      backgroundColor: Colors.transparent,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutBack,
        builder: (_, v, child) => Transform.scale(scale: cl(v, 0.0, 1.2), child: child),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: C.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: C.green.o(.4)),
            boxShadow: [BoxShadow(color: C.green.o(.25), blurRadius: 40)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(width: 0, height: 0, child: ConfettiBurst()),
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(gradient: C.gradGreen, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.black, size: 46),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(sub,
                textAlign: TextAlign.center,
                style: TextStyle(color: C.sub, fontSize: 13, height: 1.6)),
            const SizedBox(height: 18),
            GradientButton(label: 'عالیه', onTap: () => Navigator.pop(ctx)),
          ]),
        ),
      ),
    ),
  );
}

Future<T?> sheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: C.sheet,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: C.ov.o(.08)),
        ),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.92),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: C.ov.o(.2), borderRadius: BorderRadius.circular(4))),
              child,
            ]),
          ),
        ),
      ),
    ),
  );
}


// ───────── URL helper ─────────
Future<void> openUrl(BuildContext context, Uri uri, {String? copyFallback}) async {
  bool ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok && context.mounted) {
    await Clipboard.setData(ClipboardData(text: copyFallback ?? uri.toString()));
    if (context.mounted) {
      toast(context, 'باز نشد؛ لینک کپی شد', color: C.gold, icon: Icons.copy_rounded, bottom: 20);
    }
  }
}

// ───────── Shine sweep (animated light across a surface) ─────────
class ShineSweep extends StatefulWidget {
  final Duration period;
  const ShineSweep({super.key, this.period = const Duration(milliseconds: 3200)});
  @override
  State<ShineSweep> createState() => _ShineSweepState();
}

class _ShineSweepState extends State<ShineSweep> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period)..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(painter: _ShinePainter(_c.value), size: Size.infinite),
        ),
      );
}

class _ShinePainter extends CustomPainter {
  final double t;
  _ShinePainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final p = t * 1.7 - 0.35; // pause at the end of each cycle
    if (p > 1.2) return;
    final skew = size.height * 0.5;
    final x = p * (size.width + skew * 2) - skew;
    const w = 70.0;
    final path = Path()
      ..moveTo(x + skew, 0)
      ..lineTo(x + skew + w, 0)
      ..lineTo(x + w, size.height)
      ..lineTo(x, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [C.ov.o(0), Colors.white.o(.28), C.ov.o(0)],
        ).createShader(Rect.fromLTWH(x, 0, w + skew, size.height)),
    );
  }

  @override
  bool shouldRepaint(_ShinePainter o) => o.t != t;
}

// ───────── Gold loader ─────────
class GoldLoader extends StatefulWidget {
  final String? label;
  final double size;
  const GoldLoader({super.key, this.label, this.size = 64});
  @override
  State<GoldLoader> createState() => _GoldLoaderState();
}

class _GoldLoaderState extends State<GoldLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final pulse = 0.88 + 0.12 * math.sin(_c.value * 2 * math.pi * 2);
        final dots = '.' * (1 + (_c.value * 3).floor() % 3);
        return Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(alignment: Alignment.center, children: [
              CustomPaint(size: Size.square(widget.size), painter: _LoaderPainter(_c.value)),
              Transform.scale(
                scale: pulse,
                child: Icon(Icons.workspace_premium_rounded,
                    color: C.primary,
                    size: widget.size * .38,
                    shadows: [Shadow(color: C.primary.o(.8), blurRadius: 14)]),
              ),
            ]),
          ),
          if (widget.label != null) ...[
            const SizedBox(height: 12),
            Text('${widget.label}$dots',
                style: TextStyle(
                    color: Color.lerp(C.sub, C.primary, .5 + .5 * math.sin(_c.value * 2 * math.pi)),
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ],
        ]);
      },
    );
  }
}

class _LoaderPainter extends CustomPainter {
  final double t;
  _LoaderPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 5;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = C.ov.o(.08));
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(t * 2 * math.pi);
    canvas.translate(-c.dx, -c.dy);
    canvas.drawArc(
      rect,
      0,
      4.4,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(colors: [C.primary.o(0), C.primary, C.cyan], stops: const [0, .7, 1])
            .createShader(rect),
    );
    canvas.restore();
    for (int i = 0; i < 3; i++) {
      final a = -t * 2 * math.pi * 1.6 + i * 2.094;
      final o = c + Offset(math.cos(a), math.sin(a)) * (r - 11);
      canvas.drawCircle(o, 3 - i * .5, Paint()..color = C.gold.o(.9 - i * .25));
    }
  }

  @override
  bool shouldRepaint(_LoaderPainter o) => o.t != t;
}

// ───────── Skeleton (shimmer placeholder) ─────────
class _Slide extends GradientTransform {
  final double p;
  const _Slide(this.p);
  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * p, 0, 0);
}

class Skeleton extends StatefulWidget {
  final double height;
  final double radius;
  const Skeleton({super.key, this.height = 90, this.radius = 20});
  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              colors: [C.ov.o(.04), C.primary.o(.16), C.ov.o(.04)],
              stops: const [.25, .5, .75],
              transform: _Slide(-1 + _c.value * 2),
            ),
          ),
        ),
      );
}

// ───────── Confetti ─────────
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key});
  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();
  static final List<List<double>> _p = () {
    final r = math.Random(7);
    return List.generate(36, (_) => [r.nextDouble() * 6.28, 120 + r.nextDouble() * 260, r.nextDouble() * 6.28, r.nextInt(4).toDouble()]);
  }();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(painter: _ConfettiPainter(_c.value, _p)),
        ),
      );
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  final List<List<double>> p;
  _ConfettiPainter(this.t, this.p);
  @override
  void paint(Canvas canvas, Size size) {
    final cols = [C.primary, C.gold, Colors.white, C.green];
    final e = Curves.easeOutCubic.transform(t);
    for (final q in p) {
      final dx = math.cos(q[0]) * q[1] * e;
      final dy = math.sin(q[0]) * q[1] * e + 260 * t * t;
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(q[2] + t * 9);
      canvas.drawRect(
        const Rect.fromLTWH(-4, -2, 8, 4),
        Paint()..color = cols[q[3].toInt()].o(1 - t),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter o) => o.t != t;
}

// ───────── Rotating gold border ─────────
class GoldBorderCard extends StatefulWidget {
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final double borderWidth;
  const GoldBorderCard({
    super.key,
    required this.child,
    this.radius = 28,
    this.padding = const EdgeInsets.all(20),
    this.borderWidth = 1.8,
  });
  @override
  State<GoldBorderCard> createState() => _GoldBorderCardState();
}

class _GoldBorderCardState extends State<GoldBorderCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      // static blurred shadow: painted once, not 60x per second
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        boxShadow: [BoxShadow(color: C.primary.o(.22), blurRadius: 20, spreadRadius: -4)],
      ),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Container(
          padding: EdgeInsets.all(widget.borderWidth),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: SweepGradient(
              colors: [C.primary.o(.15), C.cyan, C.primary, C.primary.o(.15)],
              stops: const [0, .25, .5, 1],
              transform: GradientRotation(_c.value * 2 * math.pi),
            ),
          ),
          child: child,
        ),
        child: RepaintBoundary(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.radius - widget.borderWidth),
            child: Stack(children: [
              Container(
                padding: widget.padding,
                decoration: BoxDecoration(gradient: C.gradDark),
                child: widget.child,
              ),
              const Positioned.fill(child: IgnorePointer(child: ShineSweep(period: Duration(milliseconds: 4500)))),
            ]),
          ),
        ),
      ),
    );
  }
}


/// Paints its child (white text/icon) with a metallic gold gradient.
class GoldShader extends StatelessWidget {
  final Widget child;
  const GoldShader({super.key, required this.child});
  @override
  Widget build(BuildContext context) => ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (r) => const LinearGradient(
          colors: [Color(0xFFFFF3C4), Color(0xFFF0C94E), Color(0xFFB8860B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(r),
        child: child,
      );
}


/// Animated sun / moon button. Switches the whole app with a circular reveal.
class ThemeToggle extends StatelessWidget {
  final double size;
  const ThemeToggle({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final light = C.light;
    return Pressable(
      onTap: () => ThemeCtl.toggle(context),
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: C.ov.o(.07),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: C.primary.o(.4)),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          transitionBuilder: (w, a) => RotationTransition(
            turns: Tween<double>(begin: .75, end: 1).animate(a),
            child: ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: w)),
          ),
          child: Icon(
            light ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            key: ValueKey<bool>(light),
            color: C.primary,
          ),
        ),
      ),
    );
  }
}
