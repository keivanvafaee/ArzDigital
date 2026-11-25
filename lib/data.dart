import 'dart:math' as math;
import 'package:flutter/material.dart';

// ───────────────────────── Models ─────────────────────────

class Coin {
  final String symbol, name, glyph;
  final Color color;
  final double basePrice, volume, mcap, vol;
  final int rank;
  double price, open24, high24, low24;
  List<double> spark;

  Coin({
    required this.symbol,
    required this.name,
    required this.glyph,
    required this.color,
    required this.basePrice,
    required this.volume,
    required this.mcap,
    required this.vol,
    required this.rank,
    required this.price,
    required this.open24,
    required this.high24,
    required this.low24,
    required this.spark,
  });

  double get change => (price - open24) / open24 * 100;
}

class Holding {
  double qty;
  double avg;
  Holding(this.qty, this.avg);
}

class Analyst {
  final String id, name, handle, bio;
  final List<String> tags;
  final double rating;
  final int reviews, winRate, analysesCount;
  final double followers; // in K
  final double price; // base order price (USDT)
  final bool verified;
  final Color c1, c2;
  const Analyst({
    required this.id,
    required this.name,
    required this.handle,
    required this.bio,
    required this.tags,
    required this.rating,
    required this.reviews,
    required this.winRate,
    required this.analysesCount,
    required this.followers,
    required this.price,
    required this.verified,
    required this.c1,
    required this.c2,
  });
}

class Analysis {
  final String id, symbol, analystId, title, summary, body, tf, ago;
  final bool long, free;
  final double e, t, s; // multipliers relative to coin base price
  final int conf;
  final double price;
  int likes;
  final int views;
  final List<String> tags;
  Analysis({
    required this.id,
    required this.symbol,
    required this.analystId,
    required this.title,
    required this.summary,
    required this.body,
    required this.tf,
    required this.ago,
    required this.long,
    required this.free,
    required this.e,
    required this.t,
    required this.s,
    required this.conf,
    required this.price,
    required this.likes,
    required this.views,
    required this.tags,
  });
}

class Comment {
  final String id, user, text, ago;
  final String? symbol;
  final bool bull;
  int likes;
  final int replies;
  Comment({
    required this.id,
    required this.user,
    required this.text,
    required this.ago,
    required this.symbol,
    required this.bull,
    required this.likes,
    required this.replies,
  });
}

class OrderReq {
  final String id, analystId, symbol, kind, tf, note, urgency;
  final double price;
  int stage; // 0 submitted, 1 accepted, 2 analysing, 3 delivered
  String? analysisId;
  OrderReq({
    required this.id,
    required this.analystId,
    required this.symbol,
    required this.kind,
    required this.tf,
    required this.note,
    required this.urgency,
    required this.price,
    this.stage = 0,
    this.analysisId,
  });
}

class PriceAlert {
  final String symbol;
  final bool above;
  final double price;
  bool active;
  PriceAlert(this.symbol, this.above, this.price, {this.active = true});
}

class Tx {
  final String type; // buy sell deposit withdraw swap analysis reward
  final String title;
  final double usd;
  final String ago;
  Tx(this.type, this.title, this.usd, this.ago);
}

// ───────────────────────── Demo data ─────────────────────────

List<double> _spark(String sym, double price, double chg) {
  final seed = sym.codeUnits.fold<int>(11, (a, b) => (a * 31 + b) & 0x7fffffff);
  final r = math.Random(seed);
  final out = <double>[];
  double p = 1;
  for (int i = 0; i < 30; i++) {
    p *= 1 + (r.nextDouble() - 0.5) * 0.035 + chg / 100 / 60;
    out.add(p);
  }
  final k = price / out.last;
  return out.map((e) => e * k).toList();
}

Coin _coin(String sym, String name, String glyph, int color, double price,
    double chg, double volume, double mcap, double vol, int rank) {
  return Coin(
    symbol: sym,
    name: name,
    glyph: glyph,
    color: Color(color),
    basePrice: price,
    volume: volume,
    mcap: mcap,
    vol: vol,
    rank: rank,
    price: price,
    open24: price / (1 + chg / 100),
    high24: price * 1.018,
    low24: price * 0.972,
    spark: _spark(sym, price, chg),
  );
}

