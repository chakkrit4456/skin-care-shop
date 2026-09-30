import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api.dart';
import '../../core/l10n.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';

class AdminProductForm extends ConsumerWidget {
  final int? productId; // null = new product
  const AdminProductForm({super.key, this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (productId == null) return const _Form(product: null);
    return ref.watch(productsProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (list) {
            final p = list.where((x) => x.id == productId).firstOrNull;
            return p == null ? Center(child: Text(t(context, 'product_not_found'))) : _Form(product: p);
          },
        );
  }
}

class _TierRow {
  final minQty = TextEditingController();
  final price = TextEditingController();
  String forRole = 'all';
}

class _Form extends ConsumerStatefulWidget {
  final Product? product;
  const _Form({required this.product});
  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _retail = TextEditingController();
  final _vip = TextEditingController();
  final _promotion = TextEditingController();
  final _description = TextEditingController();
  int? _categoryId;
  bool _active = true;
  String? _imageUrl;
  Uint8List? _newImage;
  String _newImageExt = 'jpg';
  final List<_TierRow> _tiers = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p == null) {
      _tiers.addAll([_TierRow()..minQty.text = '5', _TierRow()..minQty.text = '10']);
      return;
    }
    _name.text = p.name;
    _retail.text = _num(p.retailPrice);
    _vip.text = p.vipPrice == null ? '' : _num(p.vipPrice!);
    _promotion.text = p.promotion ?? '';
    _description.text = p.description ?? '';
    _categoryId = p.categoryId;
    _active = p.active;
    _imageUrl = p.imageUrl;
    for (final t in [...p.tiers]..sort((a, b) => a.minQty.compareTo(b.minQty))) {
      _tiers.add(_TierRow()
        ..minQty.text = '${t.minQty}'
        ..price.text = _num(t.unitPrice)
        ..forRole = t.forRole);
    }
  }

  String _num(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1000, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _newImage = bytes;
      _newImageExt = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : 'jpg';
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      var imageUrl = _imageUrl;
      if (_newImage != null) {
        imageUrl = await api.uploadImage(_newImage!, 'image.$_newImageExt');
      }
      final data = {
        'name': _name.text.trim(),
        'category_id': _categoryId,
        'retail_price': double.parse(_retail.text),
        'vip_price': _vip.text.trim().isEmpty ? null : double.parse(_vip.text),
        'active': _active,
        'image_url': imageUrl,
        'promotion': _promotion.text.trim(),
        'description': _description.text.trim(),
        'price_tiers': _tiers
            .where((t) => t.minQty.text.isNotEmpty && t.price.text.isNotEmpty)
            .map((t) => PriceTier(minQty: int.parse(t.minQty.text), unitPrice: double.parse(t.price.text), forRole: t.forRole).toJson())
            .toList(),
      };
      if (widget.product == null) {
        await api.post('/admin/products', data);
      } else {
        await api.put('/admin/products/${widget.product!.id}', data);
      }

      ref.invalidate(productsProvider);
      if (mounted) {
        showMessage(context, t(context, 'saved_short'));
        context.go('/admin/products');
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t(context, 'delete_product')),
        content: Text(t(context, 'delete_product_body')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(t(context, 'cancel'))),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(c, true), child: Text(t(context, 'delete'))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await api.delete('/admin/products/${widget.product!.id}');
      ref.invalidate(productsProvider);
      if (mounted) context.go('/admin/products');
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  String? _priceValidator(String? v, {bool required = true}) {
    if ((v ?? '').trim().isEmpty) return required ? t(context, 'price_required') : null;
    final n = double.tryParse(v!);
    return n == null || n <= 0 ? t(context, 'price_invalid') : null;
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final priceFormat = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))];

    return Constrained(
      child: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Row(children: [
            IconButton(onPressed: () => context.go('/admin/products'), icon: const Icon(Icons.arrow_back)),
            Text(t(context, widget.product == null ? 'add_product' : 'edit_product'), style: Theme.of(context).textTheme.titleLarge),
          ]),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickImage,
            borderRadius: BorderRadius.circular(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 220,
                child: _newImage != null
                    ? Image.memory(_newImage!, fit: BoxFit.contain)
                    : Stack(fit: StackFit.expand, children: [
                        ProductImage(_imageUrl, fit: BoxFit.contain),
                        Align(alignment: Alignment.bottomCenter, child: Padding(padding: const EdgeInsets.all(8), child: Chip(avatar: const Icon(Icons.photo), label: Text(t(context, 'tap_photo'))))),
                      ]),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _name,
            decoration: InputDecoration(labelText: t(context, 'product_name')),
            validator: (v) => (v ?? '').trim().isEmpty ? t(context, 'name_required') : null,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<int?>(
            initialValue: categories.any((c) => c.id == _categoryId) ? _categoryId : null,
            decoration: InputDecoration(labelText: t(context, 'category')),
            items: [
              DropdownMenuItem(value: null, child: Text(t(context, 'none'))),
              for (final c in categories) DropdownMenuItem(value: c.id, child: Text(c.name)),
            ],
            onChanged: (v) => setState(() => _categoryId = v),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _retail,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: priceFormat,
                decoration: InputDecoration(labelText: t(context, 'retail_price')),
                validator: _priceValidator,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _vip,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: priceFormat,
                decoration: InputDecoration(labelText: t(context, 'vip_price'), helperText: t(context, 'optional')),
                validator: (v) => _priceValidator(v, required: false),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          TextFormField(
            controller: _promotion,
            decoration: InputDecoration(labelText: t(context, 'promotion'), helperText: t(context, 'promotion_hint')),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _description,
            maxLines: 3,
            decoration: InputDecoration(labelText: t(context, 'description')),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t(context, 'show_in_shop')),
            value: _active,
            onChanged: (v) => setState(() => _active = v),
          ),
          const Divider(),
          Text(t(context, 'wholesale_title'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final tier in _tiers)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: tier.minQty,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(labelText: t(context, 'min_qty')),
                    validator: (v) => (v ?? '').isNotEmpty && int.parse(v!) < 1 ? t(context, 'min_one') : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: tier.price,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: priceFormat,
                    decoration: InputDecoration(labelText: t(context, 'unit_price')),
                    validator: (v) => _priceValidator(v, required: tier.minQty.text.isNotEmpty),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: tier.forRole,
                  items: [
                    DropdownMenuItem(value: 'all', child: Text(t(context, 'everyone'))),
                    const DropdownMenuItem(value: 'vip', child: Text('VIP')),
                  ],
                  onChanged: (v) => setState(() => tier.forRole = v!),
                ),
                IconButton(onPressed: () => setState(() => _tiers.remove(tier)), icon: const Icon(Icons.close, color: Colors.red)),
              ]),
            ),
          OutlinedButton.icon(onPressed: () => setState(() => _tiers.add(_TierRow())), icon: const Icon(Icons.add), label: Text(t(context, 'add_tier'))),
          const SizedBox(height: 24),
          Row(children: [
            if (widget.product != null) ...[
              OutlinedButton(
                onPressed: _busy ? null : _delete,
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, padding: const EdgeInsets.all(16)),
                child: Text(t(context, 'delete')),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(child: FilledButton(onPressed: _busy ? null : _save, child: Text(_busy ? t(context, 'saving') : t(context, 'save_btn')))),
          ]),
        ]),
      ),
    );
  }
}
