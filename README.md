# Material Inventory Management API

A multi-tenant REST API for managing material inventory with user management, transaction tracking, and plan-based limits. Built with Node.js, Express, TypeScript, Prisma, and PostgreSQL.

---

## Architecture Overview

### System Design

```
┌──────────────────────────────────────────────────────────────┐
│                        Client Application                     │
└────────────────────────────┬─────────────────────────────────┘
                             │ HTTP Requests
                             │ (x-tenant-id header)
                             ▼
┌──────────────────────────────────────────────────────────────┐
│                     Express Application                       │
│  ┌────────────────────────────────────────────────────────┐  │
│  │         Middleware Layer                               │  │
│  │  • resolveTenant  - Validates tenant & injects context │  │
│  │  • validateBody   - Zod schema validation on body      │  │
│  │  • errorHandler   - Centralizes error responses        │  │
│  └────────────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────────────┐  │
│  │         Routes Layer                                   │  │
│  │  /health   /tenants   /users   /materials              │  │
│  │  /transactions                                         │  │
│  └────────────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────────────┐  │
│  │         Controllers Layer                              │  │
│  │  • Call service methods                               │  │
│  │  • Format responses via response helpers              │  │
│  │  • Parse pagination query params                      │  │
│  └────────────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────────────┐  │
│  │         Services Layer                                 │  │
│  │  • Business logic                                     │  │
│  │  • Tenant isolation (WHERE tenantId = ?)              │  │
│  │  • Plan limits enforcement                            │  │
│  │  • Paginated queries with total counts               │  │
│  └────────────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────────────┐  │
│  │         Prisma ORM Layer                              │  │
│  │  • Type-safe database queries                         │  │
│  │  • Atomic transaction support                         │  │
│  │  • Migrations + Seed data                            │  │
│  └────────────────────────────────────────────────────────┘  │
└────────────────────────────┬─────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────┐
│                   PostgreSQL Database                         │
│  Tables: tenants, users, materials, transactions             │
│  Row-Level Isolation: All data scoped by tenantId            │
└──────────────────────────────────────────────────────────────┘
```

### Data Flow: Creating a Transaction

```
1. Client sends: POST /materials/:id/transactions
   Headers: { "x-tenant-id": "abc123", "Content-Type": "application/json" }
   Body: { "quantity": 50, "type": "IN" }

2. resolveTenant Middleware:
   • Extracts tenant ID from header
   • Validates tenant exists in database
   • Attaches tenantId to req.tenantId
   • Returns 400 if missing, 404 if tenant not found

3. validateBody Middleware (Zod):
   • Parses and validates quantity (must be positive number)
   • Validates type (must be "IN" or "OUT")
   • Returns 400 with detailed message on failure

4. Transaction Controller:
   • Calls transactionService.createTransaction()

5. Transaction Service:
   • Verifies material belongs to tenant (getMaterialById)
   • Checks stock sufficiency for OUT transactions
   • Uses prisma.$transaction for atomic operation:
     a) Creates Transaction record
     b) Updates Material.currentStock (+/- quantity)
   • Returns both transaction and updated material

6. Client receives:
   { "success": true, "message": "Transaction created successfully", "data": { transaction, material } }
```

### Multi-Tenant Isolation Strategy

**Every database query includes a `tenantId` filter:**
- Users can only access their own tenant's data
- Cross-tenant access returns `404` (not `403`, to avoid information leakage)
- `resolveTenant` middleware validates the tenant before any route handler runs

### Plan-Based Limits

| Feature | FREE Plan | PRO Plan |
|---------|-----------|----------|
| Materials | Max 5 | Unlimited |
| Users | Unlimited | Unlimited |
| Transactions | Unlimited | Unlimited |

`materialService.createMaterial()` checks the tenant's plan before creation and returns `403` when a FREE tenant exceeds 5 materials.

---

## Project Structure

