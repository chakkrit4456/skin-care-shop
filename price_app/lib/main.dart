import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/api.dart';
import 'core/l10n.dart';
import 'core/prefs.dart';
import 'core/router.dart';
import 'core/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await api.init();
  await appPrefs.load();
  // Flutter web doesn't re-measure text when a font arrives late, which clips Thai labels.
  GoogleFonts.promptTextTheme();
  GoogleFonts.notoSansScTextTheme();
  for (final w in [FontWeight.w400, FontWeight.w500, FontWeight.w600, FontWeight.w700]) {
    GoogleFonts.prompt(fontWeight: w);
    GoogleFonts.notoSansSc(fontWeight: w);
  }
  await GoogleFonts.pendingFonts().catchError((_) => <void>[]);
  runApp(const ProviderScope(child: PriceApp()));
}

class PriceApp extends ConsumerWidget {
  const PriceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(prefsProvider);
    return MaterialApp.router(
      title: 'ร้านแต๊ะเอียสกินช็อป',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: prefs.themeMode,
      locale: prefs.locale,
      supportedLocales: const [Locale('th'), Locale('en'), Locale('zh')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => L10nScope(code: prefs.locale.languageCode, child: child ?? const SizedBox.shrink()),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
