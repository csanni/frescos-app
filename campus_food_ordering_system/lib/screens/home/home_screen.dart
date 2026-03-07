import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../data/mock_data.dart';
import '../../models/menu_item.dart';
import '../../providers/cart_provider.dart';
import '../cart/cart_screen.dart';
import '../menu/menu_item_detail_screen.dart';
import '../orders/order_history_screen.dart';
import '../admin/admin_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentNavIndex = 0;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  List<MenuItem> get _filteredItems {
    var items = MockData.menuItems;

    if (_selectedCategory != 'All') {
      items = items
          .where((item) => item.category == _selectedCategory)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      items = items
          .where(
            (item) =>
                item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                item.description.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    return items;
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          _buildMenuTab(),
          const OrderHistoryScreen(),
          const AdminScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.restaurant_menu_rounded, 'Menu'),
              _buildNavItem(1, Icons.receipt_long_rounded, 'Orders'),
              _buildNavItem(2, Icons.admin_panel_settings_rounded, 'Admin'),
              _buildNavItem(3, Icons.person_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentNavIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentNavIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? AppSpacing.lg : AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTab() {
    return CustomScrollView(
      slivers: [_buildAppBar(), _buildCategorySelector(), _buildMenuGrid()],
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: _showSearch ? 130 : 120,
      floating: true,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.08),
                Theme.of(context).scaffoldBackgroundColor,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      title: _showSearch
          ? _buildSearchField()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_greeting! 👋',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Fresco\'s Kitchen',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
      actions: [
        IconButton(
          onPressed: () {
            setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchController.clear();
                _searchQuery = '';
              }
            });
          },
          icon: Icon(
            _showSearch ? Icons.close_rounded : Icons.search_rounded,
            color: AppColors.textPrimary,
          ),
        ),
        _buildCartButton(),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search for pizza, pasta...',
        hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        filled: false,
      ),
      style: const TextStyle(fontSize: 14),
      onChanged: (value) => setState(() => _searchQuery = value),
    );
  }

  Widget _buildCartButton() {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        return Stack(
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                );
              },
              icon: const Icon(Icons.shopping_bag_outlined),
            ),
            if (cart.itemCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${cart.itemCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCategorySelector() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 50,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          itemCount: MockData.categories.length,
          itemBuilder: (context, index) {
            final category = MockData.categories[index];
            final isSelected = category == _selectedCategory;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: GestureDetector(
                onTap: () => setState(() => _selectedCategory = category),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.divider,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMenuGrid() {
    final items = _filteredItems;

    if (items.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'No items found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return _MenuItemCard(
            item: items[index],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MenuItemDetailScreen(item: items[index]),
                ),
              );
            },
          );
        }, childCount: items.length),
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onTap;

  const _MenuItemCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final quantityInCart = cart.getQuantity(item.id);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Food image placeholder
              Hero(
                tag: 'menu-${item.id}',
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    gradient: LinearGradient(
                      colors: _getGradientColors(item.category),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _getFoodEmoji(item.category),
                      style: const TextStyle(fontSize: 36),
                    ),
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
                        // Veg/Non-veg indicator
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: item.isVeg
                                  ? AppColors.veg
                                  : AppColors.nonVeg,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: item.isVeg
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
                            item.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Rating
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: AppColors.star,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${item.rating}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          ' (${item.ratingCount})',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${item.prepTimeMinutes} min',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Tags
                    if (item.tags.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        children: item.tags.take(2).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    // Price and Add button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${item.price.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                        ),
                        if (quantityInCart > 0)
                          _buildQuantityControls(
                            context,
                            cart,
                            item,
                            quantityInCart,
                          )
                        else
                          _buildAddButton(context, cart, item),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(
    BuildContext context,
    CartProvider cart,
    MenuItem item,
  ) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: InkWell(
        onTap: () {
          cart.addItem(item);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.name} added to cart'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.success,
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: const Text(
            'ADD',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityControls(
    BuildContext context,
    CartProvider cart,
    MenuItem item,
    int quantity,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => cart.decrementQuantity(item.id),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.remove, size: 16, color: AppColors.primary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$quantity',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          InkWell(
            onTap: () => cart.incrementQuantity(item.id),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.add, size: 16, color: AppColors.primary),
            ),
          ),
        ],
      ),
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
