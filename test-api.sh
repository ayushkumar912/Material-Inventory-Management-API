#!/bin/bash

# Material Inventory API - Complete Test Suite

# Load .env variables
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo ".env file not found. Please create one with PORT defined."
    exit 1
fi

# Ensure PORT is set
if [ -z "$PORT" ]; then
    echo "PORT is not defined in .env"
    exit 1
fi

# Construct BASE_URL from PORT
BASE_URL="http://localhost:$PORT"

echo "Using BASE_URL: $BASE_URL"

# Pre-flight: ensure the server is reachable before running any tests
if ! curl -s --max-time 3 "$BASE_URL/health" > /dev/null 2>&1; then
    echo -e "\033[0;31m✗ Cannot reach $BASE_URL — is the server running? (npm run dev)\033[0m"
    exit 1
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
GRAY='\033[0;37m'
NC='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0
TOTAL_TESTS=0
TIMESTAMP=$(date +%s)

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Material Inventory API - Complete Test Suite           ║${NC}"
echo -e "${BLUE}║   Multi-Tenant System with Full CRUD Operations          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if ! command -v jq &> /dev/null; then
    echo -e "${RED}jq is not installed. Installing via Homebrew...${NC}"
    brew install jq
fi

track_test() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if [ "$1" == "pass" ]; then
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

print_req() {
    echo -e "${PURPLE}  ▸ Request:  $1${NC}"
}

print_res() {
    echo -e "${GRAY}  ◂ Response: $(echo "$1" | jq -c . 2>/dev/null || echo "$1")${NC}"
}

# ─────────────────────────────────────────────────────────────
# Test 1: Health Check (now probes DB)
# ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 1: Health Check (includes DB probe)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
print_req "GET $BASE_URL/health"
HEALTH=$(curl -s "$BASE_URL/health")
print_res "$HEALTH"
if echo "$HEALTH" | jq -e '.data.status == "ok" and .data.db == "connected"' > /dev/null; then
    echo -e "${GREEN}✓ [PASS] Health check - API ok, DB connected${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL] Health check${NC}\n"
    track_test "fail"
fi

# ─────────────────────────────────────────────────────────────
# Test 2: Create FREE Tenant
# ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 2: Create Tenant (FREE Plan)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
print_req "POST $BASE_URL/tenants  {\"name\": \"Test Company FREE\", \"plan\": \"FREE\"}"
TENANT_FREE=$(curl -s -X POST "$BASE_URL/tenants" -H "Content-Type: application/json" -d '{"name": "Test Company FREE", "plan": "FREE"}')
print_res "$TENANT_FREE"
TENANT_FREE_ID=$(echo "$TENANT_FREE" | jq -r '.data.id')
if echo "$TENANT_FREE" | jq -e '.success == true' > /dev/null && [ "$TENANT_FREE_ID" != "null" ]; then
    echo -e "${GREEN}✓ [PASS] FREE Tenant: $TENANT_FREE_ID${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL] Failed to create FREE tenant${NC}\n"
    track_test "fail"
    exit 1
fi

# ─────────────────────────────────────────────────────────────
# Test 3: Create PRO Tenant
# ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 3: Create Tenant (PRO Plan)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
print_req "POST $BASE_URL/tenants  {\"name\": \"Test Company PRO\", \"plan\": \"PRO\"}"
TENANT_PRO=$(curl -s -X POST "$BASE_URL/tenants" -H "Content-Type: application/json" -d '{"name": "Test Company PRO", "plan": "PRO"}')
print_res "$TENANT_PRO"
TENANT_PRO_ID=$(echo "$TENANT_PRO" | jq -r '.data.id')
if echo "$TENANT_PRO" | jq -e '.success == true' > /dev/null && [ "$TENANT_PRO_ID" != "null" ]; then
    echo -e "${GREEN}✓ [PASS] PRO Tenant: $TENANT_PRO_ID${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL]${NC}\n"
    track_test "fail"
    exit 1
