# Fresco's Kitchen — Complete Local Testing Guide

This guide provides detailed, step-by-step instructions to set up, run, and test each of the 9 microservices independently on your local machine.

---

## 1. System Prerequisites

Before running any service, ensure that the following system-level dependencies are installed and running:

### Required Software & Versions
- **Node.js**: `v20.0.0` or higher (Required for all NestJS services).
- **pnpm**: `v10.31.0` or higher (Required package manager for NestJS services).
- **Python**: `v3.10` or higher (Required for the `frescos-reports-ml-service`).
- **PostgreSQL**: `v14` or higher (Running locally on default port `5432`).
- **Redis**: `v7` or higher (Running locally on default port `6379`).
- **OpenSSL**: Required to generate local RSA keys for JWT authentication.

### Global Database Setup
Each NestJS microservice uses its own logical database. Connect to your local PostgreSQL instance (e.g., via `psql` or pgAdmin) and run:

```sql
CREATE DATABASE frescos_auth;
CREATE DATABASE frescos_profile;
CREATE DATABASE frescos_menu;
CREATE DATABASE frescos_oms;
CREATE DATABASE frescos_payment;
CREATE DATABASE frescos_inventory;
CREATE DATABASE frescos_notifications;
CREATE DATABASE frescos_admin;
```

### JWT RSA Key Generation
The platform uses RS256 asymmetric encryption for JWT. You need a private/public key pair. Run this in your terminal to generate them:
```bash
openssl genrsa -out private.pem 4096
openssl rsa -in private.pem -pubout -out public.pem
```
You will use the contents of these files in the `.env` configuration for the services.

---

## 2. General Setup Instructions (NestJS Services)

For all 8 NestJS services, the general setup flow is identical:

1. **Navigate to the service directory:** `cd d:\Data_HDD\Frescos_Restaurant\backend-services\<service-name>`
2. **Install dependencies:** `pnpm install`
3. **Create Environment File:** Create a `.env` file based on the instructions below.
4. **Start the Service:** `pnpm run start:dev`
5. **Swagger UI Verification:** Open `http://localhost:<PORT>/api/docs` in your browser. If it loads, the service is running correctly. TypeORM will automatically sync and create the database tables on startup.

---

## 3. Service-by-Service Testing Guide

### 3.1 Auth Service (`frescos-auth-service`)
**Port**: `3001`
**Database**: `frescos_auth`

**Environment (`.env`)**:
```env
PORT=3001
NODE_ENV=development
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=your_pg_password
DB_DATABASE=frescos_auth
REDIS_HOST=localhost
REDIS_PORT=6379
JWT_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----\n...\n-----END RSA PRIVATE KEY-----"
JWT_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----"
JWT_ACCESS_EXPIRES=30m
MSG91_AUTH_KEY=mocked_in_dev
```

**Test: Request OTP**
```bash
curl -X POST http://localhost:3001/api/v1/auth/otp/request \
  -H "Content-Type: application/json" \
  -d '{"phone": "+919876543210"}'
```
*Expected Output:*
```json
{
  "success": true,
  "data": { "message": "OTP sent successfully", "expires_in": 600 }
}
```

**Test: Verify OTP & Get Token**
```bash
curl -X POST http://localhost:3001/api/v1/auth/otp/verify \
  -H "Content-Type: application/json" \
  -d '{"phone": "+919876543210", "otp": "the_otp_from_console"}'
```
*Expected Output:* Returns an `access_token` and `refresh_token`. *Copy the `access_token` to use as the Bearer token for other services.*

---

### 3.2 User Profile Service (`frescos-user-profile-service`)
**Port**: `3002`
**Database**: `frescos_profile`

**Environment (`.env`)**:
```env
PORT=3002
DB_DATABASE=frescos_profile
JWT_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----"
```

**Test: Get Profile**
```bash
curl -X GET http://localhost:3002/api/v1/users/me \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>"
```

---

### 3.3 Menu CMS Service (`frescos-menu-cms-service`)
**Port**: `3003`
**Database**: `frescos_menu`

**Environment (`.env`)**:
```env
PORT=3003
DB_DATABASE=frescos_menu
JWT_PUBLIC_KEY="..."
```

**Test: Get All Menu (Public)**
```bash
curl -X GET http://localhost:3003/api/v1/menu
```
*Expected Output:*
```json
{
  "success": true,
  "data": {
    "items": [],
    "meta": { "page": 1, "limit": 20, "total": 0, "totalPages": 0 }
  }
}
```

---

