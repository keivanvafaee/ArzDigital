import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class C {
  /// true = light theme. Flipped by [ThemeCtl]; every colour below reads it.
  static bool light = false;
  static Color _p(Color d, Color l) => light ? l : d;

  // ── surfaces / text (change with the theme) ──
  static Color get bg => _p(const Color(0xFF050505), const Color(0xFFF7F3E8));
  static Color get surface => _p(const Color(0xFF0F0F0F), const Color(0xFFFFFFFF));
  static Color get card => _p(const Color(0xFF151515), const Color(0xFFFFFFFF));
  static Color get text => _p(const Color(0xFFF7F2E4), const Color(0xFF1B1608));
  static Color get text2 => _p(const Color(0xFFDCD5BF), const Color(0xFF3A341F));
  static Color get sub => _p(const Color(0xFF9C957F), const Color(0xFF6B644B));
  static Color get ov => light ? Colors.black : Colors.white; // translucent overlays
  static Color get sheet => _p(const Color(0xFF0C0C0C), const Color(0xFFFFFCF3));
  static Color get glassA => _p(const Color(0xEE231F10), const Color(0xF2FFFFFF));
  static Color get glassB => _p(const Color(0xF50D0C08), const Color(0xF5FBF4E3));
  static Color get navA => _p(const Color(0xF7241F10), const Color(0xF7FFFFFF));
  static Color get navB => _p(const Color(0xF70A0A07), const Color(0xF7F6ECD2));

  // ── accents (slightly deeper in light mode for contrast) ──
  static Color get primary => _p(const Color(0xFFD4AF37), const Color(0xFFB8860B));
  static Color get cyan => _p(const Color(0xFFF3D98B), const Color(0xFFC9A24B)); // champagne
  static Color get pink => _p(const Color(0xFFE5989B), const Color(0xFFD1727A)); // rose gold
  static Color get green => _p(const Color(0xFF2EE59D), const Color(0xFF0E9F6E));
  static Color get red => _p(const Color(0xFFFF4D6D), const Color(0xFFE0314F));
  static Color get gold => _p(const Color(0xFFFFC94D), const Color(0xFFD08A00));
  static const blue = Color(0xFF1D9BF0); // verified tick

  static const grad = LinearGradient(
    colors: [Color(0xFFF6D675), Color(0xFFC9971C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradGreen = LinearGradient(
    colors: [Color(0xFF2EE59D), Color(0xFF12A56E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradRed = LinearGradient(
    colors: [Color(0xFFFF5C7A), Color(0xFFD62A4A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradGold = LinearGradient(
    colors: [Color(0xFFFFE08A), Color(0xFFE0A030)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static LinearGradient get gradDark => light
      ? const LinearGradient(
          colors: [Color(0xFFFFF7DC), Color(0xFFFBEBC0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      : const LinearGradient(
          colors: [Color(0xFF2A2415), Color(0xFF14110A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
}

extension ColorX on Color {
  Color o(double v) => withAlpha(math.max(0, math.min(255, (v * 255).round())));
}

ThemeData buildTheme() {
  final light = C.light;
  final base = ThemeData(brightness: light ? Brightness.light : Brightness.dark, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: Colors.transparent,
    colorScheme: light
        ? ColorScheme.light(primary: C.primary, secondary: C.cyan, surface: C.surface)
        : ColorScheme.dark(primary: C.primary, secondary: C.cyan, surface: C.surface),
    textTheme: GoogleFonts.getTextTheme('Vazirmatn', base.textTheme)
        .apply(bodyColor: C.text, displayColor: C.text),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    progressIndicatorTheme: ProgressIndicatorThemeData(color: C.primary),
    sliderTheme: SliderThemeData(thumbColor: C.primary, activeTrackColor: C.primary),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith(
          (st) => st.contains(MaterialState.selected) ? C.primary : C.sub),
      trackColor: MaterialStateProperty.resolveWith((st) =>
          st.contains(MaterialState.selected) ? C.primary.o(.35) : C.ov.o(.1)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.ov.o(.06),
      hintStyle: TextStyle(color: C.sub, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: C.ov.o(.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: C.ov.o(.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: C.primary, width: 1.4),
      ),
    ),
  );
}

double cl(num v, num a, num b) => math.max(a.toDouble(), math.min(b.toDouble(), v.toDouble()));

/// Readable text/icon colour on top of a gradient.
Color onGrad(Gradient g) => g.colors.first.computeLuminance() > 0.4 ? Colors.black : Colors.white;


/// Screenshot of the old theme + the point it expands from (used for the circular reveal).
class ThemeReveal {
  final ui.Image image;
  final Offset origin;
  const ThemeReveal(this.image, this.origin);
}

/// Light / dark theme controller.
class ThemeCtl {
  static final ValueNotifier<bool> isLight = ValueNotifier<bool>(false);
  static final GlobalKey boundaryKey = GlobalKey();
  static final ValueNotifier<ThemeReveal?> reveal = ValueNotifier<ThemeReveal?>(null);
  static bool _busy = false;

  static void applyChrome() {
    SystemChrome.setSystemUIOverlayStyle(
      (C.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light).copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: C.bg,
        systemNavigationBarIconBrightness: C.light ? Brightness.dark : Brightness.light,
      ),
    );
  }

  /// Colours are read from [C] at build time, so every element is rebuilt (and repainted).
  static void _rebuildAll() {
    void visit(Element e) {
      e.markNeedsBuild();
      e.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      void paint(RenderObject r) {
        r.markNeedsPaint();
        r.visitChildren(paint);
      }

      final ro = WidgetsBinding.instance.rootElement?.renderObject;
      if (ro != null) paint(ro);
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  /// Switch theme with an animated circular reveal that starts from [context]'s widget.
  static Future<void> toggle(BuildContext context) async {
    if (_busy) return;
    _busy = true;
    ThemeReveal? rv;
    try {
      final ro = context.findRenderObject();
      final dpr = MediaQuery.of(context).devicePixelRatio;
      Offset origin = Offset.zero;
      if (ro is RenderBox && ro.hasSize) {
        origin = ro.localToGlobal(ro.size.center(Offset.zero));
      }
      final b = boundaryKey.currentContext?.findRenderObject();
      if (b is RenderRepaintBoundary) {
        final img = await b.toImage(pixelRatio: cl(dpr, 1, 2));
        rv = ThemeReveal(img, origin);
      }
    } catch (_) {
      rv = null;
    }
    C.light = !C.light;
    isLight.value = C.light;
    applyChrome();
    _rebuildAll();
    if (rv != null) {
      reveal.value = rv;
    } else {
      _busy = false;
    }
  }

  static void revealDone() {
    final r = reveal.value;
    reveal.value = null;
    // dispose only after the frame that removed the overlay has been drawn
    WidgetsBinding.instance.addPostFrameCallback((_) => r?.image.dispose());
    _busy = false;
  }
}