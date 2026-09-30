import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/admin_categories_screen.dart';
import '../features/admin/admin_orders_screen.dart';
import '../features/admin/admin_product_form.dart';
import '../features/admin/admin_products_screen.dart';
import '../features/admin/admin_shell.dart';
import '../features/admin/admin_users_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/profile_screen.dart';
import '../features/settings/legal_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/catalog/catalog_screen.dart';
import '../features/orders/orders_screen.dart';
import 'api.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    refreshListenable: api,
    redirect: (context, state) {
      final loggedIn = api.loggedIn;
      final path = state.matchedLocation;
      final needsLogin = path.startsWith('/orders') || path.startsWith('/admin') || path.startsWith('/profile');
      if (needsLogin && !loggedIn) return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      if (loggedIn && (path == '/login' || path == '/register')) return state.uri.queryParameters['from'] ?? '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const CatalogScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
      GoRoute(path: '/orders', builder: (_, __) => const OrdersScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/legal/:doc', builder: (_, s) => LegalScreen(doc: s.pathParameters['doc']!)),
      ShellRoute(
        builder: (_, state, child) => AdminShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/admin', redirect: (_, __) => '/admin/products'),
          GoRoute(path: '/admin/products', builder: (_, __) => const AdminProductsScreen()),
          GoRoute(
            path: '/admin/products/:id',
            builder: (_, s) => AdminProductForm(productId: int.tryParse(s.pathParameters['id']!)),
          ),
          GoRoute(path: '/admin/categories', builder: (_, __) => const AdminCategoriesScreen()),
          GoRoute(path: '/admin/orders', builder: (_, __) => const AdminOrdersScreen()),
          GoRoute(path: '/admin/users', builder: (_, __) => const AdminUsersScreen()),
        ],
      ),
    ],
  );
});