```
material-inventory-api/
├── src/
│   ├── app.ts                     # Express app + health check
│   ├── server.ts                  # HTTP server entry point
│   ├── controllers/
│   │   ├── tenant.controller.ts
│   │   ├── user.controller.ts
│   │   ├── material.controller.ts
│   │   └── transaction.controller.ts
│   ├── services/
│   │   ├── tenant.service.ts      # Tenant logic + plan limits
│   │   ├── user.service.ts        # User CRUD + email uniqueness
│   │   ├── material.service.ts    # Material logic + pagination
│   │   └── transaction.service.ts # Atomic stock management + pagination
│   ├── middleware/
│   │   ├── tenant.ts              # resolveTenant middleware
│   │   ├── validate.ts            # validateBody(schema) middleware
│   │   └── error.ts               # Centralized error handler
│   ├── routes/
│   │   ├── tenant.routes.ts
│   │   ├── user.routes.ts
│   │   ├── material.routes.ts
│   │   └── transaction.routes.ts
│   ├── schemas/                   # Zod validation schemas
│   │   ├── tenant.schema.ts
│   │   ├── user.schema.ts
│   │   ├── material.schema.ts
│   │   └── transaction.schema.ts
│   ├── utils/
│   │   ├── response.ts            # sendSuccess / sendCreated / sendList / sendMessage
│   │   └── pagination.ts          # parsePagination / buildMeta
│   └── db/
│       └── prisma.ts              # Prisma client singleton
├── prisma/
│   ├── schema.prisma              # Database schema
│   ├── seed.ts                    # Seed data (2 tenants, 4 users, 6 materials)
│   └── migrations/                # Migration history
├── test-api.sh                    # Complete test suite (28 tests)
├── package.json
└── tsconfig.json
```

---

## Setup Instructions

### Prerequisites
- Node.js 18+
- PostgreSQL 14+
- `jq` (for running tests): `brew install jq`

### Installation

**1. Clone and install dependencies:**
```bash
git clone <repository-url>
cd material-inventory-api
npm install
```

**2. Configure environment:**
```bash
cp .env.example .env
# Edit .env with your database credentials
```

```env
DATABASE_URL="postgresql://user:password@localhost:5432/material_inventory"
PORT=3000
NODE_ENV=development
```

**3. Set up the database:**
```bash
# Run migrations (also regenerates the Prisma client)
npx prisma migrate dev --name init

# Seed with sample data
npm run db:seed
```

**4. Start the development server:**
```bash
npm run dev
# Server running at http://localhost:3000
```

---

## Seed Data

Running `npm run db:seed` populates the database with realistic sample data:

| Tenant | Plan | Users | Materials |
|--------|------|-------|-----------|
| Acme Corp | FREE | alice@acme.com (ADMIN), bob@acme.com (USER) | Steel Rods (kg), Copper Wire (m) |
| Globex Industries | PRO | carol@globex.com (ADMIN), dave@globex.com (USER) | Aluminium Sheets, Plastic Pellets, Carbon Fiber, Titanium Bolts |

Each material has a realistic IN/OUT transaction history with stock derived from it. The seed is **idempotent** — re-running it is safe and produces the same result.

Use the seeded tenant IDs (printed after seed completes) as your `x-tenant-id` header when testing manually.

---

## Testing

### Run Complete Test Suite
```bash
./test-api.sh
```

**28 automated tests covering:**
- Health check (with DB probe)
- Tenant creation (FREE & PRO plans)
- User CRUD (create, list, get, update, delete)
- Material CRUD
- Transaction operations (IN/OUT) with stock tracking
- Transaction detail retrieval
- Pagination (`?page=&limit=` on all list endpoints)
- Multi-tenant isolation (materials & users)
- Plan limit enforcement (FREE max 5)
- Zod validation (invalid email, missing fields, invalid enum, zero quantity)
- Duplicate email → 409 Conflict
- Insufficient stock → 400
- Missing tenant header → 400
- Empty update body → 400

---

## API Reference

### Base URL
```
http://localhost:3000
```

### Common Headers
```
Content-Type: application/json
x-tenant-id: <tenant-id>   # Required for all endpoints except /health and /tenants
```

### Response Envelope

All responses share a consistent envelope:

**Success (single resource):**
```json
{ "success": true, "data": { ... }, "message": "Optional message" }
```

**Success (list):**
```json
{
  "success": true,
  "data": [ ... ],
  "meta": { "total": 25, "page": 1, "limit": 20, "totalPages": 2 }
}
```

**Error:**
```json
{ "success": false, "error": "Error type", "message": "Details" }
```

### Pagination

All list endpoints support query parameters:

| Param | Default | Max | Description |
|-------|---------|-----|-------------|
| `page` | `1` | — | Page number (1-based) |
| `limit` | `20` | `100` | Items per page |

```bash
GET /materials?page=2&limit=10
```

---

## Endpoints

### Health Check

#### `GET /health`
Returns API status and database connectivity.

