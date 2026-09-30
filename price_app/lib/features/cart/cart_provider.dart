import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'cart';

/// productId -> qty, persisted locally.
class CartNotifier extends Notifier<Map<int, int>> {
  @override
  Map<int, int> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    if (raw == null) return;
    final m = (jsonDecode(raw) as Map<String, dynamic>).map((k, v) => MapEntry(int.parse(k), v as int));
    state = {...m, ...state};
  }

  Future<void> _save() async {
    (await SharedPreferences.getInstance())
        .setString(_key, jsonEncode(state.map((k, v) => MapEntry(k.toString(), v))));
  }

  void add(int productId, int qty) {
    state = {...state, productId: (state[productId] ?? 0) + qty};
    _save();
  }

  void setQty(int productId, int qty) {
    state = qty < 1 ? ({...state}..remove(productId)) : {...state, productId: qty};
    _save();
  }

  void clear() {
    state = {};
    _save();
  }
}

final cartProvider = NotifierProvider<CartNotifier, Map<int, int>>(CartNotifier.new);

final cartCountProvider = Provider<int>((ref) => ref.watch(cartProvider).values.fold(0, (a, b) => a + b));