fi

# ─────────────────────────────────────────────────────────────
# Test 4: Create Admin User
# ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 4: Create Admin User${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
print_req "POST $BASE_URL/users  [x-tenant-id: $TENANT_FREE_ID]  {\"email\": \"admin-$TIMESTAMP@test.com\", \"name\": \"Admin User\", \"role\": \"ADMIN\"}"
USER1=$(curl -s -X POST "$BASE_URL/users" -H "Content-Type: application/json" -H "x-tenant-id: $TENANT_FREE_ID" -d "{\"email\": \"admin-$TIMESTAMP@test.com\", \"name\": \"Admin User\", \"role\": \"ADMIN\"}")
print_res "$USER1"
USER1_ID=$(echo "$USER1" | jq -r '.data.id')
if echo "$USER1" | jq -e '.success == true' > /dev/null && [ "$USER1_ID" != "null" ]; then
    echo -e "${GREEN}✓ [PASS] Admin user created${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL]${NC}\n"
    track_test "fail"
fi

# ─────────────────────────────────────────────────────────────
# Test 5: Create Regular User
# ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 5: Create Regular User${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
print_req "POST $BASE_URL/users  [x-tenant-id: $TENANT_FREE_ID]  {\"email\": \"user-$TIMESTAMP@test.com\", \"name\": \"Regular User\"}"
USER2=$(curl -s -X POST "$BASE_URL/users" -H "Content-Type: application/json" -H "x-tenant-id: $TENANT_FREE_ID" -d "{\"email\": \"user-$TIMESTAMP@test.com\", \"name\": \"Regular User\"}")
print_res "$USER2"
USER2_ID=$(echo "$USER2" | jq -r '.data.id')
if echo "$USER2" | jq -e '.success == true' > /dev/null && [ "$USER2_ID" != "null" ]; then
    echo -e "${GREEN}✓ [PASS] Regular user created${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL]${NC}\n"
    track_test "fail"
fi

# ─────────────────────────────────────────────────────────────
# Test 6: List Users (paginated response)
# ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 6: List Users (paginated)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
print_req "GET $BASE_URL/users  [x-tenant-id: $TENANT_FREE_ID]"
USERS_LIST=$(curl -s -X GET "$BASE_URL/users" -H "x-tenant-id: $TENANT_FREE_ID")
print_res "$USERS_LIST"
USER_TOTAL=$(echo "$USERS_LIST" | jq -r '.meta.total')
HAS_META=$(echo "$USERS_LIST" | jq -e '.meta.page and .meta.limit and .meta.totalPages' > /dev/null && echo "yes" || echo "no")
if [ "$USER_TOTAL" == "2" ] && [ "$HAS_META" == "yes" ]; then
    echo -e "${GREEN}✓ [PASS] Listed $USER_TOTAL users with pagination meta${NC}\n"
    track_test "pass"
else
    echo -e "${YELLOW}⚠ [WARN] User total: $USER_TOTAL, meta present: $HAS_META${NC}\n"
    track_test "fail"
fi

# ─────────────────────────────────────────────────────────────
# Test 7: Get User by ID
# ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 7: Get User by ID${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
print_req "GET $BASE_URL/users/$USER1_ID  [x-tenant-id: $TENANT_FREE_ID]"
USER_DETAIL=$(curl -s -X GET "$BASE_URL/users/$USER1_ID" -H "x-tenant-id: $TENANT_FREE_ID")
print_res "$USER_DETAIL"
# Email is lowercased by Zod transform, comparison uses lowercase
if echo "$USER_DETAIL" | jq -e ".data.email == \"admin-$TIMESTAMP@test.com\"" > /dev/null; then
    echo -e "${GREEN}✓ [PASS] User details retrieved${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL]${NC}\n"
    track_test "fail"
fi

