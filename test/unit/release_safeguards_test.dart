import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Release Safeguards & Package Invariants', () {
    test('Android applicationId is locked to com.danielrispler.knew', () {
      final file = File('android/app/build.gradle.kts');
      expect(file.existsSync(), isTrue, reason: 'android/app/build.gradle.kts must exist');
      final content = file.readAsStringSync();

      expect(
        content.contains('applicationId = "com.danielrispler.knew"'),
        isTrue,
        reason: 'Android applicationId must be permanently com.danielrispler.knew',
      );
    });

    test('iOS PRODUCT_BUNDLE_IDENTIFIER is locked to com.danielrispler.knew', () {
      final file = File('ios/Runner.xcodeproj/project.pbxproj');
      expect(file.existsSync(), isTrue, reason: 'project.pbxproj must exist');
      final content = file.readAsStringSync();

      expect(
        content.contains('PRODUCT_BUNDLE_IDENTIFIER = com.danielrispler.knew;'),
        isTrue,
        reason: 'iOS PRODUCT_BUNDLE_IDENTIFIER must be permanently com.danielrispler.knew',
      );
    });

    test('AndroidManifest specifies explicit backup rules and allowBackup', () {
      final file = File('android/app/src/main/AndroidManifest.xml');
      expect(file.existsSync(), isTrue, reason: 'AndroidManifest.xml must exist');
      final content = file.readAsStringSync();

      expect(content.contains('android:allowBackup="true"'), isTrue);
      expect(content.contains('android:dataExtractionRules="@xml/data_extraction_rules"'), isTrue);
      expect(content.contains('android:fullBackupContent="@xml/full_backup_content"'), isTrue);
    });

    test('Backup XML rules exist and exclude FlutterSecureStorage', () {
      final dataRules = File('android/app/src/main/res/xml/data_extraction_rules.xml');
      final fullRules = File('android/app/src/main/res/xml/full_backup_content.xml');

      expect(dataRules.existsSync(), isTrue);
      expect(fullRules.existsSync(), isTrue);

      final dataContent = dataRules.readAsStringSync();
      final fullContent = fullRules.readAsStringSync();

      expect(dataContent.contains('domain="database"'), isTrue);
      expect(dataContent.contains('domain="sharedpref"'), isTrue);
      expect(dataContent.contains('FlutterSecureStorage.xml'), isTrue);

      expect(fullContent.contains('domain="database"'), isTrue);
      expect(fullContent.contains('domain="sharedpref"'), isTrue);
      expect(fullContent.contains('FlutterSecureStorage.xml'), isTrue);
    });
  });
}
