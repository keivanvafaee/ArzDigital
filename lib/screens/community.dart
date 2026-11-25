import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../state.dart';
import '../common.dart';
import 'coin_detail.dart';
import 'tools.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});
  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  String? _sym;
  int _shown = 6;
  bool _boot = true; // first "updating" state
  bool _loadingMore = false;
  bool _syncing = false; // live refresh banner
  final ScrollController _sc = ScrollController();
  Timer? _live;

  @override
  void initState() {
    super.initState();
    _sc.addListener(_onScroll);
    Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _boot = false);
    });
    // new comments keep arriving, each time with a short "updating" loader
    _live = Timer.periodic(const Duration(seconds: 14), (_) => _liveUpdate());
  }

  @override
  void dispose() {
    _live?.cancel();
    _sc.dispose();
    super.dispose();
  }

  void _liveUpdate() {
    if (!mounted || _boot || _syncing) return;
    setState(() => _syncing = true);
    Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      AppScope.read(context).addLiveComment();
      setState(() {
        _syncing = false;
        _shown++;
      });
    });
  }

  void _onScroll() {
    if (!_sc.hasClients || _loadingMore || _boot) return;
    if (_sc.position.pixels > _sc.position.maxScrollExtent - 320) _loadMore();
  }

  void _loadMore() {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);
    Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final s = AppScope.read(context);
      s.loadMoreComments(8);
      setState(() {
        _shown += 6;
        _loadingMore = false;
      });
    });
  }

  Future<void> _refresh() async {
    setState(() => _syncing = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final s = AppScope.read(context);
    s.addLiveComment();
    s.addLiveComment();
    setState(() {
      _syncing = false;
      _shown += 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final syms = s.comments.map((e) => e.symbol).whereType<String>().toSet().toList()..sort();
    final all = s.comments.where((m) => _sym == null || m.symbol == _sym).toList();
    final list = all.take(_shown).toList();
    final bull = all.where((m) => m.bull).length;
    final pct = all.isEmpty ? 0.5 : bull / all.length;
    final bottomPad = MediaQuery.of(context).padding.bottom + 110;

    return SafeArea(
      bottom: false,
      child: Stack(children: [
        RefreshIndicator(
          color: C.primary,
          backgroundColor: C.card,
          onRefresh: _refresh,
          child: ListView(
            controller: _sc,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad + 30),
            children: [
              Appear(
                child: Row(children: [
                  Text('نظرات کاربران', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  SizedBox(width: 8),
                  Icon(Icons.forum_rounded, color: C.primary),
                ]),
              ),
              const SizedBox(height: 14),
              _sentiment(pct, all.length),
              const SizedBox(height: 14),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: syms.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final label = i == 0 ? 'همه' : syms[i - 1];
                    final sel = i == 0 ? _sym == null : _sym == syms[i - 1];
                    return Pressable(
                      onTap: () => setState(() {
                        _sym = i == 0 ? null : syms[i - 1];
                        _shown = 6;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: sel ? C.grad : null,
                          color: sel ? null : C.ov.o(.06),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(label,
                            style: TextStyle(
                                fontWeight: FontWeight.w800, color: sel ? Colors.black : C.sub)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              // live "updating" banner
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: _syncing && !_boot
                    ? Padding(
                        key: const ValueKey<String>('sync'),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          radius: 18,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: C.primary)),
                            SizedBox(width: 12),
                            Text('در حال بروزرسانی نظرات جدید...',
                                style: TextStyle(color: C.primary, fontWeight: FontWeight.w800, fontSize: 12.5)),
                          ]),
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey<String>('nosync')),
              ),
              if (_boot) ...[
                const SizedBox(height: 10),
                const Center(child: GoldLoader(label: 'در حال بروزرسانی نظرات', size: 76)),
                const SizedBox(height: 18),
                for (int i = 0; i < 3; i++)
                  const Padding(padding: EdgeInsets.only(bottom: 12), child: Skeleton(height: 118, radius: 22)),
              ] else ...[
                if (list.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(child: Text('هنوز نظری ثبت نشده', style: TextStyle(color: C.sub))),
                  ),
                for (int i = 0; i < list.length; i++)
                  Appear(
                    key: ValueKey<String>(list[i].id),
                    delay: 30 * (i % 6),
                    child: Padding(padding: const EdgeInsets.only(bottom: 10), child: CommentCard(list[i])),
                  ),
                // infinite-scroll footer
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _loadingMore
                        ? GlassCard(
                            key: const ValueKey<String>('loading'),
                            radius: 24,
                            glow: C.primary,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: const Center(child: GoldLoader(label: 'در حال بروزرسانی نظرات', size: 58)),
                          )
                        : Center(
                            key: const ValueKey<String>('more'),
                            child: Pressable(
                              onTap: _loadMore,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(color: C.primary.o(.5)),
                                ),
                                child: Text('نمایش نظرات بیشتر',
                                    style: TextStyle(color: C.primary, fontWeight: FontWeight.w800)),
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 92,
          left: 20,
          child: Pressable(
            onTap: () => sheet<void>(context, _ComposeSheet(initial: _sym)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                gradient: C.grad,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [BoxShadow(color: C.primary.o(.55), blurRadius: 22)],
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.edit_rounded, size: 20, color: Colors.black),
                SizedBox(width: 6),
                Text('نظر بده', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _sentiment(double pct, int count) {
    return GlassCard(
      glow: pct >= .5 ? C.green : C.red,
      child: Column(children: [
        Row(children: [
          const Text('احساس جامعه', style: TextStyle(fontWeight: FontWeight.w800)),
          const Spacer(),
          Text('${_sym ?? 'کل بازار'} · $count نظر', style: TextStyle(color: C.sub, fontSize: 12.5)),
        ]),
        const SizedBox(height: 12),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(end: pct),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => Column(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 14,
                child: Row(children: [
                  Expanded(
                      flex: cl(v * 1000, 1, 999).round(),
                      child: Container(decoration: const BoxDecoration(gradient: C.gradGreen))),
                  Expanded(
                      flex: cl((1 - v) * 1000, 1, 999).round(),
                      child: Container(decoration: const BoxDecoration(gradient: C.gradRed))),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('🐂 صعودی ${(v * 100).round()}%',
                  style: TextStyle(color: C.green, fontWeight: FontWeight.w800, fontSize: 12.5)),
              Text('🐻 نزولی ${((1 - v) * 100).round()}%',
                  style: TextStyle(color: C.red, fontWeight: FontWeight.w800, fontSize: 12.5)),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _ComposeSheet extends StatefulWidget {
  final String? initial;
  const _ComposeSheet({this.initial});
  @override
  State<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<_ComposeSheet> {
  late String? _sym = widget.initial;
  bool _bull = true;
  final _t = TextEditingController();
  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('نظر شما درباره بازار', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
      const SizedBox(height: 14),
      GlassCard(
        radius: 16,
        padding: const EdgeInsets.all(12),
        onTap: () async {
          final r = await pickCoin(context, allowAll: true);
          if (!mounted) return;
          setState(() => _sym = (r == 'ALL') ? null : r ?? _sym);
        },
        child: Row(children: [
          Icon(Icons.currency_bitcoin_rounded, color: C.gold),
          const SizedBox(width: 8),
          Text(_sym ?? 'کل بازار', style: const TextStyle(fontWeight: FontWeight.w800)),
          const Spacer(),
          Icon(Icons.expand_more_rounded, color: C.sub),
        ]),
      ),
      const SizedBox(height: 12),
      Seg(items: const ['🐂 صعودی', '🐻 نزولی'], index: _bull ? 0 : 1, onChanged: (i) => setState(() => _bull = i == 0)),
      const SizedBox(height: 12),
      TextField(controller: _t, maxLines: 4, decoration: const InputDecoration(hintText: 'نظرت رو بنویس...')),
      const SizedBox(height: 14),
      GradientButton(
        label: 'ارسال نظر',
        icon: Icons.send_rounded,
        onTap: () {
          if (_t.text.trim().isEmpty) {
            toast(context, 'متن نظر خالی است', color: C.red, icon: Icons.error_rounded, bottom: 20);
            return;
          }
          s.addComment(_t.text.trim(), _sym, _bull);
          Navigator.pop(context);
        },
      ),
    ]);
  }
}
