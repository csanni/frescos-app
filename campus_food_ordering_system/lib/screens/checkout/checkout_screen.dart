import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../models/order.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../payment/payment_screen.dart';
import '../orders/order_tracking_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  DeliveryType _deliveryType = DeliveryType.selfPickup;
  PaymentMethod _paymentMethod = PaymentMethod.upi;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  bool _showOrderSummary = false;

  @override
  void dispose() {
    _addressController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery Option
            _buildSectionHeader(
              context,
              'Delivery Option',
              Icons.local_shipping_rounded,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildDeliveryOptions(),
            const SizedBox(height: AppSpacing.xl),

            // Address (if delivery)
            if (_deliveryType == DeliveryType.delivery) ...[
              _buildSectionHeader(
                context,
                'Delivery Address',
                Icons.location_on_rounded,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Enter your delivery address (Room/Block/Hostel)',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

            // Payment Method
            _buildSectionHeader(
              context,
              'Payment Method',
              Icons.payment_rounded,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildPaymentOptions(),
            const SizedBox(height: AppSpacing.xl),

            // Special Instructions
            _buildSectionHeader(
              context,
              'Special Instructions',
              Icons.note_alt_rounded,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _instructionsController,
              maxLines: 2,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: 'Any special requests? (optional)',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Order Summary
            _buildOrderSummarySection(context, cart),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: _buildPlaceOrderButton(context, cart),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildDeliveryOptions() {
    return Column(
      children: [
        _buildOptionTile(
          title: 'Self Pickup',
          subtitle: 'Pick up from the counter yourself',
          icon: Icons.store_rounded,
          isSelected: _deliveryType == DeliveryType.selfPickup,
          onTap: () => setState(() => _deliveryType = DeliveryType.selfPickup),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildOptionTile(
          title: 'Delivery',
          subtitle: 'Get it delivered to your location',
          icon: Icons.delivery_dining_rounded,
          isSelected: _deliveryType == DeliveryType.delivery,
          onTap: () => setState(() => _deliveryType = DeliveryType.delivery),
          trailing: const Text(
            '+₹30',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOptions() {
    return Column(
      children: [
        _buildOptionTile(
          title: 'UPI Payment',
          subtitle: 'Pay securely using UPI apps',
          icon: Icons.account_balance_rounded,
          isSelected: _paymentMethod == PaymentMethod.upi,
          onTap: () => setState(() => _paymentMethod = PaymentMethod.upi),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Recommended',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildOptionTile(
          title: 'Cash on Delivery',
          subtitle: 'Pay when you receive your order',
          icon: Icons.money_rounded,
          isSelected: _paymentMethod == PaymentMethod.cashOnDelivery,
          onTap: () =>
              setState(() => _paymentMethod = PaymentMethod.cashOnDelivery),
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.06)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              trailing,
              const SizedBox(width: AppSpacing.sm),
            ],
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  width: 2,
                ),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummarySection(BuildContext context, CartProvider cart) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _showOrderSummary = !_showOrderSummary),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          'Order Summary (${cart.itemCount} items)',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Icon(
                      _showOrderSummary
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                if (_showOrderSummary) ...[
                  const SizedBox(height: AppSpacing.md),
                  const Divider(),
                  ...cart.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.quantity}x ${item.menuItem.name}',
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '₹${item.totalPrice.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                _buildBillRow(
                  context,
                  'Subtotal',
                  '₹${cart.subtotal.toStringAsFixed(0)}',
                ),
                const SizedBox(height: AppSpacing.xs),
                _buildBillRow(
                  context,
                  'Delivery Fee',
                  _deliveryType == DeliveryType.delivery ? '₹30' : 'FREE',
                  valueColor: _deliveryType == DeliveryType.delivery
                      ? null
                      : AppColors.success,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Divider(),
                ),
                _buildBillRow(
                  context,
                  'Total Amount',
                  '₹${_calculateTotal(cart).toStringAsFixed(0)}',
                  isBold: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBillRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.w700 : null,
            color: isBold ? null : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? (isBold ? AppColors.primary : null),
            fontSize: isBold ? 16 : null,
          ),
        ),
      ],
    );
  }

  double _calculateTotal(CartProvider cart) {
    double deliveryFee = _deliveryType == DeliveryType.delivery ? 30 : 0;
    return cart.subtotal + deliveryFee;
  }

  Widget _buildPlaceOrderButton(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () => _handlePlaceOrder(context, cart),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline_rounded, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _paymentMethod == PaymentMethod.upi
                    ? 'Pay ₹${_calculateTotal(cart).toStringAsFixed(0)}'
                    : 'Place Order  •  ₹${_calculateTotal(cart).toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePlaceOrder(BuildContext context, CartProvider cart) {
    if (_deliveryType == DeliveryType.delivery &&
        _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your delivery address'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: const Text('Confirm Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${cart.itemCount} items • ₹${_calculateTotal(cart).toStringAsFixed(0)}',
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _deliveryType == DeliveryType.selfPickup
                  ? '📦 Self Pickup'
                  : '🚚 Delivery',
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              _paymentMethod == PaymentMethod.upi
                  ? '💳 UPI Payment'
                  : '💵 Cash on Delivery',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);

              if (_paymentMethod == PaymentMethod.upi) {
                // Navigate to payment screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentScreen(
                      total: _calculateTotal(cart),
                      deliveryType: _deliveryType,
                      deliveryAddress: _addressController.text,
                      specialInstructions: _instructionsController.text,
                    ),
                  ),
                );
              } else {
                // Cash on delivery - place order directly
                _placeOrderDirectly(context, cart);
              }
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(100, 40)),
            child: Text(
              _paymentMethod == PaymentMethod.upi
                  ? 'Proceed to Pay'
                  : 'Place Order',
            ),
          ),
        ],
      ),
    );
  }

  void _placeOrderDirectly(BuildContext context, CartProvider cart) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    double deliveryFee = _deliveryType == DeliveryType.delivery ? 30 : 0;

    final order = orderProvider.placeOrder(
      items: cart.items,
      subtotal: cart.subtotal,
      deliveryCharge: deliveryFee,
      total: _calculateTotal(cart),
      paymentMethod: PaymentMethod.cashOnDelivery,
      deliveryType: _deliveryType,
      deliveryAddress: _addressController.text.isNotEmpty
          ? _addressController.text
          : null,
      specialInstructions: _instructionsController.text.isNotEmpty
          ? _instructionsController.text
          : null,
    );

    cart.clearCart();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: order.id)),
      (route) => route.isFirst,
    );
  }
}
