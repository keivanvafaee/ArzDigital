<div align="center">

# ✨ Nova Trade

### A premium black-and-gold crypto trading & wallet app — built with Flutter

Live-style market data, a full trading wallet, a chart suite with indicators, an analyst marketplace, and a 3D "Market Pulse" orb — all running 100% offline on realistic simulated data.

![Flutter](https://img.shields.io/badge/Flutter-3.19+-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)
![Data](https://img.shields.io/badge/Backend-None%20(offline%20demo)-gold)
![Status](https://img.shields.io/badge/Status-Demo-orange)

[🌐 Website](https://keivanvafaee.ir/)

</div>

---

> **⚠️ Demo application.** Nova Trade is a UI/UX and engineering showcase. All prices, balances, analysts, news, and transactions are **simulated, local data**. No real money, no real exchange, no real trading.

## 📖 About

**Nova Trade (نوا ترید)** is a feature-rich crypto trading and wallet app that shows what a modern, polished exchange experience can feel like on mobile. It ships with a luxurious black-and-gold design system, smooth custom animations, a light/dark theme with a circular-reveal transition, and a large set of trading, analytics, and community features, all implemented in pure Flutter with almost no dependencies.

The UI is bilingual-friendly and uses the **Vazirmatn** font for Persian/Farsi text.

## 📸 Screenshots

<div align="center">

| Market | Charts | Wallet |
|:---:|:---:|:---:|
| <img src="docs/screenshots/market.png" width="220" /> | <img src="docs/screenshots/charts.png" width="220" /> | <img src="docs/screenshots/wallet.png" width="220" /> |

| Analysis | Market Pulse | Light Theme |
|:---:|:---:|:---:|
| <img src="docs/screenshots/analysis.png" width="220" /> | <img src="docs/screenshots/pulse.png" width="220" /> | <img src="docs/screenshots/light.png" width="220" /> |

</div>

## 🚀 Features

### 📈 Market
- Simulated live prices updating about every second, with an animated price ticker
- Market heat map, favorites (star) system
- Fear & Greed Index and Bitcoin dominance
- **Market Pulse** – an interactive 3D-style orb whose color, glow, orbits and particles react to market sentiment; tap for shockwaves, shakes in extreme fear

### 📊 Charts
- Candlestick, line, and multi-coin comparison charts
- Multiple timeframes with touch **crosshair**
- Indicators: **RSI, Moving Averages, MACD**
- Live order book

### 💼 Wallet
- Portfolio dashboard with balance, PnL, and asset-allocation chart
- Gold "credit card" style portfolio card
- Buy / sell that actually updates balances on the demo data
- Deposit (QR) and withdraw flows, full transaction history

### 🧠 Analysis marketplace
- Trending coin analyses, free and paid analyses (unlock with USDT)
- Order a custom analysis: pick analyst, coin, type, and delivery time, then track progress step by step until it's auto-delivered
- Verified analyst profiles (blue badge, rating, success rate, reviews, follow)

### 💬 Community
- Market-wide or per-coin comments, community sentiment, posting
- Skeleton loaders, infinite scroll, pull-to-refresh, and live incoming comments

### 🛠️ Tools & extras
- Instant **Swap** converter
- Live **price alerts**
- Daily **lucky wheel** with XP and levels
- **AI-style assistant** (demo chat)
- **Risk calculator**
- News, real-time signals & whale tracking
- Staking, automated **DCA** buying
- Copy trading and leaderboard
- Academy with quizzes, referral program, achievements
- Contact / FAQ section

### 🎨 Design & UX
- Black-and-gold theme with animated gold particles, shine effects, rotating gold borders, confetti, and gold loaders
- Light & dark mode with a circular-wave transition
- Glassmorphism cards with gradient borders, floating bottom navigation
- Custom floating glass notification banners with haptic feedback and swipe-to-dismiss
- Responsive: SafeArea everywhere, font-scale limits, tablet max-width, scrollable sheets
- Biometric (fingerprint) login — simulated

## 🧰 Tech Stack

| Layer | Technology |
|---|---|
| Language | **Dart 3** |
| Framework | **Flutter 3.19+** (Material, `CustomPainter` for charts & effects) |
| State management | Built-in Flutter state (`ChangeNotifier` / `setState`) — no external state library |
| Fonts | [`google_fonts`](https://pub.dev/packages/google_fonts) (Vazirmatn) |
| Links | [`url_launcher`](https://pub.dev/packages/url_launcher) |
| Target platform | Android |

## 🗄️ Database & Data

**There is no database and no backend.** Nova Trade runs entirely offline:

- All market data, analysts, news, comments, and transactions are generated from **in-code simulated datasets** (`lib/data.dart`).
- Prices are driven by a local random-walk simulation (`lib/charts.dart`, `lib/state.dart`).
- App state (balances, favorites, theme, etc.) lives **in memory** and resets when the app is restarted.
- No API keys, no accounts, no network calls (the internet is only used to download the font on first launch, and to open external links).

> 💡 Want to make it real? The data layer is isolated, so it can be swapped for a REST/WebSocket API (e.g. Binance, CoinGecko) and persistence added with `shared_preferences`, SQLite, or Isar.

## 📁 Project Structure

```
lib/
├── main.dart            # App entry, splash, routing
├── theme.dart           # Black/gold + light/dark design tokens
├── data.dart            # Simulated coins, analysts, news, etc.
├── state.dart           # App state & live market simulation
├── charts.dart          # Candlestick / line / indicator painters
├── common.dart          # Shared widgets, toasts, effects
├── portfolio_card.dart  # Gold portfolio card
└── screens/
    ├── auth.dart        ├── home.dart         ├── charts_page.dart
    ├── wallet.dart      ├── analysis.dart     ├── community.dart
    ├── tools.dart       ├── features.dart     ├── pulse.dart
    ├── coin_detail.dart └── shell.dart
```

## ▶️ Getting Started

**Requirements:** Flutter SDK 3.19+ (Dart 3) and an Android device/emulator.

```bash
git clone https://github.com/<your-username>/nova_trade.git
cd nova_trade

# Linux / macOS
./setup.sh
# Windows
setup.bat
```

The setup script generates the Android platform files, adds the required `INTERNET` permission, fetches packages, and runs the app. Or do it manually:

```bash
flutter create --platforms=android --project-name nova_trade --org app.novatrade .
flutter pub get
flutter run
```

Build a release APK:

```bash
flutter build apk --release
```

### 🔑 Demo login
Any email + password (min. 4 characters) works, or just tap **"Quick demo login"**.

## 🗺️ Roadmap
- [ ] Real market data via REST / WebSocket
- [ ] Persistent storage (SQLite / Isar)
- [ ] iOS & Web targets
- [ ] Real authentication backend
- [ ] Push notifications for price alerts

## 📬 Contact

Built by **Keivan Vafaee**
🌐 [keivanvafaee.ir](https://keivanvafaee.ir/)

## ⚠️ Disclaimer

Nova Trade is a demonstration project. It does not provide financial advice and does not execute real trades or hold real funds.

## 📄 License

Add a license of your choice (e.g. MIT) before publishing.
