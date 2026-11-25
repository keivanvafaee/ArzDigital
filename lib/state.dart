import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'data.dart';

class AppState extends ChangeNotifier {
  final math.Random _r = math.Random();
  Timer? _timer;
  int _tick = 0;
  final StreamController<String> _ev = StreamController<String>.broadcast();
  Stream<String> get events => _ev.stream;

  bool loggedIn = false;
  String userName = 'کاربر دمو';
  String email = 'demo@novatrade.app';

  final List<Coin> coins = buildCoins();
  late final Map<String, Coin> _by = {for (final c in coins) c.symbol: c};
  double usdt = 12480.55;
  final Map<String, Holding> holdings = {
    'BTC': Holding(0.215, 61200),
    'ETH': Holding(3.4, 2950),
    'SOL': Holding(42, 128),
    'TON': Holding(300, 5.1),
    'DOGE': Holding(15000, 0.14),
  };
  final Set<String> favorites = {'BTC', 'ETH', 'SOL'};
  final List<PriceAlert> alerts = buildAlerts();
  final List<Comment> comments = buildComments();
  final List<Analysis> analyses = buildAnalyses();
  final List<Analyst> analysts = kAnalysts;
  final List<OrderReq> orders = [];
  final Set<String> unlocked = {'n1'};
  final Set<String> following = {'a1', 'a4'};
  final Set<String> likedComments = {};
  final Set<String> likedAnalyses = {};
  final List<Tx> txs = buildTxs();
  final List<double> pfSeries = [];

  final List<StakePos> stakes = [
    StakePos('ETH', 1.0, 4.2, earned: 0.0123),
    StakePos('SOL', 10, 7.1, earned: 0.21),
  ];
  final List<DcaPlan> dcaPlans = [DcaPlan('BTC', 50, 'هفتگی', runs: 4, invested: 200)];
  final Set<String> copying = {};
  final Set<String> doneLessons = {};
  final Set<String> bookmarks = {};
  final math.Random _gen = math.Random(99);
  int _genCount = 0;
  int referrals = 3;
  double referralEarn = 45;

  int xp = 1260;
  int streak = 3;
  bool spunToday = false;
  bool notif = true;
  bool biometric = true;
  int _orderN = 0;

  AppState() {
    // portfolio history (demo)
    final r = math.Random(5);
    double p = 0.86;
    for (int i = 0; i < 30; i++) {
      p *= 1 + (r.nextDouble() - 0.42) * 0.03;
      pfSeries.add(p);
    }
    final k = total / pfSeries.last;
    for (int i = 0; i < pfSeries.length; i++) {
      pfSeries[i] *= k;
    }
  }

  Coin coin(String sym) => _by[sym]!;
  double priceOf(String sym) => sym == 'USDT' ? 1.0 : _by[sym]!.price;
  double balanceOf(String sym) =>
      sym == 'USDT' ? usdt : (holdings[sym]?.qty ?? 0);
  Analyst analyst(String id) => analysts.firstWhere((a) => a.id == id);

  double get holdingsValue {
    double v = 0;
    holdings.forEach((k, h) => v += h.qty * coin(k).price);
    return v;
  }

  double get total => usdt + holdingsValue;
  double get cost {
    double v = 0;
    holdings.forEach((k, h) => v += h.qty * h.avg);
    return v;
  }

  double get pnl => holdingsValue - cost;
  double get pnlPct => cost == 0 ? 0 : pnl / cost * 100;
  double get dayChange {
    double v = 0;
    holdings.forEach((k, h) => v += h.qty * (coin(k).price - coin(k).open24));
    return v;
  }

  double get dayPct {
    final base = total - dayChange;
    return base == 0 ? 0 : dayChange / base * 100;
  }

  int get level => xp ~/ 500 + 1;
  double get levelProgress => (xp % 500) / 500;
  int get activeAlerts => alerts.where((a) => a.active).length;

