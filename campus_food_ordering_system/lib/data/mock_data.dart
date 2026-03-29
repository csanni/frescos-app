import '../models/menu_item.dart';

class MockData {
  static const List<String> categories = [
    'All',
    'Pizza',
    'Pasta',
    'Beverages',
    'Desserts',
    'Sides',
  ];

  static List<MenuItem> get menuItems => [
    // Pizzas
    const MenuItem(
      id: 'pizza-1',
      name: 'Margherita Classic',
      description:
          'Fresh mozzarella, San Marzano tomato sauce, fresh basil leaves on a hand-tossed crust',
      price: 299,
      imageUrl: 'pizza_margherita',
      category: 'Pizza',
      isVeg: true,
      rating: 4.7,
      ratingCount: 234,
      tags: ['Bestseller', 'Classic'],
      prepTimeMinutes: 15,
    ),
    const MenuItem(
      id: 'pizza-2',
      name: 'Pepperoni Feast',
      description:
          'Loaded with double pepperoni, extra mozzarella cheese, and Italian herbs on a thick crust',
      price: 449,
      imageUrl: 'pizza_pepperoni',
      category: 'Pizza',
      isVeg: false,
      rating: 4.8,
      ratingCount: 189,
      tags: ['Popular', 'Non-Veg'],
      prepTimeMinutes: 18,
    ),
    const MenuItem(
      id: 'pizza-3',
      name: 'BBQ Chicken Supreme',
      description:
          'Smoky BBQ sauce, grilled chicken, red onions, green peppers, and cheddar cheese',
      price: 499,
      imageUrl: 'pizza_bbq',
      category: 'Pizza',
      isVeg: false,
      rating: 4.6,
      ratingCount: 156,
      tags: ['Spicy', 'Non-Veg'],
      prepTimeMinutes: 20,
    ),
    const MenuItem(
      id: 'pizza-4',
      name: 'Farm Fresh Veggie',
      description:
          'Bell peppers, mushrooms, olives, onions, corn, and fresh tomatoes with herb seasoning',
      price: 349,
      imageUrl: 'pizza_veggie',
      category: 'Pizza',
      isVeg: true,
      rating: 4.4,
      ratingCount: 112,
      tags: ['Healthy', 'Veg'],
      prepTimeMinutes: 15,
    ),
    const MenuItem(
      id: 'pizza-5',
      name: 'Four Cheese Delight',
      description:
          'Mozzarella, cheddar, parmesan, and gouda cheeses on a garlic butter crust',
      price: 429,
      imageUrl: 'pizza_cheese',
      category: 'Pizza',
      isVeg: true,
      rating: 4.9,
      ratingCount: 278,
      tags: ['Bestseller', 'Cheese Lovers'],
      prepTimeMinutes: 15,
    ),
    const MenuItem(
      id: 'pizza-6',
      name: 'Tandoori Paneer Pizza',
      description:
          'Tandoori spiced paneer, onions, capsicum with mint mayo swirl on a whole wheat crust',
      price: 399,
      imageUrl: 'pizza_tandoori',
      category: 'Pizza',
      isVeg: true,
      rating: 4.5,
      ratingCount: 98,
      tags: ['Indian Fusion', 'Spicy'],
      prepTimeMinutes: 18,
    ),

    // Pasta
    const MenuItem(
      id: 'pasta-1',
      name: 'Creamy Alfredo Pasta',
      description:
          'Penne pasta in rich parmesan cream sauce with garlic bread on the side',
      price: 249,
      imageUrl: 'pasta_alfredo',
      category: 'Pasta',
      isVeg: true,
      rating: 4.3,
      ratingCount: 87,
      tags: ['Creamy'],
      prepTimeMinutes: 12,
    ),
    const MenuItem(
      id: 'pasta-2',
      name: 'Arrabbiata Penne',
      description:
          'Spicy tomato sauce with garlic, red chili flakes, fresh basil, and parmesan shavings',
      price: 229,
      imageUrl: 'pasta_arrabbiata',
      category: 'Pasta',
      isVeg: true,
      rating: 4.2,
      ratingCount: 65,
      tags: ['Spicy', 'Classic'],
      prepTimeMinutes: 12,
    ),
    const MenuItem(
      id: 'pasta-3',
      name: 'Chicken Carbonara',
      description:
          'Spaghetti with grilled chicken, crispy bacon bits, egg, parmesan, and black pepper',
      price: 329,
      imageUrl: 'pasta_carbonara',
      category: 'Pasta',
      isVeg: false,
      rating: 4.6,
      ratingCount: 142,
      tags: ['Popular', 'Non-Veg'],
      prepTimeMinutes: 15,
    ),

    // Beverages
    const MenuItem(
      id: 'bev-1',
      name: 'Cold Coffee Frappe',
      description:
          'Blended iced coffee with chocolate drizzle, whipped cream, and coffee bean topping',
      price: 149,
      imageUrl: 'bev_coffee',
      category: 'Beverages',
      isVeg: true,
      rating: 4.5,
      ratingCount: 203,
      tags: ['Chilled', 'Popular'],
      prepTimeMinutes: 5,
    ),
    const MenuItem(
      id: 'bev-2',
      name: 'Fresh Lime Soda',
      description:
          'Freshly squeezed lime with soda water, mint leaves, and a hint of rock salt',
      price: 79,
      imageUrl: 'bev_lime',
      category: 'Beverages',
      isVeg: true,
      rating: 4.3,
      ratingCount: 156,
      tags: ['Refreshing'],
      prepTimeMinutes: 3,
    ),
    const MenuItem(
      id: 'bev-3',
      name: 'Mango Lassi',
      description:
          'Thick and creamy yogurt-based mango smoothie with a cardamom touch',
      price: 119,
      imageUrl: 'bev_lassi',
      category: 'Beverages',
      isVeg: true,
      rating: 4.7,
      ratingCount: 189,
      tags: ['Bestseller', 'Sweet'],
      prepTimeMinutes: 5,
    ),

    // Desserts
    const MenuItem(
      id: 'dessert-1',
      name: 'Chocolate Lava Cake',
      description:
          'Warm molten chocolate cake with a gooey center, served with vanilla ice cream',
      price: 199,
      imageUrl: 'dessert_lava',
      category: 'Desserts',
      isVeg: true,
      rating: 4.8,
      ratingCount: 267,
      tags: ['Bestseller', 'Must Try'],
      prepTimeMinutes: 10,
    ),
    const MenuItem(
      id: 'dessert-2',
      name: 'Tiramisu',
      description:
          'Classic Italian dessert with layers of mascarpone cream, espresso-soaked ladyfingers',
      price: 249,
      imageUrl: 'dessert_tiramisu',
      category: 'Desserts',
      isVeg: true,
      rating: 4.6,
      ratingCount: 134,
      tags: ['Premium', 'Italian'],
      prepTimeMinutes: 5,
    ),

    // Sides
    const MenuItem(
      id: 'side-1',
      name: 'Garlic Bread Sticks',
      description:
          'Crispy breadsticks brushed with garlic butter and herbs, served with marinara dip',
      price: 129,
      imageUrl: 'side_garlic',
      category: 'Sides',
      isVeg: true,
      rating: 4.4,
      ratingCount: 178,
      tags: ['Starter'],
      prepTimeMinutes: 8,
    ),
    const MenuItem(
      id: 'side-2',
      name: 'Cheesy Fries',
      description:
          'Golden crispy fries loaded with melted cheddar cheese and jalapeño peppers',
      price: 149,
      imageUrl: 'side_fries',
      category: 'Sides',
      isVeg: true,
      rating: 4.5,
      ratingCount: 198,
      tags: ['Popular', 'Cheese'],
      prepTimeMinutes: 8,
    ),
    const MenuItem(
      id: 'side-3',
      name: 'Chicken Wings (6 pcs)',
      description:
          'Spicy buffalo chicken wings with ranch dipping sauce and celery sticks',
      price: 249,
      imageUrl: 'side_wings',
      category: 'Sides',
      isVeg: false,
      rating: 4.7,
      ratingCount: 223,
      tags: ['Spicy', 'Non-Veg'],
      prepTimeMinutes: 12,
    ),
  ];
}
