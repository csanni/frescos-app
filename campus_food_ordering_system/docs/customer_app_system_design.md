# Fresco's Kitchen — Customer Mobile App System Design

**Version:** 2.0 · **Date:** 1 March 2026 · **Author:** Engineering Team  
**Companion Document:** [Admin Portal System Design](./admin_portal_system_design.md)

---

## Table of Contents

1. [Overview](#1-overview)
2. [Architecture](#2-architecture)
3. [Screen Flow & Navigation](#3-screen-flow--navigation)
4. [Existing Codebase](#4-existing-codebase)
5. [Data Models](#5-data-models)
6. [State Management](#6-state-management)
7. [Feature Specifications](#7-feature-specifications)
8. [Backend API Integration](#8-backend-api-integration)
9. [Database Schema (Customer-Facing)](#9-database-schema)
10. [Real-Time & Notifications](#10-real-time--notifications)
11. [Security](#11-security)
12. [Performance & Deployment](#12-performance--deployment)
13. [Implementation Roadmap](#13-implementation-roadmap)

---

## 1. Overview

The Fresco's Kitchen Customer Mobile App is a **cross-platform Flutter application** (Android + iOS, single codebase) that enables campus students to browse the menu, customize pizza orders, place delivery orders, track in real time, and receive WhatsApp/push notifications.

### Key Characteristics

| Aspect | Detail |
|--------|--------|
| **Framework** | Flutter 3.x (Dart) |
| **Platforms** | Android, iOS |
| **Design System** | Material Design 3 (Material You) |
| **Font** | Inter (Google Fonts) |
| **Primary Color** | `#FF6B35` (Fresco's Orange) |
| **State Management** | Provider (ChangeNotifier) |
| **Prototype** | `prototype/index.html` — 1,316 lines of working JS |
| **Delivery Model** | Dine-in + Self Pickup + Delivery (all 3 available) |
| **Preparation Time** | 25–30 minutes (prep), +10 min for delivery |
| **Payment** | Cash at Store (dine-in/pickup) or UPI to Delivery Agent (delivery) |

### Prototype Data Inventory

| Data | Count | Source |
|------|-------|--------|
| Menu Items | 23 | 6 categories: Pizza (4), Japanese (5), Sides (3), Beverages (4), Desserts (4), Combo (3) |
| Category Tabs | 7 | All, Pizzas, Sides, Japanese, Beverages, Desserts, Combo Meals |
| Sample Notifications | 3 | Promo, BOGO, system update |

---

## 2. Architecture

### 2.1 High-Level System Context

```mermaid
graph TB
    subgraph "Customer App (Flutter)"
        UI["UI Layer<br/>(12 Screens)"]
        PROV["State Layer<br/>(5 Providers)"]
        SVC["Service Layer<br/>(API + Cache)"]
    end

    subgraph "Backend"
        API["REST API<br/>(NestJS / FastAPI)"]
        WS["WebSocket Server"]
    end

    subgraph "External"
        FCM["Firebase Cloud Messaging"]
        WA["WhatsApp Business API"]
    end

    UI --> PROV
    PROV --> SVC
    SVC -->|HTTPS| API
    SVC -->|WSS| WS
    API --> FCM
    API --> WA
```

### 2.2 Flutter App Layers

```
┌──────────────────────────────────────┐
│          UI Layer (Screens)          │
│  Splash → Login → Home → Detail →   │
│  Cart → Checkout → Tracking → etc   │
├──────────────────────────────────────┤
│       State Layer (Providers)        │
│  AuthProvider · MenuProvider ·       │
│  CartProvider · OrderProvider ·      │
│  NotificationProvider                │
├──────────────────────────────────────┤
│       Service Layer (Data)           │
│  ApiService · WebSocketService ·     │
│  CacheService · NotificationService  │
├──────────────────────────────────────┤
│       Core Layer (Shared)            │
│  AppTheme · AppColors · AppSpacing · │
│  Constants · Utils · WhatsAppHelper  │
└──────────────────────────────────────┘
```

---

## 3. Screen Flow & Navigation

### 3.1 Navigation Graph

```mermaid
graph LR
    SPLASH["Splash Screen"] --> LOGIN["Login Screen"]
    LOGIN --> OTP["OTP Screen"]
    OTP --> HOME["Home / Menu"]
    HOME --> DETAIL["Item Detail"]
    HOME --> CART["Cart Screen"]
    HOME --> ORDERS["Order History"]
    HOME --> PROFILE["Profile Screen"]
    DETAIL --> CART
    CART --> CHECKOUT["Checkout"]
    CHECKOUT --> TRACKING["Order Tracking"]
    ORDERS --> TRACKING
```

### 3.1.1 Order Fulfillment User Flow

```mermaid
graph TD
    A["Browse Menu"] --> B["Select Item"]
    B --> C["Choose Size / Toppings"]
    C --> D["Add to Cart"]
    D --> E{"More items?"}
    E -->|Yes| A
    E -->|No| F["View Cart"]
    F --> G["Proceed to Checkout"]
    G --> H["Select Order Type"]
    H --> I["🍽️ Dine-in"]
    H --> J["🛍️ Self Pickup"]
    H --> K["🚚 Delivery"]
    I --> M["Review Order Summary"]
    J --> M
    K --> L["Enter Delivery Address"]
    L --> M
    M --> N["Confirm & Place Order"]
    N --> O["Order Tracking Screen"]
    O --> P{"Order Ready?"}
    P -->|No| Q["Wait for status updates"]
    Q --> P
    P -->|Dine-in| R["Slide to Confirm Dine-in ➜"]
    P -->|Pickup| S["Slide to Collect ➜"]
    P -->|Delivery| T["Slide to Accept Delivery ➜"]
    R --> U["Visit Store → Pay Cash → Enjoy"]
    S --> V["Visit Store → Pay Cash → Collect"]
    T --> W["Pay via UPI to Delivery Agent"]
    U --> X["✅ Order Completed"]
    V --> X
    W --> X
```

### 3.1.2 Order Status State Machine

```mermaid
stateDiagram-v2
    [*] --> Placed : Customer places order
    Placed --> Confirmed : Kitchen accepts (~2 min)
    Confirmed --> Ready : Food prepared (~15 min)
    Ready --> Collected : Slide to accept (Pickup)
    Ready --> DineInConfirmed : Slide to accept (Dine-in)
    Ready --> Delivered : Slide to accept (Delivery)
    Collected --> [*]
    DineInConfirmed --> [*]
    Delivered --> [*]
    Placed --> Cancelled : Customer cancels
    Confirmed --> Cancelled : Customer cancels
    Cancelled --> [*]

    note right of Ready
        Status label adapts:
        Pickup → "Ready for Pickup"
        Dine-in → "Ready for Dine-in"
        Delivery → "Out for Delivery"
    end note
```

### 3.1.3 Slide-to-Accept Button States

```mermaid
stateDiagram-v2
    [*] --> Hidden : Order status ≠ ready
    Hidden --> Idle : Order status = ready
    Idle --> Dragging : User starts dragging thumb
    Dragging --> Released : User releases before threshold
    Released --> Idle : Thumb snaps back to start
    Dragging --> Completed : Thumb passes 85% threshold
    Completed --> [*] : Order marked as collected/confirmed/delivered

    note right of Idle
        Pickup: "Slide to Collect ➜"
        Dine-in: "Slide to Confirm Dine-in ➜"
        Delivery: "Slide to Accept Delivery ➜"
    end note
    note right of Completed
        Pickup: "✔ Collected!"
        Dine-in: "✔ Dine-in Confirmed!"
        Delivery: "✔ Delivered!"
        Background turns green, confetti
    end note
```

### 3.2 Bottom Navigation

| Tab | Icon | Screen | Provider |
|-----|------|--------|----------|
| Menu | `restaurant_menu` | HomeScreen | MenuProvider |
| Orders | `receipt_long` | OrderHistoryScreen | OrderProvider |
| Alerts | `notifications` | Notification List | NotificationProvider |
| Profile | `person` | ProfileScreen | AuthProvider |

### 3.3 Screen Inventory

| # | Screen | File | Key Features | Status |
|---|--------|------|-------------|--------|
| 1 | Splash | `splash_screen.dart` | Animated logo, auto-navigate after 2s | ✅ Exists |
| 2 | Login | `login_screen.dart` | Phone number input, country code | ✅ Exists |
| 3 | OTP | `otp_screen.dart` | 6-digit OTP, resend timer, auto-verify | ✅ Exists |
| 4 | Home / Menu | `home_screen.dart` | Category tabs (flex-wrap grid, 7 tabs), search, menu item cards, veg/non-veg badge | ✅ Exists |
| 5 | Item Detail | `menu_item_detail_screen.dart` | Image, description, size picker (S/M/L), toppings checkboxes, crust options, qty stepper, cooking instructions, dynamic price | ✅ Exists |
| 6 | Cart | `cart_screen.dart` | Item list with qty adjustment, subtotal, delivery charge (₹30 if < ₹500), promo code input, grand total | ✅ Exists |
| 7 | Checkout | `checkout_screen.dart` | Order type selection (Pickup/Dine-in), location text field, cooking instructions, order summary | ✅ Exists |
| 8 | Payment | `payment_screen.dart` | Cash at Store (selected), UPI placeholder | ✅ Exists |
| 9 | Order Tracking | `order_tracking_screen.dart` | Status stepper with order-type-aware labels, order type badge, 25-30 min ETA, slide-to-accept | ✅ Exists |
| 10 | Order History | `order_history_screen.dart` | Past orders list, status badges, reorder button | ✅ Exists |
| 11 | Profile | `profile_screen.dart` | Edit name/phone, saved addresses, favorites, help/FAQ, about section | ✅ Exists |
| 12 | Admin (Mobile) | `admin_screen.dart` | Dashboard + Orders tabs (3-tab view) | ✅ Exists |

---

## 4. Existing Codebase

### 4.1 Project Structure

```
lib/
├── app.dart                              # MyApp root widget with MultiProvider
├── main.dart                             # Entry point: runApp(MyApp())
├── injection_container.dart              # Dependency injection setup
├── core/
│   ├── constants/
│   │   ├── app_colors.dart               # 20+ color constants
│   │   └── app_spacing.dart              # xs(4) → xxxl(48) + border radii
│   ├── theme/
│   │   └── app_theme.dart                # Material3 light + dark ThemeData
│   └── utils/
│       └── whatsapp_helper.dart          # URL launcher for WhatsApp
├── data/
│   └── mock_data.dart                    # 17 sample MenuItems (5 categories)
├── models/
│   ├── menu_item.dart                    # MenuItem (13 fields)
│   ├── cart_item.dart                    # CartItem (menuItem, qty, instructions)
│   └── order.dart                        # Order + OrderStatus + PaymentMethod + DeliveryType
├── providers/
│   ├── cart_provider.dart                # CartProvider (ChangeNotifier)
│   └── order_provider.dart               # OrderProvider (ChangeNotifier)
└── screens/
    ├── admin/admin_screen.dart           # 3-tab admin panel
    ├── auth/login_screen.dart            # Phone login
    ├── auth/otp_screen.dart              # OTP verification
    ├── auth/splash_screen.dart           # Splash
    ├── cart/cart_screen.dart              # Shopping cart
    ├── checkout/checkout_screen.dart      # Checkout flow
    ├── home/home_screen.dart              # Menu browsing
    ├── menu/menu_item_detail_screen.dart  # Item detail + customization
    ├── orders/order_history_screen.dart   # History
    ├── orders/order_tracking_screen.dart  # Live tracking
    ├── payment/payment_screen.dart        # Payment selection
    └── profile/profile_screen.dart        # User profile
```

### 4.2 Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter: sdk
  provider: ^6.1.2          # State management
  google_fonts: ^6.2.1      # Inter font family
  intl: ^0.19.0             # Date/number formatting
  uuid: ^4.5.1              # Order ID generation
  url_launcher: ^6.3.1      # WhatsApp links
```

---

## 5. Data Models

### 5.1 MenuItem

```dart
class MenuItem {
  final String id;            // 'pizza-1'
  final String name;          // 'Margherita Classic'
  final String description;   // Full text
  final double price;         // 299.0
  final String imageUrl;      // Asset or URL reference
  final String category;      // 'Pizza', 'Pasta', etc.
  final bool isVeg;           // true/false
  final bool isAvailable;     // Active toggle
  final double rating;        // 0.0 – 5.0
  final int ratingCount;      // Number of ratings
  final List<String> tags;    // ['Bestseller', 'Spicy']
  final int prepTimeMinutes;  // 15
}
```

### 5.2 Proposed Extensions

```dart
// NEW: Pizza customization support
class MenuItem {
  // ... existing 13 fields ...
  final List<SizeOption> sizeOptions;       // Small/Medium/Large
  final List<ToppingOption> toppingOptions; // Extra cheese, mushrooms, etc
  final List<CrustOption> crustOptions;     // Thin, Thick, Stuffed
  final String? allergenInfo;               // Dietary info
  final int? calorieCount;                  // Nutrition
  final bool isFeatured;                    // Homepage hero
}

class SizeOption {
  final String id;           // 'small', 'medium', 'large'
  final String label;        // 'Small (7")'
  final double priceAddon;   // 0 / +50 / +100
}

class ToppingOption {
  final String id;
  final String name;         // 'Extra Cheese'
  final double price;        // 40.0
  final bool isVeg;
  final String category;     // 'cheese', 'meat', 'veggies'
}

class CrustOption {
  final String id;
  final String label;        // 'Thin Crust'
  final double priceAddon;   // 0 / +50
}
```

### 5.3 CartItem

```dart
class CartItem {
  final MenuItem menuItem;
  int quantity;                        // Mutable for quick ±
  final String? specialInstructions;   // Cooking notes
  // NEW extensions:
  final SizeOption? selectedSize;
  final List<ToppingOption> selectedToppings;
  final CrustOption? selectedCrust;

  double get totalPrice =>
    (menuItem.price
     + (selectedSize?.priceAddon ?? 0)
     + selectedToppings.fold(0.0, (s, t) => s + t.price)
     + (selectedCrust?.priceAddon ?? 0)
    ) * quantity;
}
```

### 5.4 Order

```dart
enum OrderStatus {
  placed, confirmed, preparing, ready, outForDelivery, delivered, cancelled
}
enum PaymentMethod { cashAtStore, upiToAgent }
enum OrderType { dineIn, selfPickup, delivery }

class Order {
  final String id;                     // 'ORD-A1B2C3D4' or 'PIZ-20260301-0100'
  final List<CartItem> items;
  final double subtotal;
  final double deliveryCharge;         // ₹30 if subtotal < ₹500
  final double discount;
  final double total;
  final OrderStatus status;            // 7-state lifecycle
  final PaymentMethod paymentMethod;
  final OrderType orderType;           // Dine-in, Self Pickup, or Delivery
  final String? deliveryAddress;       // Hostel name / building
  final String? specialInstructions;   // Cooking instructions
  final DateTime createdAt;
  final DateTime? estimatedReadyTime;  // createdAt + 20 min
  final DateTime? completedAt;
  final bool isPaid;
}
```

---

## 6. State Management

### 6.1 Provider Architecture

```mermaid
graph TB
    subgraph "Providers (ChangeNotifier)"
        AP["AuthProvider<br/>• user session<br/>• login / logout<br/>• token refresh"]
        MP["MenuProvider<br/>• menuItems list<br/>• categories<br/>• search / filter"]
        CP["CartProvider ✅<br/>• items, qty, totals<br/>• promo codes<br/>• delivery charge"]
        OP["OrderProvider ✅<br/>• place order<br/>• active / completed<br/>• status tracking"]
        NP["NotificationProvider<br/>• notifications list<br/>• unread count<br/>• mark read"]
    end

    subgraph "Data Sources"
        API["Backend REST API"]
        WSS["WebSocket"]
        CACHE["Local Cache"]
    end

    AP --> API & CACHE
    MP --> API & CACHE
    CP --> CACHE
    OP --> API & WSS
    NP --> WSS
```

### 6.2 CartProvider (Existing)

| Method | Signature | Behavior |
|--------|-----------|----------|
| `addItem` | `addItem(MenuItem, {qty, instructions})` | Add or increment if exists |
| `removeItem` | `removeItem(String menuItemId)` | Remove by ID |
| `updateQuantity` | `updateQuantity(String id, int qty)` | Set qty; remove if ≤ 0 |
| `incrementQuantity` | `incrementQuantity(String id)` | +1 |
| `decrementQuantity` | `decrementQuantity(String id)` | -1 or remove if qty = 1 |
| `clearCart` | `clearCart()` | Remove all items |

**Computed Properties:**

| Property | Formula |
|----------|---------|
| `items` | Unmodifiable list |
| `itemCount` | Sum of all quantities |
| `subtotal` | Sum of item.totalPrice |
| `deliveryCharge` | ₹30 if subtotal < ₹500, else ₹0 |
| `total` | subtotal + deliveryCharge |
| `isEmpty` | items.isEmpty |

### 6.3 OrderProvider (Existing)

| Method | Behavior |
|--------|----------|
| `placeOrder({items, subtotal, ...})` | Creates order with UUID, starts status simulation |
| `updateOrderStatus(id, status)` | Updates status, sets completedAt if delivered |
| `cancelOrder(id)` | Sets status = cancelled |
| `_simulateOrderProgress(id)` | Timer-based demo: placed→confirmed(8s)→preparing(12s)→ready(20s)→delivered(15s) |

### 6.4 New Providers (To Build)

```dart
// AuthProvider
class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _accessToken;
  Future<void> sendOtp(String phone);
  Future<void> verifyOtp(String phone, String otp);
  Future<void> refreshToken();
  Future<void> logout();
  Future<void> updateProfile(String name, String phone);
}

// MenuProvider
class MenuProvider extends ChangeNotifier {
  List<MenuItem> _items = [];
  List<String> _categories = [];
  String _searchQuery = '';
  String _activeCategory = 'All';
  Future<void> fetchMenu();
  List<MenuItem> get filteredItems;
}

// NotificationProvider
class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  int get unreadCount;
  void markAsRead(String id);
  void markAllRead();
}
```

### 6.5 Caching Strategy

| Data | Duration | Storage | Invalidation |
|------|----------|---------|-------------|
| Menu items | 30 minutes | SharedPreferences | Manual refresh or category change |
| Categories | 1 hour | SharedPreferences | Rare admin change |
| Auth token | Until refresh | flutter_secure_storage | Logout or 401 |
| Cart items | Persistent | Hive box | clearCart() or order placed |
| Order history | 5 minutes | Memory | New order or status change |
| Notifications | Real-time | Memory | WebSocket push |

---

## 7. Feature Specifications

### 7.1 Menu Browsing

- **Categories**: 7 tabs displayed in flex-wrap grid (2 rows), all visible without scrolling
- **Item Cards**: Color-coded gradient header with Material Icon, name, description, price (₹), veg/non-veg badge
- **Quick Add**: One-tap add to cart from the menu grid
- **Search**: Real-time filtering by item name

### 7.2 Pizza Customization

| Option | Values | Price Impact |
|--------|--------|-------------|
| **Size** | Small (7") · Medium (10") · Large (13") | +₹0 · +₹50 · +₹100 |
| **Crust** | Classic · Thin · Cheese Stuffed | +₹0 · +₹0 · +₹50 |
| **Toppings** | Extra Cheese · Mushrooms · Chicken · Jalapenos | ₹30–₹60 each |
| **Quantity** | 1-10 via stepper | × multiplier |
| **Instructions** | Free text (renamed "Cooking Instructions") | — |

### 7.3 Order Restrictions

- **Beverage-only orders blocked**: Must include at least 1 food item (non-beverage/dessert)
- Validation triggers at checkout with user-friendly message

### 7.4 Order Tracking

| Status | Display | Timer |
|--------|---------|-------|
| Placed | "Order Placed" | — |
| Confirmed | "Order Confirmed" | ~2 min after placement |
| Ready | "Ready for Pickup", "Ready for Dine-in", or "Out for Delivery" (based on order type) | ~15-20 min after confirmed |
| Delivered/Collected | "Collected", "Dine-in Confirmed", or "Delivered" via slide-to-accept | Customer action |

- **ETA**: 25–30 minutes displayed on tracking screen
- **Slide to Accept**: Customer drags slider — text adapts per type:
  - Pickup: "Slide to Collect ➜"
  - Dine-in: "Slide to Confirm Dine-in ➜"
  - Delivery: "Slide to Accept Delivery ➜"

### 7.5 Order Types

| Type | Icon | Label | Description | Tracking Status | Payment |
|------|------|-------|-------------|----------------|--------|
| **Dine-in** | 🍽️ | Dine-in | Customer eats at the store | "Ready for Dine-in" → "Dine-in Confirmed" | Cash at Store |
| **Self Pickup** | 🛍️ | Pickup | Customer collects and leaves | "Ready for Pickup" → "Collected" | Cash at Store |
| **Delivery** | 🚚 | Delivery | Order delivered to customer’s location | "Out for Delivery" → "Delivered" | UPI to Delivery Agent |

- Customer selects order type during checkout (3-column radio card UI)
- **Delivery address field is only shown when Delivery is selected** — hidden for Dine-in and Pickup
- WhatsApp notification includes order type
- Order type badge shown on tracking screen (teal for Pickup, orange for Dine-in, blue for Delivery)
- Payment label adapts: "Cash at Store" for dine-in/pickup, "UPI to Delivery Agent" for delivery

### 7.6 WhatsApp Notification

Auto-triggered on order placement. Uses `url_launcher` to open WhatsApp with pre-formatted message containing order ID, items, total, order type, and ETA.

### 7.7 Profile Features

- Edit name, phone number
- Saved delivery addresses (hostel/building names)
- Favorites list
- Order history quick access
- Help & FAQ section
- About Fresco's Kitchen

---

## 8. Backend API Integration

### 8.1 API Configuration

```dart
class ApiConfig {
  static const baseUrl = 'https://api.frescoskitchen.com/v1';
  static const wsUrl = 'wss://api.frescoskitchen.com/ws';
  static const timeout = Duration(seconds: 30);
}
```

### 8.2 Customer-Facing Endpoints

#### Authentication

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| `POST` | `/auth/send-otp` | Send OTP to phone | Public |
| `POST` | `/auth/verify-otp` | Verify → JWT pair | Public |
| `POST` | `/auth/refresh` | Refresh access token | Bearer |
| `POST` | `/auth/logout` | Invalidate tokens | Bearer |
| `GET` | `/auth/profile` | Get profile | Bearer |
| `PUT` | `/auth/profile` | Update profile | Bearer |

#### Menu

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| `GET` | `/menu/items` | List items (filtered) | Public |
| `GET` | `/menu/items/:id` | Item detail with options | Public |
| `GET` | `/menu/categories` | List categories | Public |

**Query Parameters**: `?category=pizza&search=margherita&is_veg=true&sort=price_asc&page=1&limit=20`

#### Orders

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| `POST` | `/orders` | Place new order | Bearer |
| `GET` | `/orders` | My order history | Bearer |
| `GET` | `/orders/:id` | Order detail | Bearer |
| `POST` | `/orders/:id/cancel` | Cancel order | Bearer |

**Request: Place Order**
```json
{
  "items": [{
    "menu_item_id": "pizza-1",
    "quantity": 2,
    "size": "medium",
    "crust": "thin",
    "toppings": ["extra-cheese", "mushrooms"],
    "special_instructions": "Extra crispy"
  }],
  "order_type": "pickup",
  "delivery_address": "Hostel A, Room 204",
  "payment_method": "cash_at_store",
  "promo_code": "PIZZABOGO"
}
```

> **Note:** `payment_method` is auto-determined by `order_type`:  
> - `pickup` / `dinein` → `"cash_at_store"`  
> - `delivery` → `"upi_to_agent"`
```

**Response: Order Created**
```json
{
  "id": "PIZ-20260301-0100",
  "status": "placed",
  "items": [...],
  "subtotal": 698.0,
  "delivery_charge": 30.0,
  "discount": 0.0,
  "total": 728.0,
  "estimated_ready_time": "2026-03-01T15:45:00Z",
  "created_at": "2026-03-01T15:20:00Z"
}
```

#### Promotions

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| `GET` | `/promotions` | Active promos | Public |
| `POST` | `/promotions/validate` | Validate/apply code | Bearer |

#### Delivery Addresses

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| `GET` | `/addresses` | My saved addresses | Bearer |
| `POST` | `/addresses` | Add address | Bearer |
| `PUT` | `/addresses/:id` | Update | Bearer |
| `DELETE` | `/addresses/:id` | Remove | Bearer |

### 8.3 Error Handling

```dart
class ApiException implements Exception {
  final int statusCode;
  final String code;     // 'VALIDATION_ERROR', 'UNAUTHORIZED', etc.
  final String message;
  final List<FieldError>? details;
}
```

| HTTP | Code | Action |
|------|------|--------|
| 401 | `UNAUTHORIZED` | Attempt token refresh → re-login |
| 403 | `FORBIDDEN` | Show access denied |
| 422 | `VALIDATION_ERROR` | Show field-level errors |
| 429 | `RATE_LIMITED` | Show retry message |

---

## 9. Database Schema

### 9.1 Customer-Facing Tables

```mermaid
erDiagram
    USERS ||--o{ ORDERS : places
    USERS ||--o{ DELIVERY_ADDRESSES : has
    USERS ||--o{ NOTIFICATIONS : receives
    MENU_CATEGORIES ||--o{ MENU_ITEMS : contains
    MENU_ITEMS ||--o{ ITEM_SIZE_OPTIONS : has
    MENU_ITEMS ||--o{ ITEM_TOPPING_OPTIONS : has
    ORDERS ||--o{ ORDER_ITEMS : contains
    ORDERS ||--o{ ORDER_STATUS_HISTORY : tracks
    ORDER_ITEMS ||--o{ ORDER_ITEM_CUSTOMIZATIONS : has

    USERS {
        uuid id PK
        varchar phone UK
        varchar name
        varchar email
        varchar avatar_url
        boolean is_active
        timestamp created_at
    }

    MENU_ITEMS {
        uuid id PK
        uuid category_id FK
        varchar name
        text description
        decimal price
        varchar image_url
        boolean is_veg
        boolean is_available
        decimal rating
        int rating_count
        text tags
        int prep_time_minutes
        boolean is_deleted
    }

    ITEM_SIZE_OPTIONS {
        uuid id PK
        uuid menu_item_id FK
        varchar label
        varchar size_code
        decimal price_addon
    }

    ITEM_TOPPING_OPTIONS {
        uuid id PK
        uuid menu_item_id FK
        varchar name
        decimal price
        boolean is_veg
        varchar category
    }

    ORDERS {
        uuid id PK
        varchar order_number UK
        uuid customer_id FK
        enum status
        enum order_type "pickup|dinein|delivery"
        enum payment_method "cash_at_store|upi_to_agent"
        varchar delivery_address
        decimal subtotal
        decimal delivery_charge
        decimal discount
        decimal total
        text special_instructions
        boolean is_paid
        timestamp estimated_ready_time
        timestamp created_at
        timestamp completed_at
    }

    ORDER_ITEMS {
        uuid id PK
        uuid order_id FK
        uuid menu_item_id FK
        varchar item_name
        decimal item_price
        int quantity
        varchar size_selected
        varchar crust_selected
        decimal line_total
    }

    ORDER_ITEM_CUSTOMIZATIONS {
        uuid id PK
        uuid order_item_id FK
        varchar type
        varchar name
        decimal price
    }

    DELIVERY_ADDRESSES {
        uuid id PK
        uuid user_id FK
        varchar label
        varchar building_name
        varchar floor_room
        boolean is_default
    }

    NOTIFICATIONS {
        uuid id PK
        uuid user_id FK
        varchar title
        text body
        enum type
        boolean is_read
        timestamp created_at
    }
```

---

## 10. Real-Time & Notifications

### 10.1 WebSocket Connection

```dart
class WebSocketService {
  late WebSocketChannel _channel;

  void connect(String token) {
    _channel = WebSocketChannel.connect(
      Uri.parse('${ApiConfig.wsUrl}?token=$token'),
    );
    _channel.stream.listen(_handleMessage);
  }

  void _handleMessage(dynamic data) {
    final event = json.decode(data);
    switch (event['type']) {
      case 'order:status_changed':
        // Update OrderProvider
      case 'notification:push':
        // Update NotificationProvider + show local notification
    }
  }
}
```

### 10.2 Events (Client Receives)

| Event | Payload | Action |
|-------|---------|--------|
| `order:status_changed` | `{order_id, status, timestamp}` | Update OrderProvider, show push |
| `order:ready` | `{order_id}` | Show "Ready for pickup!" alert |
| `notification:push` | `{title, body, type}` | Add to NotificationProvider |

### 10.3 Push Notifications (FCM)

| Trigger | Message |
|---------|---------|
| Order Confirmed | "Your order #PIZ-XXX is confirmed! ETA: 25 mins 🍕" |
| Order Ready | "Your order is ready for pickup! Visit Fresco's Kitchen" |
| Promotional | "BOGO on all pizzas this Saturday! Use code PIZZABOGO" |

### 10.4 WhatsApp Auto-Notification

Triggered on order placement via `whatsapp_helper.dart`:
```
🍕 Fresco's Kitchen Order Confirmed!
Order: #PIZ-20260301-0100
Items: 2x Margherita Pizza (Medium)
Total: ₹728
ETA: 25-30 mins
```

---

## 11. Security

### 11.1 Authentication Flow

```mermaid
graph LR
    PHONE["Phone + OTP<br/>(6-digit, 5-min TTL)"] -->|Verify| JWT["JWT Pair<br/>(Access: 1h, Refresh: 30d)"]
    JWT --> SECURE["flutter_secure_storage"]
    SECURE --> HEADER["Authorization: Bearer xxx"]
```

### 11.2 Security Measures

| Layer | Measure |
|-------|---------|
| **Token Storage** | `flutter_secure_storage` (Keychain/Keystore) |
| **Transport** | TLS 1.3 only |
| **OTP** | 3 attempts/10 min, 5-min expiry |
| **Input** | Client-side + server-side validation |
| **Data** | Only own orders/profile accessible |
| **Certificate Pinning** | Planned for production |

---

## 12. Performance & Deployment

### 12.1 Performance Targets

| Metric | Target |
|--------|--------|
| App cold start | < 2 seconds |
| Menu load | < 500ms (cached) |
| Image load | < 500ms (CDN) |
| Order placement | < 1 second |
| Push notification | < 3 seconds |

### 12.2 Optimization Strategies

- **Image caching**: `cached_network_image` with memory + disk cache
- **Lazy loading**: Menu items paginated, loaded on scroll
- **State preservation**: Cart persisted to Hive across app restarts
- **Skeleton screens**: Shimmer placeholders during data loading
- **Compression**: WebP images, gzip API responses

### 12.3 Deployment

| Platform | Store | Requirements |
|----------|-------|-------------|
| Android | Google Play Store | Min SDK 21, Target SDK 34 |
| iOS | Apple App Store | Min iOS 13.0 |
| Testing | Firebase App Distribution | Internal beta testing |

---

## 13. Implementation Roadmap

### Phase 1 — Backend + Auth (Week 1-2)

| Task | Priority |
|------|----------|
| Set up backend project | 🔴 Critical |
| Database schema + migrations | 🔴 Critical |
| Auth API (OTP + JWT) | 🔴 Critical |
| AuthProvider + Login/OTP screens connect | 🔴 Critical |

### Phase 2 — Menu + Cart (Week 3-4)

| Task | Priority |
|------|----------|
| Menu API with filters/search | 🔴 Critical |
| MenuProvider replacing mock_data.dart | 🔴 Critical |
| Extended CartItem with size/toppings | 🟡 High |
| Image upload + CDN for menu items | 🟡 High |

### Phase 3 — Orders + Real-time (Week 5-6)

| Task | Priority |
|------|----------|
| Order API with lifecycle | 🔴 Critical |
| WebSocket for status updates | 🔴 Critical |
| Replace _simulateOrderProgress with real events | 🔴 Critical |
| FCM push notifications | 🟡 High |
| WhatsApp Business API integration | 🟡 High |

### Phase 4 — Polish + Launch (Week 7-8)

| Task | Priority |
|------|----------|
| Profile API + addresses | 🟡 High |
| Promo code validation | 🟢 Medium |
| Performance optimization | 🟡 High |
| Security audit | 🔴 Critical |
| App Store / Play Store submission | 🔴 Critical |

---

> **Prototype Reference**: [prototype/index.html](../prototype/index.html) — Live at `http://localhost:8090`  
> **Flutter Source**: [lib/](../lib/) — 12 screens, 3 models, 2 providers  
> **Companion**: [Admin Portal System Design](./admin_portal_system_design.md)
