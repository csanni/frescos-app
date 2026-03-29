import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/whatsapp_helper.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Tracking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        actions: [
          Consumer<OrderProvider>(
            builder: (context, provider, _) {
              final order = provider.getOrderById(orderId);
              if (order == null) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.share_rounded),
                tooltip: 'Share on WhatsApp',
                onPressed: () => _shareOnWhatsApp(context, order),
              );
            },
          ),
        ],
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, _) {
          final order = orderProvider.getOrderById(orderId);

          if (order == null) {
            return const Center(child: Text('Order not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Success banner (shown when just placed)
                if (order.status == OrderStatus.placed)
                  _buildSuccessBanner(context),

                // Order ID and time
                _buildOrderHeader(context, order),
                const SizedBox(height: AppSpacing.xl),

                // Estimated time
                if (order.status != OrderStatus.delivered &&
                    order.status != OrderStatus.cancelled)
                  _buildEstimatedTime(context, order),

                // Status stepper
                _buildStatusStepper(context, order),
                const SizedBox(height: AppSpacing.xl),

                // Order details
                _buildOrderDetails(context, order),
                const SizedBox(height: AppSpacing.lg),

                // Payment info
                _buildPaymentInfo(context, order),
                const SizedBox(height: AppSpacing.lg),

                // WhatsApp share button
                _buildWhatsAppShareButton(context, order),
                const SizedBox(height: AppSpacing.lg),

                // Actions
                if (order.status == OrderStatus.placed ||
                    order.status == OrderStatus.confirmed)
                  _buildCancelButton(context, order),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuccessBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withValues(alpha: 0.1),
            AppColors.success.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 28,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Placed Successfully! 🎉',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'We\'re getting your food ready',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHeader(BuildContext context, Order order) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order ${order.id}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              _buildStatusBadge(context, order.status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                order.deliveryType == DeliveryType.selfPickup
                    ? Icons.store_rounded
                    : Icons.delivery_dining_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                order.deliveryType == DeliveryType.selfPickup
                    ? 'Self Pickup'
                    : 'Delivery',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(width: AppSpacing.lg),
              Icon(
                order.paymentMethod == PaymentMethod.upi
                    ? Icons.account_balance_rounded
                    : Icons.money_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                order.paymentMethod == PaymentMethod.upi
                    ? 'UPI Payment'
                    : 'Cash on Delivery',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, OrderStatus status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case OrderStatus.placed:
      case OrderStatus.confirmed:
        bgColor = AppColors.info.withValues(alpha: 0.1);
        textColor = AppColors.info;
        break;
      case OrderStatus.preparing:
        bgColor = AppColors.warning.withValues(alpha: 0.1);
        textColor = AppColors.warning;
        break;
      case OrderStatus.ready:
      case OrderStatus.outForDelivery:
        bgColor = AppColors.primary.withValues(alpha: 0.1);
        textColor = AppColors.primary;
        break;
      case OrderStatus.delivered:
        bgColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
        break;
      case OrderStatus.cancelled:
        bgColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Text(
        status == OrderStatus.placed
            ? 'Order Placed'
            : status == OrderStatus.confirmed
            ? 'Confirmed'
            : status == OrderStatus.preparing
            ? 'Preparing'
            : status == OrderStatus.ready
            ? 'Ready'
            : status == OrderStatus.outForDelivery
            ? 'Out for Delivery'
            : status == OrderStatus.delivered
            ? 'Delivered'
            : 'Cancelled',
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEstimatedTime(BuildContext context, Order order) {
    final remaining = order.estimatedReadyTime?.difference(DateTime.now());
    final minutes = remaining != null && remaining.inMinutes > 0
        ? remaining.inMinutes
        : 0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Estimated Ready Time',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                minutes > 0 ? '~$minutes minutes' : 'Almost ready!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStepper(BuildContext context, Order order) {
    final steps = [
      _StepData(
        title: 'Order Placed',
        subtitle: 'Your order has been received',
        icon: Icons.receipt_long_rounded,
        status: OrderStatus.placed,
      ),
      _StepData(
        title: 'Confirmed',
        subtitle: 'Restaurant has confirmed your order',
        icon: Icons.check_circle_outline_rounded,
        status: OrderStatus.confirmed,
      ),
      _StepData(
        title: 'Preparing',
        subtitle: 'Your food is being prepared',
        icon: Icons.restaurant_rounded,
        status: OrderStatus.preparing,
      ),
      _StepData(
        title: 'Ready',
        subtitle: order.deliveryType == DeliveryType.selfPickup
            ? 'Ready for pickup at the counter'
            : 'Your order is ready',
        icon: Icons.check_circle_rounded,
        status: OrderStatus.ready,
      ),
      if (order.deliveryType == DeliveryType.delivery)
        _StepData(
          title: 'Out for Delivery',
          subtitle: 'Your order is on the way',
          icon: Icons.delivery_dining_rounded,
          status: OrderStatus.outForDelivery,
        ),
      _StepData(
        title: 'Delivered',
        subtitle: order.deliveryType == DeliveryType.selfPickup
            ? 'You have picked up your order'
            : 'Your order has been delivered',
        icon: Icons.done_all_rounded,
        status: OrderStatus.delivered,
      ),
    ];

    final currentIndex = _getStatusIndex(order.status, order.deliveryType);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Progress',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            final isCompleted = index <= currentIndex;
            final isCurrent = index == currentIndex;
            final isLast = index == steps.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon and connector
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? (isCurrent
                                  ? AppColors.primary
                                  : AppColors.success)
                            : AppColors.divider,
                        shape: BoxShape.circle,
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        step.icon,
                        color: isCompleted
                            ? Colors.white
                            : AppColors.textSecondary,
                        size: 18,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 40,
                        color: isCompleted && index < currentIndex
                            ? AppColors.success
                            : AppColors.divider,
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.md),
                // Text
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: TextStyle(
                            fontWeight: isCurrent
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 14,
                            color: isCompleted
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (!isLast) const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  int _getStatusIndex(OrderStatus status, DeliveryType deliveryType) {
    switch (status) {
      case OrderStatus.placed:
        return 0;
      case OrderStatus.confirmed:
        return 1;
      case OrderStatus.preparing:
        return 2;
      case OrderStatus.ready:
        return 3;
      case OrderStatus.outForDelivery:
        return 4;
      case OrderStatus.delivered:
        return deliveryType == DeliveryType.delivery ? 5 : 4;
      case OrderStatus.cancelled:
        return -1;
    }
  }

  Widget _buildOrderDetails(BuildContext context, Order order) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Details',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: item.menuItem.isVeg
                                ? AppColors.veg
                                : AppColors.nonVeg,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Center(
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: item.menuItem.isVeg
                                  ? AppColors.veg
                                  : AppColors.nonVeg,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${item.quantity}x ${item.menuItem.name}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  Text(
                    '₹${item.totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                '₹${order.total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo(BuildContext context, Order order) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (order.isPaid ? AppColors.success : AppColors.warning)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(
              order.isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
              color: order.isPaid ? AppColors.success : AppColors.warning,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.isPaid ? 'Payment Completed' : 'Payment Pending',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: order.isPaid ? AppColors.success : AppColors.warning,
                  ),
                ),
                Text(
                  order.paymentMethod == PaymentMethod.upi
                      ? 'Paid via UPI'
                      : 'Cash on ${order.deliveryType == DeliveryType.selfPickup ? 'Pickup' : 'Delivery'}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${order.total.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsAppShareButton(BuildContext context, Order order) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _shareOnWhatsApp(context, order),
        icon: const Icon(Icons.message_rounded, size: 20),
        label: const Text(
          'Share on WhatsApp',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF25D366),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  void _shareOnWhatsApp(BuildContext context, Order order) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final phoneController = TextEditingController();
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.message_rounded,
                      color: Color(0xFF25D366),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Share via WhatsApp',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Preview message
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '🍕 Order ${order.id} • ${order.statusLabel} • ₹${order.total.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),

              // Phone number input (optional)
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Phone number (optional)',
                  prefixText: '+91 ',
                  prefixIcon: const Icon(Icons.phone_rounded, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Leave empty to choose a contact from WhatsApp',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 20),

              // Share button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final phone = phoneController.text.trim();
                    final success = await WhatsAppHelper.shareOrderTracking(
                      order,
                      phoneNumber: phone.isNotEmpty ? phone : null,
                    );
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Could not open WhatsApp. Is it installed?',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.send_rounded, size: 20),
                  label: const Text(
                    'Send Order Details',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCancelButton(BuildContext context, Order order) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Cancel Order'),
              content: const Text(
                'Are you sure you want to cancel this order?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () {
                    Provider.of<OrderProvider>(
                      context,
                      listen: false,
                    ).cancelOrder(orderId);
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Yes, Cancel',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
        ),
        child: const Text('Cancel Order'),
      ),
    );
  }
}

class _StepData {
  final String title;
  final String subtitle;
  final IconData icon;
  final OrderStatus status;

  const _StepData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.status,
  });
}
