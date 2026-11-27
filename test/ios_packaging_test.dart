import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _packageRoot = 'ios/open_apps_settings_fork';
const _sourceRoot = '$_packageRoot/Sources/open_apps_settings_fork';

String _readRequiredFile(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: 'Missing packaging file: $path');
  return file.readAsStringSync();
}

void main() {
  group('iOS SwiftPM packaging', () {
    test('manifest uses Swift tools 5.9 and iOS 13', () {
      final manifest = _readRequiredFile('$_packageRoot/Package.swift');

      expect(
        manifest,
        matches(
          RegExp(r'^// swift-tools-version:\s*5\.9\s*$', multiLine: true),
        ),
      );
      expect(manifest, matches(RegExp(r'\.iOS\(\s*(?:\.v13|"13\.0")\s*\)')));
    });

    test('library product exposes the plugin target', () {
      final manifest = _readRequiredFile('$_packageRoot/Package.swift');

      expect(
        manifest,
        matches(
          RegExp(
            r'\.library\(\s*name:\s*"open-apps-settings-fork"\s*,'
            r'\s*targets:\s*\[\s*"open_apps_settings_fork"\s*,?\s*\]',
          ),
        ),
      );
      expect(
        manifest,
        matches(RegExp(r'\.target\(\s*name:\s*"open_apps_settings_fork"')),
      );
    });

    test('plugin target depends on the local FlutterFramework product', () {
      final manifest = _readRequiredFile('$_packageRoot/Package.swift');

      expect(
        manifest,
        matches(
          RegExp(
            r'\.package\(\s*(?:name:\s*"FlutterFramework"\s*,\s*)?'
            r'path:\s*"\.\./FlutterFramework"\s*,?\s*\)',
          ),
        ),
      );
      expect(
        manifest,
        matches(
          RegExp(
            r'\.target\(\s*name:\s*"open_apps_settings_fork"\s*,'
            r'[\s\S]*?dependencies:\s*\[[\s\S]*?'
            r'\.product\(\s*name:\s*"FlutterFramework"\s*,'
            r'\s*package:\s*"FlutterFramework"\s*,?\s*\)',
          ),
        ),
      );
    });

    test('shared Swift-only source exposes the pubspec plugin class', () {
      final source = _readRequiredFile(
        '$_sourceRoot/OpenAppsSettingsForkPlugin.swift',
      );
      final pubspec = _readRequiredFile('pubspec.yaml');

      expect(
        source,
        matches(
          RegExp(
            r'public\s+(?:final\s+)?class\s+OpenAppsSettingsForkPlugin\s*'
            r':\s*NSObject\s*,\s*FlutterPlugin\b',
          ),
        ),
      );
      expect(
        pubspec,
        matches(
          RegExp(
            r'^      ios:\s*\n\s+pluginClass:\s*OpenAppsSettingsForkPlugin\s*$',
            multiLine: true,
          ),
        ),
      );
      final nativeSources = Directory(_sourceRoot)
          .listSync(recursive: true)
          .whereType<File>()
          .map((file) => file.path)
          .where((path) => RegExp(r'\.(swift|h|m|mm)$').hasMatch(path));
      expect(nativeSources, isNotEmpty);
      expect(nativeSources, everyElement(endsWith('.swift')));
    });
  });

  group('CocoaPods shares the SwiftPM implementation', () {
    test('source glob points to the shared Swift source directory', () {
      final podspec = _readRequiredFile('ios/open_apps_settings_fork.podspec');

      expect(
        podspec,
        matches(
          RegExp(
            r'''\.source_files\s*=\s*['"]open_apps_settings_fork/Sources/open_apps_settings_fork/[^'"\r\n]+['"]''',
          ),
        ),
      );
    });

    test('minimum deployment target is iOS 13', () {
      final podspec = _readRequiredFile('ios/open_apps_settings_fork.podspec');

      expect(
        podspec,
        matches(
          RegExp(
            r'''(?:\.platform\s*=\s*:ios\s*,\s*|\.ios\.deployment_target\s*=\s*)['"]13\.0['"]''',
          ),
        ),
      );
    });
  });

  group('SwiftPM Flutter integration SDK requirements', () {
    late String environment;

    setUp(() {
      final pubspec = _readRequiredFile('pubspec.yaml');
      final match = RegExp(
        r'^environment:[ \t]*\r?\n((?:[ \t]+[^\n]*\n|\r?\n)*)',
        multiLine: true,
      ).firstMatch(pubspec);
      expect(match, isNotNull, reason: 'pubspec must declare environment');
      environment = match!.group(1)!;
    });

    test('Dart SDK requires >=3.11.0 <4.0.0', () {
      expect(
        environment,
        matches(
          RegExp(
            r'''^\s+sdk:\s*['"]>=3\.11\.0 <4\.0\.0['"]\s*$''',
            multiLine: true,
          ),
        ),
      );
    });

    test('Flutter SDK requires >=3.41.0', () {
      expect(
        environment,
        matches(
          RegExp(r'''^\s+flutter:\s*['"]>=3\.41\.0['"]\s*$''', multiLine: true),
        ),
      );
    });
  });
}