List<Coin> buildCoins() => [
      _coin('BTC', 'بیت‌کوین', '₿', 0xFFF7931A, 97420, 2.35, 48.2e9, 1.93e12, 1.0, 1),
      _coin('ETH', 'اتریوم', 'Ξ', 0xFF627EEA, 3640, 3.12, 21.5e9, 437e9, 1.3, 2),
      _coin('BNB', 'بایننس کوین', 'B', 0xFFF3BA2F, 712, -0.84, 2.4e9, 103e9, 1.1, 3),
      _coin('SOL', 'سولانا', 'S', 0xFF14F195, 238, 5.41, 5.8e9, 112e9, 1.8, 4),
      _coin('XRP', 'ریپل', 'X', 0xFF3B82F6, 2.48, -1.62, 4.9e9, 142e9, 1.5, 5),
      _coin('TON', 'تون‌کوین', 'T', 0xFF0098EA, 6.2, 4.08, 0.9e9, 21e9, 1.7, 6),
      _coin('DOGE', 'دوج‌کوین', 'Ð', 0xFFC2A633, 0.41, 7.25, 3.1e9, 60e9, 2.2, 7),
      _coin('ADA', 'کاردانو', '₳', 0xFF4F8BFF, 0.92, 1.18, 1.2e9, 33e9, 1.4, 8),
      _coin('AVAX', 'آوالانچ', 'A', 0xFFE84142, 41.5, -2.37, 0.8e9, 17e9, 1.6, 9),
      _coin('LINK', 'چین‌لینک', 'L', 0xFF2A5ADA, 19.8, 2.9, 0.7e9, 12e9, 1.4, 10),
      _coin('DOT', 'پولکادات', 'D', 0xFFE6007A, 7.9, -0.45, 0.4e9, 11e9, 1.3, 11),
      _coin('TRX', 'ترون', 'R', 0xFFEF0027, 0.27, 0.96, 0.6e9, 23e9, 1.0, 12),
    ];

const List<Analyst> kAnalysts = [
  Analyst(
    id: 'a1',
    name: 'آرش کیهانی',
    handle: '@arash_tech',
    bio: 'تحلیلگر ارشد تکنیکال با ۹ سال تجربه در بازار کریپتو. تمرکز روی ساختار بازار، حجم و پرایس‌اکشن.',
    tags: ['بیت‌کوین', 'پرایس‌اکشن', 'حجم'],
    rating: 4.9,
    reviews: 1284,
    winRate: 78,
    analysesCount: 412,
    followers: 24.6,
    price: 25,
    verified: true,
    c1: Color(0xFFD4AF37),
    c2: Color(0xFF8A6508),
  ),
  Analyst(
    id: 'a2',
    name: 'سارا مرادی',
    handle: '@sara_onchain',
    bio: 'متخصص تحلیل آن‌چین و آلت‌کوین‌ها. داده‌های کیف پول نهنگ‌ها را زیر نظر دارد.',
    tags: ['آن‌چین', 'آلت‌کوین', 'نهنگ‌ها'],
    rating: 4.8,
    reviews: 962,
    winRate: 74,
    analysesCount: 305,
    followers: 18.2,
    price: 20,
    verified: true,
    c1: Color(0xFFE5989B),
    c2: Color(0xFF9C5A5D),
  ),
  Analyst(
    id: 'a3',
    name: 'نیما رضوی',
    handle: '@nima_waves',
    bio: 'تحلیل موج الیوت و فیبوناچی. سیگنال‌های میان‌مدت با مدیریت ریسک دقیق.',
    tags: ['الیوت', 'فیبوناچی', 'میان‌مدت'],
    rating: 4.7,
    reviews: 745,
    winRate: 71,
    analysesCount: 268,
    followers: 12.9,
    price: 18,
    verified: true,
    c1: Color(0xFF9FB89A),
    c2: Color(0xFF4B6A47),
  ),
  Analyst(
    id: 'a4',
    name: 'مهسا آریا',
    handle: '@mahsa_fund',
    bio: 'تحلیل بنیادی پروژه‌ها، توکنومیکس و ماکرو. گزارش‌های عمیق و قابل اتکا.',
    tags: ['بنیادی', 'توکنومیکس', 'ماکرو'],
    rating: 4.9,
    reviews: 1103,
    winRate: 80,
    analysesCount: 356,
    followers: 21.4,
    price: 30,
    verified: true,
    c1: Color(0xFFFFC94D),
    c2: Color(0xFFB8741A),
  ),
  Analyst(
    id: 'a5',
    name: 'کامران فرهادی',
    handle: '@kami_scalp',
    bio: 'اسکالپر و معامله‌گر فیوچرز. سیگنال‌های کوتاه‌مدت و پرنوسان.',
    tags: ['اسکالپ', 'فیوچرز'],
    rating: 4.5,
    reviews: 388,
    winRate: 66,
    analysesCount: 190,
    followers: 6.1,
    price: 12,
    verified: false,
    c1: Color(0xFFC98A5E),
    c2: Color(0xFF6E4326),
  ),
  Analyst(
    id: 'a6',
    name: 'لیلا نوری',
    handle: '@leila_defi',
    bio: 'فعال حوزه دیفای و اکوسیستم‌های لایه ۱. شکار فرصت‌های اولیه.',
    tags: ['دیفای', 'لایه ۱', 'ایردراپ'],
    rating: 4.6,
    reviews: 512,
    winRate: 69,
    analysesCount: 221,
    followers: 8.7,
    price: 16,
    verified: true,
    c1: Color(0xFFCBBF9A),
    c2: Color(0xFF6F6648),
  ),
];

