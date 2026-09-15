# 0002. App Update and Backup Persistence

## Status

Accepted

## Date

2026-09-15

## Context

*knew* relies on local storage (SQLite database and shared preferences) on the user's mobile device ([ADR-0001](0001-local-storage.md)). Maintaining user vocabulary, learning levels, spaced-repetition progress, and preferences across application updates and device transfers is critical.

To ensure data integrity, we need clear definitions, documented guarantees, and explicit platform configurations for:
1. In-place application updates (installing a new app version over an existing installation).
2. Android Auto Backup (cloud backup and device-to-device transfer).
3. iOS device backups (iCloud and iTunes/Finder device backups).
4. Manual point-in-time JSON export/import.

## Decision

### 1. In-place OS Updates

* In-place operating system application updates preserve the existing application sandbox and local storage (`knew.db` and preferences), provided database schema migrations and update routines are strictly non-destructive.
* Application identities must remain permanently stable across releases:
  * Android: `applicationId = "com.danielrispler.knew"` with a consistent release signing identity.
  * iOS: `PRODUCT_BUNDLE_IDENTIFIER = "com.danielrispler.knew"` under a stable development team and compatible entitlements. Provisioning profiles may be rotated or regenerated as needed without affecting update compatibility.

### 2. Android Auto Backup Configuration

* Android Auto Backup is enabled explicitly (`android:allowBackup="true"`) with targeted XML configuration rules:
  * `res/xml/data_extraction_rules.xml` for Android 12+ (API 31+).
  * `res/xml/full_backup_content.xml` for legacy Android versions.
* Backup rules use directory-wide inclusion (`path="."`) to establish an explicit allowlist:
  * SQLite database directory (`<include domain="database" path="." />`). This covers `knew.db` and any SQLite sidecars (WAL, SHM, journal).
  * Shared preferences directory (`<include domain="sharedpref" path="." />`).
* Explicitly exclude hardware-bound encrypted keys (such as `FlutterSecureStorage.xml`) from backup, because Android KeyStore keys do not transfer across devices and attempting to decrypt restored secure storage on a new device will fail.
* Explicit XML rules make backup behavior intentional, documented, and testable using Android Backup Manager CLI tools (`adb shell bmgr`).

### 3. iOS Device Backup

* Persistent application data (including `knew.db`) is stored in standard, backup-eligible iOS sandbox locations (`Documents` / `Application Support`).
* Application data is eligible for inclusion in full iOS device backups (iCloud backup / Finder backup).
* Deleting and reinstalling the app alone is **not** a per-app restore mechanism on iOS, as deleting an app purges its local sandbox container.

### 4. Manual JSON Export/Import

* Manual JSON export/import serves as the primary user-controlled point-in-time backup and disaster recovery mechanism across devices.
* Export files contain full user-owned learning state (vocabulary entries, meanings, spaced-repetition progress, and settings).

### 5. Guarantees and Risk Assessment

* Absolute guarantees such as "100% preserved" or "zero-data-loss" are avoided because platform backups (e.g., Android Auto Backup, iOS device backup) are asynchronous, subject to user settings/storage limits, and best-effort disaster recovery systems.
* In-place updates preserve local data if the signing key is preserved and schema migrations execute transactionally without destructive drops.

## Consequences

* Android backup rules XML files (`data_extraction_rules.xml` and `full_backup_content.xml`) are tracked in source control.
* CI and build manifests must enforce stable application IDs (`com.danielrispler.knew`).
* SQLite database migrations must be covered by automated tests to ensure schema upgrades never drop or corrupt existing tables.
