import 'order_status.dart';

/// Maps 1:1 to the existing `orders` table.
/// Columns: id (int8), customer_name, phone, address, total_amount,
/// status (text), created_at (timestamp).
class Order {
  const Order({
    this.id,
    required this.customerName,
    this.phone,
    this.address,
    this.totalAmount,
    required this.status,
    this.rawStatus,
    this.createdAt,
  });

  final int? id;
  final String customerName;
  final String? phone;
  final String? address;
  final double? totalAmount;
  final OrderStatus status;

  /// The original free-text status as stored, kept for reference/debugging.
  final String? rawStatus;
  final DateTime? createdAt;

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: _toInt(map['id']),
      customerName: (map['customer_name'] ?? '') as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      totalAmount: _toDouble(map['total_amount']),
      status: OrderStatus.fromRaw(map['status'] as String?),
      rawStatus: map['status'] as String?,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'].toString()),
    );
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

/// Maps 1:1 to the existing `order_items` table.
/// Columns: id (int8), order_id (int8), item_name (text),
/// quantity (int4), item_price (numeric).
class OrderItem {
  const OrderItem({
    this.id,
    required this.orderId,
    required this.itemName,
    this.quantity = 1,
    this.itemPrice,
  });

  final int? id;
  final int orderId;
  final String itemName;
  final int quantity;
  final double? itemPrice;

  /// Line subtotal (price * quantity), or null if price is unknown.
  double? get lineTotal => itemPrice == null ? null : itemPrice! * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: Order._toInt(map['id']),
      orderId: Order._toInt(map['order_id']) ?? 0,
      itemName: (map['item_name'] ?? '') as String,
      quantity: Order._toInt(map['quantity']) ?? 1,
      itemPrice: Order._toDouble(map['item_price']),
    );
  }
}