List<Analysis> buildAnalyses() => [
      Analysis(
        id: 'n1', symbol: 'BTC', analystId: 'a1',
        title: 'بیت‌کوین؛ شکست مقاومت تاریخی در راه است',
        summary: 'ساختار صعودی روی تایم‌فریم ۴ ساعته حفظ شده و حجم معاملات تایید‌کننده است.',
        body: 'قیمت پس از یک اصلاح سالم، دوباره بالای میانگین متحرک ۵۰ روزه تثبیت شده است. حجم خرید در کف‌های اخیر افزایش یافته و نشان از جمع‌آوری نهادی دارد.\n\nدر صورت بسته شدن کندل روزانه بالای مقاومت کلیدی، هدف بعدی ناحیه‌ی فیبوناچی ۱.۲۷ خواهد بود. حد ضرر زیر آخرین کف مهم تعریف می‌شود تا نسبت ریسک به ریوارد مناسب بماند.',
        tf: '4H', ago: '۲ ساعت پیش', long: true, free: false,
        e: 0.995, t: 1.09, s: 0.965, conf: 86, price: 15, likes: 1284, views: 9420,
        tags: ['پرایس‌اکشن', 'شکست مقاومت'],
      ),
      Analysis(
        id: 'n2', symbol: 'ETH', analystId: 'a2',
        title: 'اتریوم؛ تجمیع نهنگ‌ها در کف کانال',
        summary: 'داده‌های آن‌چین نشان می‌دهد آدرس‌های بزرگ در حال انباشت اتریوم هستند.',
        body: 'خروج اتریوم از صرافی‌ها به بالاترین حد در ۳ ماه اخیر رسیده است. این رفتار معمولاً قبل از فازهای صعودی دیده می‌شود.\n\nمحدوده‌ی تقاضای فعلی هم‌پوشانی خوبی با کف کانال صعودی دارد. ورود پله‌ای و رعایت حد ضرر توصیه می‌شود.',
        tf: '1D', ago: '۵ ساعت پیش', long: true, free: true,
        e: 0.99, t: 1.12, s: 0.95, conf: 79, price: 0, likes: 932, views: 7310,
        tags: ['آن‌چین', 'نهنگ‌ها'],
      ),
      Analysis(
        id: 'n3', symbol: 'SOL', analystId: 'a2',
        title: 'سولانا؛ ادامه‌ی روند با هدف جدید',
        summary: 'رشد فعالیت شبکه و TVL، سولانا را در صدر آلت‌کوین‌ها نگه داشته است.',
        body: 'تعداد تراکنش‌های روزانه شبکه رکورد جدیدی ثبت کرده و جریان ورودی به پروتکل‌های دیفای رو به افزایش است.\n\nالگوی پرچم صعودی روی نمودار ۴ ساعته در حال تکمیل است و شکست آن می‌تواند حرکت انفجاری ایجاد کند.',
        tf: '4H', ago: '۸ ساعت پیش', long: true, free: false,
        e: 0.985, t: 1.15, s: 0.94, conf: 82, price: 10, likes: 871, views: 6120,
        tags: ['دیفای', 'الگوی پرچم'],
      ),
      Analysis(
        id: 'n4', symbol: 'BTC', analystId: 'a3',
        title: 'بیت‌کوین؛ واگرایی منفی RSI در تایم روزانه',
        summary: 'احتمال اصلاح کوتاه‌مدت پیش از ادامه‌ی روند اصلی وجود دارد.',
        body: 'RSI روزانه در حال ثبت سقف پایین‌تر است در حالی که قیمت سقف بالاتر ساخته. این واگرایی هشدار اصلاح می‌دهد.\n\nپیشنهاد می‌شود معامله‌گران کوتاه‌مدت سود خود را بخشی تثبیت کنند و برای ورود مجدد به نواحی حمایتی صبر کنند.',
        tf: '1D', ago: '۱ روز پیش', long: false, free: true,
        e: 1.005, t: 0.93, s: 1.03, conf: 68, price: 0, likes: 654, views: 5890,
        tags: ['RSI', 'واگرایی'],
      ),
      Analysis(
        id: 'n5', symbol: 'TON', analystId: 'a4',
        title: 'تون‌کوین؛ اثر تلگرام و رشد کاربران',
        summary: 'بررسی بنیادی: ادغام با اکوسیستم تلگرام می‌تواند تقاضای پایدار بسازد.',
        body: 'تعداد کیف پول‌های فعال ماهانه ۳۸٪ رشد داشته و پروژه‌های مینی‌اپ جریان نقدینگی جدیدی وارد شبکه کرده‌اند.\n\nدر سناریوی خوش‌بینانه، با ادامه‌ی این روند و آزادسازی کنترل‌شده‌ی توکن‌ها، هدف میان‌مدت قابل دستیابی است.',
        tf: '1W', ago: '۱ روز پیش', long: true, free: false,
        e: 0.99, t: 1.28, s: 0.9, conf: 84, price: 12, likes: 1105, views: 8040,
        tags: ['بنیادی', 'تلگرام'],
      ),
      Analysis(
        id: 'n6', symbol: 'XRP', analystId: 'a4',
        title: 'ریپل؛ سناریوهای پس از رای دادگاه',
        summary: 'نگاهی به ریسک‌ها و فرصت‌های پیش‌رو برای دارندگان میان‌مدت.',
        body: 'بازار نسبت به اخبار نظارتی حساس است و نوسان کوتاه‌مدت بالا خواهد بود. اما از نظر بنیادی، تقاضای نهادی برای بسترهای پرداخت رو به رشد است.\n\nتوصیه می‌شود با تقسیم سرمایه در چند پله وارد شوید.',
        tf: '1D', ago: '۲ روز پیش', long: true, free: true,
        e: 0.985, t: 1.18, s: 0.93, conf: 72, price: 0, likes: 540, views: 4660,
        tags: ['بنیادی', 'اخبار'],
      ),
      Analysis(
        id: 'n7', symbol: 'DOGE', analystId: 'a5',
        title: 'دوج‌کوین؛ فرصت شورت کوتاه‌مدت',
        summary: 'رشد بیش از حد و فاندینگ بالا؛ احتمال تسویه‌ی پوزیشن‌های لانگ.',
        body: 'نرخ فاندینگ به سطوح هشدار رسیده و open interest به‌شدت بالا رفته است. معمولاً چنین شرایطی قبل از لانگ‌اسکوییز دیده می‌شود.\n\nاین سیگنال کوتاه‌مدت است؛ حتماً با اهرم پایین و حد ضرر سخت معامله کنید.',
        tf: '1H', ago: '۳ ساعت پیش', long: false, free: false,
        e: 1.0, t: 0.92, s: 1.035, conf: 64, price: 8, likes: 410, views: 3120,
        tags: ['فیوچرز', 'فاندینگ'],
      ),
      Analysis(
        id: 'n8', symbol: 'LINK', analystId: 'a6',
        title: 'چین‌لینک؛ زیرساخت اوراکل در مسیر رشد',
        summary: 'همکاری‌های جدید با بانک‌ها و رشد استفاده از CCIP.',
        body: 'حجم پیام‌های بین‌زنجیره‌ای رشد چشمگیری داشته و درآمد شبکه بهبود یافته است. این موضوع از نظر توکنومیکس برای LINK مثبت ارزیابی می‌شود.',
        tf: '1D', ago: '۳ روز پیش', long: true, free: true,
        e: 0.99, t: 1.2, s: 0.94, conf: 75, price: 0, likes: 388, views: 3340,
        tags: ['اوراکل', 'CCIP'],
      ),
      Analysis(
        id: 'n9', symbol: 'BNB', analystId: 'a1',
        title: 'بایننس کوین؛ حمایت قوی در ناحیه ۶۸۰',
        summary: 'برگشت از حمایت با کندل پوشا و افزایش حجم.',
        body: 'ناحیه‌ی ۶۸۰ برای چندمین بار به‌عنوان حمایت عمل کرده است. کندل پوشای صعودی با حجم بالا نشانه‌ی بازگشت قدرت خریداران است.',
        tf: '4H', ago: '۶ ساعت پیش', long: true, free: false,
        e: 0.99, t: 1.1, s: 0.96, conf: 80, price: 12, likes: 497, views: 4010,
        tags: ['حمایت', 'کندل پوشا'],
      ),
      Analysis(
        id: 'n10', symbol: 'AVAX', analystId: 'a6',
        title: 'آوالانچ؛ الگوی دو کف در تایم ۴ ساعته',
        summary: 'تایید الگو با شکست خط گردن، ورود پله‌ای پیشنهاد می‌شود.',
        body: 'الگوی دو کف با واگرایی مثبت MACD همراه شده است. هدف الگو معادل ارتفاع آن از خط گردن محاسبه می‌شود.',
        tf: '4H', ago: '۱ روز پیش', long: true, free: true,
        e: 1.0, t: 1.14, s: 0.95, conf: 70, price: 0, likes: 301, views: 2780,
        tags: ['دو کف', 'MACD'],
      ),
      Analysis(
        id: 'n11', symbol: 'ADA', analystId: 'a4',
        title: 'کاردانو؛ بررسی به‌روزرسانی‌های شبکه',
        summary: 'ارتقاهای فنی و رشد دیفای می‌تواند محرک جدیدی باشد.',
        body: 'ارزش قفل‌شده در پروتکل‌های کاردانو رشد قابل توجهی داشته و نقشه‌ی راه توسعه‌دهندگان در حال اجرا است. ریسک اصلی، رقابت با شبکه‌های سریع‌تر است.',
        tf: '1W', ago: '۲ روز پیش', long: true, free: false,
        e: 0.98, t: 1.25, s: 0.91, conf: 77, price: 9, likes: 276, views: 2410,
        tags: ['بنیادی', 'دیفای'],
      ),
      Analysis(
        id: 'n12', symbol: 'DOT', analystId: 'a3',
        title: 'پولکادات؛ موج ۳ الیوت در حال شکل‌گیری',
        summary: 'شمارش امواج نشان از آغاز حرکت قدرتمند صعودی دارد.',
        body: 'پس از تکمیل موج ۲ در ناحیه‌ی ۶۱.۸٪ فیبوناچی، قیمت ساختار موج ۳ را آغاز کرده است. اهداف بر اساس اکستنشن‌های ۱.۶۱۸ محاسبه شده‌اند.',
        tf: '1D', ago: '۴ روز پیش', long: true, free: true,
        e: 0.99, t: 1.3, s: 0.93, conf: 73, price: 0, likes: 245, views: 2190,
        tags: ['الیوت', 'فیبوناچی'],
      ),
    ];