# ─────────────────────────────────────────────────────────────
# Test 8: Update User
# ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 8: Update User${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
print_req "PUT $BASE_URL/users/$USER2_ID  [x-tenant-id: $TENANT_FREE_ID]  {\"name\": \"Updated User\", \"role\": \"ADMIN\"}"
USER_UPDATE=$(curl -s -X PUT "$BASE_URL/users/$USER2_ID" -H "Content-Type: application/json" -H "x-tenant-id: $TENANT_FREE_ID" -d '{"name": "Updated User", "role": "ADMIN"}')
print_res "$USER_UPDATE"
if echo "$USER_UPDATE" | jq -e '.success == true and .data.name == "Updated User"' > /dev/null; then
    echo -e "${GREEN}✓ [PASS] User updated${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL]${NC}\n"
    track_test "fail"
fi

# ─────────────────────────────────────────────────────────────
# Test 9: Create Material
# ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 9: Create Material${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
print_req "POST $BASE_URL/materials  [x-tenant-id: $TENANT_FREE_ID]  {\"name\": \"Steel Rods\", \"unit\": \"kg\", \"currentStock\": 100}"
MATERIAL=$(curl -s -X POST "$BASE_URL/materials" -H "Content-Type: application/json" -H "x-tenant-id: $TENANT_FREE_ID" -d '{"name": "Steel Rods", "unit": "kg", "currentStock": 100}')
print_res "$MATERIAL"
MATERIAL_ID=$(echo "$MATERIAL" | jq -r '.data.id')
if echo "$MATERIAL" | jq -e '.success == true' > /dev/null && [ "$MATERIAL_ID" != "null" ]; then
    echo -e "${GREEN}✓ [PASS] Material created${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL]${NC}\n"
    track_test "fail"
    exit 1
fi

# ─────────────────────────────────────────────────────────────
# Test 10: FREE Plan Limit (Max 5 materials)
# ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 10: FREE Plan Limit (Max 5 materials)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
for i in {2..5}; do
    curl -s -X POST "$BASE_URL/materials" -H "Content-Type: application/json" -H "x-tenant-id: $TENANT_FREE_ID" -d "{\"name\": \"Material $i\", \"unit\": \"units\", \"currentStock\": $((i * 10))}" > /dev/null
    echo -e "${GREEN}✓ Material $i created${NC}"
done
print_req "POST $BASE_URL/materials  [x-tenant-id: $TENANT_FREE_ID]  {\"name\": \"Material 6\", \"unit\": \"units\", \"currentStock\": 60}  (6th — should be rejected)"
SIXTH=$(curl -s -X POST "$BASE_URL/materials" -H "Content-Type: application/json" -H "x-tenant-id: $TENANT_FREE_ID" -d '{"name": "Material 6", "unit": "units", "currentStock": 60}')
print_res "$SIXTH"
SIXTH_SUCCESS=$(echo "$SIXTH" | jq -r '.success')
if echo "$SIXTH" | grep -q "limit" && [ "$SIXTH_SUCCESS" == "false" ]; then
    echo -e "${GREEN}✓ [PASS] FREE limit enforced (success: false)${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL]${NC}\n"
    track_test "fail"
fi

# ─────────────────────────────────────────────────────────────
# Test 11: Create IN Transaction
# ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 11: Create IN Transaction${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
print_req "POST $BASE_URL/materials/$MATERIAL_ID/transactions  [x-tenant-id: $TENANT_FREE_ID]  {\"quantity\": 50, \"type\": \"IN\"}"
IN_TRANS=$(curl -s -X POST "$BASE_URL/materials/$MATERIAL_ID/transactions" -H "Content-Type: application/json" -H "x-tenant-id: $TENANT_FREE_ID" -d '{"quantity": 50, "type": "IN"}')
print_res "$IN_TRANS"
TRANS_ID=$(echo "$IN_TRANS" | jq -r '.data.transaction.id')
NEW_STOCK=$(echo "$IN_TRANS" | jq -r '.data.material.currentStock')
if echo "$IN_TRANS" | jq -e '.success == true' > /dev/null && [ "$NEW_STOCK" == "150" ]; then
    echo -e "${GREEN}✓ [PASS] IN transaction, new stock: $NEW_STOCK${NC}\n"
    track_test "pass"
