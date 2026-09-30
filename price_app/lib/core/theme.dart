import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

const brandGreen = Color(0xFF22C55E);
const brandGreenDark = Color(0xFF16A34A);
const brandGreenLight = Color(0xFFDCFCE7);
const ink = Color(0xFF1F2937);
const muted = Color(0xFF9CA3AF);

final _baht = NumberFormat('#,##0.##', 'en_US');
String baht(num v) => '฿${_baht.format(v)}';

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(seedColor: brandGreen, primary: brandGreen, brightness: brightness),
    scaffoldBackgroundColor: dark ? const Color(0xFF111827) : const Color(0xFFF6F7F9),
    fontFamily: GoogleFonts.prompt().fontFamily,
    fontFamilyFallback: [GoogleFonts.notoSansSc().fontFamily ?? 'Noto Sans SC'],
  );
  final surface = dark ? const Color(0xFF1F2937) : Colors.white;
  final onSurface = dark ? Colors.white : ink;
  final border = OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: dark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)));
  return base.copyWith(
    textTheme: GoogleFonts.promptTextTheme(base.textTheme).apply(bodyColor: onSurface, displayColor: onSurface),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeSlidePageTransitionsBuilder(),
      TargetPlatform.iOS: FadeSlidePageTransitionsBuilder(),
      TargetPlatform.macOS: FadeSlidePageTransitionsBuilder(),
      TargetPlatform.windows: FadeSlidePageTransitionsBuilder(),
      TargetPlatform.linux: FadeSlidePageTransitionsBuilder(),
      TargetPlatform.fuchsia: FadeSlidePageTransitionsBuilder(),
    }),
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: onSurface,
      surfaceTintColor: surface,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: Colors.black26,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: surface,
      surfaceTintColor: surface,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: brandGreen, width: 1.6)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: brandGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 1.5,
      shadowColor: dark ? Colors.black54 : const Color(0x1A16A34A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
    ),
  );
}

class FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}
