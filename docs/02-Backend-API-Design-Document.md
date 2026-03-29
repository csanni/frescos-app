# Backend API System Design Document

## 1. Overview
This document specifies the complete REST API interface for all 9 core microservices of the Fresco's Kitchen platform. It covers HTTP methods, endpoints, parameters, request schemas, response formats, authentication, rate limits, and error handling.

All endpoints are prefixed with `api/v1` in production (this document references the base paths as implemented by individual microservice controllers). 
Default response envelope for all endpoints: `{ "success": true, "data": { ... } }`.
Error envelope: `{ "success": false, "error": { "code": "...", "message": "..." } }`.

---

## 2. Authentication & Authorization (frescos-auth-service)

### 2.1 Request OTP
- **Method / Path:** `POST /auth/otp/request`
- **Description:** Sends a 6-digit OTP to user's phone via SMS.
- **Auth required:** No (Public)
- **Rate Limit:** 5 requests per minute per IP, max 3 requests per 15 minutes per phone number.
- **Request Body:**
  ```json
  {
    "phone": "+919876543210" // Required. String, format: E.164 Indian number.
  }
  ```
- **Response (200 OK):**
  ```json
  { "message": "OTP sent successfully", "expires_in": 600 }
  ```
- **Errors:** `429 OTP_RATE_LIMITED`

### 2.2 Verify OTP
- **Method / Path:** `POST /auth/otp/verify`
- **Description:** Verifies OTP and returns RS256 JWT access and refresh tokens.
- **Auth required:** No (Public)
- **Request Body:**
  ```json
  {
    "phone": "+919876543210", // Required. E.164 phone.
    "otp": "123456"          // Required. Exactly 6 digits.
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "access_token": "eyJ...", "refresh_token": "long-opaque-string",
    "token_type": "bearer", "expires_in": 1800,
    "user": { "id": "uuid", "phone": "+91...", "role": "customer" }
  }
  ```
- **Errors:** `400 OTP_INVALID`, `400 OTP_EXPIRED`, `400 OTP_MAX_ATTEMPTS`, `401 USER_DEACTIVATED`.

### 2.3 Rotate Token
- **Method / Path:** `POST /auth/token/refresh`
- **Description:** Issues a new token pair from a valid refresh token.
- **Auth required:** No (Public)
- **Request Body:**
  ```json
  { "refresh_token": "string" }
  ```
- **Response (200 OK):** Similar to `Verify OTP`.
- **Errors:** `401 TOKEN_INVALID`, `401 TOKEN_EXPIRED`.

### 2.4 Logout
- **Method / Path:** `POST /auth/logout`
- **Auth required:** Yes (Bearer JWT)
- **Request Body:**
  ```json
  { "refresh_token": "string" } // Optional. If omitted, all sessions logged out.
  ```
- **Response (200 OK):** `{ "message": "Logged out successfully" }`

### 2.5 Get Current Profile (Basic)
- **Method / Path:** `GET /auth/me`
- **Auth required:** Yes (Bearer JWT)

---

## 3. User Profiles (frescos-user-profile-service)

### 3.1 Get Profile
- **Method / Path:** `GET /users/me`
- **Auth:** Bearer JWT

### 3.2 Update Profile
- **Method / Path:** `PUT /users/me`
- **Auth:** Bearer JWT
- **Request Body:**
  ```json
  { "name": "string?", "email": "email?", "whatsappNumber": "E.164?" }
  ```

### 3.3 Manage Addresses
- **List Addresses:** `GET /users/me/addresses` (Auth: JWT)
- **Add Address:** `POST /users/me/addresses`
  - Body: `{ "addressLine": "str", "label": "str?", "landmark": "str?", "isDefault": "bool?" }`
- **Remove Address:** `DELETE /users/me/addresses/:addressId`

### 3.4 Manage Favorites
- **List Favorites:** `GET /users/me/favorites` (Auth: JWT)
- **Add Favorite:** `POST /users/me/favorites/:menuItemId`
- **Remove Favorite:** `DELETE /users/me/favorites/:menuItemId`

---

## 4. Menu CMS (frescos-menu-cms-service)

### 4.1 Consumer Menu (Public)
- **Get All Menu:** `GET /menu`
  - *Query Params:* `categoryId` (uuid?), `search` (str?), `isVeg` (bool?), `timeSlot` (enum?), `page` (int?), `limit` (int max 100?)
  - *Pagination:* `meta: { page, limit, total, totalPages }`
- **Get Categories:** `GET /menu/categories`
- **Get Single Item:** `GET /menu/:id`
- **List Outlets:** `GET /outlets`
- **Get Outlet Menu:** `GET /outlets/:id/menu`

### 4.2 Admin Management (Requires `admin` or `super_admin`)
- **Category:** `POST /admin/menu/categories`, `PUT /admin/menu/categories/:id`
- **Items:** `GET /admin/menu`, `POST /admin/menu`, `PUT /admin/menu/:id`, `DELETE /admin/menu/:id` (Soft-delete).
  - *Schema example for POST /admin/menu:*
    ```json
    {
      "categoryId": "uuid", "name": "Pizza", "basePrice": 250.0,
      "timeSlots": ["lunch", "dinner"], "sizeOptions": [], "crustOptions": []
    }
    ```