else
    echo -e "${YELLOW}⚠ Stock: $NEW_STOCK${NC}\n"
    track_test "fail"
fi

# ─────────────────────────────────────────────────────────────
# Test 12: Create OUT Transaction
# ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 12: Create OUT Transaction${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
print_req "POST $BASE_URL/materials/$MATERIAL_ID/transactions  [x-tenant-id: $TENANT_FREE_ID]  {\"quantity\": 30, \"type\": \"OUT\"}"
OUT_TRANS=$(curl -s -X POST "$BASE_URL/materials/$MATERIAL_ID/transactions" -H "Content-Type: application/json" -H "x-tenant-id: $TENANT_FREE_ID" -d '{"quantity": 30, "type": "OUT"}')
print_res "$OUT_TRANS"
NEW_STOCK=$(echo "$OUT_TRANS" | jq -r '.data.material.currentStock')
if echo "$OUT_TRANS" | jq -e '.success == true' > /dev/null && [ "$NEW_STOCK" == "120" ]; then
    echo -e "${GREEN}✓ [PASS] OUT transaction, new stock: $NEW_STOCK${NC}\n"
    track_test "pass"
else
    echo -e "${YELLOW}⚠ Stock: $NEW_STOCK${NC}\n"
    track_test "fail"
fi

# ─────────────────────────────────────────────────────────────
# Test 13: Get Transaction by ID
# ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 13: Get Transaction by ID${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
print_req "GET $BASE_URL/transactions/$TRANS_ID  [x-tenant-id: $TENANT_FREE_ID]"
TRANS_DETAIL=$(curl -s -X GET "$BASE_URL/transactions/$TRANS_ID" -H "x-tenant-id: $TENANT_FREE_ID")
print_res "$TRANS_DETAIL"
if echo "$TRANS_DETAIL" | jq -e '.success == true and .data.material.name == "Steel Rods"' > /dev/null; then
    echo -e "${GREEN}✓ [PASS] Transaction detail with material info${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL]${NC}\n"
    track_test "fail"
fi

# ─────────────────────────────────────────────────────────────
# Test 14: Get Material with Transactions
# ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 14: Get Material with Transactions${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
print_req "GET $BASE_URL/materials/$MATERIAL_ID  [x-tenant-id: $TENANT_FREE_ID]"
MAT_DETAIL=$(curl -s -X GET "$BASE_URL/materials/$MATERIAL_ID" -H "x-tenant-id: $TENANT_FREE_ID")
print_res "$MAT_DETAIL"
TRANS_COUNT=$(echo "$MAT_DETAIL" | jq -r '.data.transactions | length')
if echo "$MAT_DETAIL" | jq -e '.success == true' > /dev/null && [ "$TRANS_COUNT" == "2" ]; then
    echo -e "${GREEN}✓ [PASS] Material with $TRANS_COUNT transactions${NC}\n"
    track_test "pass"
else
    echo -e "${YELLOW}⚠ Transaction count: $TRANS_COUNT${NC}\n"
    track_test "fail"
fi

# ─────────────────────────────────────────────────────────────
# Test 15: Multi-Tenant Isolation (Material)
# ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 15: Multi-Tenant Isolation (Material)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
print_req "GET $BASE_URL/materials/$MATERIAL_ID  [x-tenant-id: $TENANT_PRO_ID]  (cross-tenant — should be denied)"
CROSS=$(curl -s -X GET "$BASE_URL/materials/$MATERIAL_ID" -H "x-tenant-id: $TENANT_PRO_ID")
print_res "$CROSS"
if echo "$CROSS" | jq -e '.success == false' > /dev/null && echo "$CROSS" | grep -qi "not found\|access denied"; then
    echo -e "${GREEN}✓ [PASS] Tenant isolation enforced${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL] Isolation breach!${NC}\n"
    track_test "fail"
