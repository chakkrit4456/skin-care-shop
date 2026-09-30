import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs extends ChangeNotifier {
  Locale locale = const Locale('th');
  ThemeMode themeMode = ThemeMode.light;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    locale = Locale(switch (p.getString('locale')) { 'en' => 'en', 'zh' => 'zh', _ => 'th' });
    themeMode = switch (p.getString('theme')) { 'dark' => ThemeMode.dark, 'system' => ThemeMode.system, _ => ThemeMode.light };
  }

  Future<void> setLocale(String code) async {
    locale = Locale(code);
    await (await SharedPreferences.getInstance()).setString('locale', code);
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode mode) async {
    themeMode = mode;
    final name = switch (mode) { ThemeMode.dark => 'dark', ThemeMode.system => 'system', _ => 'light' };
    await (await SharedPreferences.getInstance()).setString('theme', name);
    notifyListeners();
  }
}

final appPrefs = AppPrefs();
final prefsProvider = ChangeNotifierProvider<AppPrefs>((ref) => appPrefs);