### 3.4 Order Management Service (OMS) (`frescos-oms-service`)
**Port**: `3004`
**Database**: `frescos_oms`

**Environment (`.env`)**:
```env
PORT=3004
DB_DATABASE=frescos_oms
JWT_PUBLIC_KEY="..."
```

**Test: Place a Guest Order (No Auth Needed)**
```bash
curl -X POST http://localhost:3004/api/v1/orders \
  -H "Content-Type: application/json" \
  -d '{
    "outlet_id": "00000000-0000-0000-0000-000000000000",
    "order_type": "pickup",
    "payment_method": "cash",
    "customer_name": "Test Guest",
    "customer_whatsapp": "+919999999999",
    "items": [
      {
        "menu_item_id": "00000000-0000-0000-0000-000000000000",
        "quantity": 2
      }
    ]
  }'
```
*Expected Output:*
```json
{
  "success": true,
  "data": {
    "orderNumber": "PIZ-20260322-1234",
    "status": "initiated",
    "subtotal": 200.0
  }
}
```

---

### 3.5 Payment Service (`frescos-payment-service`)
**Port**: `3005`
**Database**: `frescos_payment`

**Environment (`.env`)**:
```env
PORT=3005
DB_DATABASE=frescos_payment
JWT_PUBLIC_KEY="..."
RAZORPAY_KEY_ID=test_id
RAZORPAY_KEY_SECRET=test_secret
RAZORPAY_WEBHOOK_SECRET=my_webhook_secret
```

**Test: Create Order**
```bash
curl -X POST http://localhost:3005/api/v1/payments/razorpay/create \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"order_id": "00000000-0000-0000-0000-000000000000"}'
```

---

### 3.6 Inventory Service (`frescos-inventory-service`)
**Port**: `3006`
**Database**: `frescos_inventory`

**Environment (`.env`)**:
```env
PORT=3006
DB_DATABASE=frescos_inventory
JWT_PUBLIC_KEY="..."
```

**Test: Get Low Stock Items (Needs Admin Token)**
```bash
curl -X GET http://localhost:3006/api/v1/admin/inventory/low-stock \
  -H "Authorization: Bearer <ADMIN_ACCESS_TOKEN>"
```

---

### 3.7 Admin Ops Service (`frescos-admin-ops-service`)
**Port**: `3007`
**Database**: `frescos_admin`

**Environment (`.env`)**:
```env
PORT=3007
DB_DATABASE=frescos_admin
JWT_PUBLIC_KEY="..."
```

**Test: List Staff**
```bash
curl -X GET http://localhost:3007/api/v1/admin/staff \
  -H "Authorization: Bearer <ADMIN_ACCESS_TOKEN>"
```

---

### 3.8 Notifications Service (`frescos-notifications-service`)
**Port**: `3008`
**Database**: `frescos_notifications`

**Environment (`.env`)**:
```env
PORT=3008
DB_DATABASE=frescos_notifications
JWT_PUBLIC_KEY="..."
```

**Test: Read My Notifications**
```bash
curl -X GET http://localhost:3008/api/v1/notifications/me \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>"
```

---

### 3.9 Reports & ML Service (`frescos-reports-ml-service` - Python/FastAPI)
**Port**: `8000`

**Setup:**
1. Navigate: `cd d:\Data_HDD\Frescos_Restaurant\backend-services\frescos-reports-ml-service`
2. Create virtual environment: `python -m venv venv`
3. Activate:
   - Windows: `.\venv\Scripts\activate`
   - Mac/Linux: `source venv/bin/activate`
4. Install requirements: `pip install fastapi uvicorn pydantic pyjwt`
5. Run: `uvicorn app.main:app --reload --port 8000`

**Test: Get ML Combo Recommendations**
```bash
curl -X GET http://localhost:8000/api/v1/ml/recommend-combos \
  -H "Authorization: Bearer mock_token"
```
*Expected Output:*
```json
{
  "recommended_combos": [
    {
      "items": ["Margherita Pizza", "Coke 330ml"],
      "confidence": 0.82
    }
  ]
}
```

---

## 4. Troubleshooting

- **`Unhandled Promise Rejection: ConnectionRefused`**: Ensure PostgreSQL (`5432`) and Redis (`6379`) are running globally.
- **`TOKEN_INVALID_OR_MISSING`**: Ensure the exact same `JWT_PUBLIC_KEY` is present in the `.env` file of all the microservices receiving the request. The newline characters `\n` strongly matter in PEM keys.
- **Port Conflicts**: Ensure each `.env` assigns a unique `PORT=` (3001 through 3008, and 8000).