List<Comment> buildComments() => [
      Comment(id: 'c1', user: 'مهدی_کریپتو', symbol: 'BTC', bull: true, likes: 142, replies: 18, ago: '۱۰ دقیقه پیش',
          text: 'بیت‌کوین داره از مقاومت رد می‌شه، به نظرم تا آخر ماه رکورد جدید می‌زنیم 🚀'),
      Comment(id: 'c2', user: 'Nazanin.T', symbol: 'ETH', bull: true, likes: 98, replies: 7, ago: '۲۵ دقیقه پیش',
          text: 'خروج اتریوم از صرافی‌ها خیلی معنی‌داره. من پله‌پله خرید می‌کنم.'),
      Comment(id: 'c3', user: 'trader_reza', symbol: 'DOGE', bull: false, likes: 61, replies: 22, ago: '۴۰ دقیقه پیش',
          text: 'فاندینگ دوج خیلی بالاست، من ریسک نمی‌کنم. منتظر اصلاح می‌مونم.'),
      Comment(id: 'c4', user: 'سینا۹۸', symbol: null, bull: true, likes: 210, replies: 31, ago: '۱ ساعت پیش',
          text: 'کلاً بازار در فاز طمع هست ولی هنوز نشانه‌ی سقف نمی‌بینم. مدیریت سرمایه یادتون نره!'),
      Comment(id: 'c5', user: 'Parisa_BTC', symbol: 'SOL', bull: true, likes: 87, replies: 9, ago: '۲ ساعت پیش',
          text: 'سولانا قوی‌ترین عملکرد هفته رو داشته. اکوسیستمش داره منفجر می‌شه.'),
      Comment(id: 'c6', user: 'alirezaHodl', symbol: 'BTC', bull: false, likes: 54, replies: 12, ago: '۲ ساعت پیش',
          text: 'واگرایی RSI روزانه رو دیدید؟ احتمال یه اصلاح ۸٪ هست.'),
      Comment(id: 'c7', user: 'دانیال‌ترید', symbol: 'TON', bull: true, likes: 133, replies: 14, ago: '۳ ساعت پیش',
          text: 'تون با میدلی‌های تلگرام کاربر واقعی جذب می‌کنه، من بلندمدت نگهش می‌دارم.'),
      Comment(id: 'c8', user: 'Bita.eth', symbol: null, bull: false, likes: 40, replies: 5, ago: '۴ ساعت پیش',
          text: 'حواستون به اخبار نرخ بهره باشه. بازار می‌تونه ناگهانی برگرده.'),
      Comment(id: 'c9', user: 'Omid_Alt', symbol: 'AVAX', bull: false, likes: 29, replies: 3, ago: '۵ ساعت پیش',
          text: 'آوالانچ هنوز زیر مقاومت گیره. تا شکست نشه وارد نمی‌شم.'),
      Comment(id: 'c10', user: 'کیانا_فاند', symbol: 'LINK', bull: true, likes: 76, replies: 6, ago: '۶ ساعت پیش',
          text: 'لینک یکی از بنیادی‌ترین پروژه‌هاست و مدت‌هاست دست‌کم گرفته شده.'),
      Comment(id: 'c11', user: 'Shayan.BNB', symbol: 'BNB', bull: true, likes: 33, replies: 2, ago: '۷ ساعت پیش',
          text: 'حمایت ۶۸۰ بنظرم محکمه، ریسک به ریوارد خوبی داره.'),
      Comment(id: 'c12', user: 'رضا_اسکالپ', symbol: 'XRP', bull: false, likes: 47, replies: 11, ago: '۸ ساعت پیش',
          text: 'ریپل خیلی تحت تاثیر اخبار می‌چرخه، برای من بیش از حد پرریسکه.'),
    ];

