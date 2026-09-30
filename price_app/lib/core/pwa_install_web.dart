import 'dart:js_interop';

@JS('pwaStandalone')
external String _pwaStandalone();

@JS('pwaPlatform')
external String _pwaPlatform();

@JS('downloadAndroidApk')
external void _downloadAndroidApk();

@JS('installAndroidApp')
external JSPromise<JSString> _installAndroidApp();

String _call(String Function() fn, String fallback) {
  try {
    return fn();
  } catch (_) {
    return fallback;
  }
}

bool get isStandalonePwa => _call(() => _pwaStandalone(), '0') == '1';

bool get isIosDevice => _call(() => _pwaPlatform(), 'other') == 'ios';

bool get isAndroidDevice => _call(() => _pwaPlatform(), 'other') == 'android';

void downloadAndroidApk() => _downloadAndroidApk();

Future<String> promptAndroidInstall() async {
  try {
    final result = await _installAndroidApp().toDart;
    return result.toDart;
  } catch (_) {
    return 'unavailable';
  }
}
