import 'package:url_launcher/url_launcher.dart';
import '../../models/order.dart';
import 'package:intl/intl.dart';

/// Helper class for sharing order tracking information via WhatsApp.
class WhatsAppHelper {
  WhatsAppHelper._();

  /// Builds a formatted order tracking message for WhatsApp sharing.
  static String buildOrderMessage(Order order) {
    final itemsList = order.items
        .map(
          (i) =>
              '  • ${i.quantity}x ${i.menuItem.name} — ₹${i.totalPrice.toStringAsFixed(0)}',
        )
        .join('\n');

    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt);

    final deliveryInfo = order.deliveryType == DeliveryType.selfPickup
        ? '📦 Self Pickup from Counter'
        : '🚚 Delivery${order.deliveryAddress != null ? ' to ${order.deliveryAddress}' : ''}';

    final paymentInfo = order.paymentMethod == PaymentMethod.upi
        ? '💳 Paid via UPI'
        : '💵 Cash on Delivery';

    final statusEmoji = _getStatusEmoji(order.status);

    final eta = order.estimatedReadyTime != null
        ? '\n⏰ Estimated Ready: ${DateFormat('hh:mm a').format(order.estimatedReadyTime!)}'
        : '';

    return '''
🍕 *Fresco's Pizza — Order Update*

📋 *Order:* ${order.id}
📅 *Date:* $dateStr
$statusEmoji *Status:* ${order.statusLabel}
$eta

🛒 *Items:*
$itemsList

💰 Subtotal: ₹${order.subtotal.toStringAsFixed(0)}
🚚 Delivery: ${order.deliveryCharge > 0 ? '₹${order.deliveryCharge.toStringAsFixed(0)}' : 'FREE'}
━━━━━━━━━━━━━━━
💵 *Total: ₹${order.total.toStringAsFixed(0)}*

$deliveryInfo
$paymentInfo

Track your order in the Fresco's Pizza app! 🍕
''';
  }

  /// Gets the appropriate status emoji for display.
  static String _getStatusEmoji(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return '📝';
      case OrderStatus.confirmed:
        return '✅';
      case OrderStatus.preparing:
        return '👨‍🍳';
      case OrderStatus.ready:
        return '🔔';
      case OrderStatus.outForDelivery:
        return '🛵';
      case OrderStatus.delivered:
        return '🎉';
      case OrderStatus.cancelled:
        return '❌';
    }
  }

  /// Opens WhatsApp with a pre-filled order tracking message.
  /// If [phoneNumber] is provided, it opens a direct chat.
  /// Otherwise, it opens the share dialog.
  static Future<bool> shareOrderTracking(
    Order order, {
    String? phoneNumber,
  }) async {
    final message = buildOrderMessage(order);
    final encodedMessage = Uri.encodeComponent(message);

    Uri uri;
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      // Direct message to a specific number
      final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final fullPhone = cleanPhone.startsWith('+')
          ? cleanPhone
          : '+91$cleanPhone';
      uri = Uri.parse('https://wa.me/$fullPhone?text=$encodedMessage');
    } else {
      // Open WhatsApp share dialog
      uri = Uri.parse('https://wa.me/?text=$encodedMessage');
    }

    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
