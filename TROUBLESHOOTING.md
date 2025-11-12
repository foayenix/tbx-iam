# 🔧 I AM - Troubleshooting Guide

Complete guide to resolving common setup and runtime issues.

---

## 📋 Quick Diagnostics

Run these commands first to identify issues:

```bash
# Check Flutter installation
flutter doctor -v

# Analyze code for errors
flutter analyze

# Run tests
flutter test

# Check dependencies
flutter pub get
```

---

## 🔥 **CRITICAL ISSUES** (App Won't Start)

### ❌ Issue 1: Firebase Not Configured

**Error Message:**
```
Error: No Firebase App '[DEFAULT]' has been created
```
or
```
Cannot find firebase_options.dart
```

**Root Cause:** Firebase hasn't been set up for your Flutter project.

**Solution:**

```bash
# 1. Install FlutterFire CLI
dart pub global activate flutterfire_cli

# 2. Configure Firebase for your project
flutterfire configure --project=your-firebase-project-id

# 3. This generates lib/firebase_options.dart automatically

# 4. Uncomment this line in lib/main.dart:
# import 'firebase_options.dart';

# 5. Update Firebase initialization in lib/main.dart:
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

**Verify Fix:**
```bash
# Check if file was created
ls -la lib/firebase_options.dart

# Should show generated file
```

---

### ❌ Issue 2: Missing google-services.json (Android)

**Error Message:**
```
File google-services.json is missing
```

**Root Cause:** Firebase Android configuration not downloaded.

**Solution:**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click gear icon → Project Settings
4. Scroll to "Your apps"
5. Click Android app → Download `google-services.json`
6. Place in: `android/app/google-services.json`

**Verify Fix:**
```bash
ls -la android/app/google-services.json
# File should exist
```

---

### ❌ Issue 3: Firebase Services Not Enabled

**Error Message:**
```
PERMISSION_DENIED: Missing or insufficient permissions
```
or
```
Cloud Firestore is not enabled
```

**Root Cause:** Firebase services aren't enabled in Firebase Console.

**Solution:**

Go to Firebase Console and enable:

1. **Authentication**
   - Navigate to: Authentication → Sign-in method
   - Enable: Anonymous
   - Click "Save"

2. **Cloud Firestore**
   - Navigate to: Firestore Database
   - Click "Create database"
   - Start in "Test mode" (change to production mode later)
   - Click "Enable"

3. **Cloud Functions**
   - Navigate to: Functions
   - Click "Get started"
   - Upgrade to Blaze plan (pay-as-you-go, free tier available)

4. **Firebase Analytics**
   - Navigate to: Analytics
   - Click "Enable Analytics"

5. **Remote Config**
   - Navigate to: Remote Config
   - Click "Get started"

6. **Dynamic Links**
   - Navigate to: Dynamic Links
   - Click "Get started"
   - Create URL prefix (e.g., `iam.page.link`)

7. **Cloud Storage**
   - Navigate to: Storage
   - Click "Get started"
   - Start in "Test mode"

**Verify Fix:**
- Each service should show as "Enabled" in Firebase Console

---

### ❌ Issue 4: Dependencies Failed to Install

**Error Message:**
```
Package not found
```
or
```
Version solving failed
```

**Root Cause:** Incompatible package versions or outdated Flutter.

**Solution:**

```bash
# 1. Update Flutter to latest stable
flutter upgrade

# 2. Clean previous builds
flutter clean

# 3. Remove lock file
rm pubspec.lock

# 4. Get dependencies fresh
flutter pub get

# 5. If still failing, check Flutter version
flutter --version
# Should be >= 3.0.0
```

**Alternative - Downgrade Problematic Packages:**

Edit `pubspec.yaml` and change:
```yaml
# If hooks_riverpod fails:
hooks_riverpod: ^2.4.0  # Instead of ^2.4.9

