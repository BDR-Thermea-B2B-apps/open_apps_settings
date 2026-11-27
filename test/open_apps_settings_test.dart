import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_apps_settings_fork/open_apps_settings.dart';
import 'package:open_apps_settings_fork/settings_enum.dart';

void main() {
  const MethodChannel channel = MethodChannel('open_apps_settings');
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test(
    'openAppsSettings propagates platform errors and sends setting code',
    () async {
      final calls = <MethodCall>[];
      var completed = false;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        MethodCall call,
      ) async {
        calls.add(call);
        throw PlatformException(
          code: 'settings_unavailable',
          message: 'Could not open Settings!',
          details: {'setting_code': 'app_settings'},
        );
      });

      await expectLater(
        OpenAppsSettings.openAppsSettings(
          settingsCode: SettingsCode.APP_SETTINGS,
          onCompletion: () => completed = true,
        ),
        throwsA(
          isA<PlatformException>()
              .having((error) => error.code, 'code', 'settings_unavailable')
              .having(
                (error) => error.message,
                'message',
                'Could not open Settings!',
              )
              .having((error) => error.details, 'details', {
                'setting_code': 'app_settings',
              }),
        ),
      );
      expect(calls, hasLength(1));
      expect(calls.single.method, 'openSettings');
      expect(calls.single.arguments, {'setting_code': 'app_settings'});
      expect(completed, isFalse);
    },
  );

  test(
    'openAppsSettings propagates an unimplemented platform method',
    () async {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);

      await expectLater(
        OpenAppsSettings.openAppsSettings(
          settingsCode: SettingsCode.APP_SETTINGS,
        ),
        throwsA(isA<MissingPluginException>()),
      );
    },
  );
}
