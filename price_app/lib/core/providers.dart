import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api.dart';
import 'live.dart';
import 'models.dart';

/// Rebuilds dependents whenever the user logs in or out.
final authStateProvider = ChangeNotifierProvider<ApiClient>((ref) => api);

final profileProvider = FutureProvider<Profile?>((ref) async {
  if (!ref.watch(authStateProvider).loggedIn) return null;
  refreshOnLive(ref, {'users'});
  try {
    return Profile.fromJson(await api.get('/me'));
  } on ApiException catch (e) {
    if (e.status == 401) return null;
    rethrow;
  }
});

final isVipProvider = Provider<bool>((ref) => ref.watch(profileProvider).valueOrNull?.isVip ?? false);
final isAdminProvider = Provider<bool>((ref) => ref.watch(profileProvider).valueOrNull?.isAdmin ?? false);

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  refreshOnLive(ref, {'categories'});
  final rows = await api.get('/categories') as List;
  return rows.map((r) => Category.fromJson(r)).toList();
});

final productsProvider = FutureProvider<List<Product>>((ref) async {
  ref.watch(authStateProvider); // admins also see inactive products
  refreshOnLive(ref, {'products'});
  final rows = await api.get('/products') as List;
  return rows.map((r) => Product.fromJson(r)).toList();
});

final addressesProvider = FutureProvider<List<Address>>((ref) async {
  if (!ref.watch(authStateProvider).loggedIn) return [];
  refreshOnLive(ref, {'addresses'});
  final rows = await api.get('/me/addresses') as List;
  return rows.map((r) => Address.fromJson(r)).toList();
});

final myOrdersProvider = FutureProvider<List<Order>>((ref) async {
  if (!ref.watch(authStateProvider).loggedIn) return [];
  refreshOnLive(ref, {'orders'});
  final rows = await api.get('/orders/mine') as List;
  return rows.map((r) => Order.fromJson(r)).toList();
});