fi

# ─────────────────────────────────────────────────────────────
# Test 16: Multi-Tenant Isolation (User)
# ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 16: Multi-Tenant Isolation (User)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
print_req "GET $BASE_URL/users/$USER1_ID  [x-tenant-id: $TENANT_PRO_ID]  (cross-tenant — should be denied)"
CROSS_USER=$(curl -s -X GET "$BASE_URL/users/$USER1_ID" -H "x-tenant-id: $TENANT_PRO_ID")
print_res "$CROSS_USER"
if echo "$CROSS_USER" | grep -qi "not found\|access denied"; then
    echo -e "${GREEN}✓ [PASS] User isolation enforced${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL]${NC}\n"
    track_test "fail"
fi

# ─────────────────────────────────────────────────────────────
# Test 17: Insufficient Stock Validation
# ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 17: Insufficient Stock Validation${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
print_req "POST $BASE_URL/materials/$MATERIAL_ID/transactions  [x-tenant-id: $TENANT_FREE_ID]  {\"quantity\": 500, \"type\": \"OUT\"}  (exceeds stock — should fail)"
INSUFF=$(curl -s -X POST "$BASE_URL/materials/$MATERIAL_ID/transactions" -H "Content-Type: application/json" -H "x-tenant-id: $TENANT_FREE_ID" -d '{"quantity": 500, "type": "OUT"}')
print_res "$INSUFF"
if echo "$INSUFF" | jq -e '.success == false' > /dev/null && echo "$INSUFF" | grep -q "Insufficient"; then
    echo -e "${GREEN}✓ [PASS] Stock validation enforced${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL]${NC}\n"
    track_test "fail"
fi

# ─────────────────────────────────────────────────────────────
# Test 18: Missing Tenant Header
# ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 18: Missing Tenant Header${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
print_req "GET $BASE_URL/materials  (no x-tenant-id header — should be rejected)"
NO_TENANT=$(curl -s -X GET "$BASE_URL/materials")
print_res "$NO_TENANT"
if echo "$NO_TENANT" | jq -e '.success == false' > /dev/null && echo "$NO_TENANT" | grep -qi "tenant"; then
    echo -e "${GREEN}✓ [PASS] Missing tenant header rejected${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL]${NC}\n"
    track_test "fail"
fi

# ─────────────────────────────────────────────────────────────
# Test 19: Delete User
# ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 19: Delete User${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
print_req "DELETE $BASE_URL/users/$USER2_ID  [x-tenant-id: $TENANT_FREE_ID]"
DEL_USER=$(curl -s -X DELETE "$BASE_URL/users/$USER2_ID" -H "x-tenant-id: $TENANT_FREE_ID")
print_res "$DEL_USER"
if echo "$DEL_USER" | jq -e '.success == true' > /dev/null && echo "$DEL_USER" | grep -q "deleted successfully"; then
    echo -e "${GREEN}✓ [PASS] User deleted${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL]${NC}\n"
    track_test "fail"
fi

# ─────────────────────────────────────────────────────────────
# Test 20: PRO Plan - Unlimited Materials
# ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 20: PRO Plan (Unlimited Materials)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
for i in {1..7}; do
    curl -s -X POST "$BASE_URL/materials" -H "Content-Type: application/json" -H "x-tenant-id: $TENANT_PRO_ID" -d "{\"name\": \"PRO Mat $i\", \"unit\": \"u\", \"currentStock\": 100}" > /dev/null
done
print_req "GET $BASE_URL/materials  [x-tenant-id: $TENANT_PRO_ID]  (after creating 7 materials)"
PRO_MATS=$(curl -s -X GET "$BASE_URL/materials" -H "x-tenant-id: $TENANT_PRO_ID")
print_res "$PRO_MATS"
PRO_TOTAL=$(echo "$PRO_MATS" | jq -r '.meta.total')
if [ "$PRO_TOTAL" -ge "7" ]; then
    echo -e "${GREEN}✓ [PASS] PRO has $PRO_TOTAL materials (no limit)${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL] PRO total: $PRO_TOTAL${NC}\n"
    track_test "fail"
