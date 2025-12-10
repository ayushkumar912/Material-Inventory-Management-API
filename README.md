# Material Inventory Management API

A multi-tenant REST API for managing material inventory with user management, transaction tracking, and plan-based limits. Built with Node.js, Express, TypeScript, Prisma, and PostgreSQL.

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
│  │  • resolveTenant - Validates tenant & injects context  │  │
│  │  • errorHandler - Centralizes error responses          │  │
│  └────────────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────────────┐  │
│  │         Routes Layer                                   │  │
│  │  /health   /tenants   /users   /materials              │  │
│  │  /transactions                                         │  │
│  └────────────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────────────┐  │
│  │         Controllers Layer                              │  │
│  │  • Validate request data                              │  │
│  │  • Call service methods                               │  │
│  │  • Format responses                                   │  │
│  └────────────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────────────┐  │
│  │         Services Layer                                 │  │
│  │  • Business logic                                     │  │
│  │  • Tenant isolation (WHERE tenantId = ?)              │  │
│  │  • Plan limits enforcement                            │  │
│  │  • Data validation                                    │  │
│  └────────────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────────────┐  │
│  │         Prisma ORM Layer                              │  │
│  │  • Type-safe database queries                         │  │
│  │  • Transaction support                                │  │
│  │  • Migrations                                         │  │
│  └────────────────────────────────────────────────────────┘  │
└────────────────────────────┬─────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────┐
│                   PostgreSQL Database                         │
│  Tables: Tenant, User, Material, Transaction                 │
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
   • Returns 401 if missing/invalid

3. Transaction Controller:
   • Validates quantity > 0
   • Validates type is "IN" or "OUT"
   • Calls transactionService.createTransaction()

4. Transaction Service:
   • Verifies material belongs to tenant (materialService.getMaterialById)
   • Checks stock sufficiency for OUT transactions
   • Uses Prisma.$transaction for atomic operation:
     a) Creates Transaction record
     b) Updates Material.currentStock (+/- quantity)
   • Returns both transaction and updated material

5. Controller formats response:
   { message: "Transaction created successfully", data: { transaction, material } }

6. Client receives JSON with transaction details and new stock level
```

### Multi-Tenant Isolation Strategy

**Every database query includes `tenantId` filter:**
- Users can only access their tenant's data
- Cross-tenant access returns 404 (not 403 to avoid information leakage)
- Middleware ensures tenant context before any data access

**Example Service Query:**
```typescript
// CORRECT: Tenant-scoped query
const user = await prisma.user.findFirst({
  where: { id, tenantId }
});

// WRONG: Would allow cross-tenant access
const user = await prisma.user.findFirst({
  where: { id }
});
```

### Plan-Based Limits

| Feature | FREE Plan | PRO Plan |
|---------|-----------|----------|
| Materials | Max 5 | Unlimited |
| Users | Unlimited | Unlimited |
| Transactions | Unlimited | Unlimited |

**Implementation:** 
- `materialService.createMaterial()` checks tenant plan before creation
- Returns 403 error when FREE tenant exceeds 5 materials

##  Project Structure

```
codeledger/
├── src/
│   ├── app.ts                     # Express app configuration
│   ├── server.ts                  # HTTP server entry point
│   ├── controllers/
│   │   ├── tenant.controller.ts   # Tenant CRUD handlers
│   │   ├── user.controller.ts     # User CRUD handlers
│   │   ├── material.controller.ts # Material CRUD handlers
│   │   └── transaction.controller.ts # Transaction handlers
│   ├── services/
│   │   ├── tenant.service.ts      # Tenant business logic
│   │   ├── user.service.ts        # User business logic + email uniqueness
│   │   ├── material.service.ts    # Material logic + plan limits
│   │   └── transaction.service.ts # Transaction logic + stock management
│   ├── middleware/
│   │   ├── tenant.ts              # resolveTenant (validates x-tenant-id)
│   │   └── error.ts               # errorHandler (centralizes errors)
│   ├── routes/
│   │   ├── tenant.routes.ts       # POST /tenants
│   │   ├── user.routes.ts         # /users CRUD endpoints
│   │   ├── material.routes.ts     # /materials CRUD endpoints
│   │   └── transaction.routes.ts  # /transactions endpoints
│   └── db/
│       └── prisma.ts              # Prisma client singleton
├── prisma/
│   ├── schema.prisma              # Database schema
│   └── migrations/                # Migration history
├── test-api.sh                    # Complete test suite
├── package.json
└── tsconfig.json
```

##  Setup Instructions

### Prerequisites
- Node.js 18+ and npm
- PostgreSQL 14+
- `jq` (for running tests): `brew install jq`

### Installation

1. **Clone and install dependencies:**
```bash
git clone <repository-url>
cd codeledger
npm install
```

2. **Configure environment:**
```bash
# Create .env file
cat > .env << EOF
DATABASE_URL="postgresql://user:password@localhost:5432/codeledger?schema=public"
PORT=3000
EOF
```

3. **Setup database:**
```bash
# Create database
createdb codeledger

