# Postman Collection - Material Inventory API

Complete Postman collection for testing the Material Inventory Management API with automated test scripts and environment variables.

## 📦 Files Included

- **`postman_collection.json`** - Main API collection with all endpoints
- **`postman_environment.json`** - Environment variables for local testing

## 🚀 Quick Start

### 1. Import into Postman

#### Option A: Import Collection File
1. Open Postman
2. Click **Import** button (top left)
3. Drag and drop `postman_collection.json` or click **Upload Files**
4. Select `postman_collection.json`

#### Option B: Import via Link
1. Copy the file path or upload to GitHub
2. Click **Import** → **Link** in Postman
3. Paste the URL

### 2. Import Environment

1. Click **Import** button
2. Select `postman_environment.json`
3. Click the environment dropdown (top right)
4. Select **Material Inventory API - Local**

### 3. Start Your API Server

```bash
npm run dev
# Server should be running on http://localhost:3001
```

### 4. Run the Collection

**Option A: Run Individual Requests**
- Click on any request in the collection
- Click **Send**
- View response in the bottom panel

**Option B: Run Entire Collection**
1. Click the **...** menu next to the collection name
2. Select **Run collection**
3. Click **Run Material Inventory Management API**
4. View results in the Collection Runner

## 📋 Collection Structure

### 1. **Health & Setup** (4 requests)
- Health Check
- Create FREE Tenant (saves `tenant_free_id`)
- Create PRO Tenant (saves `tenant_pro_id`)
- Get Tenant by ID

### 2. **User Management** (6 requests)
- Create Admin User (saves `user_admin_id`)
- Create Regular User (saves `user_regular_id`)
- List All Users
- Get User by ID
- Update User
- Delete User

### 3. **Material Management** (6 requests)
- Create Material - Steel Rods (saves `material_steel_id`)
- Create Material - Aluminum Sheets (saves `material_aluminum_id`)
- Create Material - Copper Wire
- List All Materials
- Get Material by ID (with transactions)
- Test Plan Limit - 6th Material (should fail for FREE plan)

### 4. **Transaction Management** (5 requests)
- Add Stock (IN Transaction) (saves `transaction_in_id`)
- Remove Stock (OUT Transaction) (saves `transaction_out_id`)
- List All Transactions
- Get Transaction by ID
- Test Insufficient Stock (should fail)

### 5. **Multi-Tenant Isolation Tests** (4 requests)
- Cross-Tenant Material Access (should fail with 404)
- Cross-Tenant User Access (should fail with 404)
- Missing Tenant Header (should fail with 401)
- Invalid Tenant ID (should fail with 401)

### 6. **Error Cases & Validation** (5 requests)
- Create User - Missing Required Fields (400)
- Create User - Duplicate Email (400)
- Create Material - Invalid Role (400)
- Create Transaction - Negative Quantity (400)
- Create Transaction - Invalid Type (400)

## 🔄 Automated Test Scripts

The collection includes automated test scripts that:

1. **Auto-save IDs to environment variables**
   - Tenant IDs → `tenant_free_id`, `tenant_pro_id`
   - User IDs → `user_admin_id`, `user_regular_id`
   - Material IDs → `material_steel_id`, `material_aluminum_id`
   - Transaction IDs → `transaction_in_id`, `transaction_out_id`

2. **Validate responses**
   - Check tenant plan types
   - Verify user roles
   - Confirm transaction types

3. **Enable sequential testing**
   - Each request uses IDs from previous requests
   - No manual copy/paste needed

## 🎯 Recommended Testing Flow

### Complete Workflow Test (Run in order):

1. **Setup Phase**
   ```
   1. Health Check
   2. Create FREE Tenant
   3. Create PRO Tenant
   ```

2. **User Management**
   ```
   4. Create Admin User
   5. Create Regular User
   6. List All Users
   7. Get User by ID
   8. Update User
   ```

3. **Material Management**
   ```
   9. Create Material - Steel Rods
   10. Create Material - Aluminum Sheets
   11. Create Material - Copper Wire
   12. List All Materials
   13. Get Material by ID
   ```

4. **Transactions**
   ```
   14. Add Stock (IN Transaction)
   15. Remove Stock (OUT Transaction)
   16. List All Transactions
   17. Get Transaction by ID
   ```

5. **Validation Tests**
   ```
   18. Test Plan Limit (should fail)
   19. Test Insufficient Stock (should fail)
   20. Cross-Tenant Access Tests (should fail)
   21. Error Cases (should all fail gracefully)
   ```

## 🛠️ Environment Variables

| Variable | Description | Auto-Populated |
|----------|-------------|----------------|
| `base_url` | API base URL | Default: `http://localhost:3001` |
| `tenant_free_id` | FREE plan tenant ID | ✅ After creating FREE tenant |
| `tenant_pro_id` | PRO plan tenant ID | ✅ After creating PRO tenant |
| `user_admin_id` | Admin user ID | ✅ After creating admin user |
| `user_regular_id` | Regular user ID | ✅ After creating regular user |
| `material_steel_id` | Steel material ID | ✅ After creating steel material |
| `material_aluminum_id` | Aluminum material ID | ✅ After creating aluminum material |
| `transaction_in_id` | IN transaction ID | ✅ After creating IN transaction |
| `transaction_out_id` | OUT transaction ID | ✅ After creating OUT transaction |

## 🔍 Testing Specific Features

### Test Multi-Tenant Isolation
1. Run "Create FREE Tenant" to get `tenant_free_id`
2. Run "Create PRO Tenant" to get `tenant_pro_id`
3. Create materials under FREE tenant
4. Run "Cross-Tenant Material Access" → Should return 404

### Test Plan Limits
1. Create 5 materials under FREE tenant
2. Run "Test Plan Limit - 6th Material" → Should return 403
3. Create materials under PRO tenant → Should succeed

### Test Stock Management
1. Create a material with initial stock
2. Run "Add Stock (IN Transaction)" → Stock increases
3. Run "Remove Stock (OUT Transaction)" → Stock decreases
4. Run "Test Insufficient Stock" → Should return 400

### Test Validation
All requests in "Error Cases & Validation" folder should return appropriate error codes (400, 401, 404).

## 📝 Notes

- **Environment Variables**: The collection automatically saves IDs from responses. Make sure to run setup requests first.
- **Sequential Dependencies**: Some requests depend on IDs from previous requests. Follow the recommended flow.
- **Port Configuration**: Default port is 3001. Update `base_url` in environment if using a different port.
- **Database State**: Each test run creates new data. Consider resetting your database between full collection runs.

## 🐛 Troubleshooting

**Issue: "Could not get any response"**
- Ensure API server is running: `npm run dev`
- Check if port 3001 is available
- Verify `base_url` in environment matches your server

**Issue: "Tenant not found" errors**
- Run "Create FREE Tenant" or "Create PRO Tenant" first
- Check that `tenant_free_id` or `tenant_pro_id` is set in environment

**Issue: "Material not found" or "User not found"**
- Run the creation requests first (they auto-populate environment variables)
- Verify the corresponding ID variable is set in your environment

**Issue: Test scripts not running**
- Ensure you have the environment selected (top right dropdown)
- Check the "Tests" tab in each request to verify scripts are present

## 🔄 Reset Environment

To start fresh:
1. Delete or reset your database: `npx prisma migrate reset`
2. Clear all environment variables (except `base_url`)
3. Run the collection from the beginning

## 📚 Additional Resources

- [API Documentation](./README.md)
- [Test Script](./test-api.sh)
- [Database Schema](./prisma/schema.prisma)