List<Tx> buildTxs() => [
      Tx('buy', 'خرید SOL', 1250.0, '۲ ساعت پیش'),
      Tx('deposit', 'واریز USDT', 3000.0, 'دیروز'),
      Tx('sell', 'فروش DOGE', 820.5, 'دیروز'),
      Tx('analysis', 'خرید تحلیل «بیت‌کوین؛ شکست مقاومت»', 15.0, '۳ روز پیش'),
      Tx('swap', 'تبدیل ETH به USDT', 640.0, '۴ روز پیش'),
      Tx('reward', 'جایزه روزانه', 5.0, '۵ روز پیش'),
    ];

List<PriceAlert> buildAlerts() => [
      PriceAlert('BTC', true, 98000),
      PriceAlert('ETH', false, 3500),
      PriceAlert('SOL', true, 250),
    ];

// ───────────── extra models ─────────────

class StakePos {
  final String symbol;
  double qty;
  final double apy;
  double earned;
  StakePos(this.symbol, this.qty, this.apy, {this.earned = 0});
}

class DcaPlan {
  final String symbol;
  final double amount;
  final String freq;
  bool active;
  int runs;
  double invested;
  DcaPlan(this.symbol, this.amount, this.freq, {this.active = true, this.runs = 0, this.invested = 0});
}

