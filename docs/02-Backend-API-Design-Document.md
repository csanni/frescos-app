# Campus Food Ordering System — Backend API Design Document

> **Version:** 1.0 | **Date:** 2026-02-13  
> **Stack:** Python (FastAPI) + PostgreSQL + Redis + Firebase

---

## Table of Contents

1. [Overview](#1-overview)
2. [Technology Stack](#2-technology-stack)
3. [Architecture](#3-architecture)
4. [Database Schema](#4-database-schema)
5. [API Specification](#5-api-specification)
6. [Authentication & Authorization](#6-authentication--authorization)
7. [Real-Time Services](#7-real-time-services)
8. [Payment Integration](#8-payment-integration)
9. [Push Notifications](#9-push-notifications)
10. [Configuration & Admin Controls](#10-configuration--admin-controls)
11. [Error Handling](#11-error-handling)
12. [Deployment & Infrastructure](#12-deployment--infrastructure)
13. [Monitoring & Logging](#13-monitoring--logging)
14. [Security](#14-security)

---

## 1. Overview

A single centralized backend serving both the **Consumer Mobile App** (Flutter) and the **Kitchen Web Portal**. Designed for a **single restaurant**, **campus-only** scope with staff-managed delivery (no GPS).

### Key Responsibilities

- OTP-based authentication
- Menu management with time-slot availability
- Order processing engine with status workflow
- UPI payment gateway integration
- Push notification dispatch
- Real-time order updates via WebSocket
- Role-based access control (Consumer / Kitchen Staff / Admin)
- Reporting & analytics

---

## 2. Technology Stack

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| **Framework** | FastAPI (Python 3.12+) | Async-native, auto-docs, type-safe |
| **Database** | PostgreSQL 16 | Relational integrity, JSON support |
| **ORM** | SQLAlchemy 2.0 + Alembic | Async ORM + migrations |
| **Cache** | Redis 7 | Session cache, rate limiting, pub/sub |
| **Auth** | JWT (access + refresh tokens) | Stateless, scalable |
| **SMS/OTP** | Twilio / MSG91 | OTP delivery |
| **Payments** | Razorpay | UPI, robust webhooks |
| **Notifications** | Firebase Admin SDK | FCM push notifications |
| **WebSocket** | FastAPI WebSocket | Real-time order status |
| **Task Queue** | Celery + Redis | Async tasks (SMS, notifications) |
| **File Storage** | AWS S3 / MinIO | Menu item images |
| **Containerization** | Docker + Docker Compose | Consistent environments |

---

## 3. Architecture

### 3.1 High-Level Architecture

```
                    ┌──────────────┐
                    │   Nginx      │  (Reverse Proxy / SSL / Rate Limit)
                    │   Gateway    │
                    └──────┬───────┘
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
      ┌──────────┐  ┌──────────┐  ┌──────────┐
      │ FastAPI  │  │ FastAPI  │  │ FastAPI  │   (Multiple Workers via Uvicorn)
      │ Worker 1 │  │ Worker 2 │  │ Worker N │
      └────┬─────┘  └────┬─────┘  └────┬─────┘
           │              │              │
           └──────────────┼──────────────┘
                          │
            ┌─────────────┼─────────────┐
            ▼             ▼             ▼
     ┌───────────┐  ┌──────────┐  ┌──────────┐
     │PostgreSQL │  │  Redis   │  │  S3 /    │
     │           │  │          │  │  MinIO   │
     └───────────┘  └──────────┘  └──────────┘
                          │
                          ▼
                   ┌──────────┐
                   │  Celery  │  (Async Workers: SMS, FCM, Reports)
                   │  Workers │
                   └──────────┘
```

### 3.2 Project Structure

```
backend/
├── app/
│   ├── main.py                  # FastAPI app factory
│   ├── config.py                # Settings via pydantic-settings
│   ├── database.py              # Async engine, session factory
│   │
│   ├── api/
│   │   ├── v1/
│   │   │   ├── router.py        # Aggregated v1 router
│   │   │   ├── auth.py          # POST /auth/request-otp, /auth/verify-otp
│   │   │   ├── menu.py          # GET /menu/categories, /menu/items
│   │   │   ├── cart.py          # Server-side cart (optional)
│   │   │   ├── orders.py        # POST /orders, GET /orders/{id}
│   │   │   ├── payments.py      # POST /payments/initiate, webhook
│   │   │   ├── users.py         # GET/PUT /users/me, device-token
│   │   │   ├── admin/
│   │   │   │   ├── menu.py      # CRUD menu items/categories
│   │   │   │   ├── orders.py    # Order management dashboard
│   │   │   │   ├── delivery.py  # Delivery assignment
│   │   │   │   ├── config.py    # System config
│   │   │   │   ├── staff.py     # Staff management
│   │   │   │   └── reports.py   # Sales & analytics
│   │   │   └── websocket.py     # WS /ws/orders/{order_id}
│   │   └── deps.py              # Dependency injection
│   │
│   ├── models/                  # SQLAlchemy ORM models
│   │   ├── user.py
│   │   ├── menu.py
│   │   ├── order.py
│   │   ├── payment.py
│   │   ├── notification.py
│   │   └── config.py
│   │
│   ├── schemas/                 # Pydantic request/response schemas
│   │   ├── auth.py
│   │   ├── menu.py
│   │   ├── order.py
│   │   ├── payment.py
│   │   ├── user.py
│   │   └── admin.py
│   │
│   ├── services/                # Business logic
│   │   ├── auth_service.py
│   │   ├── menu_service.py
│   │   ├── order_service.py
│   │   ├── payment_service.py
│   │   ├── notification_service.py
│   │   └── report_service.py
│   │
│   ├── tasks/                   # Celery async tasks
│   │   ├── sms_tasks.py
│   │   ├── notification_tasks.py
│   │   └── report_tasks.py
│   │
│   └── utils/
│       ├── security.py          # JWT, hashing
│       ├── otp.py               # OTP generation/validation
│       ├── pagination.py
│       └── exceptions.py
│
├── migrations/                  # Alembic migrations
├── tests/
├── docker-compose.yml
├── Dockerfile
├── requirements.txt
└── .env.example
```

---

## 4. Database Schema

### 4.1 Entity-Relationship Overview

```
users ──< orders ──< order_items >── menu_items >── categories
  │          │
  │          └──< payments
  │          └──< delivery_assignments
  │
  └──< device_tokens
  └──< notifications

system_config (singleton settings table)
staff_users (kitchen/admin portal users)
```

### 4.2 Table Definitions

#### `users`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK, default gen |
| phone | VARCHAR(15) | UNIQUE, NOT NULL |
| name | VARCHAR(100) | NULL (set after first login) |
| is_active | BOOLEAN | DEFAULT true |
| created_at | TIMESTAMPTZ | DEFAULT now() |
| updated_at | TIMESTAMPTZ | Auto-update |

#### `staff_users`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| username | VARCHAR(50) | UNIQUE, NOT NULL |
| password_hash | VARCHAR(255) | NOT NULL |
| role | ENUM('admin','kitchen','delivery') | NOT NULL |
| name | VARCHAR(100) | NOT NULL |
| is_active | BOOLEAN | DEFAULT true |
| created_at | TIMESTAMPTZ | DEFAULT now() |

#### `categories`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| name | VARCHAR(100) | UNIQUE, NOT NULL |
| display_order | INTEGER | DEFAULT 0 |
| is_active | BOOLEAN | DEFAULT true |
| image_url | TEXT | NULL |

#### `menu_items`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| category_id | UUID | FK → categories.id |
| name | VARCHAR(200) | NOT NULL |
| description | TEXT | NULL |
| price | DECIMAL(10,2) | NOT NULL, CHECK > 0 |
| image_url | TEXT | NULL |
| is_veg | BOOLEAN | DEFAULT true |
| is_available | BOOLEAN | DEFAULT true |
| time_slots | JSONB | `["breakfast","lunch","dinner"]` |
| display_order | INTEGER | DEFAULT 0 |
| created_at | TIMESTAMPTZ | DEFAULT now() |
| updated_at | TIMESTAMPTZ | Auto-update |

#### `orders`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| order_number | VARCHAR(20) | UNIQUE, auto-gen (e.g., ORD-20260213-001) |
| user_id | UUID | FK → users.id |
| status | ENUM | See status enum below |
| order_type | ENUM('pickup','delivery') | NOT NULL |
| subtotal | DECIMAL(10,2) | NOT NULL |
| delivery_charge | DECIMAL(10,2) | DEFAULT 0 |
| total | DECIMAL(10,2) | NOT NULL |
| payment_method | ENUM('upi','cash') | NOT NULL |
| payment_status | ENUM('pending','paid','failed','refunded') | DEFAULT 'pending' |
| special_instructions | TEXT | NULL |
| estimated_ready_time | TIMESTAMPTZ | NULL |
| delivery_address | TEXT | NULL |
| created_at | TIMESTAMPTZ | DEFAULT now() |
| updated_at | TIMESTAMPTZ | Auto-update |

**Order Status Enum:** `received` → `preparing` → `ready` → `out_for_delivery` → `completed` | `cancelled`

#### `order_items`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| order_id | UUID | FK → orders.id |
| menu_item_id | UUID | FK → menu_items.id |
| item_name | VARCHAR(200) | NOT NULL (snapshot) |
| item_price | DECIMAL(10,2) | NOT NULL (snapshot) |
| quantity | INTEGER | NOT NULL, CHECK ≥ 1 |
| line_total | DECIMAL(10,2) | NOT NULL |

#### `payments`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| order_id | UUID | FK → orders.id |
| gateway_order_id | VARCHAR(100) | Razorpay order ID |
| gateway_payment_id | VARCHAR(100) | NULL |
| amount | DECIMAL(10,2) | NOT NULL |
| status | ENUM('created','authorized','captured','failed','refunded') | NOT NULL |
| gateway_response | JSONB | Full webhook payload |
| created_at | TIMESTAMPTZ | DEFAULT now() |
| updated_at | TIMESTAMPTZ | Auto-update |

#### `delivery_assignments`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| order_id | UUID | FK → orders.id, UNIQUE |
| staff_id | UUID | FK → staff_users.id |
| status | ENUM('assigned','picked_up','delivered') | DEFAULT 'assigned' |
| assigned_at | TIMESTAMPTZ | DEFAULT now() |
| delivered_at | TIMESTAMPTZ | NULL |

#### `device_tokens`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| user_id | UUID | FK → users.id |
| token | TEXT | NOT NULL |
| platform | ENUM('android','ios') | NOT NULL |
| is_active | BOOLEAN | DEFAULT true |
| created_at | TIMESTAMPTZ | DEFAULT now() |

#### `system_config`
| Column | Type | Constraints |
|--------|------|-------------|
| key | VARCHAR(100) | PK |
| value | JSONB | NOT NULL |
| updated_at | TIMESTAMPTZ | Auto-update |
| updated_by | UUID | FK → staff_users.id |

**Default config keys:** `delivery_enabled`, `max_orders_per_slot`, `cash_payment_enabled`, `upi_payment_enabled`, `delivery_charge`, `restaurant_open`, `time_slots`

---

## 5. API Specification

**Base URL:** `/api/v1`  
**Format:** JSON  
**Auth:** Bearer JWT (except public endpoints)

### 5.1 Authentication

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/auth/request-otp` | ✗ | Send OTP to phone number |
| POST | `/auth/verify-otp` | ✗ | Verify OTP, return JWT tokens |
| POST | `/auth/refresh` | ✗ | Refresh access token |
| POST | `/auth/logout` | ✓ | Invalidate refresh token |

**POST `/auth/request-otp`**
```json
// Request
{ "phone": "+919876543210" }

// Response 200
{ "message": "OTP sent successfully", "expires_in": 300 }
```

**POST `/auth/verify-otp`**
```json
// Request
{ "phone": "+919876543210", "otp": "123456" }

// Response 200
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "token_type": "bearer",
  "expires_in": 3600,
  "user": { "id": "uuid", "phone": "+919876543210", "name": null }
}
```

### 5.2 Menu (Consumer)

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/menu/categories` | ✓ | List active categories |
| GET | `/menu/items` | ✓ | List items (filter by category, time_slot, search) |
| GET | `/menu/items/{id}` | ✓ | Single item detail |

**GET `/menu/items?category_id=uuid&time_slot=lunch&search=paneer`**
```json
// Response 200
{
  "items": [
    {
      "id": "uuid",
      "name": "Paneer Tikka",
      "description": "Grilled cottage cheese...",
      "price": 180.00,
      "image_url": "https://...",
      "is_veg": true,
      "is_available": true,
      "time_slots": ["lunch", "dinner"],
      "category": { "id": "uuid", "name": "Starters" }
    }
  ],
  "total": 15
}
```

### 5.3 Orders (Consumer)

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/orders` | ✓ | Place a new order |
| GET | `/orders` | ✓ | Order history (paginated) |
| GET | `/orders/{id}` | ✓ | Single order detail |
| GET | `/orders/{id}/status` | ✓ | Current status only |

**POST `/orders`**
```json
// Request
{
  "items": [
    { "menu_item_id": "uuid", "quantity": 2 },
    { "menu_item_id": "uuid", "quantity": 1 }
  ],
  "order_type": "pickup",
  "payment_method": "upi",
  "special_instructions": "Extra spicy",
  "delivery_address": null
}

// Response 201
{
  "order": {
    "id": "uuid",
    "order_number": "ORD-20260213-042",
    "status": "received",
    "total": 460.00,
    "payment_status": "pending",
    "created_at": "2026-02-13T08:30:00Z"
  },
  "payment": {
    "gateway_order_id": "order_RzpXXXXXX",
    "amount": 460.00,
    "currency": "INR"
  }
}
```

### 5.4 Payments

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/payments/verify` | ✓ | Verify payment after UPI completion |
| POST | `/payments/webhook` | ✗* | Razorpay webhook (*signature verified) |

### 5.5 User Profile

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/users/me` | ✓ | Get profile |
| PUT | `/users/me` | ✓ | Update name |
| POST | `/users/device-token` | ✓ | Register FCM token |
| DELETE | `/users/device-token` | ✓ | Unregister token |

### 5.6 Admin / Kitchen Portal APIs

| Method | Endpoint | Auth (Role) | Description |
|--------|----------|-------------|-------------|
| POST | `/admin/auth/login` | ✗ | Staff username/password login |
| GET | `/admin/orders` | kitchen, admin | All orders (filterable) |
| PATCH | `/admin/orders/{id}/status` | kitchen, admin | Update order status |
| POST | `/admin/orders/{id}/assign-delivery` | admin | Assign delivery staff |
| GET | `/admin/menu/items` | admin | All items (incl. inactive) |
| POST | `/admin/menu/items` | admin | Create menu item |
| PUT | `/admin/menu/items/{id}` | admin | Update menu item |
| DELETE | `/admin/menu/items/{id}` | admin | Soft-delete menu item |
| POST | `/admin/menu/categories` | admin | Create category |
| PUT | `/admin/menu/categories/{id}` | admin | Update category |
| GET | `/admin/config` | admin | Get system config |
| PUT | `/admin/config/{key}` | admin | Update config value |
| GET | `/admin/staff` | admin | List staff |
| POST | `/admin/staff` | admin | Create staff account |
| GET | `/admin/reports/daily-sales` | admin | Daily summary |
| GET | `/admin/reports/item-performance` | admin | Item-wise report |
| GET | `/admin/reports/order-volume` | admin | Order volume stats |

---

## 6. Authentication & Authorization

### 6.1 Consumer Auth — OTP Flow

```
Client                    Backend                   SMS Provider
  │                          │                          │
  │── POST /auth/request-otp─→│                          │
  │                          │── Generate 6-digit OTP ──→│
  │                          │── Store in Redis (5min) ──│
  │                          │                          │── Send SMS
  │←── 200 { expires: 300 } ─│                          │
  │                          │                          │
  │── POST /auth/verify-otp ─→│                          │
  │                          │── Validate OTP from Redis │
  │                          │── Create/find user        │
  │                          │── Generate JWT pair        │
  │←── 200 { tokens, user } ─│                          │
```

- **OTP:** 6-digit numeric, stored in Redis with TTL 300s
- **Rate limit:** Max 3 OTP requests per phone per 10 minutes
- **Access Token:** JWT, 1-hour expiry, contains `user_id`, `role`
- **Refresh Token:** JWT, 30-day expiry, stored in Redis for revocation

### 6.2 Staff Auth — Username/Password

- Bcrypt-hashed passwords
- Same JWT structure with `role` claim (`admin`, `kitchen`, `delivery`)

### 6.3 RBAC Middleware

```python
# Role-based dependency
def require_role(*roles: str):
    async def dependency(current_user = Depends(get_current_user)):
        if current_user.role not in roles:
            raise HTTPException(403, "Insufficient permissions")
        return current_user
    return Depends(dependency)

# Usage
@router.patch("/orders/{id}/status")
async def update_status(
    ...,
    user=require_role("kitchen", "admin")
):
```

---

## 7. Real-Time Services

### 7.1 WebSocket — Order Status Updates

**Endpoint:** `ws://{host}/api/v1/ws/orders/{order_id}`  
**Auth:** JWT passed as query param `?token=eyJ...`

**Server → Client Messages:**
```json
{ "event": "status_changed", "data": { "status": "preparing", "updated_at": "..." } }
{ "event": "estimated_time", "data": { "ready_by": "2026-02-13T09:15:00Z" } }
```

**Connection Lifecycle:**
1. Client connects with valid JWT + order owned by user
2. Server subscribes to Redis pub/sub channel `order:{order_id}`
3. On status change, service publishes to Redis → all connected clients receive update
4. Connection closed when order reaches `completed` or `cancelled`

### 7.2 Kitchen Portal — Server-Sent Events (SSE)

**Endpoint:** `GET /api/v1/admin/orders/stream`

Streams new incoming orders and status changes to the kitchen dashboard in real-time without the complexity of managing WebSocket state for the web portal.

---

## 8. Payment Integration

### 8.1 Razorpay UPI Flow

```
Flutter App          Backend              Razorpay
    │                   │                    │
    │── POST /orders ──→│                    │
    │                   │── Create Order ────→│
    │                   │←── order_id ────────│
    │←── order + pay ───│                    │
    │                   │                    │
    │── Launch Razorpay SDK ────────────────→│
    │←── Payment Result ─────────────────────│
    │                   │                    │
    │── POST /payments/verify ──→│           │
    │                   │── Verify Signature──│
    │                   │── Update order ─────│
    │←── 200 confirmed ─│                    │
    │                   │                    │
    │                   │←── Webhook (async) ─│  (backup confirmation)
```

### 8.2 Cash on Pickup Flow

- Order is created with `payment_method: "cash"` and `payment_status: "pending"`
- Kitchen confirms cash received → staff updates `payment_status: "paid"` via admin API
- Order only moves to `completed` after payment confirmation

---

## 9. Push Notifications

### 9.1 Trigger Events

| Event | Recipient | Title | Body |
|-------|-----------|-------|------|
| Order Received | Consumer | "Order Confirmed!" | "Your order #{number} has been received" |
| Preparing | Consumer | "Being Prepared 🍳" | "Your order is now being prepared" |
| Ready | Consumer | "Order Ready! 🎉" | "Your order is ready for pickup" |
| Out for Delivery | Consumer | "On the Way! 🚚" | "Your order is out for delivery" |
| New Order | Kitchen Staff | "New Order! 🔔" | "Order #{number} — {item_count} items — ₹{total}" |

### 9.2 Implementation

- **Firebase Admin SDK** used server-side to send via FCM
- Notifications dispatched asynchronously via **Celery task** to avoid blocking the API response
- Failed deliveries are retried up to 3 times with exponential backoff

---

## 10. Configuration & Admin Controls

The `system_config` table provides runtime-configurable settings without redeployment:

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `restaurant_open` | boolean | true | Master switch for ordering |
| `delivery_enabled` | boolean | true | Toggle delivery option |
| `delivery_charge` | number | 20.00 | Delivery fee in ₹ |
| `cash_payment_enabled` | boolean | true | Toggle cash payment |
| `upi_payment_enabled` | boolean | true | Toggle UPI payment |
| `max_orders_per_slot` | number | 50 | Order limit per time-slot |
| `time_slots` | object | See below | Slot definitions |

```json
{
  "time_slots": {
    "breakfast": { "start": "07:00", "end": "10:00" },
    "lunch":     { "start": "12:00", "end": "15:00" },
    "dinner":    { "start": "18:00", "end": "22:00" }
  }
}
```

---

## 11. Error Handling

### 11.1 Standard Error Response

```json
{
  "error": {
    "code": "ORDER_LIMIT_REACHED",
    "message": "Maximum orders for this time slot have been reached",
    "details": { "current": 50, "max": 50 }
  }
}
```

### 11.2 Error Codes

| HTTP | Code | Description |
|------|------|-------------|
| 400 | `VALIDATION_ERROR` | Request body validation failed |
| 400 | `INVALID_OTP` | OTP is incorrect or expired |
| 400 | `CART_EMPTY` | Order has no items |
| 401 | `TOKEN_EXPIRED` | Access token expired |
| 401 | `INVALID_TOKEN` | Token is malformed |
| 403 | `INSUFFICIENT_ROLE` | User lacks required role |
| 404 | `NOT_FOUND` | Resource not found |
| 409 | `ITEM_UNAVAILABLE` | Menu item no longer available |
| 409 | `ORDER_LIMIT_REACHED` | Time-slot order cap hit |
| 409 | `RESTAURANT_CLOSED` | Restaurant is not accepting orders |
| 422 | `PAYMENT_FAILED` | Payment verification failed |
| 429 | `RATE_LIMITED` | Too many requests |
| 500 | `INTERNAL_ERROR` | Unexpected server error |

---

## 12. Deployment & Infrastructure

### 12.1 Docker Compose (Development)

```yaml
services:
  api:
    build: .
    ports: ["8000:8000"]
    env_file: .env
    depends_on: [db, redis]

  db:
    image: postgres:16-alpine
    volumes: [pgdata:/var/lib/postgresql/data]
    environment:
      POSTGRES_DB: campus_food
      POSTGRES_USER: app
      POSTGRES_PASSWORD: ${DB_PASSWORD}

  redis:
    image: redis:7-alpine

  celery-worker:
    build: .
    command: celery -A app.tasks worker -l info
    depends_on: [redis]

volumes:
  pgdata:
```

### 12.2 Production Deployment

| Component | Recommendation |
|-----------|----------------|
| **Compute** | AWS EC2 (t3.medium) or DigitalOcean Droplet (4GB) |
| **Database** | AWS RDS PostgreSQL or self-managed with daily backups |
| **Redis** | AWS ElastiCache or co-located Redis |
| **SSL** | Let's Encrypt via Certbot + Nginx |
| **Process Manager** | Systemd + Gunicorn with Uvicorn workers |
| **CI/CD** | GitHub Actions → Docker build → SSH deploy |

---

## 13. Monitoring & Logging

| Concern | Tool |
|---------|------|
| **Structured Logging** | Python `structlog` → JSON format |
| **Log Aggregation** | CloudWatch / Loki (if self-hosted) |
| **APM** | Sentry (error tracking + performance) |
| **Health Check** | `GET /health` → returns DB + Redis status |
| **Metrics** | Prometheus endpoint (`/metrics`) via `prometheus-fastapi-instrumentator` |
| **Uptime** | UptimeRobot / Better Uptime (external ping) |

**Health Check Response:**
```json
{
  "status": "healthy",
  "database": "connected",
  "redis": "connected",
  "version": "1.0.0",
  "timestamp": "2026-02-13T08:30:00Z"
}
```

---

## 14. Security

| Measure | Implementation |
|---------|----------------|
| **HTTPS** | Enforced via Nginx (HSTS headers) |
| **CORS** | Whitelist mobile app origin + kitchen portal domain |
| **Rate Limiting** | Redis-based: 100 req/min (general), 3/10min (OTP) |
| **Input Validation** | Pydantic schemas on all endpoints |
| **SQL Injection** | Parameterized queries via SQLAlchemy ORM |
| **Secrets** | Environment variables (never in code); `.env` in `.gitignore` |
| **Webhook Security** | Razorpay signature verification (HMAC SHA256) |
| **JWT Security** | RS256 signing, short-lived access tokens |
| **Data Privacy** | Phone numbers hashed in logs; PII masked |
| **Dependency Audit** | `pip-audit` in CI pipeline |

---

> **Document End**  
> **Next:** [03-Integration-Design-Document.md](./03-Integration-Design-Document.md)
