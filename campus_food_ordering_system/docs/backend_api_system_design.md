# Fresco's Kitchen — Backend API System Design

**Version:** 1.0 · **Date:** 6 March 2026 · **Author:** Engineering Team  
**Companion Documents:** [Database Schema](./database_schema.md) · [Customer App](./customer_app_system_design.md) · [Admin Portal](./admin_portal_system_design.md)

---

## Table of Contents

1. [Overview](#1-overview)
2. [Architecture](#2-architecture)
3. [Module 1 — Authentication & Authorization](#3-module-1--authentication--authorization)
4. [Module 2 — Users](#4-module-2--users)
5. [Module 3 — Menu & Content](#5-module-3--menu--content)
6. [Module 4 — Orders](#6-module-4--orders)
7. [Module 5 — Payments](#7-module-5--payments)
8. [Module 6 — Inventory](#8-module-6--inventory)
9. [Module 7 — Analytics & Reporting](#9-module-7--analytics--reporting)
10. [Module 8 — Admin Operations](#10-module-8--admin-operations)
11. [Module 9 — Notifications](#11-module-9--notifications)
12. [WebSocket Events](#12-websocket-events)
13. [Error Handling](#13-error-handling)
14. [Security](#14-security)
15. [Infrastructure & Deployment](#15-infrastructure--deployment)

---

## 1. Overview

| Attribute | Value |
|-----------|-------|
| **Runtime** | Node.js 20 LTS |
| **Framework** | NestJS (TypeScript) |
| **API Style** | REST (primary) + WebSocket (real-time) |
| **Authentication** | JWT (RS256) + OTP via Twilio |
| **Database** | PostgreSQL 15 (via TypeORM) |
| **Cache** | Redis 7 |
| **Payment** | Razorpay |
| **SMS** | Twilio |
| **Push** | Firebase Cloud Messaging (FCM) |
| **Media** | AWS S3 / MinIO |
| **Base URL** | `https://api.fresco-kitchen.com/api/v1` |
| **Content-Type** | `application/json` |
| **Rate Limiting** | Global: 100 req/min per IP |

### Modules Summary

| # | Module | Endpoints | Auth Required |
|---|--------|-----------|--------------|
| 1 | Authentication | 5 | Partial |
| 2 | Users | 6 | ✅ |
| 3 | Menu & Content | 10 | Partial |
| 4 | Orders | 9 | ✅ |
| 5 | Payments | 4 | ✅ |
| 6 | Inventory | 5 | ✅ (staff+) |
| 7 | Analytics & Reporting | 8 | ✅ (admin+) |
| 8 | Admin Operations | 10 | ✅ (admin+) |
| 9 | Notifications | 4 | ✅ |

---

## 2. Architecture

### 2.1 Request Lifecycle

```mermaid
sequenceDiagram
    Client->>Nginx: HTTPS Request
    Nginx->>NestJS: Proxy pass
    NestJS->>Guard: JWT validation + RBAC check
    Guard-->>NestJS: Authorized ✅
    NestJS->>Service: Business logic
    Service->>Repository: DB query (TypeORM)
    Repository->>PostgreSQL: SQL
    PostgreSQL-->>Repository: Result
    Service->>Redis: Cache write/read
    NestJS-->>Client: JSON Response
```

### 2.2 NestJS Module Structure

```
src/
├── main.ts                    # Bootstrap, Swagger, CORS, global pipes
├── app.module.ts              # Root module
├── modules/
│   ├── auth/                  # Module 1
│   ├── users/                 # Module 2
│   ├── menu/                  # Module 3
│   ├── orders/                # Module 4
│   ├── payments/              # Module 5
│   ├── inventory/             # Module 6
│   ├── analytics/             # Module 7
│   ├── admin/                 # Module 8
│   └── notifications/         # Module 9
├── shared/
│   ├── guards/                # JwtAuthGuard, RolesGuard
│   ├── decorators/            # @Roles(), @CurrentUser()
│   ├── interceptors/          # LoggingInterceptor, TransformInterceptor
│   ├── filters/               # GlobalExceptionFilter
│   └── utils/                 # GSTCalculator, OrderNumberGenerator
└── config/
    ├── database.config.ts
    ├── redis.config.ts
    ├── jwt.config.ts
    └── razorpay.config.ts
```

### 2.3 Standard Response Envelope

```json
// Success
{
  "success": true,
  "data": { ... },
  "meta": { "page": 1, "total": 120, "limit": 20 }
}

// Error
{
  "success": false,
  "error": {
    "code": "ORDER_NOT_FOUND",
    "message": "Order PIZ-20260306-0100 does not exist",
    "statusCode": 404
  }
}
```

---

## 3. Module 1 — Authentication & Authorization

### 3.1 Flow

```mermaid
sequenceDiagram
    User->>API: POST /auth/otp/request { phone }
    API->>API: Generate 6-digit OTP
    API->>API: Hash OTP with bcrypt, store in otp_requests (TTL 10 min)
    API->>Twilio: Send SMS
    Twilio-->>User: OTP via SMS
    User->>API: POST /auth/otp/verify { phone, otp }
    API->>API: Validate OTP hash, check expiry, check attempts ≤ 5
    API->>API: Upsert user, issue JWT access + refresh tokens
    API-->>User: { access_token, refresh_token, user }
    User->>API: All subsequent requests with Authorization: Bearer <token>
```

### 3.2 Endpoints

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| POST | `/auth/otp/request` | Send OTP to phone number | — |
| POST | `/auth/otp/verify` | Verify OTP, get tokens | — |
| POST | `/auth/token/refresh` | Refresh access token | Refresh token |
| POST | `/auth/logout` | Revoke refresh token | ✅ |
| GET | `/auth/me` | Get current user | ✅ |

### 3.3 Request/Response Examples

**POST /auth/otp/request**
```json
// Request
{ "phone": "+919876543210" }

// Response 200
{ "success": true, "data": { "message": "OTP sent", "expires_in": 600 } }

// Error 429 (rate limited)
{ "success": false, "error": { "code": "OTP_RATE_LIMITED", "message": "Max 3 OTP requests per 15 minutes", "statusCode": 429 } }
```

**POST /auth/otp/verify**
```json
// Request
{ "phone": "+919876543210", "otp": "482916" }

// Response 200
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJSUzI1NiJ9...",
    "refresh_token": "dXQtc2VjcmV0LXJlZnJlc2g...",
    "expires_in": 1800,
    "user": { "id": "uuid", "phone": "+919876543210", "name": "Rahul S.", "role": "customer" }
  }
}
```

### 3.4 JWT Payload

```json
{
  "sub": "user-uuid",
  "phone": "+919876543210",
  "role": "customer",
  "iat": 1234567890,
  "exp": 1234569690
}
```

### 3.5 Token Configuration

| Token | Algorithm | Lifetime | Storage (Client) |
|-------|-----------|---------|-----------------|
| Access Token | RS256 | 30 min | Memory / Flutter SecureStorage |
| Refresh Token | SHA-256 hash | 30 days | Flutter SecureStorage |

---

## 4. Module 2 — Users

### 4.1 Endpoints

| Method | Path | Description | Auth | Role |
|--------|------|-------------|------|------|
| GET | `/users/me` | Get own profile | ✅ | any |
| PUT | `/users/me` | Update own profile | ✅ | any |
| GET | `/users/me/addresses` | Get saved addresses | ✅ | customer |
| POST | `/users/me/addresses` | Save delivery address | ✅ | customer |
| DELETE | `/users/me/addresses/:id` | Remove address | ✅ | customer |
| GET | `/users/me/favorites` | Get favorite items | ✅ | customer |
| POST | `/users/me/favorites/:menuItemId` | Add favorite | ✅ | customer |
| DELETE | `/users/me/favorites/:menuItemId` | Remove favorite | ✅ | customer |

### 4.2 Update Profile

```json
// PUT /users/me
// Request
{ "name": "Rahul Sharma", "email": "rahul@example.com" }

// Response 200
{ "success": true, "data": { "id": "uuid", "name": "Rahul Sharma", "phone": "+919876543210" } }
```

---

## 5. Module 3 — Menu & Content

### 5.1 Endpoints

| Method | Path | Description | Auth | Role |
|--------|------|-------------|------|------|
| GET | `/menu` | All available menu items | — | — |
| GET | `/menu/:id` | Item detail with options | — | — |
| GET | `/outlets` | All active outlets | — | — |
| GET | `/outlets/:id/menu` | Menu for specific outlet | — | — |
| POST | `/admin/menu` | Create item | ✅ | admin+ |
| PUT | `/admin/menu/:id` | Update item | ✅ | admin+ |
| DELETE | `/admin/menu/:id` | Soft delete item | ✅ | admin+ |
| POST | `/admin/menu/:id/image` | Upload item image | ✅ | admin+ |
| PUT | `/admin/menu/:id/availability` | Toggle item availability | ✅ | staff+ |

### 5.2 GET /menu

```json
// Response 200
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "slug": "margherita-pizza",
      "name": "Margherita Pizza",
      "description": "Classic hand-tossed...",
      "base_price": 199.00,
      "category": "Pizza",
      "is_veg": true,
      "rating": 4.5,
      "tags": ["Bestseller"],
      "size_options": [
        { "id": "uuid", "label": "Small (7\")", "size_code": "small", "price_addon": 0 },
        { "id": "uuid", "label": "Medium (9\")", "size_code": "medium", "price_addon": 50 },
        { "id": "uuid", "label": "Large (12\")", "size_code": "large", "price_addon": 100 }
      ],
      "topping_options": [
        { "id": "uuid", "name": "Extra Cheese", "price": 40, "is_veg": true, "category": "cheese" }
      ],
      "crust_options": [
        { "id": "uuid", "label": "Thin Crust", "price_addon": 0 },
        { "id": "uuid", "label": "Stuffed Crust", "price_addon": 50 }
      ]
    }
  ]
}
```

---

## 6. Module 4 — Orders

### 6.1 Strict State Machine

Order status follows a **10-state strict machine**. All transitions are **atomic** — executed in a DB transaction with optimistic locking. Frontend payment signals are **not trusted**; only the Razorpay webhook updates payment states.

```mermaid
stateDiagram-v2
    [*] --> INITIATED : Customer submits order
    INITIATED --> PAYMENT_PENDING : Razorpay session opened
    INITIATED --> CONFIRMED : Cash / UPI at store (no payment gate)
    INITIATED --> EXPIRED : Cron: 15-min TTL unpaid
    PAYMENT_PENDING --> PAYMENT_SUCCESS : 🔒 Razorpay webhook (HMAC SHA256 only)
    PAYMENT_PENDING --> EXPIRED : Cron: 15-min TTL
    PAYMENT_SUCCESS --> CONFIRMED : Auto-confirm or kitchen accepts
    CONFIRMED --> PREPARING : Kitchen starts cooking
    CONFIRMED --> CANCELLED : Admin cancels (before PREPARING)
    PREPARING --> READY
    READY --> DELIVERED : Customer slide-to-accept / admin
    DELIVERED --> REFUNDED : Admin initiates refund
    CANCELLED --> REFUNDED : If payment was already captured

    note right of PAYMENT_SUCCESS
        Frontend payment callback
        is IGNORED entirely.
        Only HMAC-SHA256 webhook
        from Razorpay is trusted.
    end note
```

**Allowed transitions table:**

| From | To | Trigger | Actor |
|------|----|---------|-------|
| `initiated` | `payment_pending` | Razorpay order created | System |
| `initiated` | `confirmed` | Cash / UPI order (no payment gate) | System |
| `initiated` | `expired` | 15-min TTL exceeded | Cron job |
| `payment_pending` | `payment_success` | Razorpay webhook received + HMAC verified | System (webhook only) |
| `payment_pending` | `expired` | 15-min TTL exceeded | Cron job |
| `payment_success` | `confirmed` | Auto-confirm (Razorpay) or admin | System / Admin |
| `confirmed` | `preparing` | Kitchen accepts | Kitchen staff |
| `confirmed` | `cancelled` | Cancellation before cooking | Admin |
| `preparing` | `ready` | Food prepared | Kitchen staff |
| `ready` | `delivered` | Customer slide-to-accept or admin | Customer / Admin |
| `delivered` | `refunded` | Refund issued | Admin |
| `cancelled` | `refunded` | Refund on already-captured payment | Admin |

> Any attempt to perform an unlisted transition returns `422 INVALID_STATUS_TRANSITION`.

### 6.2 Student QR Ordering Flow (Ordering Engine)

The primary ordering path for campus customers is QR-based. No app install required — works in the mobile browser.

```mermaid
sequenceDiagram
    Student->>QR Code: 1. Scan table QR
    QR Code-->>Browser: Opens menu URL with outlet + table
    Browser->>API: GET /menu?outlet=main-campus (no auth)
    API-->>Browser: 2. Menu rendered
    Browser->>Student: 3. Student adds items to cart
    Browser->>Student: 4. Name + WhatsApp number input (no OTP)
    Student->>API: POST /orders (guest order with name + whatsapp)
    API-->>Student: Order created → order_number + Razorpay session
    Student->>Razorpay: 5 & 6. Redirect to Razorpay payment
    Razorpay->>API: Webhook: payment.captured (HMAC verified)
    API->>API: status: initiated → payment_success → confirmed
    API->>WhatsApp: 7. Send confirmation to student's WhatsApp
    WhatsApp-->>Student: "✅ Order IITH-FY26-000145 confirmed! ETA: 25 min"
```

**Guest order fields** (no JWT required for QR orders from browser):
- `customer_name` — collected on checkout form
- `customer_whatsapp` — used for order confirmation and status updates
- `outlet_id` — from QR code payload
- `table_number` — from QR code payload
- `order_type` — auto-set to `dinein`

### 6.3 GST Calculation (server-side)

```typescript
// shared/utils/gst.calculator.ts
export function calculateGST(subtotal: number) {
  const cgst = Math.round(subtotal * 0.0125 * 100) / 100; // 1.25%
  const sgst = Math.round(subtotal * 0.0125 * 100) / 100; // 1.25%
  return { cgst, sgst, total_gst: cgst + sgst };
}

export function calculateDeliveryCharge(subtotal: number): number {
  return subtotal >= 500 ? 0 : 30;
}
```

### 6.4 GST & Invoicing

Each outlet has a **separate GSTIN** and uses **financial year-based invoice numbering**:  
Format: `{OUTLET_CODE}-{FY}-{SEQUENCE}` · Example: `IITH-FY26-000145` · Sequence resets annually.

| Invoice Feature | Implementation |
|----------------|---------------|
| **Separate GSTIN per outlet** | Stored in `outlets.gstin` |
| **Invoice number** | `next_invoice_number()` DB function — atomic, financial-year-aware |
| **CGST + SGST split** | Both stored as separate columns in `orders` |
| **Credit note** | Generated on `refunded` status; references original invoice number |
| **Downloadable PDF** | Generated server-side (Puppeteer / PDFKit), stored in S3 |
| **Invoice assigned when** | Order transitions to `confirmed` (not at `initiated`) |

```typescript
// Invoice number assigned atomically on CONFIRMED transition
async function confirmOrder(orderId: string) {
  return await db.transaction(async (trx) => {
    const order = await trx.orders.findOne(orderId, { lock: true });
    assertTransition(order.status, 'confirmed'); // throws if invalid
    const invoiceNumber = await trx.raw(
      'SELECT next_invoice_number(?, ?)', [order.outlet_id, outletCode]
    );
    await trx.orders.update(orderId, {
      status: 'confirmed',
      invoice_number: invoiceNumber,
      estimated_ready_time: new Date(Date.now() + 25 * 60_000)
    });
    await trx.order_status_history.insert({ order_id: orderId, status: 'confirmed' });
  });
}
```

### 6.5 Endpoints

| Method | Path | Description | Auth | Role |
|--------|------|-------------|------|------|
| POST | `/orders` | Place order (JWT or guest with name+whatsapp) | Optional | any |
| GET | `/orders/:id` | Get order detail + status | Optional | owner/staff |
| GET | `/orders/history` | Customer's past orders | ✅ | customer |
| POST | `/orders/:id/cancel` | Cancel order (INITIATED or CONFIRMED only) | ✅ | customer |
| GET | `/orders/:id/invoice` | Download GST invoice PDF | Optional | owner/staff |
| GET | `/admin/orders` | All orders (filter: outlet, status, date, type) | ✅ | staff+ |
| PUT | `/admin/orders/:id/status` | Advance order status (atomic) | ✅ | kitchen/admin |
| POST | `/admin/orders/:id/refund` | Initiate refund (partial or full) | ✅ | admin+ |
| GET | `/admin/orders/:id/invoice` | Reprint invoice / credit note | ✅ | staff+ |

### 6.6 POST /orders

```json
// Request (guest QR order — no JWT)
{
  "outlet_id": "main-campus-uuid",
  "table_number": 7,
  "order_type": "dinein",
  "payment_method": "razorpay",
  "customer_name": "Rahul Sharma",
  "customer_whatsapp": "+919876543210",
  "idempotency_key": "browser-uuid-or-timestamp",
  "delivery_address": null,
  "items": [{
    "menu_item_id": "pizza-1-uuid",
    "quantity": 2,
    "customizations": {
      "size_option_id": "medium-uuid",
      "crust_option_id": "thin-uuid",
      "topping_option_ids": ["extra-cheese-uuid"]
    },
    "special_instructions": "Extra crispy"
  }],
  "promo_code": "WELCOME30"
}

// Response 201
{
  "success": true,
  "data": {
    "id": "uuid",
    "order_number": "PIZ-20260307-0145",
    "invoice_number": null,           // Assigned on CONFIRMED
    "status": "initiated",
    "subtotal": 478.00,
    "cgst": 5.98,
    "sgst": 5.98,
    "discount": 143.40,
    "total": 346.56,
    "expires_at": "2026-03-07T08:00:00Z",  // 15-min TTL
    "created_at": "2026-03-07T07:45:00Z"
  }
}
```

### 6.7 PUT /admin/orders/:id/status

```json
// Request
{ "status": "confirmed", "notes": "Kitchen accepted" }

// All transitions are validated against the allowed-transition table.
// Illegal transitions return 422.

// Response 200
{ "success": true, "data": { "id": "uuid", "status": "confirmed", "invoice_number": "IITH-FY26-000145" } }
```

### 6.8 Order Status → Display Labels

| DB Status | Customer Label | Admin Label | Terminal? |
|-----------|---------------|-------------|----------|
| `initiated` | "Order Created" | "Awaiting Payment" | ❌ |
| `payment_pending` | "Processing Payment..." | "Payment Pending" | ❌ |
| `payment_success` | "Payment Confirmed ✅" | "Payment Received" | ❌ |
| `confirmed` | "Order Confirmed 👨‍🍳" | "Confirmed" | ❌ |
| `preparing` | "Being Prepared 🍳" | "In Kitchen" | ❌ |
| `ready` (pickup) | "Ready for Pickup 🛍️" | "Ready for Collection" | ❌ |
| `ready` (dinein) | "Ready for Dine-in 🍽️" | "Ready at Table" | ❌ |
| `ready` (delivery) | "Out for Delivery 🚚" | "Dispatched" | ❌ |
| `delivered` | "Delivered ✅" | "Completed" | ✅ |
| `cancelled` | "Order Cancelled" | "Cancelled" | ✅ |
| `refunded` | "Refund Processed" | "Refunded" | ✅ |
| `expired` | "Order Expired" | "Expired (unpaid)" | ✅ |

---

## 7. Module 5 — Payments

> **⚠️ Critical Rule**: Frontend payment success callbacks are **NOT trusted**. Only the Razorpay **server-side webhook** (verified with HMAC SHA256) updates the order state to `payment_success`.

### 7.1 Payment Engine Features

| Feature | Implementation |
|---------|---------------|
| **Razorpay Order API** | Creates a Razorpay order before redirecting customer |
| **Webhook verification** | HMAC SHA256 — `razorpay_order_id + '|' + razorpay_payment_id`, key = `RAZORPAY_WEBHOOK_SECRET` |
| **Idempotency enforcement** | `idempotency_key` on orders table; duplicate requests return existing order |
| **Payment reconciliation** | Nightly cron: compare Razorpay dashboard vs DB, flag mismatches |
| **Partial refund support** | `refund_amount` + `refund_razorpay_id` stored; credit note generated |
| **TTL expiry** | 15-min cron: orders stuck in `initiated` or `payment_pending` → `expired` |

### 7.2 Razorpay Webhook Flow

```mermaid
sequenceDiagram
    Customer->>API: POST /orders → status: initiated
    API->>Razorpay: Create Razorpay order
    Razorpay-->>API: razorpay_order_id
    API-->>Customer: { razorpay_order_id, amount, key_id }
    API->>DB: status → payment_pending, expires_at set

    Customer->>Razorpay: Complete payment (UPI / Card / Net Banking)
    Razorpay->>API: POST /webhooks/razorpay (payment.captured event)
    API->>API: Verify HMAC SHA256 signature against RAZORPAY_WEBHOOK_SECRET
    Note right of API: Frontend callback ignored — webhook is source of truth
    API->>DB: status → payment_success (atomic transaction)
    API->>DB: Create payment_transaction (method=razorpay, status=captured)
    API->>Notification: WhatsApp + FCM: payment confirmed
    API->>API: Auto-advance → confirmed, assign invoice_number

    Customer->>API: GET /orders/:id (polls for status)
    API-->>Customer: { status: confirmed, invoice_number: IITH-FY26-000145 }
```

### 7.3 Endpoints

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| POST | `/payments/razorpay/create` | Create Razorpay order (→ `payment_pending`) | Optional |
| POST | `/webhooks/razorpay` | Razorpay webhook receiver (HMAC verified) | Webhook secret |
| POST | `/payments/cash/confirm` | Mark cash/UPI order as paid — staff action | ✅ staff+ |
| POST | `/admin/payments/:orderId/refund` | Initiate full or partial refund via Razorpay API | ✅ admin+ |
| GET | `/payments/:orderId/receipt` | Payment receipt | Optional |
| GET | `/admin/payments/reconcile` | Run reconciliation report | ✅ admin+ |

### 7.4 POST /payments/razorpay/create

```json
// Request
{ "order_id": "order-uuid" }

// Response 200
{
  "success": true,
  "data": {
    "razorpay_order_id": "order_xxx",
    "amount": 34656,      // In paise (₹346.56 × 100)
    "currency": "INR",
    "key_id": "rzp_live_xxx",
    "order_number": "PIZ-20260307-0145",
    "expires_at": "2026-03-07T08:00:00Z"
  }
}
```

### 7.5 POST /webhooks/razorpay

```typescript
// Webhook handler (NestJS)
@Post('/webhooks/razorpay')
async handleRazorpayWebhook(
  @Body() body: any,
  @Headers('x-razorpay-signature') signature: string
) {
  // 1. Verify signature
  const expectedSig = crypto
    .createHmac('sha256', process.env.RAZORPAY_WEBHOOK_SECRET)
    .update(JSON.stringify(body))
    .digest('hex');
  if (expectedSig !== signature) throw new ForbiddenException('INVALID_WEBHOOK_SIGNATURE');

  // 2. Process event
  if (body.event === 'payment.captured') {
    const { razorpay_order_id, razorpay_payment_id } = body.payload.payment.entity;
    // 3. Atomic state transition (idempotent — safe to re-process)
    await this.ordersService.handlePaymentCaptured({ razorpay_order_id, razorpay_payment_id });
  }
  return { status: 'ok' };
}
```

**Webhook processes these events:**

| Razorpay Event | Order Transition | Action |
|---------------|-----------------|--------|
| `payment.captured` | `payment_pending` → `payment_success` → `confirmed` | Assign invoice number, notify WhatsApp |
| `payment.failed` | `payment_pending` → `expired` | Notify customer |
| `refund.processed` | `delivered` / `cancelled` → `refunded` | Generate credit note |

### 7.6 POST /admin/payments/:orderId/refund

```json
// Request
{
  "refund_type": "partial",           // 'full' | 'partial'
  "amount": 199.00,                   // For partial refunds
  "reason": "Item unavailable"
}

// Response 200
{
  "success": true,
  "data": {
    "order_number": "PIZ-20260307-0145",
    "status": "refunded",
    "refund_amount": 199.00,
    "refund_razorpay_id": "rfnd_xxx",
    "credit_note_number": "IITH-FY26-CN-000012"
  }
}
```

---

## 8. Module 6 — Inventory

### 8.1 Endpoints

| Method | Path | Description | Auth | Role |
|--------|------|-------------|------|------|
| GET | `/admin/inventory` | List all inventory items | ✅ | kitchen+ |
| GET | `/admin/inventory/low-stock` | Items below threshold | ✅ | kitchen+ |
| PUT | `/admin/inventory/:id` | Update stock level | ✅ | kitchen+ |
| POST | `/admin/inventory/:id/restock` | Log a restock event | ✅ | admin+ |
| DELETE | `/admin/inventory/:id` | Remove inventory item | ✅ | admin+ |

### 8.2 GET /admin/inventory

```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "outlet_id": "main-campus-uuid",
      "name": "Mozzarella Cheese",
      "category": "Dairy",
      "stock": 85,
      "unit": "kg",
      "low_stock_threshold": 15,
      "status": "in_stock",   // Computed: in_stock | moderate | low_stock
      "last_restock": "2026-02-25"
    }
  ]
}
```

---

## 9. Module 7 — Analytics & Reporting

### 9.1 Endpoints

| Method | Path | Description | Auth | Role |
|--------|------|-------------|------|------|
| GET | `/admin/reports/daily` | Hourly breakdown for a date | ✅ | admin+ |
| GET | `/admin/reports/weekly` | Daily breakdown for a week | ✅ | admin+ |
| GET | `/admin/reports/monthly` | Weekly/daily breakdown | ✅ | admin+ |
| GET | `/admin/reports/quarterly` | Monthly breakdown | ✅ | admin+ |
| GET | `/admin/reports/half-yearly` | 6-month breakdown | ✅ | admin+ |
| GET | `/admin/reports/annual` | 12-month breakdown | ✅ | admin+ |
| GET | `/admin/reports/gst` | GST summary (CGST + SGST) | ✅ | admin+ |
| GET | `/admin/reports/export` | Download PDF / CSV | ✅ | admin+ |

**Query params**: `?outlet_id=uuid&date=2026-03-06` (daily), `?period=2026-03` (monthly), etc.

### 9.2 GET /admin/reports/daily

```json
{
  "success": true,
  "data": {
    "outlet": "Fresco's — Main Campus",
    "date": "2026-03-06",
    "summary": {
      "order_count": 47,
      "subtotal": 12800.00,
      "cgst_collected": 160.00,
      "sgst_collected": 160.00,
      "total_gst": 320.00,
      "gross_revenue": 14050.00,
      "avg_order_value": 299.00
    },
    "hourly": [
      { "hour": 8, "orders": 3, "revenue": 890.00 },
      { "hour": 9, "orders": 5, "revenue": 1450.00 }
    ],
    "top_items": [
      { "name": "Margherita Pizza", "qty": 18, "revenue": 3582.00 }
    ]
  }
}
```

### 9.3 GET /admin/reports/gst

```json
{
  "success": true,
  "data": {
    "outlet": "Fresco's — Main Campus",
    "gstin": "29AABCF1234C1Z5",
    "period": "2026-03",
    "invoice_count": 412,
    "taxable_amount": 98500.00,
    "cgst_collected": 1231.25,
    "sgst_collected": 1231.25,
    "total_gst_collected": 2462.50,
    "gross_revenue": 107450.00
  }
}
```

---

## 10. Module 8 — Admin Operations

### 10.1 Outlets

| Method | Path | Description | Role |
|--------|------|-------------|------|
| GET | `/admin/outlets` | List all outlets | staff+ |
| POST | `/admin/outlets` | Create outlet | super_admin |
| PUT | `/admin/outlets/:id` | Update outlet config | admin+ |
| GET | `/admin/outlets/:id/qr/:table` | Get table QR code | admin+ |
| POST | `/admin/outlets/:id/qr/generate` | Generate all table QRs (ZIP) | admin+ |

### 10.2 Staff

| Method | Path | Description | Role |
|--------|------|-------------|------|
| GET | `/admin/staff` | List all staff | admin+ |
| POST | `/admin/staff` | Add new staff member | super_admin |
| PUT | `/admin/staff/:id` | Update role / outlet | super_admin |
| DELETE | `/admin/staff/:id` | Deactivate staff | super_admin |

### 10.3 Customers

| Method | Path | Description | Role |
|--------|------|-------------|------|
| GET | `/admin/customers` | Customer list with stats | admin+ |
| GET | `/admin/customers/export` | CSV export | admin+ |

### 10.4 Promotions

| Method | Path | Description | Role |
|--------|------|-------------|------|
| GET | `/admin/promos` | List all promo codes | admin+ |
| POST | `/admin/promos` | Create promo code | admin+ |
| PUT | `/admin/promos/:id` | Update promo | admin+ |
| DELETE | `/admin/promos/:id` | Deactivate promo | admin+ |
| GET | `/promos/:code/validate` | Validate code for order | ✅ (customer) |

### 10.5 QR Code Format

The table QR code encodes a signed JWT payload:

```json
{
  "outlet": "main-campus",
  "table": 7,
  "iat": 1234567890
}
```

Signed with the app's private key. The customer app verifies the signature before applying the table context.

---

## 11. Module 9 — Notifications

> **Primary channel: WhatsApp.** Works for QR guest users (no app needed). FCM is secondary for app users.

### 11.1 Notification Engine

| Feature | Implementation |
|---------|---------------|
| **WhatsApp order confirmation** | Primary channel — sent on `confirmed` for ALL orders including QR guests |
| **Status updates** | WhatsApp + FCM at key milestones: confirmed, ready, delivered |
| **Retry logic** | 3 attempts with exponential backoff (1s → 5s → 15s) |
| **Dead-letter queue** | Failed after 3 attempts → written to `notification_dlq` table for manual review |
| **Delivery receipts** | WhatsApp webhook tracks delivered/read status |
| **Broadcast** | Admin can send promo/system messages to customer segments |

### 11.2 Notification Architecture

```mermaid
sequenceDiagram
    OrderService->>NotificationQueue: Enqueue { event, orderId, channel, recipient }
    NotificationQueue->>NotificationWorker: Dequeue message
    NotificationWorker->>WhatsAppAPI: Send message
    WhatsAppAPI-->>NotificationWorker: { status: delivered | failed }
    alt Delivered
        NotificationWorker->>DB: notifications.is_delivered = true
    else Failed (attempt < 3)
        NotificationWorker->>NotificationQueue: Re-enqueue with backoff delay
    else Failed (attempt >= 3)
        NotificationWorker->>DB: INSERT notification_dlq (for manual review)
    end
```

### 11.3 Notification Triggers by Status

| Order Status | WhatsApp | FCM | Recipient | Message |
|-------------|---------|------|---------|--------|
| `confirmed` | ✅ Primary | ✅ | Customer | "✅ Order IITH-FY26-000145 confirmed! ETA 25 min." |
| `preparing` | ❌ | ✅ | Customer (app) | "👨‍🍳 Kitchen is preparing your order…" |
| `ready` (pickup) | ✅ | ✅ | Customer | "🛍️ Your order is ready for pickup at [outlet]!" |
| `ready` (dine-in) | ❌ | ✅ | Customer (app) | "🍽️ Your order is ready at your table!" |
| `ready` (delivery) | ✅ | ✅ | Customer | "🚚 Your order is on the way!" |
| `delivered` | ✅ | ✅ | Customer | "✅ Delivered! Download your invoice: [link]" |
| `payment_success` | ✅ | ✅ | Customer | "💳 Payment ₹XXX received. Invoice: IITH-FY26-000145" |
| `cancelled` | ✅ | ✅ | Customer | "❌ Order cancelled. Refund initiated if applicable." |
| `refunded` | ✅ | ✅ | Customer | "💰 Refund of ₹XXX processed. Credit note: [link]" |
| `new order` | ❌ | ❌ | Admin (WS) | WebSocket + sound alert + badge +1 |
| `low stock` | ❌ | ❌ | Admin (WS) | "⚠️ [Item] running low: [qty] [unit] remaining" |

### 11.4 Dead-Letter Queue Table

```sql
CREATE TABLE notification_dlq (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    notification_id UUID REFERENCES notifications(id),
    channel        VARCHAR(20) NOT NULL,   -- 'whatsapp' | 'fcm'
    recipient      VARCHAR(50) NOT NULL,   -- phone or FCM token
    payload        JSONB NOT NULL,
    attempts       INT NOT NULL DEFAULT 3,
    last_error     TEXT,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 11.5 Endpoints

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| GET | `/notifications` | Customer notifications | ✅ |
| PUT | `/notifications/:id/read` | Mark as read | ✅ |
| PUT | `/notifications/read-all` | Mark all as read | ✅ |
| POST | `/admin/notifications/broadcast` | Send broadcast to all/segment | ✅ admin+ |
| GET | `/admin/notifications/dlq` | View dead-letter queue | ✅ admin+ |
| POST | `/admin/notifications/dlq/:id/retry` | Manually retry failed notification | ✅ admin+ |

### 11.6 POST /admin/notifications/broadcast

```json
// Request
{
  "title": "Weekend Special 🍕",
  "body": "Use code PIZZABOGO for Buy 1 Get 1 this Saturday!",
  "channels": ["whatsapp", "fcm"],
  "target": "all_customers",   // 'all_customers' | 'segment' | 'user_ids'
  "user_ids": []
}
```

---

## 12. WebSocket Events

**Connection**: `wss://api.fresco-kitchen.com/ws?token=<access_token>`

| Event | Direction | Payload | Consumer |
|-------|-----------|---------|---------|
| `order.new` | Server → Admin | `{ order }` | Admin portal |
| `order.status_changed` | Server → Customer + Admin | `{ orderId, status, updatedAt }` | Both |
| `order.eta_updated` | Server → Customer | `{ orderId, newEta }` | Customer app |
| `payment.received` | Server → Admin | `{ orderId, method, amount }` | Admin portal |
| `inventory.low_stock` | Server → Admin | `{ itemId, name, stock, unit }` | Admin portal |
| `notification.new` | Server → Customer | `{ title, body, type }` | Customer app |
| `admin.status_update` | Admin → Server | `{ orderId, newStatus }` | Server (broadcasts) |

---

## 13. Error Handling

### 13.1 HTTP Status Codes

| Code | Usage |
|------|-------|
| 200 | Success |
| 201 | Resource created |
| 400 | Bad request / validation error |
| 401 | Unauthenticated (missing/invalid token) |
| 403 | Forbidden (insufficient role) |
| 404 | Resource not found |
| 409 | Conflict (e.g., promo already used) |
| 422 | Unprocessable entity (business rule violation) |
| 429 | Rate limited |
| 500 | Internal server error |

### 13.2 Business Error Codes

| Code | Module | Meaning |
|------|--------|---------|
| `OTP_RATE_LIMITED` | Auth | > 3 OTP requests / 15 min |
| `OTP_EXPIRED` | Auth | OTP TTL exceeded |
| `OTP_INVALID` | Auth | Wrong OTP |
| `OTP_MAX_ATTEMPTS` | Auth | > 5 wrong attempts |
| `TOKEN_EXPIRED` | Auth | JWT expired |
| `TOKEN_REVOKED` | Auth | Refresh token revoked |
| `ORDER_NOT_FOUND` | Orders | Order ID doesn't exist |
| `INVALID_STATUS_TRANSITION` | Orders | Attempted unlisted state transition |
| `ORDER_NOT_CANCELLABLE` | Orders | Status is `preparing` / `ready` / `delivered` |
| `ORDER_EXPIRED` | Orders | Order TTL exceeded — customer must re-order |
| `ITEM_UNAVAILABLE` | Orders | Menu item not available |
| `OUTLET_CLOSED` | Orders | Outlet not accepting orders |
| `PROMO_EXPIRED` | Orders | Promo past valid_till |
| `PROMO_ALREADY_USED` | Orders | Customer already used this promo |
| `PROMO_MIN_ORDER` | Orders | Order below promo minimum |
| `PAYMENT_SIGNATURE_INVALID` | Payments | Razorpay HMAC SHA256 mismatch |
| `PAYMENT_WEBHOOK_ONLY` | Payments | Frontend payment signal rejected — webhook only |
| `PAYMENT_ALREADY_CAPTURED` | Payments | Order already paid (idempotency) |
| `REFUND_EXCEEDS_AMOUNT` | Payments | Partial refund > original amount |
| `STOCK_INSUFFICIENT` | Inventory | Stock below requested quantity |

---

## 14. Security

| Concern | Implementation |
|---------|---------------|
| **Transport** | HTTPS everywhere (TLS 1.2+) |
| **JWT Algorithm** | RS256 (asymmetric: private key signs, public key verifies) |
| **OTP hashing** | bcrypt (12 rounds) before DB storage |
| **OTP rate limiting** | 3 requests / 15 min per phone (Redis counter) |
| **OTP expiry** | 10 minutes, single use |
| **Refresh tokens** | SHA-256 hashed before DB storage |
| **Token blacklist** | Revoked tokens tracked in Redis |
| **RBAC** | JWT `role` claim checked via `RolesGuard` on every endpoint |
| **Input validation** | NestJS `ValidationPipe` with `class-validator` DTOs |
| **SQL injection** | TypeORM parameterized queries (no raw SQL with user input) |
| **Razorpay security** | HMAC-SHA256 signature verified server-side |
| **DB connections** | SSL/TLS encrypted PostgreSQL connection |
| **Secrets management** | Environment variables, never committed to git |
| **CORS** | Whitelist allowed origins (`app.fresco-kitchen.com`, localhost) |
| **Helmet** | HTTP security headers (HSTS, XSS protection, etc.) |

---

## 15. Infrastructure & Deployment

### 15.1 Docker Compose (v1 — Launch)

```yaml
version: '3.9'
services:
  api:
    build: ./backend
    ports: ["3000:3000"]
    environment:
      DATABASE_URL: postgres://postgres:secret@db:5432/frescos
      REDIS_URL: redis://cache:6379
      JWT_PRIVATE_KEY_PATH: /secrets/private.pem
      RAZORPAY_KEY_ID: rzp_live_xxx
      RAZORPAY_KEY_SECRET: xxx
      TWILIO_ACCOUNT_SID: ACxxx
      TWILIO_AUTH_TOKEN: xxx
      TWILIO_PHONE: +1555xxx
    depends_on: [db, cache]

  db:
    image: postgres:15-alpine
    volumes: [pgdata:/var/lib/postgresql/data]
    environment:
      POSTGRES_DB: frescos
      POSTGRES_PASSWORD: secret

  cache:
    image: redis:7-alpine
    command: redis-server --requirepass secret

  nginx:
    image: nginx:alpine
    ports: ["80:80", "443:443"]
    volumes: [./nginx.conf:/etc/nginx/nginx.conf, ./certs:/etc/ssl]

volumes:
  pgdata:
```

### 15.2 Production (v2)

| Component | Service |
|-----------|---------|
| API | AWS ECS (Fargate) or Google Cloud Run |
| Database | AWS RDS PostgreSQL (Multi-AZ) |
| Cache | AWS ElastiCache for Redis |
| Media | AWS S3 + CloudFront CDN |
| Secrets | AWS Secrets Manager |
| Monitoring | Datadog or AWS CloudWatch |
| CI/CD | GitHub Actions → ECR → ECS deploy |

### 15.3 Environment Variables

```bash
# Server
PORT=3000
NODE_ENV=production

# Database
DATABASE_URL=postgres://user:pass@host:5432/frescos?sslmode=require

# Redis
REDIS_URL=redis://:password@host:6379

# JWT
JWT_PRIVATE_KEY_PATH=/run/secrets/jwt_private.pem
JWT_PUBLIC_KEY_PATH=/run/secrets/jwt_public.pem
JWT_ACCESS_EXPIRES=30m
JWT_REFRESH_EXPIRES=30d

# Razorpay
RAZORPAY_KEY_ID=rzp_live_xxx
RAZORPAY_KEY_SECRET=xxx

# Twilio
TWILIO_ACCOUNT_SID=ACxxx
TWILIO_AUTH_TOKEN=xxx
TWILIO_PHONE_NUMBER=+1555xxx

# Firebase
FIREBASE_PROJECT_ID=frescos-kitchen
FIREBASE_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----...

# WhatsApp
WHATSAPP_PHONE=+91XXXXXXXXXX

# AWS
AWS_S3_BUCKET=frescos-media
AWS_REGION=ap-south-1
```
