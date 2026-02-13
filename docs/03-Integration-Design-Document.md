# Campus Food Ordering System — Integration Design Document

> **Version:** 1.0 | **Date:** 2026-02-13  
> **Scope:** Communication flow between Flutter Consumer App, Kitchen Web Portal, and Backend

---

## Table of Contents

1. [Overview](#1-overview)
2. [System Integration Map](#2-system-integration-map)
3. [Communication Protocols](#3-communication-protocols)
4. [Authentication Flow](#4-authentication-flow)
5. [Core User Journeys — End-to-End](#5-core-user-journeys--end-to-end)
6. [API Client Contract](#6-api-client-contract)
7. [Real-Time Communication](#7-real-time-communication)
8. [Payment Integration Flow](#8-payment-integration-flow)
9. [Push Notification Flow](#9-push-notification-flow)
10. [Data Synchronization](#10-data-synchronization)
11. [Error Handling Across Layers](#11-error-handling-across-layers)
12. [Environment Configuration](#12-environment-configuration)
13. [Testing the Integration](#13-testing-the-integration)
14. [Sequence Diagrams](#14-sequence-diagrams)

---

## 1. Overview

This document defines **how** the three system components communicate:

| Component | Technology | Role |
|-----------|-----------|------|
| **Consumer App** | Flutter (Android/iOS) | End-user interface for ordering |
| **Kitchen Web Portal** | React SPA | Kitchen operations + admin dashboard |
| **Backend API** | FastAPI (Python) | Centralized business logic, data, services |

**Integration Principles:**
- All communication flows through the **Backend API** — frontend components never talk to each other directly
- REST for CRUD; WebSocket/SSE for real-time
- JWT-based auth on every protected request
- Consistent error contract across all endpoints
- Idempotent order placement to prevent duplicates

---

## 2. System Integration Map

```
┌─────────────────────────────────────────────────────────────────────┐
│                        EXTERNAL SERVICES                           │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐       │
│  │ Twilio/  │   │ Razorpay │   │ Firebase │   │  AWS S3  │       │
│  │ MSG91    │   │ (UPI)    │   │  (FCM)   │   │ (Images) │       │
│  └────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬─────┘       │
│       │              │              │              │               │
└───────┼──────────────┼──────────────┼──────────────┼───────────────┘
        │              │              │              │
        ▼              ▼              ▼              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       BACKEND API (FastAPI)                         │
│                                                                     │
│  ┌───────────┐  ┌───────────┐  ┌──────────┐  ┌──────────────┐     │
│  │ REST API  │  │ WebSocket │  │   SSE    │  │ Celery       │     │
│  │ /api/v1/* │  │ /ws/*     │  │ /stream  │  │ (Async Jobs) │     │
│  └─────┬─────┘  └─────┬─────┘  └────┬─────┘  └──────────────┘     │
│        │              │              │                               │
│  ┌─────┴──────────────┴──────────────┴───────┐                     │
│  │         PostgreSQL  +  Redis              │                     │
│  └───────────────────────────────────────────┘                     │
└────────────────────┬────────────────────┬───────────────────────────┘
                     │                    │
          ┌──────────┴─────┐    ┌─────────┴──────────┐
          ▼                ▼    ▼                     ▼
   ┌──────────────┐   ┌──────────────────────┐
   │ Flutter App  │   │ Kitchen Web Portal   │
   │ (Consumer)   │   │ (Admin + Kitchen)    │
   │              │   │                      │
   │ • REST       │   │ • REST               │
   │ • WebSocket  │   │ • SSE                │
   │ • FCM Push   │   │ • (No push needed)   │
   └──────────────┘   └──────────────────────┘
```

---

## 3. Communication Protocols

### 3.1 Protocol Matrix

| From → To | Protocol | Auth | Format | Use Case |
|-----------|----------|------|--------|----------|
| Flutter → Backend | HTTPS REST | JWT Bearer | JSON | All CRUD operations |
| Flutter → Backend | WSS | JWT (query param) | JSON | Order status tracking |
| Flutter → Razorpay | Native SDK | API Key | SDK-managed | Payment processing |
| Flutter ← FCM | Push | FCM Token | Notification payload | Order update alerts |
| Portal → Backend | HTTPS REST | JWT Bearer | JSON | Order/menu/config mgmt |
| Portal ← Backend | SSE | JWT (query param) | JSON stream | Live order feed |
| Backend → Twilio | HTTPS | API Key | JSON | Send OTP SMS |
| Backend → Razorpay | HTTPS | API Key+Secret | JSON | Create/verify payment |
| Backend → FCM | HTTPS | Service Account | JSON | Push notification dispatch |
| Backend → S3 | HTTPS | IAM Credentials | Binary | Image upload/retrieval |

### 3.2 Request/Response Standards

**Request Headers (all REST calls):**
```
Content-Type: application/json
Authorization: Bearer <access_token>
X-Request-ID: <uuid>          # Client-generated, for tracing
X-App-Version: 1.0.0          # Flutter app version
X-Platform: android|ios       # Client platform
```

**Response Headers:**
```
Content-Type: application/json
X-Request-ID: <echo-back>     # Same as request
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1708329600
```

**Standard Success Response:**
```json
{
  "data": { ... },
  "meta": {
    "page": 1,
    "per_page": 20,
    "total": 45
  }
}
```

**Standard Error Response:**
```json
{
  "error": {
    "code": "ITEM_UNAVAILABLE",
    "message": "One or more items are no longer available",
    "details": [
      { "menu_item_id": "uuid-1", "reason": "out_of_stock" }
    ]
  }
}
```

---

## 4. Authentication Flow

### 4.1 Consumer App — OTP Login (Complete Flow)

```
┌──────────┐         ┌──────────┐         ┌──────────┐         ┌──────────┐
│  Flutter  │         │ Backend  │         │  Redis   │         │  Twilio  │
│   App     │         │  API     │         │          │         │          │
└────┬──────┘         └────┬─────┘         └────┬─────┘         └────┬─────┘
     │                     │                    │                     │
     │ POST /auth/request-otp                   │                     │
     │ { phone: "+91..." } │                    │                     │
     │────────────────────→│                    │                     │
     │                     │                    │                     │
     │                     │ SET otp:+91... = 123456 (TTL 300s)      │
     │                     │───────────────────→│                     │
     │                     │                    │                     │
     │                     │ Celery task: send_sms(phone, otp)       │
     │                     │─────────────────────────────────────────→│
     │                     │                    │                     │
     │ 200 { expires: 300 }│                    │                     │
     │←────────────────────│                    │                     │
     │                     │                    │                     │
     │ POST /auth/verify-otp                    │                     │
     │ { phone, otp }      │                    │                     │
     │────────────────────→│                    │                     │
     │                     │ GET otp:+91...     │                     │
     │                     │───────────────────→│                     │
     │                     │ "123456" (match!)  │                     │
     │                     │←───────────────────│                     │
     │                     │                    │                     │
     │                     │ DEL otp:+91...     │                     │
     │                     │───────────────────→│                     │
     │                     │                    │                     │
     │                     │ Find/Create user in PostgreSQL           │
     │                     │ Generate access_token (1hr) + refresh_token (30d)
     │                     │ Store refresh token in Redis             │
     │                     │───────────────────→│                     │
     │                     │                    │                     │
     │ 200 { tokens, user }│                    │                     │
     │←────────────────────│                    │                     │
     │                     │                    │                     │
     │ Store tokens in     │                    │                     │
     │ flutter_secure_storage                   │                     │
     │                     │                    │                     │
```

### 4.2 Token Refresh Flow (Dio Interceptor)

```dart
// Flutter Dio Interceptor — Automatic Token Refresh
class AuthInterceptor extends QueuedInterceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        final newTokens = await _refreshToken();
        // Retry original request with new access token
        final retryResponse = await _retryRequest(err.requestOptions, newTokens);
        handler.resolve(retryResponse);
      } catch (e) {
        // Refresh failed → force logout
        _forceLogout();
        handler.next(err);
      }
    } else {
      handler.next(err);
    }
  }
}
```

**Token lifecycle across the system:**

```
Flutter App                          Backend
    │                                   │
    │── Any API call ──────────────────→│ Access token valid? ✓ → process
    │                                   │ Access token expired? → 401
    │                                   │
    │── POST /auth/refresh ────────────→│ Refresh token valid? ✓ → new pair
    │   { refresh_token }               │ Refresh token expired? → 401
    │                                   │
    │←── New { access, refresh } ───────│
    │                                   │
    │── Retry original request ────────→│ ✓ Proceed
    │                                   │
```

---

## 5. Core User Journeys — End-to-End

### 5.1 Journey: Browse Menu & Place Order

```
Step  Flutter App                    Backend                     Kitchen Portal
─────┬───────────────────────────────┬──────────────────────────┬────────────────────
  1  │ App opens → GET /menu/categories                        │
     │ + GET /menu/items?time_slot=lunch                       │
     │──────────────────────────────→│                         │
  2  │←── categories + items ────────│                         │
     │ Render menu grid              │                         │
  3  │ User adds 3 items to cart     │                         │
     │ (local CartBloc state)        │                         │
  4  │ User taps "Checkout"          │                         │
     │ Navigate to CheckoutScreen    │                         │
  5  │ User selects: Pickup + UPI    │                         │
     │ Taps "Place Order"            │                         │
  6  │ POST /orders { items, type,   │                         │
     │   payment_method }            │                         │
     │──────────────────────────────→│                         │
  7  │                               │ Validate items available│
     │                               │ Calculate totals        │
     │                               │ Create order (status:   │
     │                               │   received)             │
     │                               │ Create Razorpay order   │
     │                               │ ──── FCM push ─────────→│ "New Order!" 🔔
     │                               │ ──── SSE event ────────→│ Dashboard updates
  8  │←── order + payment details ───│                         │
  9  │ Launch Razorpay SDK           │                         │
     │ User completes UPI payment    │                         │
 10  │ POST /payments/verify         │                         │
     │ { razorpay_payment_id,        │                         │
     │   razorpay_signature }        │                         │
     │──────────────────────────────→│                         │
 11  │                               │ Verify Razorpay signature│
     │                               │ Mark payment: captured  │
     │                               │ Confirm order           │
 12  │←── 200 { order confirmed } ───│                         │
 13  │ Navigate to OrderTrackingScreen                         │
     │ Connect WebSocket             │                         │
     │ ws://host/ws/orders/{id}      │                         │
     │──────────────────────────────→│                         │
 14  │                               │                         │ Staff sees order
     │                               │                         │ clicks "Preparing"
     │                               │                         │ PATCH /admin/orders/
     │                               │                         │   {id}/status
     │                               │←────────────────────────│
 15  │                               │ Update DB               │
     │                               │ Publish to Redis pubsub │
     │                               │ Send FCM push           │
 16  │←── WS: { status: preparing }──│                         │
     │ Stepper animates to step 2    │                         │
     │ Push notification received    │                         │
```

### 5.2 Journey: Kitchen Processes Order to Completion

```
Kitchen Portal                Backend              Flutter App
     │                           │                      │
     │ SSE: new_order event      │                      │
     │←──────────────────────────│                      │
     │ Dashboard shows new order │                      │
     │                           │                      │
     │ PATCH /admin/orders/{id}/ │                      │
     │   status { "preparing" }  │                      │
     │──────────────────────────→│                      │
     │                           │ Update order status  │
     │                           │ Redis PUBLISH        │
     │                           │ Celery: send FCM     │
     │                           │─── WS message ──────→│ Stepper: "Preparing"
     │                           │─── FCM push ────────→│ Notification banner
     │                           │                      │
     │ PATCH { "ready" }         │                      │
     │──────────────────────────→│                      │
     │                           │─── WS + FCM ────────→│ Stepper: "Ready"
     │                           │                      │ Sound alert 🔔
     │                           │                      │
     │ (For delivery orders:)    │                      │
     │ POST /admin/orders/{id}/  │                      │
     │   assign-delivery         │                      │
     │ { staff_id: "uuid" }      │                      │
     │──────────────────────────→│                      │
     │                           │ Create assignment    │
     │                           │                      │
     │ PATCH { "out_for_delivery"}│                     │
     │──────────────────────────→│                      │
     │                           │─── WS + FCM ────────→│ Stepper: "Out for Delivery"
     │                           │                      │
     │ PATCH { "completed" }     │                      │
     │──────────────────────────→│                      │
     │                           │ Close WS connection  │
     │                           │─── FCM push ────────→│ "Order Delivered! ✅"
     │                           │                      │ Navigate to feedback
```

---

## 6. API Client Contract

### 6.1 Flutter API Client (Dio Configuration)

```dart
class ApiClient {
  late final Dio _dio;

  ApiClient({required String baseUrl, required TokenStorage tokenStorage}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'X-Platform': Platform.isAndroid ? 'android' : 'ios',
        'X-App-Version': AppConfig.version,
      },
    ));

    _dio.interceptors.addAll([
      AuthInterceptor(tokenStorage: tokenStorage, dio: _dio),
      RetryInterceptor(retries: 3, retryOn: [500, 502, 503]),
      LogInterceptor(requestBody: true, responseBody: true),
    ]);
  }
}
```

### 6.2 Kitchen Portal API Client (Axios)

```javascript
const apiClient = axios.create({
  baseURL: process.env.REACT_APP_API_URL,
  timeout: 15000,
  headers: { 'Content-Type': 'application/json' }
});

apiClient.interceptors.request.use(config => {
  const token = localStorage.getItem('access_token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  config.headers['X-Request-ID'] = crypto.randomUUID();
  return config;
});
```

### 6.3 Idempotency — Preventing Duplicate Orders

```
Flutter App                          Backend
    │                                   │
    │ Generate idempotency_key (UUID)   │
    │                                   │
    │ POST /orders                      │
    │ Header: X-Idempotency-Key: uuid   │
    │──────────────────────────────────→│
    │                                   │ Check Redis: idempotency:{key}
    │                                   │ Not found → process order
    │                                   │ SET idempotency:{key} = order_id (TTL 24h)
    │←── 201 { order } ────────────────│
    │                                   │
    │ (Network timeout — user retries)  │
    │ POST /orders (same key)           │
    │──────────────────────────────────→│
    │                                   │ Found in Redis → return existing order
    │←── 200 { same order } ───────────│
```

---

## 7. Real-Time Communication

### 7.1 WebSocket — Flutter App (Order Tracking)

**Connection lifecycle from Flutter:**

```dart
class OrderWebSocketService {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  int _retryCount = 0;

  void connect(String orderId, String token) {
    final uri = Uri.parse('$wsBaseUrl/ws/orders/$orderId?token=$token');
    _channel = WebSocketChannel.connect(uri);

    _channel!.stream.listen(
      (message) {
        final event = jsonDecode(message);
        _handleEvent(event);  // Emit to BLoC
        _retryCount = 0;
      },
      onError: (error) => _reconnect(orderId, token),
      onDone: () {
        if (_shouldReconnect) _reconnect(orderId, token);
      },
    );
  }

  void _reconnect(String orderId, String token) {
    final delay = min(pow(2, _retryCount).toInt(), 30); // Max 30s
    _reconnectTimer = Timer(Duration(seconds: delay), () {
      _retryCount++;
      if (_retryCount <= 10) connect(orderId, token);
      else _fallbackToPolling(orderId); // Switch to HTTP polling
    });
  }
}
```

**Backend WebSocket handler:**

```python
@router.websocket("/ws/orders/{order_id}")
async def order_websocket(websocket: WebSocket, order_id: str, token: str):
    user = await verify_ws_token(token)
    order = await verify_order_ownership(order_id, user.id)

    await websocket.accept()
    pubsub = redis.pubsub()
    await pubsub.subscribe(f"order:{order_id}")

    try:
        async for message in pubsub.listen():
            if message["type"] == "message":
                await websocket.send_json(json.loads(message["data"]))
    except WebSocketDisconnect:
        await pubsub.unsubscribe(f"order:{order_id}")
```

### 7.2 SSE — Kitchen Web Portal

**Backend SSE endpoint:**

```python
@router.get("/admin/orders/stream")
async def order_stream(request: Request, user=require_role("kitchen", "admin")):
    async def event_generator():
        pubsub = redis.pubsub()
        await pubsub.subscribe("kitchen:orders")
        async for message in pubsub.listen():
            if await request.is_disconnected():
                break
            if message["type"] == "message":
                yield f"data: {message['data']}\n\n"

    return StreamingResponse(event_generator(), media_type="text/event-stream")
```

**Kitchen Portal JS consumer:**

```javascript
const eventSource = new EventSource(
  `${API_URL}/admin/orders/stream?token=${accessToken}`
);
eventSource.onmessage = (event) => {
  const data = JSON.parse(event.data);
  dispatch(updateOrdersDashboard(data));
};
```

### 7.3 How Status Changes Propagate

```
Kitchen Portal                Backend                    Redis              Flutter App
     │                           │                          │                    │
     │ PATCH status: "ready"     │                          │                    │
     │──────────────────────────→│                          │                    │
     │                           │ UPDATE orders SET status │                    │
     │                           │                          │                    │
     │                           │ PUBLISH order:{id}       │                    │
     │                           │──────────────────────────→│                    │
     │                           │                          │── WS forward ─────→│
     │                           │ PUBLISH kitchen:orders   │                    │
     │                           │──────────────────────────→│                    │
     │                           │                          │── SSE forward ────→│(Portal)
     │                           │                          │                    │
     │                           │ Celery: send_push_notification               │
     │                           │─────────── (async) ──────────── FCM ────────→│
```

---

## 8. Payment Integration Flow

### 8.1 Complete UPI Payment Sequence

```
Flutter App          Backend              Razorpay           User's UPI App
    │                   │                    │                     │
    │ POST /orders      │                    │                     │
    │──────────────────→│                    │                     │
    │                   │ POST /v1/orders    │                     │
    │                   │───────────────────→│                     │
    │                   │←── { id, amount }──│                     │
    │                   │                    │                     │
    │←── { order,       │                    │                     │
    │   gateway_order_id│                    │                     │
    │   key_id }        │                    │                     │
    │                   │                    │                     │
    │ Razorpay.open({   │                    │                     │
    │   key, amount,    │                    │                     │
    │   order_id })     │                    │                     │
    │───────────────────────────────────────→│                     │
    │                   │                    │ Launch UPI intent   │
    │                   │                    │────────────────────→│
    │                   │                    │                     │ User enters PIN
    │                   │                    │←────────────────────│
    │←── { payment_id,  │                    │                     │
    │   signature }     │                    │                     │
    │                   │                    │                     │
    │ POST /payments/   │                    │                     │
    │   verify          │                    │                     │
    │ { payment_id,     │                    │                     │
    │   order_id,       │                    │                     │
    │   signature }     │                    │                     │
    │──────────────────→│                    │                     │
    │                   │ HMAC SHA256 verify │                     │
    │                   │ generated_sig ==   │                     │
    │                   │   received_sig?    │                     │
    │                   │ Update: paid ✓     │                     │
    │←── 200 confirmed ─│                    │                     │
    │                   │                    │                     │
    │                   │←── Webhook (async) ─│  (backup confirm)  │
```

### 8.2 Payment Failure Recovery

| Scenario | Flutter Action | Backend Action |
|----------|---------------|---------------|
| UPI app not installed | Show error, suggest other UPI apps | No action needed |
| Payment timeout | Show "Payment Pending" screen | Hold order 5 min, then cancel |
| Payment declined | Show "Try Again" + "Pay with Cash" | Mark payment failed |
| Network drop mid-payment | On reconnect, call GET /orders/{id} to check status | Rely on Razorpay webhook |
| Verify API fails | Retry 3x, then show "Contact Support" with order number | Webhook will update eventually |

---

## 9. Push Notification Flow

### 9.1 FCM Token Registration

```
Flutter App                    Backend                 Firebase
    │                             │                       │
    │ App start → FirebaseMessaging                       │
    │   .instance.getToken()      │                       │
    │←────────────────────────────────────── token ────────│
    │                             │                       │
    │ POST /users/device-token    │                       │
    │ { token, platform }         │                       │
    │────────────────────────────→│                       │
    │                             │ Upsert device_tokens  │
    │←── 200 ────────────────────│                       │
    │                             │                       │
    │ Listen: onTokenRefresh      │                       │
    │←───────────────────────────────── new_token ────────│
    │ POST /users/device-token    │                       │
    │────────────────────────────→│                       │
```

### 9.2 Notification Delivery Chain

```
Backend (Order Service)         Celery Worker          Firebase        Flutter App
    │                               │                     │                │
    │ order.status = "ready"        │                     │                │
    │ dispatch send_notification    │                     │                │
    │   .delay(user_id, payload)    │                     │                │
    │──────────────────────────────→│                     │                │
    │                               │ Lookup device_tokens│                │
    │                               │ for user_id         │                │
    │                               │                     │                │
    │                               │ firebase_admin      │                │
    │                               │  .messaging.send()  │                │
    │                               │────────────────────→│                │
    │                               │                     │── Push ───────→│
    │                               │                     │                │
    │                               │                     │                │ Foreground:
    │                               │                     │                │  flutter_local_
    │                               │                     │                │  notifications
    │                               │                     │                │  shows banner
    │                               │                     │                │
    │                               │                     │                │ Background:
    │                               │                     │                │  System tray
    │                               │                     │                │  notification
    │                               │                     │                │
    │                               │                     │                │ Tap → deep link
    │                               │                     │                │  /order/{id}/
    │                               │                     │                │  tracking
```

### 9.3 Notification Payload Format

```json
{
  "notification": {
    "title": "Order Ready! 🎉",
    "body": "Your order #ORD-20260213-042 is ready for pickup"
  },
  "data": {
    "type": "order_status",
    "order_id": "uuid-xxx",
    "status": "ready",
    "click_action": "ORDER_TRACKING"
  }
}
```

**Flutter handles `data.click_action`** to determine navigation target on notification tap.

---

## 10. Data Synchronization

### 10.1 Menu Data — Cache Strategy

```
Flutter App                      Backend
    │                               │
    │ GET /menu/items               │
    │ If-None-Match: "etag-abc"     │
    │──────────────────────────────→│
    │                               │ Compare ETag
    │                               │
    │ (Menu unchanged)              │
    │←── 304 Not Modified ──────────│
    │ Use Hive-cached data          │
    │                               │
    │ (Menu changed)                │
    │←── 200 + ETag: "etag-xyz" ───│
    │ Update Hive cache             │
    │ Update ETag in storage        │
```

### 10.2 Cart — Client-Side with Server Validation

The cart is maintained **entirely on the client** (Flutter `CartBloc` persisted via `hydrated_bloc`). Server validates at checkout:

```
Flutter App                      Backend
    │                               │
    │ POST /orders                  │
    │ { items: [{id, qty}, ...] }   │
    │──────────────────────────────→│
    │                               │ For each item:
    │                               │  - Exists? ✓
    │                               │  - Available? ✓
    │                               │  - Price matches? (use server price)
    │                               │  - Time slot valid? ✓
    │                               │
    │ (All valid)                   │
    │←── 201 Order Created ─────────│
    │                               │
    │ (Item unavailable)            │
    │←── 409 { ITEM_UNAVAILABLE,   │
    │   details: [{id, reason}] }  │
    │                               │
    │ Show dialog: "X is no longer │
    │   available. Remove and       │
    │   continue?"                  │
```

### 10.3 System Config — Periodic Sync

```dart
// Flutter: Fetch admin-controlled settings on app start & every 5 minutes
class ConfigService {
  Future<AppConfig> fetchConfig() async {
    final response = await apiClient.get('/config/public');
    return AppConfig(
      deliveryEnabled: response['delivery_enabled'],
      cashEnabled: response['cash_payment_enabled'],
      upiEnabled: response['upi_payment_enabled'],
      restaurantOpen: response['restaurant_open'],
      timeSlots: response['time_slots'],
    );
  }
}
```

The Flutter app uses these settings to:
- Show/hide delivery option in checkout
- Show/hide payment methods
- Show "Restaurant Closed" banner
- Filter menu by active time slots

---

## 11. Error Handling Across Layers

### 11.1 Error Flow — End to End

```
Flutter UI Layer          Flutter Data Layer         Backend
    │                         │                         │
    │ User taps "Place Order" │                         │
    │────────────────────────→│                         │
    │                         │ POST /orders            │
    │                         │────────────────────────→│
    │                         │                         │ 409 ITEM_UNAVAILABLE
    │                         │←────────────────────────│
    │                         │                         │
    │                         │ Parse error response    │
    │                         │ Map to ServerFailure    │
    │                         │ Return Left(failure)    │
    │                         │                         │
    │←── BLoC emits           │                         │
    │    OrderError state     │                         │
    │                         │                         │
    │ Show error dialog       │                         │
    │ with specific message   │                         │
    │ and recovery action     │                         │
```

### 11.2 Error Mapping Table

| HTTP Status | Backend Code | Flutter Failure | UI Action |
|-------------|-------------|----------------|-----------|
| 400 | VALIDATION_ERROR | `ValidationFailure` | Show field-level errors |
| 401 | TOKEN_EXPIRED | `AuthFailure` | Auto-refresh → retry |
| 401 | INVALID_TOKEN | `AuthFailure` | Force logout + login |
| 403 | INSUFFICIENT_ROLE | `AuthFailure` | "Access denied" toast |
| 404 | NOT_FOUND | `NotFoundFailure` | "Item not found" message |
| 409 | ITEM_UNAVAILABLE | `ConflictFailure` | Dialog: remove item |
| 409 | RESTAURANT_CLOSED | `ConflictFailure` | Full-screen "Closed" |
| 429 | RATE_LIMITED | `RateLimitFailure` | "Try again in X seconds" |
| 500 | INTERNAL_ERROR | `ServerFailure` | "Something went wrong" + retry |
| — | Network timeout | `NetworkFailure` | Offline banner + retry |

---

## 12. Environment Configuration

### 12.1 Flutter Environment Variables

```dart
class AppConfig {
  static String get apiBaseUrl =>
    const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000/api/v1');

  static String get wsBaseUrl =>
    const String.fromEnvironment('WS_BASE_URL', defaultValue: 'ws://10.0.2.2:8000/api/v1');

  static String get razorpayKey =>
    const String.fromEnvironment('RAZORPAY_KEY');
}
```

### 12.2 Environment Matrix

| Variable | Dev | Staging | Production |
|----------|-----|---------|------------|
| `API_BASE_URL` | `http://10.0.2.2:8000/api/v1` | `https://staging-api.example.com/api/v1` | `https://api.example.com/api/v1` |
| `WS_BASE_URL` | `ws://10.0.2.2:8000/api/v1` | `wss://staging-api.example.com/api/v1` | `wss://api.example.com/api/v1` |
| `RAZORPAY_KEY` | `rzp_test_xxx` | `rzp_test_xxx` | `rzp_live_xxx` |

---

## 13. Testing the Integration

### 13.1 API Contract Testing

| Test Type | Tool | Scope |
|-----------|------|-------|
| **API Contract** | Pact / Schemathesis | Validate Flutter expectations vs Backend |
| **Backend Integration** | pytest + httpx | Test full request → DB → response cycle |
| **Flutter Integration** | `integration_test` | Test full flows with mock server |
| **E2E Smoke** | Manual / Appium | Place order → Kitchen process → Complete |

### 13.2 Mock Server for Flutter Development

During Flutter development, use a mock server so frontend work isn't blocked by backend:

```dart
// test/mocks/mock_api_server.dart
// Uses package:mock_web_server or shelf
final mockServer = MockWebServer();
mockServer.enqueue(body: jsonEncode(menuItemsResponse), httpCode: 200);
```

### 13.3 Integration Test Checklist

- [ ] OTP request → verify → token received
- [ ] Menu fetch with category + time-slot filters
- [ ] Place order → receive order ID + payment details
- [ ] Payment verify → order confirmed
- [ ] WebSocket connects and receives status updates
- [ ] FCM token registration
- [ ] Token refresh on 401
- [ ] Idempotent order placement (duplicate key → same order)
- [ ] Error responses correctly parsed and displayed
- [ ] Kitchen portal SSE receives new orders
- [ ] Kitchen status update → consumer receives via WS + FCM

---

## 14. Sequence Diagrams

### 14.1 Complete Order Lifecycle (All Systems)

```
Consumer App        Backend API        PostgreSQL    Redis    Razorpay    FCM    Kitchen Portal
    │                   │                  │           │         │         │          │
    ├── POST /orders ──→│                  │           │         │         │          │
    │                   ├── INSERT order ──→│           │         │         │          │
    │                   ├── Create payment ─────────────────────→│         │          │
    │                   │←─────────────────────────────────── ok─│         │          │
    │                   ├── PUBLISH ────────────────────→│        │         │          │
    │                   │                  │           │──SSE──────────────────────────→│
    │                   ├── Celery task ────────────────────────────────→│              │
    │                   │                  │           │         │      push           │
    │←── 201 order ─────│                  │           │         │         │          │
    │                   │                  │           │         │         │          │
    ├── Razorpay SDK ──────────────────────────────────→│        │         │          │
    │←── payment result ───────────────────────────────│         │         │          │
    ├── POST verify ───→│                  │           │         │         │          │
    │                   ├── Verify sig ────────────────────────→│         │          │
    │                   ├── UPDATE paid ──→│           │         │         │          │
    │←── 200 confirmed ─│                  │           │         │         │          │
    │                   │                  │           │         │         │          │
    ├── WS connect ────→│                  │           │         │         │          │
    │                   ├── subscribe ─────────────────→│        │         │          │
    │                   │                  │           │         │         │          │
    │                   │                  │           │         │         │←─ PATCH status
    │                   │←──────────────────────────────────────────────────── preparing
    │                   ├── UPDATE ───────→│           │         │         │          │
    │                   ├── PUBLISH ────────────────────→│        │         │          │
    │←── WS: preparing ─│                  │           │         │         │          │
    │                   ├── Celery FCM ────────────────────────────────→│              │
    │                   │                  │           │         │      push           │
    │                   │                  │           │         │         │          │
    │   ... (ready, out_for_delivery, completed — same pattern) ...     │          │
```

---

> **Document End**  
> **Companion Documents:**  
> - [01-Flutter-UI-Design-Document.md](./01-Flutter-UI-Design-Document.md)  
> - [02-Backend-API-Design-Document.md](./02-Backend-API-Design-Document.md)
