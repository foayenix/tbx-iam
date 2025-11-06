# 🚀 Quick Setup Checklist for I AM

Follow this checklist to get your I AM riddle game up and running.

## ✅ Step-by-Step Setup

### 1. Prerequisites
- [ ] Flutter SDK installed (>=3.0.0)
- [ ] Firebase account created
- [ ] AdMob account created
- [ ] Git installed

### 2. Install Dependencies
```bash
flutter pub get
cd functions && npm install && cd ..
```

### 3. Firebase Project Setup
- [ ] Create Firebase project at https://console.firebase.google.com/
- [ ] Enable Authentication → Anonymous sign-in
- [ ] Enable Cloud Firestore
- [ ] Enable Cloud Functions
- [ ] Enable Cloud Storage
- [ ] Enable Firebase Analytics
- [ ] Enable Remote Config
- [ ] Create Dynamic Link domain (e.g., iam.page.link)

### 4. FlutterFire CLI Setup
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Run configuration
flutterfire configure --project=YOUR_PROJECT_ID
```
- [ ] This generates `lib/firebase_options.dart`
- [ ] Uncomment import in `lib/main.dart`

### 5. Remote Config Values
Go to Firebase Console → Remote Config and add these parameters:
- [ ] `timer_seconds` = 12
- [ ] `max_rewarded_ads_per_day` = 5
- [ ] `max_rewarded_skips_per_day` = 3
- [ ] `daily_skips` = 3
- [ ] `coin_per_correct` = 1
- [ ] `skip_cost_coins` = 1
- [ ] `streak_save_alt_cost_coins` = 3
- [ ] `difficulty_mix_easy` = 0.6
- [ ] `difficulty_mix_medium` = 0.3
- [ ] `difficulty_mix_hard` = 0.1
- [ ] `streak_bonus_threshold` = 5
- [ ] `streak_bonus_coins` = 1
- [ ] `daily_login_coins` = 3
- [ ] `ugc_reward_coins` = 25
- [ ] `referral_coins_inviter` = 2
- [ ] `referral_coins_invitee` = 2
- [ ] `ad_cooldown_seconds` = 120

### 6. AdMob Setup
- [ ] Create app in AdMob console
- [ ] Create Rewarded Ad unit
- [ ] Copy App ID and Ad Unit IDs
- [ ] Update `lib/core/env.dart` with your IDs
- [ ] Add AdMob App ID to `android/app/src/main/AndroidManifest.xml`

### 7. Dynamic Links Setup
- [ ] Create Dynamic Link URL prefix in Firebase Console
- [ ] Update domain in `lib/core/env.dart`
- [ ] Add intent filter to `android/app/src/main/AndroidManifest.xml`

### 8. Deploy Firebase Resources
```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Cloud Functions
cd functions
npm run build
firebase deploy --only functions
cd ..
```

### 9. Seed Initial Data
- [ ] Import riddles from `seed_data/riddles.json` to Firestore
- [ ] Use Firebase Console or Admin SDK script
- [ ] Ensure each riddle has all required fields

### 10. Font Setup (Optional)
- [ ] Download Poppins font from Google Fonts
- [ ] Place in `assets/fonts/` directory:
  - `Poppins-Regular.ttf`
  - `Poppins-Medium.ttf`
  - `Poppins-SemiBold.ttf`
  - `Poppins-Bold.ttf`

### 11. Test Run
```bash
# Run on Android
flutter run

# Run tests
flutter test
```

### 12. Verify Features
- [ ] App launches and shows splash screen
- [ ] Can play riddles with timer
- [ ] Scoring works correctly
- [ ] Can navigate to all screens
- [ ] Remote Config values load (check logs)
- [ ] Ads initialize (test mode)

## 🔧 Troubleshooting

### Firebase Connection Issues
- Ensure `google-services.json` exists in `android/app/`
- Run `flutterfire configure` again if needed

### AdMob Not Working
- Verify App ID in AndroidManifest.xml
- Check that test mode is enabled during development
- Allow time for ad inventory to load

### Functions Deploy Fails
- Check Node version (must be 18)
- Run `npm install` in functions directory
- Check Firebase billing is enabled (Functions require Blaze plan)

### Riddles Not Loading
- Check Firestore rules are deployed
- Verify anonymous auth is enabled
- Check security rules allow read access for live riddles

## 📝 Notes

- Use **test Ad IDs** during development
- Enable **Firebase Emulator** for local development
- Set up **CI/CD** before production deployment
- Configure **app signing** for release builds

## 🎉 You're Ready!

Once all items are checked, your I AM game should be fully functional!

For detailed instructions, see [README.md](README.md)