fi

# ─────────────────────────────────────────────────────────────
# Test 21: Pagination - page & limit params
# ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 21: Pagination (page=1&limit=1)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
print_req "GET $BASE_URL/materials?page=1&limit=1  [x-tenant-id: $TENANT_PRO_ID]"
PAGE_RESP=$(curl -s -X GET "$BASE_URL/materials?page=1&limit=1" -H "x-tenant-id: $TENANT_PRO_ID")
print_res "$PAGE_RESP"
PAGE_DATA_LEN=$(echo "$PAGE_RESP" | jq -r '.data | length')
PAGE_NUM=$(echo "$PAGE_RESP" | jq -r '.meta.page')
PAGE_LIMIT=$(echo "$PAGE_RESP" | jq -r '.meta.limit')
TOTAL_PAGES=$(echo "$PAGE_RESP" | jq -r '.meta.totalPages')
if [ "$PAGE_DATA_LEN" == "1" ] && [ "$PAGE_NUM" == "1" ] && [ "$PAGE_LIMIT" == "1" ] && [ "$TOTAL_PAGES" -ge "7" ]; then
    echo -e "${GREEN}✓ [PASS] Pagination working - 1 item/page, $TOTAL_PAGES total pages${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL] data_len=$PAGE_DATA_LEN page=$PAGE_NUM limit=$PAGE_LIMIT total_pages=$TOTAL_PAGES${NC}\n"
    track_test "fail"
fi

# ─────────────────────────────────────────────────────────────
# Test 22: Pagination - transactions list
# ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 22: Pagination - Transactions List${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
print_req "GET $BASE_URL/transactions?page=1&limit=1  [x-tenant-id: $TENANT_FREE_ID]"
TRANS_LIST=$(curl -s -X GET "$BASE_URL/transactions?page=1&limit=1" -H "x-tenant-id: $TENANT_FREE_ID")
print_res "$TRANS_LIST"
TRANS_DATA_LEN=$(echo "$TRANS_LIST" | jq -r '.data | length')
TRANS_TOTAL=$(echo "$TRANS_LIST" | jq -r '.meta.total')
if echo "$TRANS_LIST" | jq -e '.success == true and .meta != null' > /dev/null && [ "$TRANS_DATA_LEN" == "1" ] && [ "$TRANS_TOTAL" -ge "2" ]; then
    echo -e "${GREEN}✓ [PASS] Transactions paginated - total: $TRANS_TOTAL${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL] data_len=$TRANS_DATA_LEN total=$TRANS_TOTAL${NC}\n"
    track_test "fail"
fi

# ─────────────────────────────────────────────────────────────
# Test 23: Zod Validation - Invalid Email
# ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 23: Zod Validation - Invalid Email Format${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
print_req "POST $BASE_URL/users  [x-tenant-id: $TENANT_FREE_ID]  {\"email\": \"not-an-email\", \"name\": \"Test\"}"
BAD_EMAIL=$(curl -s -X POST "$BASE_URL/users" -H "Content-Type: application/json" -H "x-tenant-id: $TENANT_FREE_ID" -d '{"email": "not-an-email", "name": "Test"}')
BAD_EMAIL_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/users" -H "Content-Type: application/json" -H "x-tenant-id: $TENANT_FREE_ID" -d '{"email": "not-an-email", "name": "Test"}')
print_res "$BAD_EMAIL"
if [ "$BAD_EMAIL_STATUS" == "400" ] && echo "$BAD_EMAIL" | jq -e '.success == false and .error == "Validation error"' > /dev/null; then
    echo -e "${GREEN}✓ [PASS] Invalid email rejected with 400${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL] Status: $BAD_EMAIL_STATUS, body: $BAD_EMAIL${NC}\n"
    track_test "fail"
