import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../providers/cart_provider.dart';
import '../checkout/checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              if (cart.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Clear Cart'),
                      content: const Text('Remove all items from your cart?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            cart.clearCart();
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Clear',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: Text(
                  'Clear All',
                  style: TextStyle(color: AppColors.error, fontSize: 13),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.isEmpty) {
            return _buildEmptyState(context);
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return Dismissible(
                      key: Key(item.menuItem.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => cart.removeItem(item.menuItem.id),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: AppSpacing.xl),
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.error,
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
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
                            // Thumbnail
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusSm,
                                ),
                                gradient: LinearGradient(
                                  colors: _getGradientColors(
                                    item.menuItem.category,
                                  ),
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _getFoodEmoji(item.menuItem.category),
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: item.menuItem.isVeg
                                                ? AppColors.veg
                                                : AppColors.nonVeg,
                                            width: 1.5,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              color: item.menuItem.isVeg
                                                  ? AppColors.veg
                                                  : AppColors.nonVeg,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          item.menuItem.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${item.menuItem.price.toStringAsFixed(0)} each',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  if (item.specialInstructions != null &&
                                      item.specialInstructions!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Note: ${item.specialInstructions}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.primary,
                                            fontStyle: FontStyle.italic,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: AppSpacing.sm),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Quantity controls
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: AppColors.divider,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            AppSpacing.radiusSm,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(
                                              onTap: () =>
                                                  cart.decrementQuantity(
                                                    item.menuItem.id,
                                                  ),
                                              child: const Padding(
                                                padding: EdgeInsets.all(6),
                                                child: Icon(
                                                  Icons.remove,
                                                  size: 16,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                  ),
                                              child: Text(
                                                '${item.quantity}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () =>
                                                  cart.incrementQuantity(
                                                    item.menuItem.id,
                                                  ),
                                              child: const Padding(
                                                padding: EdgeInsets.all(6),
                                                child: Icon(
                                                  Icons.add,
                                                  size: 16,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Line total
                                      Text(
                                        '₹${item.totalPrice.toStringAsFixed(0)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              _buildCartSummary(context, cart),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🛒', style: TextStyle(fontSize: 48)),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Your cart is empty',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add some delicious items from our menu',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: 200,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Browse Menu'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartSummary(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bill details
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(
                    context,
                    'Subtotal',
                    '₹${cart.subtotal.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildSummaryRow(
                    context,
                    'Delivery Fee',
                    cart.deliveryCharge > 0
                        ? '₹${cart.deliveryCharge.toStringAsFixed(0)}'
                        : 'FREE',
                    valueColor: cart.deliveryCharge > 0
                        ? null
                        : AppColors.success,
                  ),
                  if (cart.subtotal > 0 && cart.subtotal <= 500) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Add ₹${(500 - cart.subtotal).toStringAsFixed(0)} more for free delivery',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Divider(),
                  ),
                  _buildSummaryRow(
                    context,
                    'Total',
                    '₹${cart.total.toStringAsFixed(0)}',
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Checkout button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              ),
              child: Text(
                'Proceed to Checkout  •  ₹${cart.total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
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
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
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

  List<Color> _getGradientColors(String category) {
    switch (category) {
      case 'Pizza':
        return [const Color(0xFFFF9A8B), const Color(0xFFFF6B6B)];
      case 'Pasta':
        return [const Color(0xFFFBD786), const Color(0xFFF7797D)];
      case 'Beverages':
        return [const Color(0xFF89F7FE), const Color(0xFF66A6FF)];
      case 'Desserts':
        return [const Color(0xFFA18CD1), const Color(0xFFFBC2EB)];
      case 'Sides':
        return [const Color(0xFFFAD961), const Color(0xFFF76B1C)];
      default:
        return [const Color(0xFF667EEA), const Color(0xFF764BA2)];
    }
  }

  String _getFoodEmoji(String category) {
    switch (category) {
      case 'Pizza':
        return '🍕';
      case 'Pasta':
        return '🍝';
      case 'Beverages':
        return '🥤';
      case 'Desserts':
        return '🍰';
      case 'Sides':
        return '🍟';
      default:
        return '🍽️';
    }
  }
}
