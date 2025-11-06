# I AM - Riddle Game MVP

A Flutter-based riddle game where players solve "I am..." riddles under time pressure. Features include daily challenges, leaderboards, user-generated content, rewarded ads, coins economy, and social sharing.

## 🎮 Features

### Core Gameplay
- **Timed riddles**: 12-second timer (configurable via Remote Config)
- **Smart answer matching**: Tolerates typos, British/American spelling, punctuation
- **Difficulty mix**: 60% easy, 30% medium, 10% hard (configurable)
- **Streak system**: Bonus coins every 5 consecutive correct answers
- **Daily skips**: 3 free skips per day

### Monetisation (Rewarded Ads Only)
- **Save Streak**: Watch ad to retry after wrong answer
- **Get Skip**: Watch ad for additional skip (when daily skips exhausted)
- **Double Coins**: Watch ad at end of round to double coins earned
- Daily cap: 5 rewarded ads per user (configurable)
- 2-minute cooldown between ads

### Economy
- Earn coins for correct answers
- Spend coins on skips or save streak
- Daily login bonus coins
- UGC creators earn coins when riddles are approved

### Social Features
- **Daily & Global Leaderboards**: Compete with others
- **Daily Challenge**: One featured riddle per day for fastest time
- **Share Cards**: Share score to WhatsApp/Instagram/Twitter
- **Referral System**: Invite friends via Dynamic Links, both earn coins

### UGC (User-Generated Content)
- Submit custom riddles
- Automatic duplicate detection (SHA-256 + SimHash)
- Moderation queue for admin review
- Banned words filter
- Format validation ("I am..." prefix required)

## 📋 Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK
- Firebase project
- AdMob account
- Android Studio / Xcode

## 🚀 Setup Instructions

### 1. Clone & Install Dependencies

```bash
git clone <repository-url>
cd tbx-iam
flutter pub get
```

### 2. Firebase Setup

#### a) Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project named "I AM"
3. Enable **Anonymous Authentication**
4. Enable **Cloud Firestore** (production mode to start)
5. Enable **Cloud Functions**
6. Enable **Cloud Storage**
7. Enable **Firebase Analytics**
8. Enable **Remote Config**
9. Enable **Dynamic Links** (set up a domain, e.g., `iam.page.link`)

#### b) Configure FlutterFire

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your Flutter app
flutterfire configure --project=your-firebase-project-id
```

This will generate `lib/firebase_options.dart` automatically.

#### c) Update main.dart

Uncomment the import in `lib/main.dart`:
```dart
import 'firebase_options.dart';
```

And update initialization:
```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

#### d) Deploy Firestore Rules

```bash
firebase deploy --only firestore:rules
```

#### e) Deploy Cloud Functions

```bash
cd functions
npm install
npm run build
firebase deploy --only functions
```

### 3. Remote Config Setup

In Firebase Console → Remote Config, add these keys with default values:

| Key | Type | Default Value |
|-----|------|---------------|
| `timer_seconds` | Number | 12 |
| `max_rewarded_ads_per_day` | Number | 5 |
| `max_rewarded_skips_per_day` | Number | 3 |
| `daily_skips` | Number | 3 |
| `coin_per_correct` | Number | 1 |
| `skip_cost_coins` | Number | 1 |
| `streak_save_alt_cost_coins` | Number | 3 |
| `difficulty_mix_easy` | Number | 0.6 |
| `difficulty_mix_medium` | Number | 0.3 |
| `difficulty_mix_hard` | Number | 0.1 |
| `streak_bonus_threshold` | Number | 5 |
| `streak_bonus_coins` | Number | 1 |
| `daily_login_coins` | Number | 3 |
| `ugc_reward_coins` | Number | 25 |
| `referral_coins_inviter` | Number | 2 |
| `referral_coins_invitee` | Number | 2 |
| `ad_cooldown_seconds` | Number | 120 |

### 4. AdMob Setup