fi

# ─────────────────────────────────────────────────────────────
# Test 24: Zod Validation - Missing Required Fields
# ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 24: Zod Validation - Missing Required Fields${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
print_req "POST $BASE_URL/materials  [x-tenant-id: $TENANT_PRO_ID]  {\"currentStock\": 10}  (missing name & unit)"
MISSING_FIELDS=$(curl -s -X POST "$BASE_URL/materials" -H "Content-Type: application/json" -H "x-tenant-id: $TENANT_PRO_ID" -d '{"currentStock": 10}')
MISSING_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/materials" -H "Content-Type: application/json" -H "x-tenant-id: $TENANT_PRO_ID" -d '{"currentStock": 10}')
print_res "$MISSING_FIELDS"
if [ "$MISSING_STATUS" == "400" ] && echo "$MISSING_FIELDS" | jq -e '.success == false and .error == "Validation error"' > /dev/null; then
    echo -e "${GREEN}✓ [PASS] Missing fields rejected with 400${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL] Status: $MISSING_STATUS, body: $MISSING_FIELDS${NC}\n"
    track_test "fail"
fi

# ─────────────────────────────────────────────────────────────
# Test 25: Zod Validation - Invalid Enum (plan)
# ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 25: Zod Validation - Invalid Plan Enum${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
print_req "POST $BASE_URL/tenants  {\"name\": \"Bad Tenant\", \"plan\": \"ENTERPRISE\"}  (invalid enum)"
BAD_PLAN=$(curl -s -X POST "$BASE_URL/tenants" -H "Content-Type: application/json" -d '{"name": "Bad Tenant", "plan": "ENTERPRISE"}')
BAD_PLAN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/tenants" -H "Content-Type: application/json" -d '{"name": "Bad Tenant", "plan": "ENTERPRISE"}')
print_res "$BAD_PLAN"
if [ "$BAD_PLAN_STATUS" == "400" ] && echo "$BAD_PLAN" | jq -e '.success == false' > /dev/null; then
    echo -e "${GREEN}✓ [PASS] Invalid plan enum rejected with 400${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL] Status: $BAD_PLAN_STATUS, body: $BAD_PLAN${NC}\n"
    track_test "fail"
fi

# ─────────────────────────────────────────────────────────────
# Test 26: Zod Validation - Zero/Negative Quantity
# ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 26: Zod Validation - Zero Quantity${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
print_req "POST $BASE_URL/materials/$MATERIAL_ID/transactions  [x-tenant-id: $TENANT_FREE_ID]  {\"quantity\": 0, \"type\": \"IN\"}  (zero qty)"
ZERO_QTY=$(curl -s -X POST "$BASE_URL/materials/$MATERIAL_ID/transactions" -H "Content-Type: application/json" -H "x-tenant-id: $TENANT_FREE_ID" -d '{"quantity": 0, "type": "IN"}')
ZERO_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/materials/$MATERIAL_ID/transactions" -H "Content-Type: application/json" -H "x-tenant-id: $TENANT_FREE_ID" -d '{"quantity": 0, "type": "IN"}')
print_res "$ZERO_QTY"
if [ "$ZERO_STATUS" == "400" ] && echo "$ZERO_QTY" | jq -e '.success == false' > /dev/null; then
    echo -e "${GREEN}✓ [PASS] Zero quantity rejected with 400${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL] Status: $ZERO_STATUS, body: $ZERO_QTY${NC}\n"
    track_test "fail"
fi