**Response (200 — healthy):**
```json
{
  "success": true,
  "data": {
    "status": "ok",
    "db": "connected",
    "timestamp": "2024-12-10T10:30:00.000Z",
    "service": "material-inventory-api"
  }
}
```

**Response (503 — DB unreachable):**
```json
{
  "success": true,
  "data": {
    "status": "degraded",
    "db": "disconnected",
    "timestamp": "2024-12-10T10:30:00.000Z",
    "service": "material-inventory-api"
  }
}
```

---

### Tenant Management

#### `POST /tenants`
Create a new tenant.

**Request Body:**
```json
{
  "name": "Acme Corp",
  "plan": "FREE"
}
```

| Field | Type | Required | Rules |
|-------|------|----------|-------|
| `name` | string | Yes | Max 100 chars |
| `plan` | `"FREE"` \| `"PRO"` | No | Defaults to `"FREE"` |

**Response (201):**
```json
{
  "success": true,
  "message": "Tenant created successfully",
  "data": {
    "id": "cm52abc123",
    "name": "Acme Corp",
    "plan": "FREE",
    "createdAt": "2024-12-10T10:30:00.000Z",
    "updatedAt": "2024-12-10T10:30:00.000Z"
  }
}
```

---

#### `GET /tenants/:id`
Get tenant by ID.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "cm52abc123",
    "name": "Acme Corp",
    "plan": "FREE",
    "createdAt": "2024-12-10T10:30:00.000Z",
    "updatedAt": "2024-12-10T10:30:00.000Z"
  }
}
```

---

### User Management

#### `POST /users`
Create a new user.

**Headers:** `x-tenant-id` required

**Request Body:**
```json
{
  "email": "john@acme.com",
  "name": "John Doe",
  "role": "ADMIN"
}
```

| Field | Type | Required | Rules |
|-------|------|----------|-------|
| `email` | string | Yes | Valid email format, max 255 chars, globally unique |
| `name` | string | Yes | Max 100 chars |
| `role` | `"ADMIN"` \| `"USER"` | No | Defaults to `"USER"` |

**Response (201):**
```json
{
  "success": true,
  "message": "User created successfully",
  "data": {
    "id": "cm53user123",
    "email": "john@acme.com",
    "name": "John Doe",
    "role": "ADMIN",
    "tenantId": "cm52abc123",
    "createdAt": "2024-12-10T10:31:00.000Z",
    "updatedAt": "2024-12-10T10:31:00.000Z"
  }
}
```

**Errors:**
- `400` — Validation error (invalid email, missing name)
- `409` — Email already exists

---

#### `GET /users`
List all users for tenant (paginated).

**Headers:** `x-tenant-id` required

**Query Params:** `page`, `limit`

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "cm53user123",
      "email": "john@acme.com",
      "name": "John Doe",
      "role": "ADMIN",
      "createdAt": "2024-12-10T10:31:00.000Z"
    }
  ],
  "meta": { "total": 2, "page": 1, "limit": 20, "totalPages": 1 }
}
```

---

#### `GET /users/:id`
Get user by ID.