# Run migrations
npx prisma migrate dev

# (Optional) Open Prisma Studio to view data
npx prisma studio
```

4. **Start development server:**
```bash
npm run dev
# Server runs on http://localhost:3000
```

##  Testing

### Run Complete Test Suite
```bash
./test-api.sh
```

**Output:** Automated tests covering:
- Health check
- Tenant creation (FREE & PRO plans)
- User CRUD operations (5 tests)
- Material CRUD operations
- Transaction operations (IN/OUT)
- Transaction detail retrieval
- Multi-tenant isolation (materials & users)
- Plan limit enforcement
- Stock validation
- Header validation

### Manual Testing Examples

**1. Create a tenant:**
```bash
curl -X POST http://localhost:3000/tenants \
  -H "Content-Type: application/json" \
  -d '{"name": "Acme Corp", "plan": "FREE"}'

# Response:
{
  "message": "Tenant created successfully",
  "data": {
    "id": "cm52abc...",
    "name": "Acme Corp",
    "plan": "FREE",
    "createdAt": "2024-12-10T...",
    "updatedAt": "2024-12-10T..."
  }
}
```

**2. Create a user:**
```bash
TENANT_ID="cm52abc..." # Use tenant ID from above

curl -X POST http://localhost:3000/users \
  -H "Content-Type: application/json" \
  -H "x-tenant-id: $TENANT_ID" \
  -d '{"email": "john@acme.com", "name": "John Doe", "role": "ADMIN"}'
```

**3. Create a material:**
```bash
TENANT_ID="cm52abc..." # Use tenant ID from above

curl -X POST http://localhost:3000/materials \
  -H "Content-Type: application/json" \
  -H "x-tenant-id: $TENANT_ID" \
  -d '{"name": "Steel Rods", "unit": "kg", "currentStock": 100}'
```

**3. Create a material:**
```bash
curl -X POST http://localhost:3000/materials \
  -H "Content-Type: application/json" \
  -H "x-tenant-id: $TENANT_ID" \
  -d '{"name": "Steel Rods", "unit": "kg", "currentStock": 100}'
```

**4. Add stock (IN transaction):**
```bash
MATERIAL_ID="cm53xyz..." # Use material ID from above

curl -X POST http://localhost:3000/materials/$MATERIAL_ID/transactions \
  -H "Content-Type: application/json" \
  -H "x-tenant-id: $TENANT_ID" \
  -d '{"quantity": 50, "type": "IN"}'

# Material stock becomes 150
```

**5. Remove stock (OUT transaction):**
```bash
curl -X POST http://localhost:3000/materials/$MATERIAL_ID/transactions \
  -H "Content-Type: application/json" \
  -H "x-tenant-id: $TENANT_ID" \
  -d '{"quantity": 30, "type": "OUT"}'

# Material stock becomes 120
```

## 📚 API Reference

### Base URL
```
http://localhost:3000
```

### Common Headers
```
Content-Type: application/json
x-tenant-id: <tenant-id>  # Required for all endpoints except /health and /tenants
```

---

## Endpoints

### Health Check

#### `GET /health`
Check API status.

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2024-12-10T10:30:00.000Z",
  "service": "material-inventory-api"
}
```

---

### Tenant Management

#### `POST /tenants`
Create a new tenant.

**Request Body:**
```json
{
  "name": "Company Name",
  "plan": "FREE"  // or "PRO"
}
```

**Response:**
```json
{
  "message": "Tenant created successfully",
  "data": {
    "id": "cm52abc123",
    "name": "Company Name",
    "plan": "FREE",
    "createdAt": "2024-12-10T10:30:00.000Z",
    "updatedAt": "2024-12-10T10:30:00.000Z"
  }
}
```

---

#### `GET /tenants/:id`
Get tenant by ID.

**Request:**
```bash
curl -X GET http://localhost:3000/tenants/cm52abc123
```

**Response:**
```json
{
  "data": {
    "id": "cm52abc123",
    "name": "Company Name",
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
  "email": "user@example.com",
  "name": "John Doe",
  "role": "ADMIN"  // Optional: "ADMIN" or "USER" (default: "USER")
}
```

