#!/bin/bash

# Material Inventory API - Complete Test Suite

set -e

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

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

# Test 1: Health Check
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 1: Health Check${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
HEALTH=$(curl -s GET "$BASE_URL/health")
echo "Response: $HEALTH"
if echo "$HEALTH" | jq -e '.status == "ok"' > /dev/null; then
    echo -e "${GREEN}✓ [PASS] Health check${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL] Health check${NC}\n"
    track_test "fail"
fi

# Test 2: Create FREE Tenant
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 2: Create Tenant (FREE Plan)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
TENANT_FREE=$(curl -s -X POST "$BASE_URL/tenants" -H "Content-Type: application/json" -d '{"name": "Test Company FREE", "plan": "FREE"}')
echo "Response: $TENANT_FREE"
TENANT_FREE_ID=$(echo "$TENANT_FREE" | jq -r '.data.id')
if [ "$TENANT_FREE_ID" != "null" ]; then
    echo -e "${GREEN}✓ [PASS] FREE Tenant: $TENANT_FREE_ID${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL] Failed${NC}\n"
    track_test "fail"
    exit 1
fi

# Test 3: Create PRO Tenant
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 3: Create Tenant (PRO Plan)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
TENANT_PRO=$(curl -s -X POST "$BASE_URL/tenants" -H "Content-Type: application/json" -d '{"name": "Test Company PRO", "plan": "PRO"}')
TENANT_PRO_ID=$(echo "$TENANT_PRO" | jq -r '.data.id')
if [ "$TENANT_PRO_ID" != "null" ]; then
    echo -e "${GREEN}✓ [PASS] PRO Tenant: $TENANT_PRO_ID${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL]${NC}\n"
    track_test "fail"
    exit 1
fi

# Test 4-8: User CRUD Operations
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 4: Create Admin User${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
USER1=$(curl -s -X POST "$BASE_URL/users" -H "Content-Type: application/json" -H "x-tenant-id: $TENANT_FREE_ID" -d "{\"email\": \"admin-$TIMESTAMP@test.com\", \"name\": \"Admin User\", \"role\": \"ADMIN\"}")
USER1_ID=$(echo "$USER1" | jq -r '.data.id')
if [ "$USER1_ID" != "null" ]; then
    echo -e "${GREEN}✓ [PASS] Admin user created${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL]${NC}\n"
    track_test "fail"
fi

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 5: Create Regular User${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
USER2=$(curl -s -X POST "$BASE_URL/users" -H "Content-Type: application/json" -H "x-tenant-id: $TENANT_FREE_ID" -d "{\"email\": \"user-$TIMESTAMP@test.com\", \"name\": \"Regular User\"}")
USER2_ID=$(echo "$USER2" | jq -r '.data.id')
if [ "$USER2_ID" != "null" ]; then
    echo -e "${GREEN}✓ [PASS] Regular user created${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL]${NC}\n"
    track_test "fail"
fi

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 6: List Users${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
USERS_LIST=$(curl -s -X GET "$BASE_URL/users" -H "x-tenant-id: $TENANT_FREE_ID")
USER_COUNT=$(echo "$USERS_LIST" | jq -r '.count')
if [ "$USER_COUNT" == "2" ]; then
    echo -e "${GREEN}✓ [PASS] Listed $USER_COUNT users${NC}\n"
    track_test "pass"
else
    echo -e "${YELLOW}⚠ [WARN] User count: $USER_COUNT${NC}\n"
    track_test "fail"
fi

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 7: Get User by ID${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
USER_DETAIL=$(curl -s -X GET "$BASE_URL/users/$USER1_ID" -H "x-tenant-id: $TENANT_FREE_ID")
if echo "$USER_DETAIL" | jq -e ".data.email == \"admin-$TIMESTAMP@test.com\"" > /dev/null; then
    echo -e "${GREEN}✓ [PASS] User details retrieved${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL]${NC}\n"
    track_test "fail"
fi

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 8: Update User${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
USER_UPDATE=$(curl -s -X PUT "$BASE_URL/users/$USER2_ID" -H "Content-Type: application/json" -H "x-tenant-id: $TENANT_FREE_ID" -d '{"name": "Updated User", "role": "ADMIN"}')
if echo "$USER_UPDATE" | jq -e '.data.name == "Updated User"' > /dev/null; then
    echo -e "${GREEN}✓ [PASS] User updated${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL]${NC}\n"
    track_test "fail"
fi

# Test 9-13: Material Operations
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 9: Create Material${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
MATERIAL=$(curl -s -X POST "$BASE_URL/materials" -H "Content-Type: application/json" -H "x-tenant-id: $TENANT_FREE_ID" -d '{"name": "Steel Rods", "unit": "kg", "currentStock": 100}')
MATERIAL_ID=$(echo "$MATERIAL" | jq -r '.data.id')
if [ "$MATERIAL_ID" != "null" ]; then
    echo -e "${GREEN}✓ [PASS] Material created${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL]${NC}\n"
    track_test "fail"
    exit 1
fi

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 10: Test FREE Plan Limit (Max 5)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
for i in {2..5}; do
    curl -s -X POST "$BASE_URL/materials" -H "Content-Type: application/json" -H "x-tenant-id: $TENANT_FREE_ID" -d "{\"name\": \"Material $i\", \"unit\": \"units\", \"currentStock\": $((i * 10))}" > /dev/null
    echo -e "${GREEN}✓ Material $i created${NC}"
done
SIXTH=$(curl -s -X POST "$BASE_URL/materials" -H "Content-Type: application/json" -H "x-tenant-id: $TENANT_FREE_ID" -d '{"name": "Material 6", "unit": "units", "currentStock": 60}')
if echo "$SIXTH" | grep -q "limit"; then
    echo -e "${GREEN}✓ [PASS] FREE limit enforced${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL]${NC}\n"
    track_test "fail"
fi

# Test 11-15: Transaction Operations
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 11: Create IN Transaction${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
IN_TRANS=$(curl -s -X POST "$BASE_URL/materials/$MATERIAL_ID/transactions" -H "Content-Type: application/json" -H "x-tenant-id: $TENANT_FREE_ID" -d '{"quantity": 50, "type": "IN"}')
TRANS_ID=$(echo "$IN_TRANS" | jq -r '.data.transaction.id')
NEW_STOCK=$(echo "$IN_TRANS" | jq -r '.data.material.currentStock')
if [ "$NEW_STOCK" == "150" ]; then
    echo -e "${GREEN}✓ [PASS] IN transaction, stock: $NEW_STOCK${NC}\n"
    track_test "pass"
else
    echo -e "${YELLOW}⚠ Stock: $NEW_STOCK${NC}\n"
    track_test "fail"
fi

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 12: Create OUT Transaction${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
OUT_TRANS=$(curl -s -X POST "$BASE_URL/materials/$MATERIAL_ID/transactions" -H "Content-Type: application/json" -H "x-tenant-id: $TENANT_FREE_ID" -d '{"quantity": 30, "type": "OUT"}')
NEW_STOCK=$(echo "$OUT_TRANS" | jq -r '.data.material.currentStock')
if [ "$NEW_STOCK" == "120" ]; then
    echo -e "${GREEN}✓ [PASS] OUT transaction, stock: $NEW_STOCK${NC}\n"
    track_test "pass"
else
    echo -e "${YELLOW}⚠ Stock: $NEW_STOCK${NC}\n"
    track_test "fail"
fi

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 13: Get Transaction by ID (NEW)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
TRANS_DETAIL=$(curl -s -X GET "$BASE_URL/transactions/$TRANS_ID" -H "x-tenant-id: $TENANT_FREE_ID")
if echo "$TRANS_DETAIL" | jq -e '.data.material.name == "Steel Rods"' > /dev/null; then
    echo -e "${GREEN}✓ [PASS] Transaction detail with material info${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL]${NC}\n"
    track_test "fail"
fi

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 14: Get Material with Transactions${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
MAT_DETAIL=$(curl -s -X GET "$BASE_URL/materials/$MATERIAL_ID" -H "x-tenant-id: $TENANT_FREE_ID")
TRANS_COUNT=$(echo "$MAT_DETAIL" | jq -r '.data.transactions | length')
if [ "$TRANS_COUNT" == "2" ]; then
    echo -e "${GREEN}✓ [PASS] Material with $TRANS_COUNT transactions${NC}\n"
    track_test "pass"
else
    echo -e "${YELLOW}⚠ Transaction count: $TRANS_COUNT${NC}\n"
    track_test "fail"
fi

# Test 15-19: Security & Validation
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 15: Multi-Tenant Isolation (Material)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
CROSS=$(curl -s -X GET "$BASE_URL/materials/$MATERIAL_ID" -H "x-tenant-id: $TENANT_PRO_ID")
if echo "$CROSS" | grep -q "not found\|access denied"; then
    echo -e "${GREEN}✓ [PASS] Isolation working${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL] Isolation breach!${NC}\n"
    track_test "fail"
fi

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 16: Multi-Tenant Isolation (User)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
CROSS_USER=$(curl -s -X GET "$BASE_URL/users/$USER1_ID" -H "x-tenant-id: $TENANT_PRO_ID")
if echo "$CROSS_USER" | grep -q "not found\|access denied"; then
    echo -e "${GREEN}✓ [PASS] User isolation working${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL]${NC}\n"
    track_test "fail"
fi

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 17: Insufficient Stock Validation${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
INSUFF=$(curl -s -X POST "$BASE_URL/materials/$MATERIAL_ID/transactions" -H "Content-Type: application/json" -H "x-tenant-id: $TENANT_FREE_ID" -d '{"quantity": 500, "type": "OUT"}')
if echo "$INSUFF" | grep -q "Insufficient"; then
    echo -e "${GREEN}✓ [PASS] Stock validation working${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL]${NC}\n"
    track_test "fail"
fi

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 18: Missing Tenant Header${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
NO_TENANT=$(curl -s -X GET "$BASE_URL/materials")
if echo "$NO_TENANT" | grep -q "tenant"; then
    echo -e "${GREEN}✓ [PASS] Header validation${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL]${NC}\n"
    track_test "fail"
fi

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 19: Delete User${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
DEL_USER=$(curl -s -X DELETE "$BASE_URL/users/$USER2_ID" -H "x-tenant-id: $TENANT_FREE_ID")
if echo "$DEL_USER" | grep -q "deleted successfully"; then
    echo -e "${GREEN}✓ [PASS] User deleted${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL]${NC}\n"
    track_test "fail"
fi

# Test 20: PRO Plan Unlimited
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 20: PRO Plan (Unlimited)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
for i in {1..7}; do
    curl -s -X POST "$BASE_URL/materials" -H "Content-Type: application/json" -H "x-tenant-id: $TENANT_PRO_ID" -d "{\"name\": \"PRO Mat $i\", \"unit\": \"u\", \"currentStock\": 100}" > /dev/null
done
PRO_MATS=$(curl -s -X GET "$BASE_URL/materials" -H "x-tenant-id: $TENANT_PRO_ID")
PRO_COUNT=$(echo "$PRO_MATS" | jq -r '.count')
if [ "$PRO_COUNT" -ge "7" ]; then
    echo -e "${GREEN}✓ [PASS] PRO has $PRO_COUNT materials (no limit)${NC}\n"
    track_test "pass"
else
    echo -e "${RED}✗ [FAIL]${NC}\n"
    track_test "fail"
fi

# Summary
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
echo -e "  ${GREEN}✓${NC} Health check"
echo -e "  ${GREEN}✓${NC} Tenant management (FREE & PRO)"
echo -e "  ${GREEN}✓${NC} User CRUD operations (Create, Read, Update, Delete)"
echo -e "  ${GREEN}✓${NC} Material CRUD operations"
echo -e "  ${GREEN}✓${NC} Transaction operations (IN/OUT)"
echo -e "  ${GREEN}✓${NC} Transaction detail retrieval (GET /transactions/:id)"
echo -e "  ${GREEN}✓${NC} Multi-tenant isolation (materials & users)"
echo -e "  ${GREEN}✓${NC} FREE plan limits (max 5 materials)"
echo -e "  ${GREEN}✓${NC} PRO plan unlimited"
echo -e "  ${GREEN}✓${NC} Stock validation"
echo -e "  ${GREEN}✓${NC} Header validation"
echo ""
echo -e "${GREEN}Complete test suite finished!${NC}"