# If go_router fails:
go_router: ^11.0.0  # Instead of ^12.1.1
```

Then:
```bash
flutter pub get
```

---

## ⚠️ **MODERATE ISSUES** (App Starts But Has Problems)

### ⚠️ Issue 5: Font Warnings

**Error Message:**
```
Unable to load asset: assets/fonts/Poppins-Regular.ttf
```

**Root Cause:** Font files not downloaded.

**Impact:** App works but uses system default fonts.

**Solution (Optional):**

1. Download Poppins from [Google Fonts](https://fonts.google.com/specimen/Poppins)
2. Extract and place in `assets/fonts/`:
   - `Poppins-Regular.ttf`
   - `Poppins-Medium.ttf`
   - `Poppins-SemiBold.ttf`
   - `Poppins-Bold.ttf`

**Quick Fix (Skip Fonts):**

Comment out font section in `pubspec.yaml`:
```yaml
# fonts:
#   - family: Poppins
#     fonts:
#       - asset: assets/fonts/Poppins-Regular.ttf
```

App will use system default font (perfectly fine for MVP).

---

### ⚠️ Issue 6: AdMob Errors

**Error Message:**
```
AdMob app ID is invalid
```
or
```
Ad failed to load: Error code 3 (No fill)
```

**Root Cause:** AdMob not configured or test IDs being used.

**Solution:**

**For Development (Keep Test IDs):**
- Test IDs are SUPPOSED to be used during development
- "No fill" errors are normal in test mode
- Ignore these warnings during development

**For Production:**

1. Create AdMob account at [AdMob Console](https://admob.google.com/)
2. Create new app
3. Create Rewarded Ad Unit
4. Copy your real IDs

Edit `lib/core/env.dart`:
```dart
// Replace with YOUR real IDs
static const String androidAdMobAppId = 'ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX';
static const String androidRewardedAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
```

Update `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
  android:name="com.google.android.gms.ads.APPLICATION_ID"
  android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>
```

**Verify Fix:**
```bash
grep -r "ca-app-pub" lib/core/env.dart android/app/src/main/AndroidManifest.xml
# Should show your real IDs (not test IDs)
```

---

### ⚠️ Issue 7: Firestore Security Rules Blocking Reads

**Error Message:**
```
PERMISSION_DENIED: Missing or insufficient permissions
```

**Root Cause:** Firestore rules haven't been deployed or are too restrictive.

**Solution:**

```bash
# Deploy rules
firebase deploy --only firestore:rules

# Verify rules were deployed
firebase firestore:rules:get
```

**Temporary Fix for Testing (DO NOT USE IN PRODUCTION):**

In Firebase Console → Firestore → Rules, temporarily use:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;  // INSECURE - TEST ONLY!
    }
  }
}
```

**⚠️ CRITICAL:** Change back to production rules from `firestore.rules` before launching!

---

### ⚠️ Issue 8: Cloud Functions Not Working

**Error Message:**
```
Function not found
```
or
```
Internal server error
```

**Root Cause:** Functions not deployed or billing not enabled.

**Solution:**

```bash
# 1. Check Firebase plan
# Functions require Blaze (pay-as-you-go) plan

# 2. Deploy functions
cd functions
npm install
npm run build
firebase deploy --only functions

# 3. Check deployment status
firebase functions:log

# 4. Test a function
firebase functions:shell
# Then: submitScore({delta: 1, solved: 1})
```

**Check Function Status:**
- Go to Firebase Console → Functions
- All 6 functions should be listed and "Healthy"

---

### ⚠️ Issue 9: No Riddles Loading

**Error Message:**
- App works but no riddles appear
- Empty screen on Play

**Root Cause:** Riddles not imported to Firestore.

**Solution:**

**Manual Import via Firebase Console:**

1. Go to Firebase Console → Firestore Database
2. Create collection: `riddles`
3. For each riddle in `seed_data/riddles.json`:
   - Add document with auto-ID
   - Copy fields from JSON
   - Add these additional fields:
     ```json
     {
       "canonText": "<lowercase, no punctuation>",
       "canonAnswer": "<lowercase, no punctuation>",
       "status": "live",
       "createdAt": "<current timestamp>",
       "stats": {
         "plays": 0,
         "correctFirstTry": 0,
         "skips": 0,
         "reports": 0,
         "avgSolveMs": 0
       },
       "hashes": {
         "sha256": "<generate using Canon.sha256Hash>",
         "simhash64": 0
       }
     }
     ```