**Response:**
```json
{
  "message": "User created successfully",
  "data": {
    "id": "cm53user123",
    "email": "user@example.com",
    "name": "John Doe",
    "role": "USER",
    "tenantId": "cm52abc123",
    "createdAt": "2024-12-10T10:31:00.000Z",
    "updatedAt": "2024-12-10T10:31:00.000Z"
  }
}
```

**Validation:**
- Email must be globally unique across all tenants
- Role must be "ADMIN" or "USER"

---

#### `GET /users`
List all users for tenant.

**Headers:** `x-tenant-id` required

**Response:**
```json
{
  "data": [
    {
      "id": "cm53user123",
      "email": "user@example.com",
      "name": "John Doe",
      "role": "USER",
      "createdAt": "2024-12-10T10:31:00.000Z"
    },
    {
      "id": "cm53user456",
      "email": "admin@example.com",
      "name": "Jane Admin",
      "role": "ADMIN",
      "createdAt": "2024-12-10T10:32:00.000Z"
    }
  ],
  "count": 2
}
```

---

#### `GET /users/:id`
Get user by ID.

**Headers:** `x-tenant-id` required

**Response:**
```json
{
  "data": {
    "id": "cm53user123",
    "email": "user@example.com",
    "name": "John Doe",
    "role": "USER",
    "tenantId": "cm52abc123",
    "createdAt": "2024-12-10T10:31:00.000Z"
  }
}
```

**Errors:**
- `404` - User not found or belongs to different tenant

---

#### `PUT /users/:id`
Update user.

**Headers:** `x-tenant-id` required

**Request Body:**
```json
{
  "name": "John Updated",      // Optional
  "role": "ADMIN"               // Optional: "ADMIN" or "USER"
}
```

**Response:**
```json
{
  "message": "User updated successfully",
  "data": {
    "id": "cm53user123",
    "email": "user@example.com",
    "name": "John Updated",
    "role": "ADMIN",
    "updatedAt": "2024-12-10T10:35:00.000Z"
  }
}
```

**Note:** Email cannot be updated (immutable)

---

#### `DELETE /users/:id`
Delete user.

**Headers:** `x-tenant-id` required

**Response:**
```json
{
  "message": "User deleted successfully"
}
```

**Errors:**
- `404` - User not found or belongs to different tenant

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

