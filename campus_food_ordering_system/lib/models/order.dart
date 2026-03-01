import 'cart_item.dart';

enum OrderStatus {
  placed,
  confirmed,
  preparing,
  ready,
  outForDelivery,
  delivered,
  cancelled,
}

enum PaymentMethod { upi, cashOnDelivery }

enum DeliveryType { selfPickup, delivery }

class Order {
  final String id;
  final List<CartItem> items;
  final double subtotal;
  final double deliveryCharge;
  final double discount;
  final double total;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final DeliveryType deliveryType;
  final String? deliveryAddress;
  final String? specialInstructions;
  final DateTime createdAt;
  final DateTime? estimatedReadyTime;
  final DateTime? completedAt;
  final bool isPaid;

  const Order({
    required this.id,
    required this.items,
    required this.subtotal,
    this.deliveryCharge = 0,
    this.discount = 0,
    required this.total,
    this.status = OrderStatus.placed,
    required this.paymentMethod,
    required this.deliveryType,
    this.deliveryAddress,
    this.specialInstructions,
    required this.createdAt,
    this.estimatedReadyTime,
    this.completedAt,
    this.isPaid = false,
  });

  Order copyWith({
    String? id,
    List<CartItem>? items,
    double? subtotal,
    double? deliveryCharge,
    double? discount,
    double? total,
    OrderStatus? status,
    PaymentMethod? paymentMethod,
    DeliveryType? deliveryType,
    String? deliveryAddress,
    String? specialInstructions,
    DateTime? createdAt,
    DateTime? estimatedReadyTime,
    DateTime? completedAt,
    bool? isPaid,
  }) {
    return Order(
      id: id ?? this.id,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      deliveryType: deliveryType ?? this.deliveryType,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      createdAt: createdAt ?? this.createdAt,
      estimatedReadyTime: estimatedReadyTime ?? this.estimatedReadyTime,
      completedAt: completedAt ?? this.completedAt,
      isPaid: isPaid ?? this.isPaid,
    );
  }

  String get statusLabel {
    switch (status) {
      case OrderStatus.placed:
        return 'Order Placed';
      case OrderStatus.confirmed:
        return 'Order Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}