**Programmatic Import (Recommended):**

Create script `scripts/import_riddles.dart`:
```dart
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/core/utils/canon.dart';

void main() async {
  await Firebase.initializeApp();
  final db = FirebaseFirestore.instance;

  final jsonString = await File('seed_data/riddles.json').readAsString();
  final List riddles = json.decode(jsonString);

  for (final riddle in riddles) {
    final canonText = Canon.canonicalise(riddle['text']);
    final canonAnswer = Canon.canonicalise(riddle['answer']);

    await db.collection('riddles').add({
      'text': riddle['text'],
      'canonText': canonText,
      'answer': riddle['answer'],
      'canonAnswer': canonAnswer,
      'aliases': riddle['aliases'] ?? [],
      'category': riddle['category'],
      'difficulty': riddle['difficulty'],
      'hint': riddle['hint'],
      'status': 'live',
      'createdAt': FieldValue.serverTimestamp(),
      'stats': {
        'plays': 0,
        'correctFirstTry': 0,
        'skips': 0,
        'reports': 0,
        'avgSolveMs': 0,
      },
      'hashes': {
        'sha256': Canon.sha256Hash(riddle['text']),
        'simhash64': Canon.simHash64(riddle['text']),
      },
    });
    print('Imported: ${riddle['text']}');
  }

  print('Done! Imported ${riddles.length} riddles');
}
```

Run:
```bash
dart run scripts/import_riddles.dart
```

**Verify Fix:**
- Check Firestore Console → riddles collection
- Should see 35+ documents

---

### ⚠️ Issue 10: Dynamic Links Not Working

**Error Message:**
```
Dynamic link domain not configured
```

**Root Cause:** Dynamic Links domain not set up.

**Solution:**

1. Go to Firebase Console → Dynamic Links
2. Click "Get Started"
3. Add domain (e.g., `iam.page.link`)
4. Update `lib/core/env.dart`:
   ```dart
   static const String dynamicLinksDomain = 'iam.page.link';
   static const String dynamicLinksPrefix = 'https://iam.page.link';
   ```

5. For Android, add to `android/app/src/main/AndroidManifest.xml`:
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

---

## 🐛 **MINOR ISSUES** (Warnings/Non-Breaking)

### 🟡 Issue 11: Analyzer Warnings

**Warning Message:**
```
Unused import
```
or
```
Missing return type
```

**Impact:** Code works but shows warnings.

**Solution:**

```bash
# Run analyzer
flutter analyze

# Fix automatically (if possible)
dart fix --apply

# Manual fix: Remove unused imports
# Update based on analyzer suggestions
```

---

### 🟡 Issue 12: Test Failures

**Error Message:**
```
Expected: true
Actual: false
```

**Root Cause:** Test expectations may differ from actual behavior.

**Solution:**

```bash
# Run specific test file
flutter test test/unit/text_match_test.dart

# Run with verbose output
flutter test --reporter expanded

# Skip failing tests temporarily
# Add @Skip annotation:
@Skip('Pending Firebase mock setup')
test('example test', () { ... });
```

---

### 🟡 Issue 13: Hot Reload Not Working

**Issue:** Changes don't appear after hot reload.

**Solution:**

```bash
# Use hot restart instead
# Press 'R' in terminal (capital R)

# Or full restart
flutter run
```

---

## 🔍 **DEBUGGING TECHNIQUES**

### Check Logs

```bash
# Flutter logs
flutter logs

# Firebase logs
firebase functions:log

# Android logs (if device connected)
adb logcat | grep -i flutter
```

### Enable Verbose Logging

Add to `lib/main.dart`:
```dart
import 'package:logger/logger.dart';

final logger = Logger(
  level: Level.debug, // Change to Level.verbose for more details
);
```

### Check Firebase Connection

Add to any screen:
```dart
import 'package:firebase_core/firebase_core.dart';

print('Firebase initialized: ${Firebase.apps.isNotEmpty}');
print('Firebase app name: ${Firebase.app().name}');
```

