# Backup, Updates, and Data Persistence Guide

This document describes how data persistence, application updates, and disaster recovery work in *knew*.

---

## 1. Storage & Persistence Overview

*knew* stores user vocabulary entries, meanings, spaced-repetition levels, and settings locally on device using SQLite (`knew.db`) and shared preferences.

### Data Classification

| Data Category | Storage Location | Preserved across OS App Updates? | Android Auto Backup Eligible? | iOS Device Backup Eligible? | Notes |
|---|---|---|---|---|---|
| **Vocabulary & Progress** | SQLite (`knew.db`) | Yes | Yes (`domain="database"`) | Yes (`Documents`) | Primary user learning data. |
| **User Preferences** | Shared Preferences | Yes | Yes (`domain="sharedpref"`) | Yes (`Library/Preferences`) | Theme, session size, language settings. |
| **Gemini API Key** | Secure Storage (`FlutterSecureStorage`) | Yes (same device) | Excluded | Excluded | Encrypted with hardware KeyStore key; excluded from Auto Backup to prevent decryption errors on new devices. |
| **Caches & Temporary Data** | Cache / Temp directories | No guarantee | Excluded | Excluded | Re-creatable temporary files. |

---

## 2. Distinction Between Backup & Recovery Mechanisms

### A. Normal Application Update (In-Place OS Update)
* **How it works**: Installing a new version of *knew* directly over an existing installation without uninstalling.
* **Expected Result**: All local data in SQLite (`knew.db`) and preferences remain intact.
* **Requirements**:
  * Stable Android `applicationId`: `com.danielrispler.knew`
  * Stable iOS `PRODUCT_BUNDLE_IDENTIFIER`: `com.danielrispler.knew`
  * Consistent signing keys between releases.
  * Non-destructive, transactional database migrations.

### B. Manual JSON Export/Import (Primary User Recovery)
* **How it works**: User generates an atomic `.json` export file from Settings and saves or shares it. When imported on any device running *knew*, entries and progress are restored/merged.
* **Expected Result**: Point-in-time snapshot recovery across devices or fresh installs.
* **Scope**: Contains all user-created vocabulary, meanings, learning levels, review timestamps, and settings.

### C. Android Auto Backup (Asynchronous Disaster Recovery)
* **How it works**: Android automatically backs up eligible application data (`database` and `sharedpref` domains) to Google Drive or during device-to-device transfer.
* **Expected Result**: Data is restored automatically upon fresh installation on a new device logged into the same Google account.
* **Caveat**: Asynchronous and best-effort. Reinstalling the app without an internet connection or cloud backup enabled will not restore data.

### D. iOS Device Backup (Full Device Restore)
* **How it works**: `knew.db` is stored in the app's `Documents` directory, which is included in iCloud and Finder full device backups.
* **Expected Result**: Restoring an entire iPhone backup to a new device restores *knew* and its database.
* **Caveat**: Deleting and reinstalling the app alone on iOS purges the local sandbox container and is **not** a per-app restore flow.

---

## 3. Manual Release Validation Procedures

### Android In-Place Update Acceptance Test (Step 9)

1. Build and install version 1 APK:
   ```bash
   flutter build apk --release
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```
2. Launch *knew*, add vocabulary entries, and complete a practice session.
3. Increment version in `pubspec.yaml` (or simulate v2 build).
4. Build and install version 2 APK **over** v1 without uninstalling:
   ```bash
   flutter build apk --release
   adb install -r build/app/outputs/flutter-apk/app-release.apk
   ```
5. Launch *knew* v2 and verify all original vocabulary entries, levels, and review dates exist.

### Android Auto Backup & Restore Test (Step 10)

1. Install app on emulator/test device and populate test data.
2. Force Android Backup Manager to run:
   ```bash
   adb shell bmgr enable true
   adb shell bmgr transport com.google.android.gms/.backup.BackupTransportService
   adb shell bmgr backupnow com.danielrispler.knew
   ```
3. Clear application storage (or uninstall/reinstall):
   ```bash
   adb shell pm clear com.danielrispler.knew
   ```
4. Trigger restore:
   ```bash
   adb shell bmgr restore com.danielrispler.knew
   ```
5. Launch *knew* and verify database entries are restored cleanly.

### iOS Persistence & Update Test (Step 11)

1. Run application in iOS Simulator / Device.
2. Populate vocabulary data.
3. Re-run app from Xcode / CLI as an update over the installed app container.
4. Verify local SQLite data persists cleanly across launches.
