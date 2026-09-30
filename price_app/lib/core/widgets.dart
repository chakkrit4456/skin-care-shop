import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'api.dart';
import 'l10n.dart';

class ProductImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  const ProductImage(this.url, {super.key, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: const Color(0xFFFCE7F3),
      alignment: Alignment.center,
      child: const Icon(Icons.shopping_bag_outlined, size: 40, color: Color(0xFFDB2777)),
    );
    final full = api.resolveUrl(url);
    if (full == null) return placeholder;
    return CachedNetworkImage(imageUrl: full, fit: fit, placeholder: (_, __) => placeholder, errorWidget: (_, __, ___) => placeholder);
  }
}

/// Profile picture, falling back to the first letter of the username.
class UserAvatar extends StatelessWidget {
  final String? url;
  final String username;
  final double radius;
  final Color? background;
  const UserAvatar({super.key, this.url, required this.username, this.radius = 20, this.background});

  @override
  Widget build(BuildContext context) {
    final full = api.resolveUrl(url);
    return CircleAvatar(
      radius: radius,
      backgroundColor: background ?? const Color(0xFFFCE7F3),
      foregroundImage: full == null ? null : CachedNetworkImageProvider(full),
      child: Text(
        username.isEmpty ? '?' : username.characters.first.toUpperCase(),
        style: TextStyle(fontSize: radius * 0.8, fontWeight: FontWeight.w700, color: const Color(0xFF6B4F3A)),
      ),
    );
  }
}

class PromotionBadge extends StatelessWidget {
  final String text;
  const PromotionBadge(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      );
}

void showError(BuildContext context, Object e) {
  final raw = '$e';
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(tf(context, 'error_prefix', {'e': localizeError(context, raw)})), backgroundColor: Colors.red),
  );
}

void showMessage(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

/// Fade and rise used for first paint of cards, banners, and steps.
class Entrance extends StatelessWidget {
  final int index;
  final Widget child;
  const Entrance({super.key, this.index = 0, required this.child});

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduce ? 1 : 0, end: 1),
      duration: reduce ? Duration.zero : Duration(milliseconds: 380 + (index % 8) * 45),
      curve: Curves.easeOutCubic,
      // Opacity paints into a layer that turns this transparent logo black.
      builder: (context, v, child) => Transform.translate(offset: Offset(0, (1 - v) * 14), child: child),
      child: child,
    );
  }
}

/// Centered content with a max width for wide web screens.
class Constrained extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const Constrained({super.key, required this.child, this.maxWidth = 720});
  @override
  Widget build(BuildContext context) =>
      Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child));
}