  void start() {
    _timer ??= Timer.periodic(const Duration(milliseconds: 1200), (_) => _step());
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _step() {
    _tick++;
    for (final c in coins) {
      final d = (_r.nextDouble() - 0.5) * 0.0035 * c.vol;
      c.price *= 1 + d;
      if (c.price > c.high24) c.high24 = c.price;
      if (c.price < c.low24) c.low24 = c.price;
      c.spark[c.spark.length - 1] = c.price;
      if (_tick % 6 == 0) {
        c.spark.removeAt(0);
        c.spark.add(c.price);
      }
    }
    pfSeries[pfSeries.length - 1] = total;
    if (_tick % 6 == 0) {
      pfSeries.removeAt(0);
      pfSeries.add(total);
    }
    for (final st in stakes) {
      st.earned += st.qty * st.apy / 100 * 1.2 / 31536000 * 30000;
    }
    if (_tick % 25 == 0) {
      for (final p in dcaPlans) {
        if (p.active && usdt >= p.amount) {
          runDca(p, silent: true);
          _ev.add('🔁 خرید خودکار DCA: ${p.amount.toStringAsFixed(0)}\$ ${p.symbol}');
        }
      }
    }
    for (final a in alerts) {
      if (!a.active) continue;
      final p = coin(a.symbol).price;
      if ((a.above && p >= a.price) || (!a.above && p <= a.price)) {
        a.active = false;
        if (notif) {
          _ev.add('🔔 هشدار: ${a.symbol} به ${a.above ? "بالای" : "زیر"} ${a.price} رسید');
        }
      }
    }
    notifyListeners();
  }

  // ───────── trading ─────────
  bool buy(String sym, double usd) {
    if (usd <= 0 || usd > usdt + 1e-9) return false;
    final c = coin(sym);
    final qty = usd * 0.999 / c.price;
    final h = holdings[sym];
    if (h == null) {
      holdings[sym] = Holding(qty, c.price);
    } else {
      h.avg = (h.avg * h.qty + c.price * qty) / (h.qty + qty);
      h.qty += qty;
    }
    usdt -= usd;
    txs.insert(0, Tx('buy', 'خرید $sym', usd, 'همین الان'));
    xp += 15;
    notifyListeners();
    return true;
  }

  bool sell(String sym, double qty) {
    final h = holdings[sym];
    if (h == null || qty <= 0 || qty > h.qty + 1e-12) return false;
    final usd = qty * coin(sym).price * 0.999;
    usdt += usd;
    h.qty -= qty;
    if (h.qty < 1e-9) holdings.remove(sym);
    txs.insert(0, Tx('sell', 'فروش $sym', usd, 'همین الان'));
    xp += 15;
    notifyListeners();
    return true;
  }

  bool swap(String from, String to, double amount) {
    if (from == to || amount <= 0 || amount > balanceOf(from) + 1e-12) return false;
    final usd = amount * priceOf(from);
    final got = usd * 0.998 / priceOf(to);
    // debit
    if (from == 'USDT') {
      usdt -= amount;
    } else {
      final h = holdings[from]!;
      h.qty -= amount;
      if (h.qty < 1e-9) holdings.remove(from);
    }
    // credit
    if (to == 'USDT') {
      usdt += got;
    } else {
      final h = holdings[to];
      if (h == null) {
        holdings[to] = Holding(got, priceOf(to));
      } else {
        h.avg = (h.avg * h.qty + priceOf(to) * got) / (h.qty + got);
        h.qty += got;
      }
    }
    txs.insert(0, Tx('swap', 'تبدیل $from به $to', usd, 'همین الان'));
    xp += 20;
    notifyListeners();
    return true;
  }

  void deposit(double v) {
    usdt += v;
    txs.insert(0, Tx('deposit', 'واریز USDT', v, 'همین الان'));
    notifyListeners();
  }

  bool withdraw(double v) {
    if (v <= 0 || v > usdt) return false;
    usdt -= v;
    txs.insert(0, Tx('withdraw', 'برداشت USDT', v, 'همین الان'));
    notifyListeners();
    return true;
  }

  void toggleFav(String sym) {
    favorites.contains(sym) ? favorites.remove(sym) : favorites.add(sym);
    notifyListeners();
  }

  void toggleFollow(String id) {
    following.contains(id) ? following.remove(id) : following.add(id);
    notifyListeners();
  }

  void likeComment(Comment c) {
    if (likedComments.contains(c.id)) {
      likedComments.remove(c.id);
      c.likes--;
    } else {
      likedComments.add(c.id);
      c.likes++;
    }
    notifyListeners();
  }

  void likeAnalysis(Analysis a) {
    if (likedAnalyses.contains(a.id)) {
      likedAnalyses.remove(a.id);
      a.likes--;
    } else {
      likedAnalyses.add(a.id);
      a.likes++;
    }
    notifyListeners();
  }

  void addComment(String text, String? sym, bool bull) {
    comments.insert(
      0,
      Comment(
        id: 'u${comments.length}',
        user: userName,
        text: text,
        ago: 'همین الان',
        symbol: sym,
        bull: bull,
        likes: 0,
        replies: 0,
      ),
    );
    xp += 5;
    notifyListeners();
  }

  bool unlock(Analysis a) {
    if (usdt < a.price) return false;
    usdt -= a.price;
    unlocked.add(a.id);
    txs.insert(0, Tx('analysis', 'خرید تحلیل «${a.title}»', a.price, 'همین الان'));
    xp += 10;
    notifyListeners();
    return true;
  }

  bool placeOrder(Analyst an, String sym, String kind, String tf, String note,
      String urgency, double price) {
    if (usdt < price) return false;
    usdt -= price;
    final o = OrderReq(
      id: 'o${++_orderN}',
      analystId: an.id,
      symbol: sym,
      kind: kind,
      tf: tf,
      note: note,
      urgency: urgency,
      price: price,
    );
    orders.insert(0, o);
    txs.insert(0, Tx('analysis', 'سفارش تحلیل $sym از ${an.name}', price, 'همین الان'));
    xp += 25;
    Timer(const Duration(seconds: 4), () {
      o.stage = 1;
      notifyListeners();
    });
    Timer(const Duration(seconds: 9), () {
      o.stage = 2;
      notifyListeners();
    });
    Timer(const Duration(seconds: 15), () {
      final long = _r.nextBool();
      final a = Analysis(
        id: 'od${o.id}',
        symbol: sym,
        analystId: an.id,
        title: 'تحلیل اختصاصی ${coin(sym).name}',
        summary: 'تحلیل ${kind} سفارشی شما روی تایم‌فریم $tf آماده شد.',
        body: 'درخواست شما: «${note.isEmpty ? "تحلیل کلی" : note}»\n\nبر اساس بررسی ساختار قیمت، حجم و شرایط کلی بازار، سناریوی اصلی ${long ? "صعودی" : "نزولی"} ارزیابی می‌شود. سطوح ورود، هدف و حد ضرر در بخش بالا آمده است. حتماً مدیریت سرمایه را رعایت کنید.',
        tf: tf,
        ago: 'همین الان',
        long: long,
        free: false,
        e: long ? 0.995 : 1.005,
        t: long ? 1.11 : 0.9,
        s: long ? 0.96 : 1.04,
        conf: 75 + _r.nextInt(15),
        price: 0,
        likes: 0,
        views: 1,
        tags: ['سفارشی', kind],
      );
      analyses.insert(0, a);
      unlocked.add(a.id);
      o.analysisId = a.id;
      o.stage = 3;
      _ev.add('✅ تحلیل سفارشی ${sym} از ${an.name} تحویل شد');
      notifyListeners();
    });
    notifyListeners();
    return true;
  }

  void addAlert(PriceAlert a) {
    alerts.insert(0, a);
    notifyListeners();
  }

  void removeAlert(PriceAlert a) {
    alerts.remove(a);
    notifyListeners();
  }

  void toggleAlert(PriceAlert a, bool v) {
    a.active = v;
    notifyListeners();
  }

  void claimReward(double usd, int addXp, String label) {
    usdt += usd;
    xp += addXp;
    streak++;
    spunToday = true;
    txs.insert(0, Tx('reward', 'جایزه روزانه ($label)', usd, 'همین الان'));
    notifyListeners();
  }

  // ───────── staking ─────────
  bool stake(String sym, double qty) {
    final h = holdings[sym];
    if (h == null || qty <= 0 || qty > h.qty + 1e-12) return false;
    h.qty -= qty;
    if (h.qty < 1e-9) holdings.remove(sym);
    final apy = {'BTC': 3.1, 'ETH': 4.2, 'SOL': 7.1, 'TON': 6.4, 'ADA': 3.9, 'DOT': 11.0, 'AVAX': 8.2, 'BNB': 5.0}[sym] ?? 4.0;
    final ex = stakes.where((e) => e.symbol == sym);
    if (ex.isNotEmpty) {
      ex.first.qty += qty;
    } else {
      stakes.add(StakePos(sym, qty, apy));
    }
    xp += 20;
    notifyListeners();
    return true;
  }

  void unstake(StakePos p) {
    final back = p.qty + p.earned;
    final h = holdings[p.symbol];
    if (h == null) {
      holdings[p.symbol] = Holding(back, coin(p.symbol).price);
    } else {
      h.qty += back;
    }
    stakes.remove(p);
    txs.insert(0, Tx('reward', 'پاداش استیکینگ ${p.symbol}', p.earned * coin(p.symbol).price, 'همین الان'));
    notifyListeners();
  }

  // ───────── DCA ─────────
  void addDca(DcaPlan p) {
    dcaPlans.insert(0, p);
    notifyListeners();
  }

  bool runDca(DcaPlan p, {bool silent = false}) {
    if (usdt < p.amount) return false;
    buy(p.symbol, p.amount);
    p.runs++;
    p.invested += p.amount;
    if (!silent) notifyListeners();
    return true;
  }

  void toggleDca(DcaPlan p, bool v) {
    p.active = v;
    notifyListeners();
  }

  void removeDca(DcaPlan p) {
    dcaPlans.remove(p);
    notifyListeners();
  }

  // ───────── social / content ─────────
  void toggleCopy(String id) {
    copying.contains(id) ? copying.remove(id) : copying.add(id);
    notifyListeners();
  }

  void toggleBookmark(String id) {
    bookmarks.contains(id) ? bookmarks.remove(id) : bookmarks.add(id);
    notifyListeners();
  }

  void completeLesson(String id, int reward) {
    if (doneLessons.add(id)) {
      xp += reward;
      notifyListeners();
    }
  }

  /// Older comments appended to the end of the feed (infinite scroll).
  void loadMoreComments(int n) {
    comments.addAll(buildMoreComments(_genCount, n, _gen));
    _genCount += n;
    notifyListeners();
  }

  /// A fresh live comment at the top of the feed.
  void addLiveComment() {
    final c = buildMoreComments(_genCount + 1000, 1, _gen).first;
    comments.insert(
      0,
      Comment(
        id: 'l${_genCount++}',
        user: c.user,
        text: c.text,
        ago: 'همین الان',
        symbol: c.symbol,
        bull: c.bull,
        likes: 0,
        replies: 0,
      ),
    );
    notifyListeners();
  }

  void setNotif(bool v) {
    notif = v;
    notifyListeners();
  }

  void setBiometric(bool v) {
    biometric = v;
    notifyListeners();
  }

  void login(String name) {
    loggedIn = true;
    if (name.isNotEmpty) userName = name;
    notifyListeners();
  }

  void logout() {
    loggedIn = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ev.close();
    super.dispose();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
  static AppState read(BuildContext c) =>
      c.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
