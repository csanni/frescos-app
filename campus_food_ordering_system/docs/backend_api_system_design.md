# Fresco's Kitchen — Backend API System Design

**Version:** 2.0 · **Date:** 7 March 2026 · **Author:** Engineering Team  
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
9. [Module 7 — Analytics, Reporting & ML (FastAPI)](#9-module-7--analytics-reporting--ml-fastapi)
10. [Module 8 — Admin Operations](#10-module-8--admin-operations)
11. [Module 9 — Notifications](#11-module-9--notifications)
12. [WebSocket Events](#12-websocket-events)
13. [Error Handling](#13-error-handling)
14. [Security](#14-security)
15. [Edge Case Handling Matrix](#15-edge-case-handling-matrix)
16. [Infrastructure & Deployment](#16-infrastructure--deployment)
17. [Technology Decision Record](#17-technology-decision-record)

---

## 1. Overview

> **Hybrid Architecture** — The backend is split into two services: a **NestJS gateway** that owns all customer-facing APIs, WebSockets, and business logic, and a **FastAPI analytics microservice** that owns reporting, ML-powered recommendations, and data exports. Clients always talk to the NestJS gateway; it proxies analytics requests internally.

### 1.1 Service Matrix

| | **API Gateway** | **Analytics Service** |
|---|---|---|
| **Runtime** | Node.js 20 LTS | Python 3.12 |
| **Framework** | NestJS (TypeScript) | FastAPI (Pydantic v2) |
| **Port** | 3000 | 8000 |
| **Owns** | Auth, Users, Menu, Orders, Payments, Inventory, Admin, Notifications, WebSocket | Reports, GST Summaries, ML Recommendations, CSV/PDF Exports |
| **Database access** | Read/Write (TypeORM) | **Read-only replica** (SQLAlchemy 2.0 async) |
| **Inter-service** | Proxies `/admin/reports/*`, `/recommendations/*` → analytics:8000 | Receives proxied requests from gateway |

### 1.2 Shared Infrastructure

| Attribute | Value |
|-----------|-------|
| **API Style** | REST (primary) + WebSocket (real-time) |
| **Authentication** | JWT (RS256) + OTP via MSG91 |
| **Database** | PostgreSQL 15 (primary) + read replica |
| **Cache** | Redis 7 |
| **Payment** | Razorpay |
| **SMS / OTP** | MSG91 (DLT-compliant, India-optimised) |
| **WhatsApp** | Meta WhatsApp Cloud API (direct, no middleman) |
| **Push** | Firebase Cloud Messaging (FCM) |
| **Media** | Cloudflare R2 / MinIO |
| **Base URL** | `https://api.fresco-kitchen.com/api/v1` |
| **Content-Type** | `application/json` |
| **Rate Limiting** | Global: 100 req/min per IP |

### 1.3 Modules Summary

| # | Module | Service | Endpoints | Auth Required |
|---|--------|---------|-----------|---------------|
| 1 | Authentication | NestJS Gateway | 5 | Partial |
| 2 | Users | NestJS Gateway | 6 | ✅ |
| 3 | Menu & Content | NestJS Gateway | 10 | Partial |
| 4 | Orders | NestJS Gateway | 9 | ✅ |
| 5 | Payments | NestJS Gateway | 4 | ✅ |
| 6 | Inventory | NestJS Gateway | 5 | ✅ (staff+) |
| 7 | Analytics, Reporting & ML | **FastAPI** | 11 | ✅ (admin+) |
| 8 | Admin Operations | NestJS Gateway | 10 | ✅ (admin+) |
| 9 | Notifications | NestJS Gateway | 4 | ✅ |

---

## 2. Architecture

### 2.1 Microservice Topology

```mermaid
flowchart TB
    subgraph Clients
        FLUTTER["Flutter App (Customer)"]
        ADMIN["Admin Portal (Web)"]
        BROWSER["QR Browser Order"]
    end

    subgraph Edge
        NGINX["Nginx Reverse Proxy\nTLS termination"]
    end

    subgraph Services
        NEST["NestJS Gateway :3000\n(TypeScript)\nAuth · Users · Menu · Orders\nPayments · Inventory · Admin\nNotifications · WebSocket"]
        FAST["FastAPI Analytics :8000\n(Python 3.12)\nReports · GST · ML Recs\nCSV/PDF Export"]
    end

    subgraph Data
        PG_PRIMARY[("PostgreSQL 15\nPrimary (R/W)")]
        PG_REPLICA[("PostgreSQL 15\nRead Replica")]
        REDIS[("Redis 7\nCache + Pub/Sub")]
        R2[("Cloudflare R2 / MinIO\nMedia + Reports")]
    end

    subgraph External
        RAZORPAY["Razorpay"]
        MSG91["MSG91 SMS/OTP"]
        FCM["Firebase FCM"]
        WHATSAPP["Meta WhatsApp\nCloud API"]
    end

    FLUTTER & ADMIN & BROWSER --> NGINX
    NGINX --> NEST
    NEST -- "internal HTTP\n/admin/reports/*\n/recommendations/*" --> FAST
    NEST --> PG_PRIMARY
    NEST --> REDIS
    FAST --> PG_REPLICA
    FAST --> REDIS
    FAST --> R2
    NEST --> RAZORPAY & MSG91 & FCM & WHATSAPP
```

### 2.2 Request Lifecycle — Standard (NestJS)

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

### 2.3 Request Lifecycle — Analytics (FastAPI via Gateway Proxy)

```mermaid
sequenceDiagram
    Admin Portal->>Nginx: GET /api/v1/admin/reports/daily
    Nginx->>NestJS: Proxy pass
    NestJS->>Guard: JWT validation + RBAC (admin+ only)
    Guard-->>NestJS: Authorized ✅
    NestJS->>FastAPI: Internal proxy → http://analytics:8000/reports/daily
    Note right of NestJS: Forwards JWT payload as X-User-Id,<br/>X-User-Role headers
    FastAPI->>PG Replica: Async SQLAlchemy query
    PG Replica-->>FastAPI: Result
    FastAPI->>Redis: Cache result (TTL 5 min)
    FastAPI-->>NestJS: JSON response
    NestJS-->>Admin Portal: Wrapped in standard envelope
```

### 2.4 NestJS Gateway — Module Structure

```
backend/
├── src/
│   ├── main.ts                    # Bootstrap, Swagger, CORS, global pipes
│   ├── app.module.ts              # Root module
│   ├── modules/
│   │   ├── auth/                  # Module 1
│   │   ├── users/                 # Module 2
│   │   ├── menu/                  # Module 3
│   │   ├── orders/                # Module 4
│   │   ├── payments/              # Module 5
│   │   ├── inventory/             # Module 6
│   │   ├── analytics-proxy/       # Module 7 — Proxy to FastAPI (no business logic)
│   │   ├── admin/                 # Module 8
│   │   └── notifications/         # Module 9
│   ├── shared/
│   │   ├── guards/                # JwtAuthGuard, RolesGuard
│   │   ├── decorators/            # @Roles(), @CurrentUser()
│   │   ├── interceptors/          # LoggingInterceptor, TransformInterceptor
│   │   ├── filters/               # GlobalExceptionFilter
│   │   └── utils/                 # GSTCalculator, OrderNumberGenerator
│   └── config/
│       ├── database.config.ts
│       ├── redis.config.ts
│       ├── jwt.config.ts
│       └── razorpay.config.ts
```

### 2.5 FastAPI Analytics Service — Project Structure

```
analytics-service/
├── app/
│   ├── main.py                    # FastAPI app, lifespan, middleware
│   ├── config.py                  # Pydantic Settings (env vars)
│   ├── database.py                # AsyncEngine + sessionmaker (read-only replica)
│   ├── dependencies.py            # get_db, get_redis, verify_internal_auth
│   ├── routers/
│   │   ├── reports.py             # /reports/daily, weekly, monthly, etc.
│   │   ├── gst.py                 # /reports/gst
│   │   ├── recommendations.py     # /recommendations/trending, personal, upsell
│   │   └── exports.py             # /reports/export (CSV, PDF)
│   ├── services/
│   │   ├── report_service.py      # Report aggregation queries
│   │   ├── gst_service.py         # GST computation logic
│   │   ├── recommendation_engine.py  # ML recommendation logic
│   │   └── export_service.py      # PDF (WeasyPrint) + CSV generation
│   ├── ml/
│   │   ├── models/                # Serialised model files (.joblib / .pkl)
│   │   ├── training/              # Offline training scripts (scheduled)
│   │   │   ├── demand_forecast.py
│   │   │   └── collaborative_filter.py
│   │   └── inference.py           # Load model → predict
│   └── schemas/
│       ├── report_schemas.py      # Pydantic response models
│       └── recommendation_schemas.py
├── tests/
│   ├── test_reports.py
│   ├── test_recommendations.py
│   └── conftest.py
├── Dockerfile
├── pyproject.toml                 # Dependencies (uv / poetry)
└── alembic/                       # DB migrations (read-only, schema-aware)
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
    API->>MSG91: Send OTP SMS (DLT-registered template)
    MSG91-->>User: OTP via SMS
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
    INITIATED --> CONFIRMED : Cash or UPI at store
    INITIATED --> EXPIRED : Cron - 15 min TTL unpaid
    PAYMENT_PENDING --> PAYMENT_SUCCESS : Razorpay webhook HMAC SHA256
    PAYMENT_PENDING --> EXPIRED : Cron - 15 min TTL
    PAYMENT_SUCCESS --> CONFIRMED : Auto-confirm or kitchen accepts
    CONFIRMED --> PREPARING : Kitchen starts cooking
    CONFIRMED --> CANCELLED : Admin cancels before PREPARING
    PREPARING --> READY
    READY --> DELIVERED : Customer slide-to-accept or admin
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
| **Downloadable PDF** | Generated server-side (Puppeteer / PDFKit), stored in Cloudflare R2 |
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

## 9. Module 7 — Analytics, Reporting & ML (FastAPI)

> **Service:** `analytics-service` · **Runtime:** Python 3.12 · **Framework:** FastAPI + Pydantic v2  
> **Database:** PostgreSQL 15 **read replica** (SQLAlchemy 2.0 async) · **ML:** scikit-learn + pandas  
> This module runs as a **separate microservice**. The NestJS gateway proxies all requests after JWT validation.

### 9.1 Inter-Service Communication

```mermaid
sequenceDiagram
    Admin Portal->>NestJS Gateway: GET /api/v1/admin/reports/daily?outlet_id=X&date=Y
    NestJS Gateway->>NestJS Gateway: JWT verify + RolesGuard(admin+)
    NestJS Gateway->>FastAPI: GET http://analytics:8000/reports/daily?outlet_id=X&date=Y
    Note right of NestJS Gateway: Headers forwarded:<br/>X-User-Id, X-User-Role,<br/>X-Request-Id (tracing)
    FastAPI->>PG Read Replica: Async aggregation query
    PG Read Replica-->>FastAPI: Result rows
    FastAPI->>Redis: Cache with key report:daily:{outlet}:{date} TTL 5m
    FastAPI-->>NestJS Gateway: { outlet, date, summary, hourly, top_items }
    NestJS Gateway-->>Admin Portal: { success: true, data: { ... } }
```

**NestJS Proxy Module** (`analytics-proxy/`):

```typescript
// modules/analytics-proxy/analytics-proxy.controller.ts
@Controller('admin/reports')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin', 'super_admin')
export class AnalyticsProxyController {
  constructor(private readonly httpService: HttpService) {}

  @All('*')
  async proxyToAnalytics(@Req() req: Request, @CurrentUser() user: JwtPayload) {
    const analyticsUrl = `${process.env.ANALYTICS_SERVICE_URL}${req.path.replace('/api/v1/admin/', '/')}`;
    const response = await this.httpService.axiosRef({
      method: req.method,
      url: analyticsUrl,
      params: req.query,
      data: req.body,
      headers: {
        'X-User-Id': user.sub,
        'X-User-Role': user.role,
        'X-Request-Id': req.headers['x-request-id'],
      },
    });
    return { success: true, data: response.data };
  }
}
```

**FastAPI Internal Auth** (verifies request came from gateway, not external):

```python
# app/dependencies.py
async def verify_internal_auth(request: Request):
    """Ensures requests only come from the NestJS gateway (internal network)."""
    user_id = request.headers.get("X-User-Id")
    user_role = request.headers.get("X-User-Role")
    if not user_id or not user_role:
        raise HTTPException(status_code=403, detail="Direct access forbidden")
    if user_role not in ("admin", "super_admin"):
        raise HTTPException(status_code=403, detail="Insufficient role")
    return {"user_id": user_id, "role": user_role}
```

### 9.2 Report Endpoints (FastAPI Internal)

> **External URL** (via gateway): `/api/v1/admin/reports/*`  
> **Internal URL** (FastAPI direct): `http://analytics:8000/reports/*`

| Method | Internal Path | External Path (via gateway) | Description |
|--------|--------------|---------------------------|-------------|
| GET | `/reports/daily` | `/admin/reports/daily` | Hourly breakdown for a date |
| GET | `/reports/weekly` | `/admin/reports/weekly` | Daily breakdown for a week |
| GET | `/reports/monthly` | `/admin/reports/monthly` | Weekly/daily breakdown |
| GET | `/reports/quarterly` | `/admin/reports/quarterly` | Monthly breakdown |
| GET | `/reports/half-yearly` | `/admin/reports/half-yearly` | 6-month breakdown |
| GET | `/reports/annual` | `/admin/reports/annual` | 12-month breakdown |
| GET | `/reports/gst` | `/admin/reports/gst` | GST summary (CGST + SGST) |
| GET | `/reports/export` | `/admin/reports/export` | Download PDF / CSV |

**Query params**: `?outlet_id=uuid&date=2026-03-06` (daily), `?period=2026-03` (monthly), etc.

### 9.3 ML-Powered Recommendation Endpoints (New)

| Method | Internal Path | External Path (via gateway) | Description |
|--------|--------------|---------------------------|-------------|
| GET | `/recommendations/trending` | `/recommendations/trending` | Top trending items by outlet (last 7 days) |
| GET | `/recommendations/personal/:userId` | `/recommendations/personal/:userId` | Personalised picks based on order history |
| GET | `/recommendations/upsell/:menuItemId` | `/recommendations/upsell/:menuItemId` | "Frequently bought together" items |

### 9.4 Recommendation Engine

```python
# app/services/recommendation_engine.py
from sklearn.neighbors import NearestNeighbors
import pandas as pd
import joblib
from functools import lru_cache

class RecommendationEngine:
    """Collaborative filtering + popularity-based hybrid recommender."""

    def __init__(self, model_path: str = "app/ml/models/collab_filter.joblib"):
        self.model: NearestNeighbors = joblib.load(model_path)
        self.item_vectors: pd.DataFrame = joblib.load("app/ml/models/item_vectors.joblib")

    async def trending(self, outlet_id: str, days: int = 7, limit: int = 10) -> list[dict]:
        """Top items by order frequency in the last N days (popularity-based)."""
        query = """
            SELECT mi.id, mi.name, mi.slug, COUNT(*) as order_count,
                   SUM(oi.subtotal) as revenue
            FROM order_items oi
            JOIN menu_items mi ON oi.menu_item_id = mi.id
            JOIN orders o ON oi.order_id = o.id
            WHERE o.outlet_id = :outlet_id
              AND o.created_at >= NOW() - INTERVAL :days DAY
              AND o.status NOT IN ('expired', 'cancelled')
            GROUP BY mi.id, mi.name, mi.slug
            ORDER BY order_count DESC
            LIMIT :limit
        """
        # Executed via async SQLAlchemy session
        ...

    async def personal(self, user_id: str, limit: int = 5) -> list[dict]:
        """Collaborative filtering: find similar users → recommend their top items."""
        user_vector = await self._get_user_vector(user_id)
        distances, indices = self.model.kneighbors([user_vector], n_neighbors=20)
        # Aggregate top items from similar users, exclude already-ordered
        ...

    async def upsell(self, menu_item_id: str, limit: int = 3) -> list[dict]:
        """Frequently bought together — association rule mining."""
        query = """
            SELECT mi2.id, mi2.name, mi2.slug, COUNT(*) as co_occurrence
            FROM order_items oi1
            JOIN order_items oi2 ON oi1.order_id = oi2.order_id AND oi1.menu_item_id != oi2.menu_item_id
            JOIN menu_items mi2 ON oi2.menu_item_id = mi2.id
            WHERE oi1.menu_item_id = :menu_item_id
            GROUP BY mi2.id, mi2.name, mi2.slug
            ORDER BY co_occurrence DESC
            LIMIT :limit
        """
        ...
```

### 9.5 ML Training Pipeline

```mermaid
flowchart LR
    CRON["Scheduled Job\n(daily 2 AM)"] --> EXTRACT["Extract order history\nfrom PG read replica"]
    EXTRACT --> TRANSFORM["Build user-item matrix\n(pandas)"]
    TRANSFORM --> TRAIN["Train NearestNeighbors\n(scikit-learn)"]
    TRAIN --> SERIALIZE["Serialize model\n(joblib → Persistent Disk)"]
    SERIALIZE --> RELOAD["FastAPI hot-reload\nmodel on next request"]
```

| ML Feature | Algorithm | Retraining | Fallback |
|-----------|-----------|-----------|----------|
| **Trending items** | SQL aggregation (no ML) | Real-time | Top 10 all-time |
| **Personal recommendations** | k-NN collaborative filtering | Daily (2 AM) | Trending items |
| **Upsell / cross-sell** | Association rule mining (Apriori) | Daily (2 AM) | Random items from same category |
| **Demand forecasting** | Prophet / ARIMA (future v3) | Weekly | Historical average |

### 9.6 Report Responses

**GET /reports/daily** (FastAPI internal → wrapped by gateway)

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

**GET /reports/gst**

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

**GET /recommendations/trending**

```json
{
  "success": true,
  "data": {
    "outlet_id": "main-campus-uuid",
    "period_days": 7,
    "items": [
      { "id": "uuid", "name": "Margherita Pizza", "slug": "margherita-pizza", "order_count": 142, "revenue": 28258.00 },
      { "id": "uuid", "name": "Pepperoni Feast", "slug": "pepperoni-feast", "order_count": 98, "revenue": 24402.00 },
      { "id": "uuid", "name": "Garlic Bread", "slug": "garlic-bread", "order_count": 87, "revenue": 8700.00 }
    ]
  }
}
```

**GET /recommendations/personal/:userId**

```json
{
  "success": true,
  "data": {
    "user_id": "user-uuid",
    "strategy": "collaborative_filtering",
    "items": [
      { "id": "uuid", "name": "BBQ Chicken Pizza", "slug": "bbq-chicken-pizza", "confidence": 0.87, "reason": "Users with similar taste ordered this" },
      { "id": "uuid", "name": "Loaded Nachos", "slug": "loaded-nachos", "confidence": 0.72, "reason": "Popular combo with your past orders" }
    ],
    "fallback": false
  }
}
```

**GET /recommendations/upsell/:menuItemId**

```json
{
  "success": true,
  "data": {
    "menu_item_id": "pizza-1-uuid",
    "menu_item_name": "Margherita Pizza",
    "frequently_bought_together": [
      { "id": "uuid", "name": "Garlic Bread", "co_occurrence": 68, "price": 99.00 },
      { "id": "uuid", "name": "Coca-Cola 330ml", "co_occurrence": 54, "price": 40.00 },
      { "id": "uuid", "name": "Extra Cheese Dip", "co_occurrence": 41, "price": 30.00 }
    ]
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

> **Primary channel: WhatsApp** (via Meta Cloud API). Works for QR guest users (no app needed). FCM is secondary for app users. OTP SMS sent via **MSG91**.

### 11.1 Notification Engine

| Feature | Provider | Implementation |
|---------|----------|---------------|
| **OTP SMS** | MSG91 | DLT-registered template, auto-retry with OTP widget, ₹0.14–0.22/SMS |
| **WhatsApp order confirmation** | Meta WhatsApp Cloud API | Primary channel — sent on `confirmed` for ALL orders including QR guests |
| **Status updates** | Meta WhatsApp Cloud API + FCM | WhatsApp at key milestones: confirmed, ready, delivered |
| **Retry logic** | Both | 3 attempts with exponential backoff (1s → 5s → 15s) |
| **Dead-letter queue** | Both | Failed after 3 attempts → written to `notification_dlq` table for manual review |
| **Delivery receipts** | Meta WhatsApp Cloud API | Webhook tracks delivered/read status |
| **Broadcast** | Meta WhatsApp Cloud API | Admin can send promo/system messages to customer segments |
| **Free tier** | Meta WhatsApp Cloud API | 1,000 free service conversations/month |

### 11.2 Notification Architecture

```mermaid
sequenceDiagram
    OrderService->>NotificationQueue: Enqueue { event, orderId, channel, recipient }
    NotificationQueue->>NotificationWorker: Dequeue message
    NotificationWorker->>MetaCloudAPI: Send WhatsApp message
    MetaCloudAPI-->>NotificationWorker: { status: delivered | failed }
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
| **Transport** | HTTPS mandatory everywhere (TLS 1.2+) |
| **JWT Algorithm** | RS256 (asymmetric: private key signs, public key verifies) |
| **OTP hashing** | bcrypt (12 rounds) before DB storage |
| **OTP rate limiting** | 3 requests / 15 min per phone (Redis counter) |
| **OTP expiry** | 10 minutes, single use |
| **Refresh tokens** | SHA-256 hashed before DB storage |
| **Token blacklist** | Revoked tokens tracked in Redis |
| **RBAC** | JWT `role` claim checked via `RolesGuard` on every endpoint |
| **Input validation** | NestJS `ValidationPipe` with `class-validator` DTOs |
| **SQL injection** | TypeORM parameterized queries (no raw SQL with user input) |
| **PostgreSQL RLS** | Row-Level Security policies enforce tenant isolation — customers can only read their own orders, staff scoped to their outlet |
| **Encrypted PII** | Phone numbers, addresses, and WhatsApp numbers encrypted at rest using AES-256-GCM; decrypted only in-memory at query time |
| **Razorpay security** | HMAC-SHA256 signature verified server-side |
| **DB connections** | SSL/TLS encrypted PostgreSQL connection |
| **Secrets management** | Environment variables, never committed to git |
| **CORS** | Whitelist allowed origins (`app.fresco-kitchen.com`, localhost) |
| **Helmet** | HTTP security headers (HSTS, XSS protection, etc.) |
| **WAF** | Cloudflare WAF (production) / ModSecurity (self-hosted) — SQL injection, XSS, bot protection, geo-blocking |
| **Rate limiting** | Global: 100 req/min per IP; OTP: 3/15 min per phone; sensitive endpoints: 10 req/min |
| **Audit logs** | Immutable append-only `audit_logs` table — records all status transitions, payment events, admin actions with actor, IP, timestamp, and before/after snapshots |

### 14.1 PostgreSQL Row-Level Security

```sql
-- Customers can only see their own orders
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY orders_customer_policy ON orders
    FOR SELECT
    USING (customer_id = current_setting('app.current_user_id')::UUID);

-- Staff can only see orders for their assigned outlet
CREATE POLICY orders_staff_policy ON orders
    FOR ALL
    USING (outlet_id IN (
        SELECT outlet_id FROM staff_assignments
        WHERE user_id = current_setting('app.current_user_id')::UUID
    ));

-- Admin/super_admin can see everything (bypass RLS)
CREATE POLICY orders_admin_policy ON orders
    FOR ALL
    USING (current_setting('app.current_user_role') IN ('admin', 'super_admin'));
```

### 14.2 PII Encryption

```typescript
// shared/utils/encryption.ts
import { createCipheriv, createDecipheriv, randomBytes } from 'crypto';

const ALGORITHM = 'aes-256-gcm';
const KEY = Buffer.from(process.env.PII_ENCRYPTION_KEY, 'hex'); // 32 bytes

export function encryptPII(plaintext: string): string {
  const iv = randomBytes(12);
  const cipher = createCipheriv(ALGORITHM, KEY, iv);
  const encrypted = Buffer.concat([cipher.update(plaintext, 'utf8'), cipher.final()]);
  const tag = cipher.getAuthTag();
  // Format: iv:tag:ciphertext (all base64)
  return `${iv.toString('base64')}:${tag.toString('base64')}:${encrypted.toString('base64')}`;
}

export function decryptPII(encoded: string): string {
  const [ivB64, tagB64, dataB64] = encoded.split(':');
  const decipher = createDecipheriv(ALGORITHM, KEY, Buffer.from(ivB64, 'base64'));
  decipher.setAuthTag(Buffer.from(tagB64, 'base64'));
  return decipher.update(Buffer.from(dataB64, 'base64')) + decipher.final('utf8');
}
```

### 14.3 Audit Log Schema

```sql
CREATE TABLE audit_logs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id        UUID,                           -- User who performed the action
    actor_role      VARCHAR(20) NOT NULL,
    action          VARCHAR(50) NOT NULL,           -- 'order.status_change', 'payment.refund', etc.
    entity_type     VARCHAR(30) NOT NULL,           -- 'order', 'payment', 'menu_item'
    entity_id       UUID NOT NULL,
    before_state    JSONB,                          -- Snapshot before change
    after_state     JSONB,                          -- Snapshot after change
    ip_address      INET,
    user_agent      TEXT,
    metadata        JSONB,                          -- Additional context
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Immutable: no UPDATE or DELETE allowed
REVOKE UPDATE, DELETE ON audit_logs FROM app_user;

-- Index for fast lookups
CREATE INDEX idx_audit_entity ON audit_logs (entity_type, entity_id, created_at DESC);
CREATE INDEX idx_audit_actor ON audit_logs (actor_id, created_at DESC);
```

---

## 15. Edge Case Handling Matrix

### 15.1 Payment Edge Cases

| Scenario | Handling | Error Code | Recovery |
|----------|----------|-----------|----------|
| **Webhook delayed** | Order remains `PAYMENT_PENDING` until webhook arrives or 15-min TTL expires. Customer sees "Processing Payment..." | — | Cron job expires after 15 min; customer can retry |
| **Duplicate webhook** | Idempotency check — `razorpay_payment_id` is unique-indexed on `payment_transactions` table. Second processing is a no-op | `PAYMENT_ALREADY_CAPTURED` | Safe to re-process; returns existing order status |
| **Double payment** | Detected via idempotency key + Razorpay order-to-payment mapping. If excess amount captured, flag for admin review and initiate automatic partial refund | `REFUND_EXCEEDS_AMOUNT` | Auto-refund excess via Razorpay Refund API; alert admin |
| **Gateway timeout** | Customer sees "Awaiting confirmation" screen with auto-polling (`GET /orders/:id` every 5s). Frontend does **not** update payment status — only webhook does | — | Webhook will arrive eventually; 15-min TTL is safety net |
| **DB failure after payment** | Webhook handler wraps all DB writes in an atomic transaction. If transaction fails, Razorpay retries webhook (up to 24 hours). Handler is idempotent | — | Razorpay automatic webhook retry; manual reconciliation via nightly cron |
| **Razorpay down** | Order stays `INITIATED`. Customer shown "Payment service temporarily unavailable" with option to pay via Cash/UPI at counter | `PAYMENT_GATEWAY_UNAVAILABLE` | Fallback to cash payment; retry Razorpay later |

### 15.2 Order Edge Cases

| Scenario | Handling | Error Code | Recovery |
|----------|----------|-----------|----------|
| **Item unavailable** (after cart) | Revalidate all item availability at `POST /orders` time (before payment). If any item is unavailable, reject entire order with specific item details | `ITEM_UNAVAILABLE` | Customer removes item and resubmits; real-time availability via WebSocket |
| **Cart refresh / stale prices** | Server recalculates all prices at order submission time using current DB prices. Client-side totals are for display only — never trusted | — | Price mismatch logged; customer shown updated total before payment |
| **Staff cancels paid order** | Atomic transition `CONFIRMED` → `CANCELLED`. Auto-initiates full Razorpay refund. Credit note generated. WhatsApp notification sent to customer | `ORDER_NOT_CANCELLABLE` (if past `PREPARING`) | Refund via Razorpay; credit note for GST reconciliation |
| **Student dispute** | Order flagged for manual admin review. Admin can view full audit trail (order history, payment status, status transitions). Resolution options: refund, re-prepare, or reject | — | Admin portal dispute resolution workflow; audit log provides evidence |
| **Outlet closes mid-order** | Orders in `INITIATED`/`PAYMENT_PENDING` are auto-expired. Orders already `CONFIRMED` or beyond continue to completion. New orders rejected with `OUTLET_CLOSED` | `OUTLET_CLOSED` | Admin toggles outlet status; existing orders honored |
| **Concurrent status updates** | Optimistic locking via `version` column on `orders` table. If two staff members try to advance status simultaneously, one gets `409 Conflict` | `CONCURRENT_MODIFICATION` | Retry with fresh state; UI auto-refreshes via WebSocket |

### 15.3 Notification Edge Cases

| Scenario | Handling |
|----------|----------|
| **WhatsApp delivery failure** | 3 retries with exponential backoff → dead-letter queue → admin notification |
| **Invalid phone number** | MSG91 returns error → order proceeds without OTP (guest flow falls back to name-only) |
| **FCM token expired** | Token refresh on next app open; missed push notifications visible in in-app notification feed |
| **Bulk broadcast failure** | Batch processing with per-message error tracking; partial success allowed; failed messages retry |

---

## 16. Infrastructure & Deployment

### 16.1 Docker Compose (v1 — Launch)

```yaml
version: '3.9'
services:
  # ── NestJS API Gateway ──────────────────────────
  api:
    build: ./backend
    ports: ["3000:3000"]
    environment:
      DATABASE_URL: postgres://postgres:secret@db:5432/frescos
      REDIS_URL: redis://cache:6379
      JWT_PRIVATE_KEY_PATH: /secrets/private.pem
      ANALYTICS_SERVICE_URL: http://analytics:8000  # Internal service discovery
      RAZORPAY_KEY_ID: rzp_live_xxx
      RAZORPAY_KEY_SECRET: xxx
      MSG91_AUTH_KEY: xxx
      MSG91_SENDER_ID: FRESCO
      MSG91_OTP_TEMPLATE_ID: xxx
      WHATSAPP_PHONE_NUMBER_ID: xxx
      WHATSAPP_ACCESS_TOKEN: xxx
      WHATSAPP_BUSINESS_ACCOUNT_ID: xxx
    depends_on: [db, cache, analytics]

  # ── FastAPI Analytics Microservice ──────────────
  analytics:
    build: ./analytics-service
    ports: ["8000:8000"]   # Exposed only for development; Nginx doesn't route here
    environment:
      DATABASE_URL: postgres://readonly:secret@db:5432/frescos?sslmode=disable
      REDIS_URL: redis://cache:6379
      R2_BUCKET: frescos-reports
      ML_MODEL_PATH: /app/ml/models
      ALLOWED_GATEWAY_HOSTS: api  # Only accept requests from NestJS container
    depends_on: [db, cache]
    volumes:
      - ml_models:/app/ml/models

  # ── Database ────────────────────────────────────
  db:
    image: postgres:15-alpine
    volumes: [pgdata:/var/lib/postgresql/data]
    environment:
      POSTGRES_DB: frescos
      POSTGRES_PASSWORD: secret
    # In production: use a read replica for analytics-service

  # ── Cache ───────────────────────────────────────
  cache:
    image: redis:7-alpine
    command: redis-server --requirepass secret

  # ── Reverse Proxy ───────────────────────────────
  nginx:
    image: nginx:alpine
    ports: ["80:80", "443:443"]
    volumes: [./nginx.conf:/etc/nginx/nginx.conf, ./certs:/etc/ssl]

volumes:
  pgdata:
  ml_models:     # Persisted ML model artifacts
```

### 16.2 Production (v2)

| Component | Service |
|-----------|---------|
| NestJS Gateway | Render Web Service |
| FastAPI Analytics | Render Private Service (internal network) | 
| Database (Primary) | Render PostgreSQL |
| Database (Read Replica) | Render PostgreSQL Read Replica |
| Cache | Render Redis |
| Media + Reports | Cloudflare R2 + CDN |
| ML Models | Render Persistent Disk (mounted volume) |
| Secrets | Render Environment Variables / Secret Files |
| Monitoring | Datadog (via Render Log Streams) |
| CI/CD | GitHub Actions → Render Deploy Hook or Auto-Deploy |

### 16.3 Environment Variables — NestJS Gateway

```bash
# Server
PORT=3000
NODE_ENV=production

# Database
DATABASE_URL=postgres://user:pass@host:5432/frescos?sslmode=require

# Redis
REDIS_URL=redis://:password@host:6379

# Analytics Service (internal)
ANALYTICS_SERVICE_URL=http://analytics:8000

# JWT
JWT_PRIVATE_KEY_PATH=/run/secrets/jwt_private.pem
JWT_PUBLIC_KEY_PATH=/run/secrets/jwt_public.pem
JWT_ACCESS_EXPIRES=30m
JWT_REFRESH_EXPIRES=30d

# Razorpay
RAZORPAY_KEY_ID=rzp_live_xxx
RAZORPAY_KEY_SECRET=xxx

# MSG91 (SMS / OTP)
MSG91_AUTH_KEY=xxx
MSG91_SENDER_ID=FRESCO                  # 6-char DLT-registered sender ID
MSG91_OTP_TEMPLATE_ID=xxx               # DLT-approved OTP template
MSG91_OTP_LENGTH=6
MSG91_OTP_EXPIRY=600                    # 10 minutes (seconds)

# Meta WhatsApp Cloud API
WHATSAPP_PHONE_NUMBER_ID=xxx            # From Meta Business Manager
WHATSAPP_ACCESS_TOKEN=xxx               # System user token (permanent)
WHATSAPP_BUSINESS_ACCOUNT_ID=xxx        # WABA ID
WHATSAPP_VERIFY_TOKEN=xxx               # Webhook verification token
WHATSAPP_API_VERSION=v21.0

# Firebase
FIREBASE_PROJECT_ID=frescos-kitchen
FIREBASE_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----...

# Cloudflare R2 (Object Storage)
R2_BUCKET_NAME=frescos-media
R2_ACCOUNT_ID=xxx
R2_ACCESS_KEY_ID=xxx
R2_SECRET_ACCESS_KEY=xxx
```

### 16.4 Environment Variables — FastAPI Analytics Service

```bash
# Server
PORT=8000
ENVIRONMENT=production
DEBUG=false

# Database (READ-ONLY replica)
DATABASE_URL=postgres://readonly:pass@replica-host:5432/frescos?sslmode=require

# Redis (shared cache)
REDIS_URL=redis://:password@host:6379

# ML Models
ML_MODEL_PATH=/app/ml/models
ML_RETRAIN_CRON="0 2 * * *"     # Daily at 2 AM IST

# Report Storage (Cloudflare R2)
R2_BUCKET_NAME=frescos-reports
R2_ACCOUNT_ID=xxx
R2_ACCESS_KEY_ID=xxx
R2_SECRET_ACCESS_KEY=xxx

# Security
ALLOWED_GATEWAY_HOSTS=api,10.0.0.0/16   # Accept only from internal network
```

---

## 17. Technology Decision Record

### TDR-001: Hybrid Architecture — NestJS Gateway + FastAPI Analytics

**Status:** Accepted · **Date:** 7 March 2026

#### Context

The system requires two fundamentally different workloads:

| Workload | Characteristics |
|----------|----------------|
| **Customer-facing APIs** | High concurrency, real-time WebSockets, I/O-bound, payment processing |
| **Analytics & ML** | CPU-bound aggregations, data science libraries, model training, heavy reporting |

A single runtime cannot optimally serve both.

#### Decision

| Service | Technology | Responsibility |
|---------|-----------|----------------|
| **API Gateway** | Node.js 20 + NestJS (TypeScript) | Auth, Users, Menu, Orders, Payments, Inventory, Admin, Notifications, WebSocket |
| **Analytics Microservice** | Python 3.12 + FastAPI (Pydantic v2) | Reports, GST summaries, ML recommendations, CSV/PDF exports |

#### Rationale — Why NestJS for the Gateway

1. **WebSocket-first** — 7+ real-time event types (order status, kitchen alerts, low-stock). Node.js event-loop + Socket.IO handles 10K+ idle connections efficiently.
2. **SDK ecosystem** — Razorpay, Firebase Admin, MSG91, and Meta WhatsApp Cloud API all have first-class Node.js SDKs.
3. **NestJS structure** — Guards, Interceptors, Decorators, modular DI — enterprise-grade without boilerplate.
4. **TypeScript safety** — Compile-time type checking is critical for payment-processing code paths.

#### Rationale — Why FastAPI for Analytics

1. **Python data science ecosystem** — pandas, scikit-learn, Prophet are native Python libraries with no viable Node.js equivalents.
2. **Pydantic v2** — The fastest data validation library available; auto-generates OpenAPI docs.
3. **Async SQLAlchemy 2.0** — True async DB access on the read replica without blocking.
4. **ML pipeline integration** — Model training (scikit-learn, joblib) and inference live in the same codebase.
5. **Report generation** — WeasyPrint (PDF) and pandas (CSV) are Python-native.

#### Why Not Python FastAPI for Everything?

| Concern | Detail |
|---------|--------|
| **WebSocket maturity** | FastAPI supports WebSockets, but Socket.IO rooms/namespaces/broadcasting is far more mature in Node.js. |
| **Concurrent idle connections** | Node.js event-loop handles idle WebSocket connections more efficiently than Python asyncio at scale. |
| **Payment SDK quality** | Razorpay's official Python SDK is community-maintained; Node.js SDK is first-party. |
| **Team velocity** | NestJS's decorator-based architecture enabled rapid Module 1–9 development in v1. |

#### Why Not Go + gRPC for Everything?

| Concern | Detail |
|---------|--------|
| **Browser incompatibility** | gRPC requires a gRPC-Web proxy (Envoy) for browser-based QR ordering — unnecessary complexity. |
| **Development speed** | Go's verbosity slows v1 iteration; error handling (`if err != nil`) adds boilerplate. |
| **WebSocket story** | No built-in WebSocket framework comparable to NestJS `@WebSocketGateway()`. |
| **Data science** | No pandas/scikit-learn equivalent — would still need a Python sidecar for ML. |
| **Hiring** | Go developers are harder to find in India's startup ecosystem compared to Node.js/Python. |
| **When to reconsider** | If order throughput exceeds 50K+/min, extract a Go microservice for the hot path (order routing). |

#### Consequences

- **Pro:** Each service uses the best tool for its workload. Analytics can scale independently.
- **Pro:** Read replica isolates analytics queries from transactional DB load.
- **Pro:** ML models can be retrained without touching the gateway.
- **Con:** Two deployment pipelines, two Docker images, two sets of dependencies.
- **Con:** Inter-service latency (mitigated by internal Docker network + Redis caching).
- **Mitigation:** Single Docker Compose for local dev; single CI/CD pipeline with parallel builds.