- **Image Upload:** `POST /admin/menu/:id/image` (Multipart form-data)
- **Toggle Availability:** `PUT /admin/menu/:id/availability` (Allows `kitchen` role)

---

## 5. Order Management System (frescos-oms-service)

### 5.1 Place Order
- **Method / Path:** `POST /orders`
- **Auth required:** Token optional (Guest checkout supported).
- **Request Body:**
  ```json
  {
    "outlet_id": "uuid",
    "order_type": "dinein|pickup|delivery",
    "payment_method": "razorpay|cash|upi_counter",
    "items": [
      {
        "menu_item_id": "uuid", "quantity": 1,
        "customizations": { "size_option_id": "uuid?", ... }
      }
    ],
    "customer_name": "Required for guest",
    "customer_whatsapp": "Required for guest",
    "delivery_address": "Required for delivery",
    "idempotency_key": "uuid"
  }
  ```
- **Response (201 Created):** Creates order in `INITIATED` state.

### 5.2 Order History & Control
- **Get Order Status:** `GET /orders/:id` (Auth: owner or staff).
- **History:** `GET /orders/history/me` (Auth: JWT).
- **Cancel:** `POST /orders/:id/cancel` (Auth: owner, only if INITIATED/CONFIRMED). Reason in body.
- **Invoice:** `GET /orders/:id/invoice` (Only post-confirmation).

### 5.3 Admin Order Control
- **List:** `GET /admin/orders` (Auth: Staff+, Query: `status`, `outlet_id`, `date`)
- **Status Advancement:** `PUT /admin/orders/:id/status` (Auth: Staff+)
  - **Allowed chain:** INITIATED → PAYMENT_SUCCESS → CONFIRMED → PREPARING → READY → DELIVERED.
  - *Body:* `{ "status": "preparing" }`
- **Refund Initiation:** `POST /admin/orders/:id/refund` (Auth: Admin+)
  - *Body:* `{ "refund_type": "full|partial", "amount": number }`

---

## 6. Payments (frescos-payment-service)

- **Create Razorpay Order:** `POST /payments/razorpay/create` (Auth: JWT, `{ order_id: uuid }`)
- **Webhook Listener:** `POST /webhooks/razorpay` (Public. HMAC-SHA256 verified single source of truth for payment success/failure).
- **Confirm Cash Payment:** `POST /payments/cash/confirm` (Auth: Staff+, `{ order_id: uuid }`).
- **Receipt Query:** `GET /payments/:orderId/receipt`

---

## 7. Inventory Management (frescos-inventory-service)

Requires `kitchen` or `admin` roles.

- **List Inventory:** `GET /admin/inventory` (Returns computed status: `in_stock`, `low_stock`, etc.)
- **Low Stock Report:** `GET /admin/inventory/low-stock`
- **Create Item:** `POST /admin/inventory`
- **Update Stock/Thresholds:** `PUT /admin/inventory/:id`
- **Log Supplier Restock:** `POST /admin/inventory/:id/restock` (Adds to total atomically).
  - *Body:* `{ "quantity": 10.5, "supplier": "Local Vendor", "costPerUnit": 50 }`

---

## 8. Notifications (frescos-notifications-service)

- **Get In-App:** `GET /notifications/me`
- **Mark Read:** `PUT /notifications/me/:id/read`
- **Settings:** `GET /notifications/settings`, `POST /notifications/settings` (Push, WhatsApp, SMS toggles).
- **Internal Publisher:** `POST /notifications/internal/send` (Restricted to internal network / system roles. Dispatches payloads to FCM and MSG91).

---

## 9. Admin Operations (frescos-admin-ops-service)

Manage staff roles mapping to Auth Service.
- **List Staff:** `GET /admin/staff`
- **Create Staff:** `POST /admin/staff`
  - *Body:* `{ "name": "str", "phone": "str", "role": "kitchen_staff", "outletId": "uuid?" }`
- **Update Staff:** `PUT /admin/staff/:id`

---

## 10. Analytics & ML (frescos-reports-ml-service - FastAPI)

*Note: Base path `/api/v1` applies.*

- **Daily Reports:** `GET /reports/daily` (Query: `report_date`, `outlet_id`)
- **Inventory Forecast (ARIMA):** `GET /reports/inventory-forecast` (Query: `days_ahead`, `outlet_id`)
- **Combo Recommender (Apriori):** `GET /ml/recommend-combos`

---

## 11. WebSocket / Real-Time Events
Service boundary: **OMS**
- **Channel:** `order:{orderId}`. Messages emitted when internal state machine triggers `updateOrderStatus()`. Used by mobile apps to poll-free track delivery/preparation times.
- **Channel:** `admin:orders:stream`. SSE implementation feeding live events to Kitchen POS iPads.

---

## 12. Standard Error Codes
- `INTERNAL_ERROR`: Deep system panic (Code 500)
- `VALIDATION_ERROR`: NestJS DTO failure (Code 400)
- `INVALID_STATUS_TRANSITION`: State-machine violation in OMS (Code 422)
- `OTP_RATE_LIMITED`: Throttling triggered in Auth (Code 429)
- `WEBHOOK_SIGNATURE_INVALID`: Bad Razorpay HMAC (Code 403)
