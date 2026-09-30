import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/models.dart';
import '../../core/pricing.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../auth/auth_service.dart';
import '../cart/cart_provider.dart';
import 'install_banner.dart';
import 'price_sheet.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});
  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  String _query = '';
  int? _categoryId;

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        toolbarHeight: 64,
        title: const _Logo(),
        actions: const [
          InstallAppButton(),
          _CartButton(),
          _LoginButton(),
          _AccountMenu(),
          SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoriesProvider);
          ref.invalidate(productsProvider);
          await ref.read(productsProvider.future);
        },
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Entrance(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: t(context, 'search_products'),
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                children: [
                  AnimatedScale(
                    scale: _categoryId == null ? 1.04 : 1,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    child: _chip(t(context, 'all'), null),
                  ),
                  for (final c in categories)
                    AnimatedScale(
                      scale: _categoryId == c.id ? 1.04 : 1,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      child: _chip(c.name, c.id),
                    ),
                ],
              ),
            ),
          ),
          ...products.when(
            loading: () => [const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))],
            error: (e, _) => [SliverFillRemaining(child: Center(child: Text(tf(context, 'load_failed', {'e': '$e'}), textAlign: TextAlign.center)))],
            data: (all) {
              final list = all
                  .where((p) => p.active)
                  .where((p) => _categoryId == null || p.categoryId == _categoryId)
                  .where((p) => p.name.toLowerCase().contains(_query))
                  .toList();
              return [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Row(children: [
                      Text(t(context, 'featured'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Text(tf(context, 'item_count', {'n': '${list.length}'}), style: const TextStyle(color: muted)),
                    ]),
                  ),
                ),
                if (list.isEmpty)
                  SliverFillRemaining(hasScrollBody: false, child: Center(child: Text(t(context, 'no_products'), style: const TextStyle(color: muted))))
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 240,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.68,
                      ),
                      delegate: SliverChildBuilderDelegate((_, i) => Entrance(index: i, child: ProductCard(list[i])), childCount: list.length),
                    ),
                  ),
              ];
            },
          ),
        ]),
      ),
    );
  }

  Widget _chip(String label, int? id) {
    final on = _categoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, softWrap: false, overflow: TextOverflow.visible),
        selected: on,
        showCheckmark: false,
        selectedColor: brandGreen,
        shape: const StadiumBorder(side: BorderSide.none),
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF374151) : const Color(0xFFEEF0F3),
        labelStyle: TextStyle(color: on ? Colors.white : Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500),
        onSelected: (_) => setState(() => _categoryId = id),
      ),
    );
  }
}

class ProductCard extends ConsumerWidget {
  final Product product;
  const ProductCard(this.product, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vip = ref.watch(isVipProvider);
    final options = priceOptions(product, vip: vip);
    final best = options.reduce((a, b) => b.price <= a.price ? b : a);

    return _HoverLift(
      child: Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showPriceSheet(context, product),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(fit: StackFit.expand, children: [
              ProductImage(product.imageUrl),
              if (product.promotion != null)
                Positioned(top: 8, left: 8, child: PromotionBadge(product.promotion!)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(tf(context, 'retail', {'price': baht(product.retailPrice)}), style: const TextStyle(color: muted, fontSize: 13)),
              if (best.price < product.retailPrice)
                Text(
                  '${best.minQty > 1 ? tf(context, 'wholesale', {'qty': '${best.minQty}'}) : t(context, 'vip_tag')}${tf(context, 'per_piece', {'price': baht(best.price)})}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: brandGreenDark, fontWeight: FontWeight.w600, fontSize: 14),
                ),
            ]),
          ),
        ]),
      ),
    ),
    );
  }
}

class _HoverLift extends StatefulWidget {
  final Widget child;
  const _HoverLift({required this.child});
  @override
  State<_HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<_HoverLift> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _on = true),
      onExit: (_) => setState(() => _on = false),
      child: AnimatedScale(
        scale: _on && !reduce ? 1.03 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _CartButton extends ConsumerWidget {
  const _CartButton();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartCountProvider);
    return IconButton(
      tooltip: t(context, 'cart'),
      onPressed: () => context.push('/cart'),
      icon: Badge(isLabelVisible: count > 0, label: Text('$count'), child: const Icon(Icons.shopping_cart_outlined)),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();
  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/logo.png',
        height: 56,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.low,
        isAntiAlias: true,
      );
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MenuRow(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Flexible(child: Text(label)),
      ]);
}

class _LoginButton extends ConsumerWidget {
  const _LoginButton();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(profileProvider).valueOrNull != null) return const SizedBox.shrink();
    return TextButton.icon(onPressed: () => context.push('/login'), icon: const Icon(Icons.login), label: Text(t(context, 'login')));
  }
}

class _AccountMenu extends ConsumerWidget {
  const _AccountMenu();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    return PopupMenuButton<String>(
      tooltip: profile?.name ?? t(context, 'menu'),
      offset: const Offset(0, 48),
      icon: profile == null
          ? const Icon(Icons.menu_rounded)
          : profile.avatarUrl != null
              ? UserAvatar(url: profile.avatarUrl, username: profile.username, radius: 18)
              : CircleAvatar(
                  backgroundColor: profile.isVip ? const Color(0xFFFDE68A) : brandGreenLight,
                  child: Text(profile.isVip ? 'VIP' : profile.username.characters.first.toUpperCase(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ink)),
                ),
      onSelected: (v) async {
        if (v == 'logout') {
          await signOut();
        } else if (context.mounted) {
          context.push(v);
        }
      },
      itemBuilder: (_) => [
        if (profile == null)
          PopupMenuItem(value: '/settings', child: _MenuRow(Icons.settings_outlined, t(context, 'settings')))
        else ...[
          PopupMenuItem(enabled: false, child: Text('${profile.name} (${profile.username})')),
          PopupMenuItem(value: '/profile', child: _MenuRow(Icons.person_outline, t(context, 'my_profile'))),
          PopupMenuItem(value: '/orders', child: _MenuRow(Icons.receipt_long_outlined, t(context, 'my_orders'))),
          PopupMenuItem(value: '/settings', child: _MenuRow(Icons.settings_outlined, t(context, 'settings'))),
          if (profile.isAdmin) PopupMenuItem(value: '/admin', child: _MenuRow(Icons.storefront_outlined, t(context, 'admin_shop'))),
          PopupMenuItem(value: 'logout', child: _MenuRow(Icons.logout, t(context, 'logout'))),
        ],
      ],
    );
  }
}