**Headers:** `x-tenant-id` required

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "cm53user123",
    "email": "john@acme.com",
    "name": "John Doe",
    "role": "ADMIN",
    "tenantId": "cm52abc123",
    "createdAt": "2024-12-10T10:31:00.000Z"
  }
}
```

**Errors:** `404` — User not found or belongs to a different tenant

---

#### `PUT /users/:id`
Update user name and/or role. Email is immutable.

**Headers:** `x-tenant-id` required

**Request Body:** (at least one field required)
```json
{
  "name": "John Updated",
  "role": "ADMIN"
}
```

| Field | Type | Rules |
|-------|------|-------|
| `name` | string | Max 100 chars |
| `role` | `"ADMIN"` \| `"USER"` | — |

**Response (200):**
```json
{
  "success": true,
  "message": "User updated successfully",
  "data": {
    "id": "cm53user123",
    "email": "john@acme.com",
    "name": "John Updated",
    "role": "ADMIN",
    "updatedAt": "2024-12-10T10:35:00.000Z"
  }
}
```

**Errors:**
- `400` — Empty body (at least one field required)
- `404` — User not found

---

#### `DELETE /users/:id`
Delete user.

**Headers:** `x-tenant-id` required

**Response (200):**
```json
{ "success": true, "message": "User deleted successfully" }
```

**Errors:** `404` — User not found

---

### Material Management

#### `POST /materials`
Create a material.

**Headers:** `x-tenant-id` required

**Request Body:**
```json
{
  "name": "Steel Rods",
  "unit": "kg",
  "currentStock": 100
}
```

| Field | Type | Required | Rules |
|-------|------|----------|-------|
| `name` | string | Yes | Max 100 chars, unique per tenant |
| `unit` | string | Yes | Max 50 chars |
| `currentStock` | number | No | Non-negative, defaults to `0` |

**Response (201):**
```json
{
  "success": true,
  "message": "Material created successfully",
  "data": {
    "id": "cm53mat123",
    "name": "Steel Rods",
    "unit": "kg",
    "currentStock": 100,
    "tenantId": "cm52abc123",
    "createdAt": "2024-12-10T10:40:00.000Z",
    "updatedAt": "2024-12-10T10:40:00.000Z"
  }
}
```

**Errors:**
- `400` — Validation error
- `403` — FREE plan material limit (5) exceeded
- `409` — Material name already exists for this tenant

---

#### `GET /materials`
List all materials for tenant (paginated).

**Headers:** `x-tenant-id` required

**Query Params:** `page`, `limit`

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "cm53mat123",
      "name": "Steel Rods",
      "unit": "kg",
      "currentStock": 450,
      "tenantId": "cm52abc123",
      "createdAt": "2024-12-10T10:40:00.000Z",
      "updatedAt": "2024-12-10T10:50:00.000Z"
    }
  ],
  "meta": { "total": 2, "page": 1, "limit": 20, "totalPages": 1 }
}
```

---

#### `GET /materials/:id`
Get material with full transaction history.

**Headers:** `x-tenant-id` required

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "cm53mat123",
    "name": "Steel Rods",
    "unit": "kg",
    "currentStock": 450,
    "tenantId": "cm52abc123",
    "createdAt": "2024-12-10T10:40:00.000Z",
    "updatedAt": "2024-12-10T10:50:00.000Z",
    "transactions": [
      { "id": "cm54txn456", "quantity": 30, "type": "OUT", "createdAt": "2024-12-10T10:50:00.000Z" },
      { "id": "cm54txn123", "quantity": 500, "type": "IN",  "createdAt": "2024-12-10T10:45:00.000Z" }
    ]
  }
}
```

**Errors:** `404` — Material not found or belongs to a different tenant

---

### Transaction Management

#### `POST /materials/:id/transactions`
Create a stock transaction (IN to add, OUT to remove). Atomically updates material stock.

**Headers:** `x-tenant-id` required

**Request Body:**
```json
{
  "quantity": 50,
  "type": "IN"
}
```

| Field | Type | Required | Rules |
|-------|------|----------|-------|
| `quantity` | number | Yes | Must be > 0 |
| `type` | `"IN"` \| `"OUT"` | Yes | — |

**Response (201):**
```json
{
  "success": true,
  "message": "Transaction created successfully",
  "data": {
    "transaction": {
      "id": "cm54txn123",
      "tenantId": "cm52abc123",
      "materialId": "cm53mat123",
      "quantity": 50,
      "type": "IN",
      "createdAt": "2024-12-10T10:45:00.000Z"
    },
    "material": {
      "id": "cm53mat123",
      "name": "Steel Rods",
      "unit": "kg",
      "currentStock": 150,
      "tenantId": "cm52abc123",
      "createdAt": "2024-12-10T10:40:00.000Z",
      "updatedAt": "2024-12-10T10:45:00.000Z"
    }
  }
}
```

**Errors:**
- `400` — Validation error or insufficient stock for OUT transaction
- `404` — Material not found or belongs to a different tenant

---

#### `GET /transactions`
List all transactions for tenant across all materials (paginated).

**Headers:** `x-tenant-id` required

**Query Params:** `page`, `limit`

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "cm54txn123",
      "tenantId": "cm52abc123",
      "materialId": "cm53mat123",
      "quantity": 50,
      "type": "IN",
      "createdAt": "2024-12-10T10:45:00.000Z",
      "material": { "name": "Steel Rods", "unit": "kg" }
    }
  ],
  "meta": { "total": 8, "page": 1, "limit": 20, "totalPages": 1 }
}
```

---

#### `GET /transactions/:id`
Get a single transaction with material details.

