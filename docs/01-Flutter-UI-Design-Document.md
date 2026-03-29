# Campus Food Ordering System — Flutter UI Design Document

> **Version:** 1.0  
> **Date:** 2026-02-13  
> **Project:** Campus Food Ordering System — Consumer Mobile Application  
> **Platform:** Android & iOS (Flutter — Single Codebase)

---

## Table of Contents

1. [Overview](#1-overview)
2. [Design Goals & Principles](#2-design-goals--principles)
3. [Target Platforms & Device Matrix](#3-target-platforms--device-matrix)
4. [Architecture & Folder Structure](#4-architecture--folder-structure)
5. [State Management Strategy](#5-state-management-strategy)
6. [Navigation & Routing](#6-navigation--routing)
7. [Theming & Design System](#7-theming--design-system)
8. [Screen-by-Screen Specification](#8-screen-by-screen-specification)
9. [Reusable Widget Catalog](#9-reusable-widget-catalog)
10. [Notifications & Real-Time Updates](#10-notifications--real-time-updates)
11. [Offline & Error Handling Strategy](#11-offline--error-handling-strategy)
12. [Accessibility](#12-accessibility)
13. [Performance Optimization](#13-performance-optimization)
14. [Testing Strategy](#14-testing-strategy)
15. [Build, Release & CI/CD](#15-build-release--cicd)
16. [Dependencies & Packages](#16-dependencies--packages)
17. [Appendix — Wireframe Reference Map](#17-appendix--wireframe-reference-map)

---

## 1. Overview

The **Consumer Mobile Application** is a Flutter-based, cross-platform mobile app that allows campus users to:

- Browse the restaurant menu (organized by categories and time-based availability)
- Add items to a cart and checkout
- Choose between **self-pickup** and **staff-handled delivery**
- Pay via **UPI (online)** or **Cash on Pickup**
- Track order status in real time
- View order history
- Receive push notifications on order updates

The app communicates exclusively with a single centralized backend via RESTful APIs and WebSocket connections.

> **Scope Boundary:** The app is designed for a **single restaurant** operating within a **campus-only** environment. There is no GPS-based live tracking, no multi-restaurant support, and no campus-wallet integration.

---

## 2. Design Goals & Principles

| # | Principle | Description |
|---|-----------|-------------|
| 1 | **Simplicity First** | Minimal cognitive load — users should be able to place an order within 60 seconds of opening the app. |
| 2 | **Speed & Responsiveness** | Target < 2s cold start; < 500ms screen transitions; skeleton loading for all async content. |
| 3 | **Consistency** | Unified design tokens, spacing, typography, and color palette across all screens. |
| 4 | **Reliability** | Graceful degradation with offline banners, retry mechanisms, and cached fallbacks. |
| 5 | **Accessibility** | WCAG 2.1 AA compliance — proper semantics, contrast ratios, and screen-reader support. |
| 6 | **Scalability** | Clean architecture to support future expansion (multi-restaurant, wallet, etc.) |

---

## 3. Target Platforms & Device Matrix

| Platform | Min SDK / OS | Target |
|----------|-------------|--------|
| Android | API 24 (Android 7.0) | API 34 (Android 14) |
| iOS | iOS 14.0 | iOS 17.x |
| Flutter SDK | 3.22+ (stable) | Latest stable |
| Dart SDK | 3.4+ | Latest stable |

**Supported screen sizes:** 4.7" – 6.9" phones. Tablets are not a primary target but layouts should be responsive.

---

## 4. Architecture & Folder Structure

### 4.1 Architecture Pattern — **Clean Architecture + BLoC**

The app follows a layered Clean Architecture approach with clear separation of concerns:

```
┌─────────────────────────────────────────────┐
│              Presentation Layer             │
│   (Screens, Widgets, BLoCs / Cubits)        │
├─────────────────────────────────────────────┤
│               Domain Layer                  │
│   (Entities, Use Cases, Repository          │
│    Interfaces / Abstract Classes)           │
├─────────────────────────────────────────────┤
│                Data Layer                   │
│   (Repository Impls, Data Sources,          │
│    API Client, DTOs, Local Storage)         │
└─────────────────────────────────────────────┘
```

### 4.2 Folder Structure

```
lib/
├── main.dart                        # App entry point
├── app.dart                         # MaterialApp / GoRouter setup
├── injection_container.dart         # Dependency injection (get_it)
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   ├── app_spacing.dart
│   │   ├── app_assets.dart
│   │   └── api_endpoints.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── dark_theme.dart
│   ├── network/
│   │   ├── api_client.dart          # Dio-based HTTP client
│   │   ├── api_interceptors.dart
│   │   ├── network_info.dart
│   │   └── websocket_client.dart
│   ├── error/
│   │   ├── failures.dart
│   │   └── exceptions.dart
│   ├── utils/
│   │   ├── validators.dart
│   │   ├── formatters.dart
│   │   └── date_time_utils.dart
│   └── widgets/                     # Shared/global widgets
│       ├── app_button.dart
│       ├── app_text_field.dart
│       ├── loading_shimmer.dart
│       ├── error_view.dart
│       ├── empty_state.dart
│       ├── network_status_banner.dart
│       └── cached_image.dart
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── auth_remote_data_source.dart
│   │   │   ├── models/
│   │   │   │   └── user_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── usecases/
│   │   │       ├── request_otp.dart
│   │   │       ├── verify_otp.dart
│   │   │       └── logout.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── auth_bloc.dart
│   │       │   ├── auth_event.dart
│   │       │   └── auth_state.dart
│   │       └── screens/
│   │           ├── splash_screen.dart
│   │           ├── login_screen.dart
│   │           └── otp_verification_screen.dart
│   │
│   ├── menu/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── menu_remote_data_source.dart
│   │   │   │   └── menu_local_data_source.dart
│   │   │   ├── models/
│   │   │   │   ├── category_model.dart
│   │   │   │   └── menu_item_model.dart
│   │   │   └── repositories/
│   │   │       └── menu_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── category.dart
│   │   │   │   └── menu_item.dart
│   │   │   ├── repositories/
│   │   │   │   └── menu_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_categories.dart
│   │   │       ├── get_menu_items.dart
│   │   │       └── get_menu_by_time_slot.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── menu_bloc.dart
│   │       │   ├── menu_event.dart
│   │       │   └── menu_state.dart
│   │       ├── screens/
│   │       │   ├── home_screen.dart
│   │       │   └── menu_item_detail_screen.dart
│   │       └── widgets/
│   │           ├── category_tab_bar.dart
│   │           ├── menu_item_card.dart
│   │           ├── time_slot_selector.dart
│   │           └── menu_search_bar.dart
│   │
│   ├── cart/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── cart_item_model.dart
│   │   │   └── repositories/
│   │   │       └── cart_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── cart.dart
│   │   │   │   └── cart_item.dart
│   │   │   ├── repositories/
│   │   │   │   └── cart_repository.dart
│   │   │   └── usecases/
│   │   │       ├── add_to_cart.dart
│   │   │       ├── remove_from_cart.dart
│   │   │       ├── update_quantity.dart
│   │   │       └── clear_cart.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── cart_bloc.dart
│   │       │   ├── cart_event.dart
│   │       │   └── cart_state.dart
│   │       ├── screens/
│   │       │   └── cart_screen.dart
│   │       └── widgets/
│   │           ├── cart_item_tile.dart
│   │           ├── cart_summary.dart
│   │           └── quantity_selector.dart
│   │
│   ├── checkout/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── checkout_remote_data_source.dart
│   │   │   ├── models/
│   │   │   │   └── order_request_model.dart
│   │   │   └── repositories/
│   │   │       └── checkout_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── checkout_summary.dart
│   │   │   ├── repositories/
│   │   │   │   └── checkout_repository.dart
│   │   │   └── usecases/
│   │   │       ├── place_order.dart
│   │   │       └── initiate_payment.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── checkout_bloc.dart
│   │       │   ├── checkout_event.dart
│   │       │   └── checkout_state.dart
│   │       ├── screens/
│   │       │   ├── checkout_screen.dart
│   │       │   └── payment_screen.dart
│   │       └── widgets/
│   │           ├── delivery_option_selector.dart
│   │           ├── payment_method_selector.dart
│   │           └── order_summary_card.dart
│   │
│   ├── orders/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── order_remote_data_source.dart
│   │   │   │   └── order_websocket_data_source.dart
│   │   │   ├── models/
│   │   │   │   └── order_model.dart
│   │   │   └── repositories/
│   │   │       └── order_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── order.dart
│   │   │   ├── repositories/
│   │   │   │   └── order_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_order_status.dart
│   │   │       ├── get_order_history.dart
│   │   │       └── subscribe_order_updates.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── order_tracking_bloc.dart
│   │       │   ├── order_tracking_event.dart
│   │       │   ├── order_tracking_state.dart
│   │       │   ├── order_history_bloc.dart
│   │       │   ├── order_history_event.dart
│   │       │   └── order_history_state.dart
│   │       ├── screens/
│   │       │   ├── order_tracking_screen.dart
│   │       │   └── order_history_screen.dart
│   │       └── widgets/
│   │           ├── order_status_stepper.dart
│   │           ├── order_card.dart
│   │           └── order_detail_bottom_sheet.dart
│   │
│   ├── notifications/
│   │   ├── data/
│   │   │   └── services/
│   │   │       └── fcm_service.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── notification_bloc.dart
│   │       │   ├── notification_event.dart
│   │       │   └── notification_state.dart
│   │       └── screens/
│   │           └── notifications_screen.dart
│   │
│   └── profile/
│       ├── data/
│       │   ├── datasources/
│       │   │   └── profile_remote_data_source.dart
│       │   ├── models/
│       │   │   └── profile_model.dart
│       │   └── repositories/
│       │       └── profile_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── profile.dart
│       │   ├── repositories/
│       │   │   └── profile_repository.dart
│       │   └── usecases/
│       │       ├── get_profile.dart
│       │       └── update_profile.dart
│       └── presentation/
│           ├── bloc/
│           │   ├── profile_bloc.dart
│           │   ├── profile_event.dart
│           │   └── profile_state.dart
│           └── screens/
│               └── profile_screen.dart
│
├── l10n/                            # Localization (future)
│   └── app_en.arb
│
└── gen/                             # Generated code
    ├── assets.gen.dart
    └── colors.gen.dart
```

---

## 5. State Management Strategy

### 5.1 Primary: **flutter_bloc** (BLoC / Cubit)

| Concern | Approach |
|---------|----------|
| Feature-level state (auth, menu, cart, orders) | **BLoC** with events and states |
| Simple UI toggles (e.g., password visibility) | **Cubit** or `ValueNotifier` |
| Global state (auth token, connectivity) | **BLoC** provided at the app root via `MultiBlocProvider` |
| Cart state | **CartBloc** — survives across screens; persisted to local storage |

### 5.2 BLoC Conventions

- **Every BLoC** has a corresponding `_event.dart` and `_state.dart` file.
- States use **sealed classes** (Dart 3 pattern matching) for exhaustive handling:

```dart
sealed class MenuState {}
class MenuInitial extends MenuState {}
class MenuLoading extends MenuState {}
class MenuLoaded extends MenuState {
  final List<Category> categories;
  final List<MenuItem> items;
  MenuLoaded({required this.categories, required this.items});
}
class MenuError extends MenuState {
  final String message;
  MenuError(this.message);
}
```

- **BlocObserver** is registered globally for debug logging.
- **Hydrated BLoC** (via `hydrated_bloc` package) is used for `CartBloc` to persist cart data across app restarts.

### 5.3 Dependency Injection — `get_it` + `injectable`

All repositories, data sources, use cases, and BLoCs are registered in `injection_container.dart` using `get_it`. The `injectable` code-generator automates registration.

---

## 6. Navigation & Routing

### 6.1 Router: **GoRouter**

Declarative routing using `go_router` with `ShellRoute` for the bottom navigation shell.

### 6.2 Route Map

```
/                           → SplashScreen (redirect logic)
/login                      → LoginScreen
/otp                        → OTPVerificationScreen
/home                       → HomeScreen (ShellRoute — BottomNav)
  /home/menu                → MenuTab (default tab)
  /home/orders              → OrderHistoryTab
  /home/notifications       → NotificationsTab
  /home/profile             → ProfileTab
/menu/:itemId               → MenuItemDetailScreen
/cart                       → CartScreen
/checkout                   → CheckoutScreen
/payment                    → PaymentScreen (UPI flow)
/order/:orderId/tracking    → OrderTrackingScreen
```

### 6.3 Route Guards

| Guard | Logic |
|-------|-------|
| **AuthGuard** | If no valid token in secure storage → redirect to `/login` |
| **CheckoutGuard** | If cart is empty → redirect to `/home/menu` |

### 6.4 Deep Linking

Push notification payloads include an `orderId`. Tapping a notification navigates to `/order/:orderId/tracking`.

---

## 7. Theming & Design System

### 7.1 Color Palette

| Token | Light Mode | Dark Mode | Usage |
|-------|-----------|-----------|-------|
| `primary` | `#FF6B35` (Warm Orange) | `#FF8A5C` | Primary actions, CTA buttons, active tabs |
| `primaryVariant` | `#E55A2B` | `#FF6B35` | Pressed/focused state |
| `secondary` | `#2EC4B6` (Teal) | `#3DD5C7` | Secondary accents, success states |
| `surface` | `#FFFFFF` | `#1E1E2E` | Card backgrounds, bottom sheets |
| `background` | `#F5F5F7` | `#121218` | Screen background |
| `error` | `#E53935` | `#FF6B6B` | Error states, destructive actions |
| `onPrimary` | `#FFFFFF` | `#FFFFFF` | Text on primary color |
| `onSurface` | `#1A1A2E` | `#E8E8F0` | Primary text |
| `onSurfaceVariant` | `#6B6B80` | `#9898A8` | Secondary/caption text |
| `divider` | `#E8E8F0` | `#2A2A3A` | Dividers, borders |

### 7.2 Typography

Font Family: **Inter** (via `google_fonts` package)

| Style | Size | Weight | Line Height | Usage |
|-------|------|--------|-------------|-------|
| `headlineLarge` | 28sp | Bold (700) | 1.3 | Screen titles |
| `headlineMedium` | 22sp | SemiBold (600) | 1.3 | Section headers |
| `titleLarge` | 18sp | SemiBold (600) | 1.4 | Card titles |
| `titleMedium` | 16sp | Medium (500) | 1.4 | Subtitles |
| `bodyLarge` | 16sp | Regular (400) | 1.5 | Body text |
| `bodyMedium` | 14sp | Regular (400) | 1.5 | Default text |
| `bodySmall` | 12sp | Regular (400) | 1.4 | Captions, timestamps |
| `labelLarge` | 14sp | SemiBold (600) | 1.2 | Button labels |

### 7.3 Spacing Scale

Base unit: **4dp**

```
xs:  4dp   |  sm:  8dp   |  md: 12dp  |  lg: 16dp
xl: 24dp   |  2xl: 32dp  |  3xl: 48dp |  4xl: 64dp
```

### 7.4 Border Radius

```
sm:  8dp  (chips, small cards)
md: 12dp  (standard cards, inputs)
lg: 16dp  (bottom sheets, modals)
xl: 24dp  (floating buttons, pills)
full: 999dp (circular avatars)
```

### 7.5 Elevation & Shadows

Material 3 elevation system:
- **Level 0:** Flat (inline elements)
- **Level 1:** 1dp (cards, tiles)
- **Level 2:** 3dp (raised buttons, app bar)
- **Level 3:** 6dp (floating elements, FAB)
- **Level 4:** 8dp (modal bottom sheets, dialogs)

### 7.6 Iconography

Primary icon set: **Material Symbols Rounded** (via built-in Flutter `Icons` with rounded variants). For custom food-related icons use **Phosphor Icons** (`phosphor_flutter` package).

---

## 8. Screen-by-Screen Specification

### 8.1 Splash Screen

| Attribute | Detail |
|-----------|--------|
| **Route** | `/` |
| **Duration** | 1.5s (min) — 3s (max with token check) |
| **Purpose** | Brand display + silent auth token validation |
| **Flow** | • Check `flutter_secure_storage` for valid JWT → `/home` <br>• No token or expired → `/login` |
| **UI Elements** | App logo (centered, scaled animation), brand name, linear progress indicator at bottom |
| **Animation** | Logo fade-in + scale (0.8 → 1.0) over 800ms with `CurvedAnimation(Curves.easeOutBack)` |

### 8.2 Login Screen

| Attribute | Detail |
|-----------|--------|
| **Route** | `/login` |
| **Purpose** | Collect user's mobile number and request OTP |
| **UI Elements** | • Illustration/hero image (top 40% of screen) <br>• "Welcome" heading <br>• "Enter your mobile number" subtext <br>• Phone number input (with country code `+91` prefix — fixed) <br>• "Send OTP" primary button <br>• Terms & conditions footer link |
| **Validation** | 10-digit Indian mobile number; real-time validation with error display |
| **Loading State** | Button shows circular progress indicator; input becomes read-only |
| **Error State** | Snackbar for API errors (rate limit, server error) |

### 8.3 OTP Verification Screen

| Attribute | Detail |
|-----------|--------|
| **Route** | `/otp` |
| **Parameters** | `phoneNumber` (passed from Login) |
| **UI Elements** | • Back button <br>• "Verify your number" heading <br>• "OTP sent to +91-XXXXXXXX" subtext <br>• 6-digit OTP input (individual boxes, auto-advance) <br>• "Verify" primary button <br>• "Resend OTP" text button (disabled for 30s with countdown timer) |
| **Auto-submit** | Triggers verification automatically when all 6 digits are entered |
| **SMS Autofill** | Uses `sms_autofill` package for automatic OTP detection on Android |
| **Error State** | Shake animation on input boxes + "Invalid OTP" error text |

### 8.4 Home Screen (Shell with Bottom Navigation)

| Attribute | Detail |
|-----------|--------|
| **Route** | `/home` |
| **Navigation** | Bottom Navigation Bar with 4 tabs: <br>• 🍕 **Menu** (`/home/menu`) — Default <br>• 📋 **Orders** (`/home/orders`) <br>• 🔔 **Notifications** (`/home/notifications`) — Badge for unread count <br>• 👤 **Profile** (`/home/profile`) |
| **Persistence** | Each tab preserves its scroll position & state via `AutomaticKeepAliveClientMixin` |

### 8.5 Menu Tab (Home Default)

| Attribute | Detail |
|-----------|--------|
| **Route** | `/home/menu` |
| **AppBar** | • "Good [Morning/Afternoon/Evening], {Name}" greeting <br>• Cart icon button (with badge count) → navigates to `/cart` |
| **Time-Slot Selector** | Horizontal chips: `Breakfast`, `Lunch`, `Dinner` — auto-selects based on current time. Each chip filters menu items by time-slot availability |
| **Category Tabs** | Horizontally scrollable tab bar below the time-slot selector. Categories fetched from API (e.g., "Starters", "Main Course", "Beverages", "Desserts") |
| **Menu Grid/List** | • Default: **List view** with toggle to **Grid view** <br>• Each card shows: item image, name, short description, price, veg/non-veg indicator, "Add" button <br>• Disabled overlay for unavailable items with "Available at [time]" label |
| **Search** | Expandable search bar in the app bar. Filters items by name in real-time (debounced 300ms) |
| **Loading** | Shimmer placeholders matching card layout |
| **Empty State** | "No items available for [time slot]" illustration |
| **Pull to Refresh** | `RefreshIndicator` to re-fetch menu data |

### 8.6 Menu Item Detail Screen

| Attribute | Detail |
|-----------|--------|
| **Route** | `/menu/:itemId` |
| **UI Elements** | • Hero image (top) with back button overlay <br>• Item name, price, veg/non-veg badge <br>• Full description <br>• Customization options (if any — future scope) <br>• Quantity selector (± stepper, min=1) <br>• "Add to Cart — ₹{total}" sticky bottom button |
| **Animation** | `Hero` animation from menu card image to detail image |

### 8.7 Cart Screen

| Attribute | Detail |
|-----------|--------|
| **Route** | `/cart` |
| **AppBar** | "Your Cart" title + "Clear All" text button |
| **Cart Items** | List of `CartItemTile` widgets: <br>• Item image (small thumbnail) <br>• Item name and unit price <br>• Quantity selector (±) with swipe-to-delete (Dismissible) <br>• Line total |
| **Cart Summary** (sticky bottom) | • Subtotal <br>• Delivery charge (if applicable, else "Free") <br>• **Grand Total** (bold) <br>• "Proceed to Checkout — ₹{total}" primary button |
| **Empty State** | "Your cart is empty" illustration + "Browse Menu" button → `/home/menu` |
| **Animations** | • Item removal: `AnimatedList` slide-out <br>• Total update: counting animation |

### 8.8 Checkout Screen

| Attribute | Detail |
|-----------|--------|
| **Route** | `/checkout` |
| **Sections** | 1. **Delivery Option** — Radio selection: "Self Pickup" / "Delivery" (if delivery is enabled by admin). Delivery shows address/location input <br>2. **Payment Method** — Radio selection: "UPI Payment" / "Cash on Pickup" (options controlled by admin config) <br>3. **Order Summary** — Collapsed card showing items count + total (expandable to see full item list) <br>4. **Special Instructions** — Optional text field (max 200 chars) |
| **"Place Order" button** | Sticky bottom. Validates all selections. Shows confirmation dialog before placing |
| **Confirmation Dialog** | "Confirm your order?" with order summary, total, and delivery/pickup choice. "Confirm" / "Cancel" buttons |

### 8.9 Payment Screen (UPI Flow)

| Attribute | Detail |
|-----------|--------|
| **Route** | `/payment` |
| **Flow** | 1. Display order total and payment breakdown <br>2. Launch UPI intent via payment gateway SDK <br>3. Show "Processing payment..." state with animated loader <br>4. On success → navigate to `/order/:orderId/tracking` with success animation <br>5. On failure → show retry option + "Pay with Cash" fallback |
| **Timeout** | 5-minute payment timeout with countdown. On timeout → order held for 2 min before cancellation |

### 8.10 Order Tracking Screen

| Attribute | Detail |
|-----------|--------|
| **Route** | `/order/:orderId/tracking` |
| **UI Elements** | • **Order ID** and timestamp <br>• **Status Stepper** (vertical): <br>&nbsp;&nbsp;1. ✅ Order Received <br>&nbsp;&nbsp;2. 🔄 Preparing <br>&nbsp;&nbsp;3. ✅ Ready <br>&nbsp;&nbsp;4. 🚚 Out for Delivery (only if delivery was selected) <br>&nbsp;&nbsp;5. ✅ Completed <br>• **Estimated Time** — e.g., "Ready in ~15 mins" (provided by backend) <br>• **Order Details** — expandable card with item list <br>• **Contact Kitchen** — call/message button |
| **Real-Time Updates** | WebSocket subscription for live status changes. Status stepper animates to next step on update |
| **Notification** | Local notification + sound when order moves to "Ready" |

### 8.11 Order History Screen

| Attribute | Detail |
|-----------|--------|
| **Route** | `/home/orders` |
| **UI Elements** | • Paginated list of past orders (newest first) <br>• Each card shows: Order ID, date, item count, total, final status badge <br>• Tap → `OrderDetailBottomSheet` with full order breakdown <br>• **"Reorder"** button on each completed order → adds same items to cart |
| **Pagination** | Infinite scroll with `ScrollController` listener. 20 orders per page |
| **Empty State** | "No orders yet" illustration + "Order Now" button |

### 8.12 Notifications Screen

| Attribute | Detail |
|-----------|--------|
| **Route** | `/home/notifications` |
| **UI Elements** | • List of notification cards grouped by date <br>• Each card: icon, title, body, timestamp, read/unread indicator <br>• Swipe to mark as read / delete |
| **Types** | Order updates, promotional messages (future), system alerts |

### 8.13 Profile Screen

| Attribute | Detail |
|-----------|--------|
| **Route** | `/home/profile` |
| **UI Elements** | • User avatar (initials-based), name, phone number <br>• **Edit Profile** → Name editing <br>• **My Addresses** (if delivery enabled) <br>• **About** → App version, terms, privacy policy <br>• **Logout** button with confirmation dialog |

---

## 9. Reusable Widget Catalog

| Widget | Description | Used In |
|--------|-------------|---------|
| `AppButton` | Primary/secondary/outline/text button with loading state | All screens |
| `AppTextField` | Styled text input with label, hint, error, prefix/suffix | Login, Checkout, Profile |
| `LoadingShimmer` | Skeleton loader matching target widget dimensions | Menu, Orders, Notifications |
| `ErrorView` | Error illustration + message + retry button | All data-fetching screens |
| `EmptyState` | Illustration + message + optional CTA button | Cart, Orders, Notifications |
| `NetworkStatusBanner` | Sticky top banner for offline/reconnecting states | App-wide (via overlay) |
| `CachedImage` | `cached_network_image` wrapper with placeholder and error widget | Menu cards, details |
| `QuantitySelector` | `−` / count / `+` stepper widget | Menu detail, Cart |
| `PriceText` | Formatted price display with rupee symbol (`₹`) | Menu, Cart, Checkout |
| `VegNonVegBadge` | Green/red circle indicator for veg/non-veg | Menu cards, details |
| `StatusBadge` | Colored pill badge for order statuses | Orders, Tracking |
| `TimeSlotChip` | Selectable chip representing breakfast/lunch/dinner | Menu screen |
| `CartBadge` | Animated dot/count badge overlay on cart icon | AppBar |
| `OTPInputField` | Row of individual digit input boxes | OTP Screen |
| `OrderStatusStepper` | Vertical stepper showing order progress stages | Order Tracking |
| `ConfirmationDialog` | Styled AlertDialog with title, body, confirm/cancel buttons | Checkout, Logout |

---

## 10. Notifications & Real-Time Updates

### 10.1 Push Notifications — Firebase Cloud Messaging (FCM)

| Aspect | Detail |
|--------|--------|
| **Service** | Firebase Cloud Messaging |
| **Package** | `firebase_messaging`, `flutter_local_notifications` |
| **Registration** | FCM token obtained on login; sent to backend via `POST /api/v1/users/device-token` |
| **Token Refresh** | Listened via `FirebaseMessaging.instance.onTokenRefresh` → updates backend |
| **Foreground** | Displayed as local notification banner (via `flutter_local_notifications`) |
| **Background/Terminated** | Handled by FCM's native handler; tap opens relevant screen via deep link |

### 10.2 Real-Time Order Updates — WebSocket

| Aspect | Detail |
|--------|--------|
| **Protocol** | WebSocket (via `web_socket_channel` package) |
| **Connection** | Established when user navigates to Order Tracking screen |
| **Channel** | `ws://{host}/ws/orders/{orderId}` |
| **Events Received** | `order_status_changed`, `estimated_time_updated` |
| **Reconnection** | Exponential backoff (1s, 2s, 4s, 8s… max 30s) with max 10 retries |
| **Fallback** | If WebSocket fails, fall back to polling every 15 seconds |

---

## 11. Offline & Error Handling Strategy

### 11.1 Network Connectivity

- **Package:** `connectivity_plus` + `internet_connection_checker_plus`
- **Behavior:**
  - Global `ConnectivityBloc` monitors network state
  - `NetworkStatusBanner` widget overlays top of screen when offline
  - All API calls wrapped in `try-catch` with `Failure` object propagation

### 11.2 Offline Capabilities

| Feature | Offline Behavior |
|---------|------------------|
| Menu browsing | Show cached menu data (Hive local storage). Display "Last updated X ago" |
| Cart | Fully functional offline (persisted in Hive) |
| Place order | Blocked — show "You're offline" dialog |
| Order tracking | Show last known status. Disable real-time updates |
| Login/OTP | Blocked — requires network |

### 11.3 Error Handling Patterns

```dart
// All API failures return Either<Failure, T> via dartz package
abstract class Failure {
  final String message;
  final int? statusCode;
}

class ServerFailure extends Failure { ... }
class NetworkFailure extends Failure { ... }
class CacheFailure extends Failure { ... }
class AuthFailure extends Failure { ... }     // 401 → redirect to login
class ValidationFailure extends Failure { ... }
```

### 11.4 Retry Logic

- **API calls:** Automatic retry x3 for `5xx` errors and timeouts (via Dio interceptor with exponential backoff)
- **Manual retry:** `ErrorView` widget provides a "Retry" button that re-emits the last BLoC event

---

## 12. Accessibility

| Requirement | Implementation |
|-------------|----------------|
| **Semantic Labels** | All `Image`, `Icon`, and interactive widgets have `semanticLabel` / `Semantics` wrapper |
| **Focus Order** | Logical focus traversal via `FocusTraversalGroup` |
| **Contrast** | Minimum 4.5:1 contrast ratio for text (AA) |
| **Touch Targets** | Minimum 48x48dp for all tappable elements |
| **Font Scaling** | Text respects system font size settings (tested up to 1.5x) |
| **Screen Reader** | Tested with TalkBack (Android) and VoiceOver (iOS) |
| **Motion** | Respect `MediaQuery.disableAnimations` to reduce motion for users who prefer reduced motion |

---

## 13. Performance Optimization

| Area | Technique |
|------|-----------|
| **Images** | `cached_network_image` with in-memory + disk cache. Serve WebP format. Lazy loading in lists |
| **Lists** | `ListView.builder` / `SliverList` for all dynamic lists. Never `ListView(children: [...])` for long lists |
| **Build optimization** | `const` constructors everywhere possible. `RepaintBoundary` around complex widgets |
| **Memory** | Dispose BLoCs, StreamSubscriptions, AnimationControllers in `dispose()` |
| **Cold Start** | Defer non-critical initialization. Lazy-load feature modules |
| **Bundle Size** | Tree-shaking enabled. Use `--split-debug-info` and `--obfuscate` for release builds |
| **API Calls** | Debounce search (300ms). Throttle refresh actions (1 per 5s) |
| **Profiling** | Regular profiling with Flutter DevTools. Monitor jank via `SchedulerBinding.addTimingsCallback` |

---

## 14. Testing Strategy

### 14.1 Test Pyramid

```
           ╱  E2E Tests (integration_test)  ╲        ~10%
          ╱     Widget Tests (flutter_test)    ╲      ~30%
         ╱        Unit Tests (test/)              ╲   ~60%
```

### 14.2 Test Coverage Targets

| Layer | Target | Tools |
|-------|--------|-------|
| **Unit Tests** | ≥ 80% | `test`, `mockito`, `bloc_test` |
| **Widget Tests** | ≥ 60% | `flutter_test`, `golden_toolkit` |
| **Integration Tests** | Core flows | `integration_test`, `patrol` |

### 14.3 Key Test Scenarios

| Feature | Test Cases |
|---------|------------|
| **Auth** | OTP request, verify success/failure, token storage, logout |
| **Menu** | Category filtering, time-slot filtering, search, unavailable items |
| **Cart** | Add/remove/update items, quantity limits, persistence, clear |
| **Checkout** | Delivery option toggle, payment method selection, validation |
| **Orders** | Status stepper progression, WebSocket message parsing, history pagination |

### 14.4 Golden Tests

Visual regression tests for critical widgets (menu card, cart item, order stepper) using `golden_toolkit`.

---

## 15. Build, Release & CI/CD

### 15.1 Flavors / Environments

| Flavor | API Base URL | Description |
|--------|-------------|-------------|
| `dev` | `http://10.0.2.2:8000/api/v1` | Local development |
| `staging` | `https://staging-api.campus-food.example.com/api/v1` | Staging server |
| `prod` | `https://api.campus-food.example.com/api/v1` | Production server |

Managed via `--dart-define` flags:

```bash
flutter run --dart-define=FLAVOR=dev
flutter build apk --dart-define=FLAVOR=prod
```

### 15.2 Build Configurations

| Build Type | Obfuscated | Split Debug Info | Proguard/R8 |
|------------|-----------|-----------------|-------------|
| Debug | ✗ | ✗ | ✗ |
| Profile | ✗ | ✗ | ✗ |
| Release | ✓ | ✓ | ✓ (Android) |

### 15.3 CI/CD Pipeline (GitHub Actions)

```
Push/PR → Analyze → Test → Build APK/IPA → Upload Artifact
                                              │
                                    (on main branch merge)
                                              │
                                    Deploy to Play Store (internal track)
```

---

## 16. Dependencies & Packages

### 16.1 Core Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_bloc` | ^8.x | State management |
| `hydrated_bloc` | ^9.x | Persistent BLoC state (Cart) |
| `go_router` | ^14.x | Declarative routing |
| `get_it` | ^7.x | Service locator / DI |
| `injectable` | ^2.x | DI code generation |
| `dio` | ^5.x | HTTP client |
| `dartz` | ^0.10.x | Functional programming (Either type) |
| `equatable` | ^2.x | Value equality for states/entities |

### 16.2 UI & UX

| Package | Purpose |
|---------|---------|
| `google_fonts` | Typography (Inter) |
| `cached_network_image` | Image caching |
| `shimmer` | Skeleton loading |
| `lottie` | Animated illustrations (empty states, success, loading) |
| `flutter_animate` | Declarative animations |
| `phosphor_flutter` | Extended icon set |

### 16.3 Firebase & Messaging

| Package | Purpose |
|---------|---------|
| `firebase_core` | Firebase initialization |
| `firebase_messaging` | Push notifications (FCM) |
| `flutter_local_notifications` | Foreground notification display |

### 16.4 Storage & Network

| Package | Purpose |
|---------|---------|
| `flutter_secure_storage` | Secure token storage |
| `hive_flutter` | Local data persistence (menu cache, cart) |
| `web_socket_channel` | WebSocket for real-time updates |
| `connectivity_plus` | Network state monitoring |

### 16.5 Payment

| Package | Purpose |
|---------|---------|
| `razorpay_flutter` or `paytm` | UPI payment gateway SDK (TBD based on vendor selection) |

### 16.6 Dev Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_test` | Widget testing |
| `bloc_test` | BLoC testing |
| `mockito` | Mocking |
| `build_runner` | Code generation runner |
| `injectable_generator` | DI code gen |
| `hive_generator` | Hive type adapter gen |
| `flutter_lints` | Lint rules |
| `golden_toolkit` | Visual regression |

---

## 17. Appendix — Wireframe Reference Map

Below is a conceptual wireframe flow showing the user journey through the app:

```
┌──────────┐    ┌──────────┐    ┌──────────┐
│  Splash  │───→│  Login   │───→│   OTP    │
│  Screen  │    │  Screen  │    │  Verify  │
└──────────┘    └──────────┘    └────┬─────┘
                                     │
                                     ▼
                            ┌────────────────┐
                            │   Home Shell   │
                            │ (Bottom Nav)   │
                            ├────┬───┬───┬───┤
                            │Menu│Ord│Not│Pro│
                            │Tab │ers│ify│file│
                            └─┬──┴─┬─┴───┴───┘
                              │    │
                    ┌─────────┘    └─────────┐
                    ▼                        ▼
            ┌──────────────┐        ┌──────────────┐
            │ Menu Item    │        │Order History  │
            │ Detail       │        │              │
            └──────┬───────┘        └──────┬───────┘
                   │                       │
                   ▼                       ▼
            ┌──────────────┐        ┌──────────────┐
            │    Cart      │        │Order Detail  │
            │              │        │Bottom Sheet  │
            └──────┬───────┘        └──────────────┘
                   │
                   ▼
            ┌──────────────┐
            │  Checkout    │
            │              │
            └──────┬───────┘
                   │
            ┌──────┴──────┐
            ▼             ▼
     ┌───────────┐ ┌───────────┐
     │  UPI Pay  │ │  Cash on  │
     │  Screen   │ │  Pickup   │
     └─────┬─────┘ └─────┬─────┘
           │              │
           └──────┬───────┘
                  ▼
           ┌──────────────┐
           │   Order      │
           │  Tracking    │
           │  (Live)      │
           └──────────────┘
```

---

> **Document End**  
> **Next:** [02-Backend-API-Design-Document.md](./02-Backend-API-Design-Document.md)
