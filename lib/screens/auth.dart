import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../state.dart';
import '../common.dart';
import 'shell.dart';
import 'features.dart';

class NovaLogo extends StatefulWidget {
  final double size;
  const NovaLogo({super.key, this.size = 90});
  @override
  State<NovaLogo> createState() => _NovaLogoState();
}

class _NovaLogoState extends State<NovaLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, -6 * _c.value),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            gradient: C.grad,
            borderRadius: BorderRadius.circular(widget.size * .32),
            boxShadow: [
              BoxShadow(
                  color: C.primary.o(.45 + .25 * _c.value),
                  blurRadius: 30 + 20 * _c.value,
                  spreadRadius: 2),
            ],
          ),
          child: Icon(Icons.workspace_premium_rounded, color: Colors.black, size: widget.size * .52),
        ),
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  int _mode = 0;
  bool _hide = true, _loading = false;
  final _name = TextEditingController();
  final _email = TextEditingController(text: 'demo@novatrade.app');
  final _pass = TextEditingController(text: '123456');

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _enter(String name) {
    final s = AppScope.read(context);
    s.login(name);
    Navigator.of(context).pushReplacement(PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const MainShell(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    ));
  }

  void _submit() {
    if (!_email.text.contains('@') || _pass.text.length < 4) {
      toast(context, 'ایمیل یا رمز عبور معتبر نیست', color: C.red, icon: Icons.error_rounded, bottom: 20);
      return;
    }
    if (_mode == 1 && _name.text.trim().isEmpty) {
      toast(context, 'نام خود را وارد کنید', color: C.red, icon: Icons.error_rounded, bottom: 20);
      return;
    }
    setState(() => _loading = true);
    Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _enter(_mode == 1 ? _name.text.trim() : '');
    });
  }

  Future<void> _bio() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _BioDialog(),
    );
    if (mounted) _enter('');
  }

  @override
  Widget build(BuildContext context) {
    return Aurora(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: Column(children: [
                const NovaLogo(size: 84),
                const SizedBox(height: 16),
                const GoldShader(
                  child: Text('NOVA TRADE',
                      style: TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 5, color: Colors.white)),
                ),
                const SizedBox(height: 2),
                const Text('نوا ترید', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('وارد دنیای هوشمند کریپتو شوید',
                    style: TextStyle(color: C.sub, fontSize: 13.5)),
                const SizedBox(height: 26),
                Appear(
                  delay: 150,
                  child: GlassCard(
                    radius: 28,
                    padding: const EdgeInsets.all(20),
                    glow: C.primary,
                    child: Column(children: [
                      Seg(
                          items: const ['ورود', 'ثبت نام'],
                          index: _mode,
                          onChanged: (i) => setState(() => _mode = i)),
                      const SizedBox(height: 18),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        child: _mode == 1
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: TextField(
                                  controller: _name,
                                  decoration: InputDecoration(
                                      hintText: 'نام و نام خانوادگی',
                                      prefixIcon: Icon(Icons.person_rounded, color: C.sub)),
                                ),
                              )
                            : const SizedBox(width: double.infinity),
                      ),
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                            hintText: 'ایمیل',
                            prefixIcon: Icon(Icons.mail_rounded, color: C.sub)),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _pass,
                        obscureText: _hide,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          hintText: 'رمز عبور',
                          prefixIcon: Icon(Icons.lock_rounded, color: C.sub),
                          suffixIcon: IconButton(
                            icon: Icon(
                                _hide ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                color: C.sub),
                            onPressed: () => setState(() => _hide = !_hide),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => toast(context, 'لینک بازیابی به ایمیل ارسال شد (دمو)',
                              icon: Icons.mail_outline_rounded, bottom: 20),
                          child: Text('فراموشی رمز؟',
                              style: TextStyle(color: C.cyan, fontSize: 12.5)),
                        ),
                      ),
                      GradientButton(
                          label: _mode == 0 ? 'ورود به حساب' : 'ساخت حساب جدید',
                          loading: _loading,
                          onTap: _submit),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(child: Divider(color: C.ov.o(.1))),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('یا', style: TextStyle(color: C.sub, fontSize: 12)),
                        ),
                        Expanded(child: Divider(color: C.ov.o(.1))),
                      ]),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(child: _social(Icons.g_mobiledata_rounded, 'گوگل')),
                        const SizedBox(width: 10),
                        Expanded(child: _social(Icons.apple_rounded, 'اپل')),
                        const SizedBox(width: 10),
                        Expanded(child: _social(Icons.fingerprint_rounded, 'اثر انگشت', onTap: _bio)),
                      ]),
                    ]),
                  ),
                ),
                const SizedBox(height: 18),
                Pressable(
                  onTap: () => _enter(''),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: C.cyan.o(.5)),
                      color: C.cyan.o(.08),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.bolt_rounded, color: C.cyan, size: 20),
                      SizedBox(width: 6),
                      Text('ورود سریع به نسخه دمو',
                          style: TextStyle(color: C.cyan, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
                Text(kDemoNote,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: C.sub, fontSize: 11.5, height: 1.7)),
                TextButton.icon(
                  onPressed: () => go(context, const ContactScreen()),
                  icon: Icon(Icons.support_agent_rounded, color: C.primary, size: 18),
                  label: Text('تماس با ما', style: TextStyle(color: C.primary, fontWeight: FontWeight.w800)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _social(IconData i, String t, {VoidCallback? onTap}) {
    return Pressable(
      onTap: onTap ?? () => _enter(''),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: C.ov.o(.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.ov.o(.08)),
        ),
        child: Column(children: [
          Icon(i, size: 26),
          const SizedBox(height: 2),
          Text(t, style: TextStyle(fontSize: 11, color: C.sub)),
        ]),
      ),
    );
  }
}

class _BioDialog extends StatefulWidget {
  const _BioDialog();
  @override
  State<_BioDialog> createState() => _BioDialogState();
}

class _BioDialogState extends State<_BioDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer(const Duration(milliseconds: 900), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: C.cyan.o(.4)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedBuilder(
            animation: _c,
            builder: (_, __) {
              final done = _c.value > .95;
              return Stack(alignment: Alignment.center, children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: CircularProgressIndicator(
                      value: _c.value,
                      strokeWidth: 4,
                      color: done ? C.green : C.cyan,
                      backgroundColor: C.ov.o(.08)),
                ),
                Icon(done ? Icons.check_rounded : Icons.fingerprint_rounded,
                    size: 54, color: done ? C.green : C.cyan),
              ]);
            },
          ),
          const SizedBox(height: 18),
          const Text('در حال تایید هویت...',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}