**Headers:** `x-tenant-id` required

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "cm54txn123",
    "tenantId": "cm52abc123",
    "materialId": "cm53mat123",
    "quantity": 50,
    "type": "IN",
    "createdAt": "2024-12-10T10:45:00.000Z",
    "material": {
      "id": "cm53mat123",
      "name": "Steel Rods",
      "unit": "kg",
      "currentStock": 150
    }
  }
}
```

**Errors:** `404` — Transaction not found or belongs to a different tenant

---

## Validation

All request bodies are validated by **Zod schemas** before reaching controllers. Validation errors return:

```json
{
  "success": false,
  "error": "Validation error",
  "message": "Invalid email format, Name is required and cannot be empty"
}
```

| Schema | Rules |
|--------|-------|
| `createTenantSchema` | `name` max 100, `plan` enum |
| `createUserSchema` | `email` format + max 255, `name` max 100, `role` enum |
| `updateUserSchema` | At least one of `name` or `role` required |
| `createMaterialSchema` | `name` max 100, `unit` max 50, `currentStock` non-negative |
| `createTransactionSchema` | `quantity` positive, `type` enum |

---

## Error Reference

| Status | Meaning |
|--------|---------|
| `400` | Validation error (Zod), business logic failure (insufficient stock) |
| `403` | Plan limit exceeded |
| `404` | Resource not found or tenant isolation violation |
| `409` | Duplicate entry (email, material name per tenant) |
| `503` | Health check — database unreachable |
| `500` | Unexpected server error |

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Runtime | Node.js 18+ |
| Framework | Express 4.18 |
| Language | TypeScript 5.3 |
| Validation | Zod 4 |
| ORM | Prisma 5.22 |
| Database | PostgreSQL 14+ |
| Dev server | tsx (hot reload) |

---

## Database Schema

```prisma
enum Plan            { FREE PRO }
enum Role            { ADMIN USER }
enum TransactionType { IN OUT }

model Tenant {
  id        String   @id @default(uuid())
  name      String
  plan      Plan     @default(FREE)
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt      @map("updated_at")
  users        User[]
  materials    Material[]
  transactions Transaction[]
  @@map("tenants")
}

model User {
  id        String   @id @default(uuid())
  tenantId  String   @map("tenant_id")
  email     String   @unique
  name      String
  role      Role     @default(USER)
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt      @map("updated_at")
  tenant    Tenant   @relation(fields: [tenantId], references: [id], onDelete: Cascade)
  @@index([tenantId])
  @@map("users")
}

model Material {
  id           String   @id @default(uuid())
  tenantId     String   @map("tenant_id")
  name         String
  unit         String
  currentStock Float    @default(0) @map("current_stock")
  createdAt    DateTime @default(now()) @map("created_at")
  updatedAt    DateTime @updatedAt      @map("updated_at")
  tenant       Tenant        @relation(fields: [tenantId], references: [id], onDelete: Cascade)
  transactions Transaction[]
  @@index([tenantId])
  @@unique([tenantId, name])
  @@map("materials")
}

model Transaction {
  id         String          @id @default(uuid())
  tenantId   String          @map("tenant_id")
  materialId String          @map("material_id")
  quantity   Float
  type       TransactionType @default(IN)
  createdAt  DateTime        @default(now()) @map("created_at")
  tenant     Tenant   @relation(fields: [tenantId],   references: [id], onDelete: Cascade)
  material   Material @relation(fields: [materialId], references: [id], onDelete: Cascade)
  @@index([tenantId])
  @@index([materialId])
  @@index([createdAt])
  @@map("transactions")
}
```

---

## Development Scripts

```bash
npm run dev              # Start server with hot reload
npm run build            # Compile TypeScript → dist/
npm start                # Run compiled build

npm run db:seed          # Seed database with sample data
npm run prisma:migrate   # Create and apply a new migration
npm run prisma:generate  # Regenerate Prisma client
npm run prisma:studio    # Open Prisma Studio (DB GUI)
npm run db:push          # Push schema changes without a migration
```

---

## Troubleshooting

**Database connection error:**
```bash
pg_isready   # Check PostgreSQL is running
# Verify DATABASE_URL format: postgresql://user:password@localhost:5432/dbname
```

**Reset database and re-seed:**
```bash
npx prisma migrate reset   # WARNING: deletes all data, re-runs migrations and seed
```

**Port already in use:**
```bash
lsof -ti:3000 | xargs kill -9
```

**Prisma type errors after schema change:**
```bash
npx prisma migrate dev --name <migration_name>   # runs generate automatically
# or manually:
npx prisma generate
```

**Clear build and reinstall:**
```bash
rm -rf node_modules dist && npm install
```