# ─────────────────────────────────────────────────────────────
# Test 27: Duplicate Email → 409 Conflict
# ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 27: Duplicate Email → 409 Conflict${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
print_req "POST $BASE_URL/users  [x-tenant-id: $TENANT_FREE_ID]  {\"email\": \"admin-$TIMESTAMP@test.com\", \"name\": \"Duplicate\"}  (already exists)"
DUP_EMAIL=$(curl -s -X POST "$BASE_URL/users" -H "Content-Type: application/json" -H "x-tenant-id: $TENANT_FREE_ID" -d "{\"email\": \"admin-$TIMESTAMP@test.com\", \"name\": \"Duplicate\"}")
DUP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/users" -H "Content-Type: application/json" -H "x-tenant-id: $TENANT_FREE_ID" -d "{\"email\": \"admin-$TIMESTAMP@test.com\", \"name\": \"Duplicate\"}")
print_res "$DUP_EMAIL"
if [ "$DUP_STATUS" == "409" ] && echo "$DUP_EMAIL" | jq -e '.success == false' > /dev/null; then
    echo -e "${GREEN}✓ [PASS] Duplicate email returns 409${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL] Status: $DUP_STATUS (expected 409), body: $DUP_EMAIL${NC}\n"
    track_test "fail"
fi

# ─────────────────────────────────────────────────────────────
# Test 28: Update User - Empty Body Rejected
# ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 28: Update User - Empty Body Rejected${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
print_req "PUT $BASE_URL/users/$USER1_ID  [x-tenant-id: $TENANT_FREE_ID]  {}  (empty body)"
EMPTY_UPDATE=$(curl -s -X PUT "$BASE_URL/users/$USER1_ID" -H "Content-Type: application/json" -H "x-tenant-id: $TENANT_FREE_ID" -d '{}')
EMPTY_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "$BASE_URL/users/$USER1_ID" -H "Content-Type: application/json" -H "x-tenant-id: $TENANT_FREE_ID" -d '{}')
print_res "$EMPTY_UPDATE"
if [ "$EMPTY_STATUS" == "400" ] && echo "$EMPTY_UPDATE" | jq -e '.success == false' > /dev/null; then
    echo -e "${GREEN}✓ [PASS] Empty update body rejected with 400${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL] Status: $EMPTY_STATUS, body: $EMPTY_UPDATE${NC}\n"
    track_test "fail"
fi

# ─────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    TEST SUMMARY                           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}✓ ALL TESTS PASSED! ($PASS_COUNT/$TOTAL_TESTS)${NC}"
else
    echo -e "${YELLOW}⚠ SOME TESTS FAILED${NC}"
    echo -e "${GREEN}  Passed: $PASS_COUNT${NC}"
    echo -e "${RED}  Failed: $FAIL_COUNT${NC}"
    echo -e "${CYAN}  Total:  $TOTAL_TESTS${NC}"
fi
echo ""
echo -e "${BLUE}Tested Features:${NC}"
echo -e "  ${GREEN}✓${NC} Health check (with DB probe)"
echo -e "  ${GREEN}✓${NC} Tenant management (FREE & PRO)"
echo -e "  ${GREEN}✓${NC} User CRUD (Create, Read, Update, Delete)"
echo -e "  ${GREEN}✓${NC} Material CRUD"
echo -e "  ${GREEN}✓${NC} Transactions (IN/OUT) with atomic stock update"
echo -e "  ${GREEN}✓${NC} Transaction detail retrieval"
echo -e "  ${GREEN}✓${NC} Multi-tenant isolation (materials & users)"
echo -e "  ${GREEN}✓${NC} FREE plan limit (max 5 materials)"
echo -e "  ${GREEN}✓${NC} PRO plan unlimited"
echo -e "  ${GREEN}✓${NC} Pagination (page, limit, meta)"
echo -e "  ${GREEN}✓${NC} Zod validation (email format, required fields, enums, quantity)"
echo -e "  ${GREEN}✓${NC} Duplicate email → 409 Conflict"
echo -e "  ${GREEN}✓${NC} Insufficient stock → 400"
echo -e "  ${GREEN}✓${NC} Missing tenant header → 400"
echo -e "  ${GREEN}✓${NC} Consistent success/error envelope"
echo ""
echo -e "${GREEN}Complete test suite finished!${NC}"
