double _d(dynamic v) => (v as num).toDouble();

class Category {
  final int id;
  final String name;
  final int sort;
  Category({required this.id, required this.name, this.sort = 0});
  factory Category.fromJson(Map<String, dynamic> j) => Category(id: j['id'], name: j['name'], sort: j['sort'] ?? 0);
}

class PriceTier {
  final int minQty;
  final double unitPrice;
  final String forRole; // 'all' | 'vip'
  PriceTier({required this.minQty, required this.unitPrice, this.forRole = 'all'});
  factory PriceTier.fromJson(Map<String, dynamic> j) =>
      PriceTier(minQty: j['min_qty'], unitPrice: _d(j['unit_price']), forRole: j['for_role']);
  Map<String, dynamic> toJson() => {'min_qty': minQty, 'unit_price': unitPrice, 'for_role': forRole};
}

class Product {
  final int id;
  final String name;
  final int? categoryId;
  final String? imageUrl;
  final double retailPrice;
  final double? vipPrice;
  final bool active;
  final String? description;
  final String? promotion;
  final List<PriceTier> tiers;

  Product({
    this.description,
    this.promotion,
    required this.id,
    required this.name,
    this.categoryId,
    this.imageUrl,
    required this.retailPrice,
    this.vipPrice,
    this.active = true,
    this.tiers = const [],
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'],
        name: j['name'],
        categoryId: j['category_id'],
        imageUrl: j['image_url'],
        retailPrice: _d(j['retail_price']),
        vipPrice: j['vip_price'] == null ? null : _d(j['vip_price']),
        active: j['active'] ?? true,
        description: j['description'],
        promotion: j['promotion'],
        tiers: ((j['price_tiers'] as List?) ?? []).map((t) => PriceTier.fromJson(t)).toList(),
      );
}

class Profile {
  final int id;
  final String name;
  final String username;
  final String? phone;
  final String? avatarUrl;
  final String role; // customer | vip | admin
  Profile({required this.id, required this.name, required this.username, this.phone, this.avatarUrl, required this.role});
  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'],
        name: j['name'] ?? '',
        username: j['username'],
        phone: j['phone'],
        avatarUrl: j['avatar_url'],
        role: j['role'],
      );

  bool get isAdmin => role == 'admin';
  bool get isVip => role == 'vip' || role == 'admin';
}

class Address {
  final int id;
  final String label;
  final String recipientName;
  final String phone;
  final String addressLine;
  final String subdistrict;
  final String district;
  final String province;
  final String postalCode;
  final bool isDefault;

  Address({
    required this.id,
    this.label = '',
    required this.recipientName,
    required this.phone,
    required this.addressLine,
    this.subdistrict = '',
    this.district = '',
    required this.province,
    this.postalCode = '',
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> j) => Address(
        id: j['id'],
        label: j['label'] ?? '',
        recipientName: j['recipient_name'] ?? '',
        phone: j['phone'] ?? '',
        addressLine: j['address_line'] ?? '',
        subdistrict: j['subdistrict'] ?? '',
        district: j['district'] ?? '',
        province: j['province'] ?? '',
        postalCode: j['postal_code'] ?? '',
        isDefault: j['is_default'] == true,
      );

  String get block {
    String join(List<String> parts) => parts.where((s) => s.isNotEmpty).join(' ');
    return [
      recipientName,
      phone,
      addressLine,
      join([subdistrict, district]),
      join([province, postalCode]),
    ].where((s) => s.isNotEmpty).join('\n');
  }
}

class OrderItem {
  final String productName;
  final int qty;
  final double unitPrice;
  OrderItem({required this.productName, required this.qty, required this.unitPrice});
  factory OrderItem.fromJson(Map<String, dynamic> j) =>
      OrderItem(productName: j['product_name'], qty: j['qty'], unitPrice: _d(j['unit_price_snapshot']));
}

class Order {
  final int id;
  final String status;
  final double total;
  final String? note;
  final String? trackingNo;
  final DateTime createdAt;
  final List<OrderItem> items;
  final Profile? customer;
  final String shipRecipient;
  final String shipPhone;
  final String shipLine;
  final String shipSubdistrict;
  final String shipDistrict;
  final String shipProvince;
  final String shipPostal;

  Order({
    required this.id,
    required this.status,
    required this.total,
    this.note,
    this.trackingNo,
    required this.createdAt,
    this.items = const [],
    this.customer,
    this.shipRecipient = '',
    this.shipPhone = '',
    this.shipLine = '',
    this.shipSubdistrict = '',
    this.shipDistrict = '',
    this.shipProvince = '',
    this.shipPostal = '',
  });

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'],
        status: j['status'],
        total: _d(j['total']),
        note: j['note'],
        trackingNo: j['tracking_no'],
        createdAt: DateTime.parse(j['created_at']).toLocal(),
        items: ((j['order_items'] as List?) ?? []).map((i) => OrderItem.fromJson(i)).toList(),
        customer: j['customer'] == null ? null : Profile.fromJson(j['customer']),
        shipRecipient: j['ship_recipient'] ?? '',
        shipPhone: j['ship_phone'] ?? '',
        shipLine: j['ship_line'] ?? '',
        shipSubdistrict: j['ship_subdistrict'] ?? '',
        shipDistrict: j['ship_district'] ?? '',
        shipProvince: j['ship_province'] ?? '',
        shipPostal: j['ship_postal'] ?? '',
      );

  String get shipBlock {
    String join(List<String> parts) => parts.where((s) => s.isNotEmpty).join(' ');
    return [shipRecipient, shipPhone, shipLine, join([shipSubdistrict, shipDistrict]), join([shipProvince, shipPostal])]
        .where((s) => s.isNotEmpty)
        .join('\n');
  }
}