#### a) Create AdMob Account
1. Go to [AdMob](https://admob.google.com/)
2. Create an app
3. Create a **Rewarded Ad Unit**

#### b) Update Ad IDs

Edit `lib/core/env.dart` and replace test IDs with your real IDs:

```dart
// Replace with your AdMob App IDs
static const String androidAdMobAppId = 'ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX';
static const String iosAdMobAppId = 'ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX';

// Replace with your Rewarded Ad Unit IDs
static const String androidRewardedAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
static const String iosRewardedAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
```

#### c) Update AndroidManifest.xml

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest ...>
  <application ...>
    <!-- AdMob App ID -->
    <meta-data
      android:name="com.google.android.gms.ads.APPLICATION_ID"
      android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>
  </application>
</manifest>
```

### 5. Dynamic Links Setup

1. In Firebase Console → Dynamic Links, create a URL prefix (e.g., `https://iam.page.link`)
2. Update `lib/core/env.dart`:

```dart
static const String dynamicLinksDomain = 'iam.page.link';
static const String dynamicLinksPrefix = 'https://iam.page.link';
```

3. For Android, add intent filters to `AndroidManifest.xml`:

```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data
    android:scheme="https"
    android:host="iam.page.link"/>
</intent-filter>
```

### 6. Seed Initial Data

To populate Firestore with sample riddles, use Firebase Console or create a script:

1. Go to Firestore in Firebase Console
2. Import riddles from `seed_data/riddles.json`
3. For each riddle, generate:
   - `canonText`: Canonicalized version using the Canon utility
   - `canonAnswer`: Canonicalized answer
   - `hashes.sha256`: SHA-256 hash of canonText
   - `hashes.simhash64`: SimHash of canonText
   - `status`: "live"
   - `createdAt`: Current timestamp
   - `stats`: Empty stats object

Or use the Firebase Admin SDK to batch import.

### 7. Run the App

#### Android
```bash
flutter run
```

#### iOS (requires Mac)
```bash
cd ios
pod install
cd ..
flutter run
```

## 🧪 Testing

### Run Unit Tests
```bash
flutter test test/unit/
```

### Run Widget Tests
```bash
flutter test test/widget/
```

### Run All Tests
```bash
flutter test
```

## 🎨 App Structure

```
lib/
├── core/
│   ├── ads/               # AdMob rewarded ads
│   ├── analytics/         # Firebase Analytics
│   ├── config/            # Remote Config
│   ├── utils/             # Text matching, canonicalization, time
│   └── env.dart           # Environment config
├── data/
│   ├── models/            # Riddle, User, Leaderboard models
│   ├── repositories/      # Data access layer
│   └── services/          # Firebase, Share, Dynamic Links
├── domain/
│   ├── logic/             # Rotation engine
│   └── usecases/          # Business logic (play round, etc.)
├── presentation/
│   ├── routes/            # Go Router configuration
│   ├── screens/           # UI screens
│   ├── theme/             # App theme
│   └── widgets/           # Reusable widgets
├── app.dart               # Root app widget
└── main.dart              # Entry point
```

## 🔒 Admin Moderation

To enable admin access for a user:

1. Go to Firestore Console
2. Find the user document: `users/{uid}`
3. Add/update the `roles` field:
   ```json
   {
     "roles": {
       "isAdmin": true
     }
   }
   ```
4. User can now access `/admin/moderation` route

## 📊 Analytics Events

The app tracks these key events:
- `session_start`
- `riddle_shown`
- `answer_submitted` (with correct/time)
- `ad_offered` / `ad_watched` / `ad_capped`
- `share_card_created`
- `referral_link_opened`
- `ugc_submitted` / `ugc_accepted` / `ugc_rejected`
- `leaderboard_viewed`
- `daily_challenge_played`
- `skip_used`
- `coins_earned` / `coins_spent`

## 🎯 Key Acceptance Criteria

- ✅ Play 10 rounds offline (with cached riddles)
- ✅ Daily skips decrement and reset at midnight
- ✅ Rewarded ads grant skips/coins with caps
- ✅ Leaderboards show top 20 + user rank
- ✅ UGC submissions reject exact duplicates
- ✅ Share cards work on WhatsApp/Instagram/Twitter
- ✅ Referral grants coins once per pair

## 🚧 Known Limitations (MVP)

- No interstitial or banner ads
- No social login (anonymous only for MVP)
- No IAP or paywall
- Simplified duplicate detection (SimHash with threshold)
- No complex semantic matching for riddle similarity
- Mock riddles in Play screen (connect to real Firestore in production)

## 🔧 Configuration

### Environment Variables

Create `.env` file (optional, currently using `env.dart`):
```
FIREBASE_PROJECT_ID=your-project-id
ADMOB_APP_ID_ANDROID=ca-app-pub-xxx
ADMOB_APP_ID_IOS=ca-app-pub-xxx
ADMOB_REWARDED_UNIT_ANDROID=ca-app-pub-xxx
ADMOB_REWARDED_UNIT_IOS=ca-app-pub-xxx
```

### Feature Flags

In `lib/core/env.dart`:
```dart
static const bool enableUGC = true;
static const bool enableAds = true;
static const bool enableAnalytics = true;
```

## 📝 Cloud Functions

All Cloud Functions are in `functions/index.ts`:

- `submitScore`: Update user score + leaderboards
- `grantReward`: Grant coins/skips from ads
- `submitRiddle`: Validate and create UGC riddle
- `moderateRiddle`: Approve/reject pending riddles (admin only)
- `handleReferral`: Process referral and reward both users
- `dailyReset`: Scheduled function (midnight UTC) to reset daily counters

## 🎨 UI Theme

- **Dark-first design** with pastel gradient backgrounds
- **Primary colour**: Purple (#6B5FCD)
- **Secondary colour**: Blue (#5FA3CD)
- **Font**: Poppins (add font files to `assets/fonts/`)
- **Rounded corners**: 12-16px radius
- **Accessible**: Large fonts, clear contrast

## 📱 Platform Support

- ✅ Android: Full support
- 🚧 iOS: Structure ready, needs Xcode project setup
- ❌ Web: Not supported in MVP

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and test thoroughly
4. Run `flutter test` to ensure tests pass
5. Submit a pull request

## 📄 License

(Add your license here)

## 🙋 Support

For issues or questions:
- Check Firebase Console logs for backend errors
- Check Flutter logs: `flutter logs`
- Review Firestore security rules if getting permission errors
- Ensure AdMob test mode is enabled during development

## 🎉 Next Steps (Post-MVP)

- [ ] Add social login (Google, Apple)
- [ ] Implement IAP for coin packs
- [ ] Add daily/weekly challenges
- [ ] Implement push notifications
- [ ] Add sound effects and haptics
- [ ] Create tutorial/onboarding flow
- [ ] Add more advanced duplicate detection
- [ ] Implement chat/social features
- [ ] Add achievements and badges
- [ ] Multi-language support

---

Built with ❤️ using Flutter & Firebase