const List<String> kCommentUsers = [
  'آرمین_ترید', 'Sara.Crypto', 'نیلوفر۹۰', 'Hamed_HODL', 'کاوه_بیت', 'Mina.eth',
  'پوریا_آلت', 'Ramin.T', 'الهه_فاند', 'Arvin_BTC', 'مریم_ترید', 'Soroush.sol',
  'دانا_کریپتو', 'Yasi.trader', 'فرزاد_لانگ', 'Nasim_DeFi',
];

List<Comment> buildMoreComments(int start, int n, math.Random r) {
  const names = {
    'BTC': 'بیت‌کوین', 'ETH': 'اتریوم', 'BNB': 'بایننس کوین', 'SOL': 'سولانا',
    'XRP': 'ریپل', 'TON': 'تون', 'DOGE': 'دوج', 'ADA': 'کاردانو',
    'AVAX': 'آوالانچ', 'LINK': 'چین‌لینک', 'DOT': 'پولکادات', 'TRX': 'ترون',
  };
  const bullT = [
    '{c} قوی داره حرکت می‌کنه، حجم خریدش عالیه 🚀',
    'من تو {c} پله‌ای خرید می‌کنم، ساختارش صعودیه.',
    'شکست مقاومت {c} نزدیکه، منتظر کندل تایید هستم.',
    'خروج {c} از صرافی‌ها داره زیاد می‌شه، نشونه خوبیه 👌',
    'تحلیل‌های اخیر {c} رو دیدید؟ خیلی امیدوارکننده‌ست.',
    'برای {c} هدف بعدی رو خیلی بالاتر می‌بینم.',
  ];
  const bearT = [
    'مراقب {c} باشید، واگرایی منفی داره.',
    'من سود {c} رو برداشتم؛ احتمال اصلاح هست.',
    'فاندینگ {c} زیاده، ریسک لانگ‌اسکوییز وجود داره.',
    '{c} زیر حمایت کلیدی بسته شد، من وارد نمی‌شم.',
    'حجم {c} داره کم می‌شه، صعود پایدار به نظر نمیاد.',
  ];
  const ago = ['۱ ساعت پیش', '۳ ساعت پیش', '۵ ساعت پیش', '۸ ساعت پیش', 'دیروز', '۲ روز پیش', '۳ روز پیش'];
  final syms = names.keys.toList();
  return List.generate(n, (i) {
    final bull = r.nextDouble() > 0.38;
    final sym = r.nextDouble() > 0.15 ? syms[r.nextInt(syms.length)] : null;
    final tpl = (bull ? bullT : bearT)[r.nextInt(bull ? bullT.length : bearT.length)];
    final txt = sym == null
        ? (bull ? 'حال و هوای کل بازار مثبته، فقط مدیریت سرمایه یادتون نره!' : 'بازار خیلی هیجانی شده، احتیاط کنید.')
        : tpl.replaceAll('{c}', names[sym]!);
    return Comment(
      id: 'g${start + i}',
      user: kCommentUsers[r.nextInt(kCommentUsers.length)],
      text: txt,
      ago: ago[math.min(ago.length - 1, (start + i) ~/ 6)],
      symbol: sym,
      bull: bull,
      likes: r.nextInt(120),
      replies: r.nextInt(15),
    );
  });
}
