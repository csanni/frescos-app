import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../models/order.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../orders/order_tracking_screen.dart';

class PaymentScreen extends StatefulWidget {
  final double total;
  final DeliveryType deliveryType;
  final String? deliveryAddress;
  final String? specialInstructions;

  const PaymentScreen({
    super.key,
    required this.total,
    required this.deliveryType,
    this.deliveryAddress,
    this.specialInstructions,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  PaymentState _paymentState = PaymentState.initial;
  late AnimationController _pulseController;
  late AnimationController _successController;
  Timer? _timeoutTimer;
  int _remainingSeconds = 300; // 5 minutes
  Timer? _countdownTimer;
  String? _selectedUpiApp;

  final List<Map<String, dynamic>> _upiApps = [
    {
      'name': 'Google Pay',
      'icon': Icons.g_mobiledata_rounded,
      'color': const Color(0xFF4285F4),
    },
    {
      'name': 'PhonePe',
      'icon': Icons.phone_android_rounded,
      'color': const Color(0xFF5F259F),
    },
    {
      'name': 'Paytm',
      'icon': Icons.account_balance_wallet_rounded,
      'color': const Color(0xFF00BAF2),
    },
    {
      'name': 'BHIM',
      'icon': Icons.currency_rupee_rounded,
      'color': const Color(0xFF00838F),
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _successController.dispose();
    _timeoutTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startPayment() {
    setState(() => _paymentState = PaymentState.processing);

    // Start countdown
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
          if (_remainingSeconds <= 0) {
            timer.cancel();
            setState(() => _paymentState = PaymentState.timeout);
          }
        });
      }
    });

    // Simulate payment success after 3 seconds
    _timeoutTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _countdownTimer?.cancel();
        setState(() => _paymentState = PaymentState.success);
        _successController.forward();

        // Auto-navigate after success animation
        Timer(const Duration(seconds: 2), () {
          if (mounted) _completePayment();
        });
      }
    });
  }

  void _completePayment() {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    double deliveryFee = widget.deliveryType == DeliveryType.delivery ? 30 : 0;

    final order = orderProvider.placeOrder(
      items: cart.items,
      subtotal: cart.subtotal,
      deliveryCharge: deliveryFee,
      total: widget.total,
      paymentMethod: PaymentMethod.upi,
      deliveryType: widget.deliveryType,
      deliveryAddress: widget.deliveryAddress,
      specialInstructions: widget.specialInstructions,
    );

    cart.clearCart();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: order.id)),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        leading: _paymentState == PaymentState.processing
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    switch (_paymentState) {
      case PaymentState.initial:
        return _buildInitialState();
      case PaymentState.processing:
        return _buildProcessingState();
      case PaymentState.success:
        return _buildSuccessState();
      case PaymentState.failed:
        return _buildFailedState();
      case PaymentState.timeout:
        return _buildTimeoutState();
    }
  }

  Widget _buildInitialState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Amount card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Amount to Pay',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '₹${widget.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  ),
                  child: const Text(
                    'Secure Payment',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // UPI app selection
          Text(
            'Select UPI App',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.lg),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 2.5,
            ),
            itemCount: _upiApps.length,
            itemBuilder: (context, index) {
              final app = _upiApps[index];
              final isSelected = _selectedUpiApp == app['name'];
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedUpiApp = app['name'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (app['color'] as Color).withValues(alpha: 0.1)
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: isSelected
                          ? app['color'] as Color
                          : AppColors.divider,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        app['icon'] as IconData,
                        color: app['color'] as Color,
                        size: 24,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        app['name'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isSelected
                              ? app['color'] as Color
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Pay button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedUpiApp != null ? _startPayment : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                disabledBackgroundColor: AppColors.divider,
              ),
              child: Text(
                _selectedUpiApp != null
                    ? 'Pay ₹${widget.total.toStringAsFixed(0)} via $_selectedUpiApp'
                    : 'Select a UPI app to continue',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Security note
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Your payment is 100% secure',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingState() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.1),
                child: child,
              );
            },
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Processing Payment...',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Please complete the payment in your UPI app',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: _remainingSeconds < 60
                  ? AppColors.error
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Time remaining',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Center(
      child: AnimatedBuilder(
        animation: _successController,
        builder: (context, child) {
          return Transform.scale(
            scale: _successController.value,
            child: Opacity(opacity: _successController.value, child: child),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 64,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Payment Successful!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '₹${widget.total.toStringAsFixed(0)} paid successfully',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: AppSpacing.xl),
            const CircularProgressIndicator(strokeWidth: 2),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Redirecting to order tracking...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 64,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Payment Failed',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Something went wrong with the payment.\nPlease try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _paymentState = PaymentState.initial;
                    _remainingSeconds = 300;
                  });
                },
                child: const Text('Try Again'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // Switch to COD
                  final cart = Provider.of<CartProvider>(
                    context,
                    listen: false,
                  );
                  final orderProvider = Provider.of<OrderProvider>(
                    context,
                    listen: false,
                  );
                  double deliveryFee =
                      widget.deliveryType == DeliveryType.delivery ? 30 : 0;

                  final order = orderProvider.placeOrder(
                    items: cart.items,
                    subtotal: cart.subtotal,
                    deliveryCharge: deliveryFee,
                    total: widget.total,
                    paymentMethod: PaymentMethod.cashOnDelivery,
                    deliveryType: widget.deliveryType,
                    deliveryAddress: widget.deliveryAddress,
                    specialInstructions: widget.specialInstructions,
                  );

                  cart.clearCart();

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderTrackingScreen(orderId: order.id),
                    ),
                    (route) => route.isFirst,
                  );
                },
                child: const Text('Pay with Cash Instead'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeoutState() {
    return _buildFailedState();
  }
}

enum PaymentState { initial, processing, success, failed, timeout }
