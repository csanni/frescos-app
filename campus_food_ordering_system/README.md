# Fresco's Pizza - Campus Food Ordering System

A comprehensive food ordering solution featuring a Flutter mobile application and an interactive HTML/JS prototype.

## 📱 Flutter Application

The main application built with Flutter, designed for Android, iOS, and Web.

### Prerequisites

*   [Flutter SDK](https://docs.flutter.dev/get-started/install) installed and configured.
*   An Android Emulator, iOS Simulator, or a physical device connected.

### Setup & Installation

1.  **Navigate to the project directory:**
    ```bash
    cd campus_food_ordering_system
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

### Running the App

**For Mobile (Android/iOS):**
1.  Ensure your device or emulator is running (`flutter devices` to check).
2.  Run the app:
    ```bash
    flutter run
    ```

**For Web:**
```bash
flutter run -d chrome
```

---

## 🎨 Interactive Prototype (HTML/JS)

A rapid prototype built with standard HTML, CSS, and JavaScript to visualize features like Profile, Order Tracking, and Checkout.

### How to Run

1.  **Navigate to the prototype directory:**
    ```bash
    cd prototype
    ```

2.  **Start a local server:**
    You need a local web server to run the prototype correctly. You can use Python's built-in server:
    
    ```bash
    # For Python 3
    python3 -m http.server 8090
    
    # Or for Python 2
    python -m SimpleHTTPServer 8090
    ```

3.  **Open in Browser:**
    Go to [http://localhost:8090](http://localhost:8090) in your web browser.

### Key Features in Prototype
*   **Authentication Flow**: Login and OTP simulation.
*   **Ordering**: Menu browsing, Cart management, and Checkout.
*   **Order Tracking**: Real-time status updates with a "Back to Home" navigation.
*   **Profile**: User profile with logout functionality.
*   **COD Support**: Cash on Delivery payment option with detailed confirmation.