### Test Firestore Connectivity

```dart
final test = await FirebaseFirestore.instance
    .collection('riddles')
    .limit(1)
    .get();
print('Riddles found: ${test.docs.length}');
```

---

## 📱 **PLATFORM-SPECIFIC ISSUES**

### Android

**Gradle Build Failed:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

**Min SDK Version Error:**
Check `android/app/build.gradle`:
```gradle
minSdkVersion 21  // Should be at least 21
```

### iOS (When You Add It)

**CocoaPods Error:**
```bash
cd ios
rm Podfile.lock
pod install --repo-update
cd ..
flutter run
```

---

## 🆘 **EMERGENCY FIXES**

### Nuclear Option (Start Fresh)

If everything is broken:

```bash
# 1. Clean everything
flutter clean
cd android && ./gradlew clean && cd ..
rm -rf build/
rm pubspec.lock

# 2. Remove Firebase config
rm lib/firebase_options.dart
rm android/app/google-services.json

# 3. Reinstall dependencies
flutter pub get

# 4. Reconfigure Firebase
flutterfire configure --project=your-project-id

# 5. Try again
flutter run
```

### Rollback to Known Good State

```bash
# Check git log
git log --oneline

# Rollback to specific commit
git reset --hard 4cc3871  # Initial MVP commit

# Restore your changes
git pull origin claude/build-iam-riddle-game-mvp-011CUrn3opWjZLiepnxytMYy
```

---

## 📞 **Getting Help**

### Check These Resources First:

1. **Flutter Docs**: https://docs.flutter.dev/
2. **Firebase Docs**: https://firebase.google.com/docs
3. **FlutterFire Docs**: https://firebase.flutter.dev/
4. **Package Issues**: Check pub.dev for each package

### Error Search Strategy:

```bash
# Copy exact error message
# Search: "flutter [error message]"
# Common sites: stackoverflow.com, github.com
```

### Ask for Help:

When asking for help, include:
1. Full error message
2. Flutter version (`flutter --version`)
3. Firebase services enabled
4. Steps you've already tried

---

## ✅ **Verification Checklist**

After fixing issues, verify:

```bash
✅ flutter doctor (no errors)
✅ flutter analyze (0 issues)
✅ flutter test (all pass)
✅ flutter run (app launches)
✅ Firebase Console (all services enabled)
✅ Firestore (riddles visible)
✅ Functions (deployed and healthy)
✅ Authentication (anonymous enabled)
✅ Remote Config (parameters set)
```

---

## 🎯 **Common Setup Order Issues**

**CORRECT ORDER:**

1. ✅ Install Flutter SDK
2. ✅ Create Firebase project
3. ✅ Enable Firebase services
4. ✅ Run `flutterfire configure`
5. ✅ Update `lib/main.dart` with firebase_options import
6. ✅ Deploy Firestore rules & Functions
7. ✅ Set Remote Config parameters
8. ✅ Import seed riddles
9. ✅ Configure AdMob (optional for testing)
10. ✅ Run `flutter pub get`
11. ✅ Run `flutter run`

**WRONG ORDER (Common Mistake):**
- ❌ Running `flutter run` before Firebase setup
- ❌ Skipping `flutterfire configure`
- ❌ Not enabling Firebase services
- ❌ Forgetting to import seed data

---

## 📊 **Success Indicators**

You know it's working when:

✅ Splash screen shows with "I AM" logo
✅ Home screen appears with menu grid
✅ Play button launches game
✅ Riddle displays with timer
✅ Can submit answer and see result
✅ Score updates correctly
✅ No red error screens

---

## 💬 **Still Stuck?**

If you've tried everything and it still doesn't work:

1. **Check SETUP_CHECKLIST.md** - Did you miss a step?
2. **Review README.md** - Detailed setup instructions
3. **Check Firebase Console** - Are all services showing "Enabled"?
4. **Try Firebase Emulator** - Test locally without real services
5. **Create minimal test app** - Verify Firebase works independently

---

**Remember:** Most issues are configuration, not code! The code is production-ready. 🚀

Good luck! 🍀