**Response:**
```json
{
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

**Plan Limits:**
- FREE: Maximum 5 materials (returns 403 when limit exceeded)
- PRO: Unlimited

**Validation:**
- Material name must be unique per tenant

---

#### `GET /materials`
List all materials for tenant.

**Headers:** `x-tenant-id` required

**Response:**
```json
{
  "data": [
    {
      "id": "cm53mat123",
      "name": "Steel Rods",
      "unit": "kg",
      "currentStock": 150,
      "createdAt": "2024-12-10T10:40:00.000Z",
      "updatedAt": "2024-12-10T10:40:00.000Z"
    },
    {
      "id": "cm53mat456",
      "name": "Aluminum Sheets",
      "unit": "pieces",
      "currentStock": 75,
      "createdAt": "2024-12-10T10:41:00.000Z",
      "updatedAt": "2024-12-10T10:41:00.000Z"
    }
  ],
  "count": 2
}
```

---

#### `GET /materials/:id`
Get material with transaction history.

**Headers:** `x-tenant-id` required

**Response:**
```json
{
  "data": {
    "id": "cm53mat123",
    "name": "Steel Rods",
    "unit": "kg",
    "currentStock": 150,
    "tenantId": "cm52abc123",
    "createdAt": "2024-12-10T10:40:00.000Z",
    "updatedAt": "2024-12-10T10:40:00.000Z",
    "transactions": [
      {
        "id": "cm54txn123",
        "quantity": 50,
        "type": "IN",
        "createdAt": "2024-12-10T10:45:00.000Z"
      },
      {
        "id": "cm54txn456",
        "quantity": 30,
        "type": "OUT",
        "createdAt": "2024-12-10T10:50:00.000Z"
      }
    ]
  }
}
```

---

### Transaction Management

#### `POST /materials/:id/transactions`
Create a stock transaction (add or remove inventory).

**Headers:** `x-tenant-id` required

**Request Body:**
```json
{
  "quantity": 50,
  "type": "IN"  // "IN" to add stock, "OUT" to remove
}
```

**Response:**
```json
{
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

**Validation:**
- Quantity must be > 0
- For OUT transactions: Ensures sufficient stock available
- Atomic operation: Transaction creation and stock update happen together

**Errors:**
- `400` - Insufficient stock for OUT transaction
- `404` - Material not found or belongs to different tenant

---

#### `GET /transactions`
List all transactions for tenant (across all materials).

**Headers:** `x-tenant-id` required

**Response:**
```json
{
  "data": [
    {
      "id": "cm54txn123",
      "tenantId": "cm52abc123",
      "materialId": "cm53mat123",
      "quantity": 50,
      "type": "IN",
      "createdAt": "2024-12-10T10:45:00.000Z",
      "material": {
        "name": "Steel Rods",
        "unit": "kg"
      }
    },
    {
      "id": "cm54txn456",
      "tenantId": "cm52abc123",
      "materialId": "cm53mat123",
      "quantity": 30,
      "type": "OUT",
      "createdAt": "2024-12-10T10:50:00.000Z",
      "material": {
        "name": "Steel Rods",
        "unit": "kg"
      }
    }
  ],
  "count": 5
}
```

---

#### `GET /transactions/:id` *(NEW)*
Get single transaction with material details.

**Headers:** `x-tenant-id` required

**Response:**
```json
{
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

**Use Case:** View transaction details with associated material information

**Errors:**
- `404` - Transaction not found or belongs to different tenant

---

### Security & Validation

### Tenant Isolation
- All queries filtered by `tenantId`
- Cross-tenant access returns `404` (not `403`)
- Middleware validates tenant before any operation

### Input Validation
- Required fields enforcement
- Transaction type validation (must be "IN" or "OUT")
- Positive number validation (stock, quantity)
- Unique constraints (material names per tenant, emails globally)

### Error Handling
- Centralized error middleware
- Consistent error response format:
```json
{
  "error": "Error type",
  "message": "Error description",
  "statusCode": 400
}
```

##  Tech Stack

- **Runtime:** Node.js 18+
- **Framework:** Express 4.18.2
- **Language:** TypeScript 5.3.3
- **Database:** PostgreSQL 14+
- **ORM:** Prisma 5.22
- **Dev Tools:** tsx (hot reload)

##  Database Schema

```prisma
model Tenant {
  id           String        @id @default(uuid())
  name         String
  plan         Plan          @default(FREE)
  createdAt    DateTime      @default(now()) @map("created_at")
  updatedAt    DateTime      @updatedAt @map("updated_at")
  
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
  updatedAt DateTime @updatedAt @map("updated_at")
  
  tenant    Tenant   @relation(fields: [tenantId], references: [id], onDelete: Cascade)

  @@index([tenantId])
  @@map("users")
}

model Material {
  id           String        @id @default(uuid())
  tenantId     String        @map("tenant_id")
  name         String
  unit         String
  currentStock Float         @default(0) @map("current_stock")
  createdAt    DateTime      @default(now()) @map("created_at")
  updatedAt    DateTime      @updatedAt @map("updated_at")
  
  tenant       Tenant        @relation(fields: [tenantId], references: [id], onDelete: Cascade)
  transactions Transaction[]

  @@index([tenantId])
  @@unique([tenantId, name])
  @@map("materials")
}

model Transaction {
  id         String   @id @default(uuid())
  tenantId   String   @map("tenant_id")
  materialId String   @map("material_id")
  quantity   Float
  type       String   @default("IN") // "IN" or "OUT"
  createdAt  DateTime @default(now()) @map("created_at")
  
  tenant     Tenant   @relation(fields: [tenantId], references: [id], onDelete: Cascade)
  material   Material @relation(fields: [materialId], references: [id], onDelete: Cascade)

  @@index([tenantId])
  @@index([materialId])
  @@index([createdAt])
  @@map("transactions")
}

enum Plan { FREE PRO }
enum Role { ADMIN USER }
```

##  Troubleshooting

### Common Issues

**1. Database connection error:**
```bash
# Check PostgreSQL is running
pg_isready

# Verify DATABASE_URL in .env
# Format: postgresql://user:password@localhost:5432/dbname
```

**2. Migration errors:**
```bash
# Reset database (WARNING: deletes all data)
npx prisma migrate reset

# Or create new migration
npx prisma migrate dev --name fix_name
```

**3. Port already in use:**
```bash
# Change PORT in .env or kill process
lsof -ti:3000 | xargs kill -9
```

**4. TypeScript errors:**
```bash
# Regenerate Prisma client
npx prisma generate

# Clear build cache
rm -rf node_modules dist
npm install
```

## 📝 Development Scripts

```bash
npm run dev         # Start development server (hot reload)
npm run build       # Compile TypeScript to JavaScript
npm start           # Run production build
npm run lint        # Run ESLint
npx prisma studio   # Open database GUI
npx prisma migrate dev  # Create/apply migrations
```



