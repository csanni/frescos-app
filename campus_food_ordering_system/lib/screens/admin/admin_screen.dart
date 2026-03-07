import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Orders'),
            Tab(text: 'Menu'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          _buildOrdersManagementTab(),
          _buildMenuManagementTab(),
        ],
      ),
    );
  }

  // ─── DASHBOARD TAB ─────────────────────────────────────────────────

  Widget _buildDashboardTab() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, _) {
        final orders = orderProvider.orders;
        final active = orderProvider.activeOrders;
        final completedCount = orderProvider.completedOrders.length;
        final totalRevenue = orders
            .where((o) => o.status == OrderStatus.delivered)
            .fold(0.0, (sum, o) => sum + o.total);
        final totalOrders = orders.length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats cards
              Text(
                'Overview',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.lg),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard(
                    context,
                    title: 'Total Revenue',
                    value: '₹${totalRevenue.toStringAsFixed(0)}',
                    icon: Icons.currency_rupee_rounded,
                    color: AppColors.success,
                  ),
                  _buildStatCard(
                    context,
                    title: 'Total Orders',
                    value: '$totalOrders',
                    icon: Icons.receipt_long_rounded,
                    color: AppColors.info,
                  ),
                  _buildStatCard(
                    context,
                    title: 'Active Orders',
                    value: '${active.length}',
                    icon: Icons.pending_actions_rounded,
                    color: AppColors.primary,
                  ),
                  _buildStatCard(
                    context,
                    title: 'Completed',
                    value: '$completedCount',
                    icon: Icons.done_all_rounded,
                    color: AppColors.warning,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Recent active orders
              if (active.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active Orders',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _tabController.animateTo(1),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                ...active.take(3).map((order) => _AdminOrderCard(order: order)),
              ],

              if (orders.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxxl),
                    child: Column(
                      children: [
                        const Text('📊', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'No orders yet',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Dashboard will populate when orders come in',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            title,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ─── ORDERS MANAGEMENT TAB ─────────────────────────────────────────

  Widget _buildOrdersManagementTab() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, _) {
        final orders = orderProvider.orders;

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('📦', style: TextStyle(fontSize: 48)),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'No orders to manage',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            return _AdminOrderCard(order: orders[index]);
          },
        );
      },
    );
  }

  // ─── MENU MANAGEMENT TAB ──────────────────────────────────────────

  Widget _buildMenuManagementTab() {
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
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🍕', style: TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Menu Management',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add, edit, or remove menu items.\nComing soon with backend integration.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Menu management will be available with backend integration',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Menu Item'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 48)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminOrderCard extends StatelessWidget {
  final Order order;

  const _AdminOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: _getStatusColor(order.status).withValues(alpha: 0.3),
          width: 1,
        ),
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.id,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd MMM, hh:mm a').format(order.createdAt),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              _buildStatusBadge(order.status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),

          // Items
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
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
                  Expanded(
                    child: Text(
                      '${item.quantity}x ${item.menuItem.name}',
                      style: const TextStyle(fontSize: 13),
                    ),
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
          const SizedBox(height: AppSpacing.sm),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    order.deliveryType == DeliveryType.selfPickup
                        ? Icons.store_rounded
                        : Icons.delivery_dining_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    order.deliveryType == DeliveryType.selfPickup
                        ? 'Pickup'
                        : 'Delivery',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Icon(
                    order.isPaid
                        ? Icons.check_circle_rounded
                        : Icons.pending_rounded,
                    size: 14,
                    color: order.isPaid ? AppColors.success : AppColors.warning,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    order.isPaid ? 'Paid' : 'COD',
                    style: TextStyle(
                      color: order.isPaid
                          ? AppColors.success
                          : AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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

          // Admin actions
          if (order.status != OrderStatus.delivered &&
              order.status != OrderStatus.cancelled) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () => _advanceOrder(context, order),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text(_getNextActionLabel(order.status)),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () {
                      Provider.of<OrderProvider>(
                        context,
                        listen: false,
                      ).cancelOrder(order.id);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _advanceOrder(BuildContext context, Order order) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    OrderStatus? next;

    switch (order.status) {
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
        next = order.deliveryType == DeliveryType.delivery
            ? OrderStatus.outForDelivery
            : OrderStatus.delivered;
        break;
      case OrderStatus.outForDelivery:
        next = OrderStatus.delivered;
        break;
      default:
        break;
    }

    if (next != null) {
      orderProvider.updateOrderStatus(order.id, next);
    }
  }

  String _getNextActionLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return 'Confirm Order';
      case OrderStatus.confirmed:
        return 'Start Preparing';
      case OrderStatus.preparing:
        return 'Mark Ready';
      case OrderStatus.ready:
        return 'Mark Delivered';
      case OrderStatus.outForDelivery:
        return 'Mark Delivered';
      default:
        return '';
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
      case OrderStatus.confirmed:
        return AppColors.info;
      case OrderStatus.preparing:
        return AppColors.warning;
      case OrderStatus.ready:
      case OrderStatus.outForDelivery:
        return AppColors.primary;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
    }
  }

  Widget _buildStatusBadge(OrderStatus status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Text(
        order.statusLabel,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
