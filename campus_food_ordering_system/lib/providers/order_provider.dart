import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/order.dart';
import '../models/cart_item.dart';

class OrderProvider extends ChangeNotifier {
  final List<Order> _orders = [];
  Timer? _statusTimer;
  final _uuid = const Uuid();

  List<Order> get orders => List.unmodifiable(_orders);

  List<Order> get activeOrders => _orders
      .where(
        (o) =>
            o.status != OrderStatus.delivered &&
            o.status != OrderStatus.cancelled,
      )
      .toList();

  List<Order> get completedOrders => _orders
      .where(
        (o) =>
            o.status == OrderStatus.delivered ||
            o.status == OrderStatus.cancelled,
      )
      .toList();

  Order? getOrderById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  Order placeOrder({
    required List<CartItem> items,
    required double subtotal,
    required double deliveryCharge,
    required double total,
    required PaymentMethod paymentMethod,
    required DeliveryType deliveryType,
    String? deliveryAddress,
    String? specialInstructions,
  }) {
    final orderId = 'ORD-${_uuid.v4().substring(0, 8).toUpperCase()}';
    final now = DateTime.now();

    final order = Order(
      id: orderId,
      items: List.from(
        items.map(
          (item) => CartItem(
            menuItem: item.menuItem,
            quantity: item.quantity,
            specialInstructions: item.specialInstructions,
          ),
        ),
      ),
      subtotal: subtotal,
      deliveryCharge: deliveryCharge,
      total: total,
      status: OrderStatus.placed,
      paymentMethod: paymentMethod,
      deliveryType: deliveryType,
      deliveryAddress: deliveryAddress,
      specialInstructions: specialInstructions,
      createdAt: now,
      estimatedReadyTime: now.add(const Duration(minutes: 20)),
      isPaid: paymentMethod == PaymentMethod.upi,
    );

    _orders.insert(0, order);
    notifyListeners();

    // Simulate order status progression
    _simulateOrderProgress(orderId);

    return order;
  }

  void _simulateOrderProgress(String orderId) {
    const statusDurations = {
      OrderStatus.placed: Duration(seconds: 8),
      OrderStatus.confirmed: Duration(seconds: 12),
      OrderStatus.preparing: Duration(seconds: 20),
      OrderStatus.ready: Duration(seconds: 15),
      OrderStatus.outForDelivery: Duration(seconds: 10),
    };

    void nextStatus(OrderStatus currentStatus) {
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index < 0) return;

      final order = _orders[index];
      if (order.status == OrderStatus.cancelled) return;

      OrderStatus next;
      switch (currentStatus) {
        case OrderStatus.placed:
          next = OrderStatus.confirmed;
          break;
        case OrderStatus.confirmed:
          next = OrderStatus.preparing;
          break;
        case OrderStatus.preparing:
          next = OrderStatus.ready;
          break;
        case OrderStatus.ready:
          if (order.deliveryType == DeliveryType.delivery) {
            next = OrderStatus.outForDelivery;
          } else {
            next = OrderStatus.delivered;
          }
          break;
        case OrderStatus.outForDelivery:
          next = OrderStatus.delivered;
          break;
        default:
          return;
      }

      final duration = statusDurations[currentStatus];
      if (duration == null) return;

      Timer(duration, () {
        final idx = _orders.indexWhere((o) => o.id == orderId);
        if (idx < 0) return;
        if (_orders[idx].status == OrderStatus.cancelled) return;

        _orders[idx] = _orders[idx].copyWith(
          status: next,
          completedAt: next == OrderStatus.delivered ? DateTime.now() : null,
          isPaid: next == OrderStatus.delivered ? true : _orders[idx].isPaid,
        );
        notifyListeners();

        if (next != OrderStatus.delivered && next != OrderStatus.cancelled) {
          nextStatus(next);
        }
      });
    }

    nextStatus(OrderStatus.placed);
  }

  void updateOrderStatus(String orderId, OrderStatus newStatus) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      _orders[index] = _orders[index].copyWith(
        status: newStatus,
        completedAt: newStatus == OrderStatus.delivered ? DateTime.now() : null,
      );
      notifyListeners();
    }
  }

  void cancelOrder(String orderId) {
    updateOrderStatus(orderId, OrderStatus.cancelled);
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }
}
