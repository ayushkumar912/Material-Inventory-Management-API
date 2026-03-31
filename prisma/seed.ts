/// <reference types="node" />
import { PrismaClient, Plan, Role } from '@prisma/client';

const prisma = new PrismaClient();

// ─── Fixed IDs (stable across re-runs) ───────────────────────────────────────

const TENANT_ACME_ID    = 'seed-tenant-acme-0000-000000000001';
const TENANT_GLOBEX_ID  = 'seed-tenant-globex-000-000000000002';

const USER_ALICE_ID     = 'seed-user-alice-00000-000000000001';
const USER_BOB_ID       = 'seed-user-bob-000000-000000000002';
const USER_CAROL_ID     = 'seed-user-carol-0000-000000000003';
const USER_DAVE_ID      = 'seed-user-dave-00000-000000000004';

const MAT_STEEL_ID      = 'seed-mat-steel-000000-000000000001';
const MAT_COPPER_ID     = 'seed-mat-copper-00000-000000000002';
const MAT_ALUMINIUM_ID  = 'seed-mat-aluminium-0-000000000003';
const MAT_PLASTIC_ID    = 'seed-mat-plastic-000-000000000004';
const MAT_CARBON_ID     = 'seed-mat-carbon-0000-000000000005';
const MAT_TITANIUM_ID   = 'seed-mat-titanium-00-000000000006';

// ─── Helpers ─────────────────────────────────────────────────────────────────

function computeStock(transactions: { quantity: number; type: 'IN' | 'OUT' }[]): number {
  return transactions.reduce((stock, t) => {
    return t.type === 'IN' ? stock + t.quantity : stock - t.quantity;
  }, 0);
}

// ─── Seed Data ────────────────────────────────────────────────────────────────

const tenants = [
  { id: TENANT_ACME_ID,   name: 'Acme Corp',          plan: Plan.FREE },
  { id: TENANT_GLOBEX_ID, name: 'Globex Industries',  plan: Plan.PRO  },
];

const users = [
  { id: USER_ALICE_ID, tenantId: TENANT_ACME_ID,   email: 'alice@acme.com',   name: 'Alice Johnson', role: Role.ADMIN },
  { id: USER_BOB_ID,   tenantId: TENANT_ACME_ID,   email: 'bob@acme.com',     name: 'Bob Smith',     role: Role.USER  },
  { id: USER_CAROL_ID, tenantId: TENANT_GLOBEX_ID, email: 'carol@globex.com', name: 'Carol White',   role: Role.ADMIN },
  { id: USER_DAVE_ID,  tenantId: TENANT_GLOBEX_ID, email: 'dave@globex.com',  name: 'Dave Brown',    role: Role.USER  },
];

// Each material defines its transaction history; currentStock is derived from it
const materialDefs = [
  {
    id: MAT_STEEL_ID, tenantId: TENANT_ACME_ID,
    name: 'Steel Rods', unit: 'kg',
    transactions: [
      { quantity: 500, type: 'IN'  as const },
      { quantity: 100, type: 'OUT' as const },
      { quantity: 200, type: 'IN'  as const },
      { quantity: 150, type: 'OUT' as const },
    ],
  },
  {
    id: MAT_COPPER_ID, tenantId: TENANT_ACME_ID,
    name: 'Copper Wire', unit: 'm',
    transactions: [
      { quantity: 300, type: 'IN'  as const },
      { quantity: 80,  type: 'OUT' as const },
    ],
  },
  {
    id: MAT_ALUMINIUM_ID, tenantId: TENANT_GLOBEX_ID,
    name: 'Aluminium Sheets', unit: 'kg',
    transactions: [
      { quantity: 1000, type: 'IN'  as const },
      { quantity: 200,  type: 'OUT' as const },
    ],
  },
  {
    id: MAT_PLASTIC_ID, tenantId: TENANT_GLOBEX_ID,
    name: 'Plastic Pellets', unit: 'ton',
    transactions: [
      { quantity: 50, type: 'IN'  as const },
      { quantity: 5,  type: 'OUT' as const },
    ],
  },
  {
    id: MAT_CARBON_ID, tenantId: TENANT_GLOBEX_ID,
    name: 'Carbon Fiber', unit: 'm',
    transactions: [
      { quantity: 800, type: 'IN'  as const },
      { quantity: 100, type: 'OUT' as const },
      { quantity: 50,  type: 'IN'  as const },
      { quantity: 140, type: 'OUT' as const },
    ],
  },
  {
    id: MAT_TITANIUM_ID, tenantId: TENANT_GLOBEX_ID,
    name: 'Titanium Bolts', unit: 'units',
    transactions: [
      { quantity: 2000, type: 'IN'  as const },
      { quantity: 50,   type: 'OUT' as const },
    ],
  },
];

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log('🌱 Starting seed...\n');

  // Tenants
  console.log('→ Upserting tenants...');
  for (const t of tenants) {
    await prisma.tenant.upsert({
      where:  { id: t.id },
      update: { name: t.name, plan: t.plan },
      create: t,
    });
    console.log(`   ✓ ${t.name} (${t.plan})`);
  }

  // Users
  console.log('\n→ Upserting users...');
  for (const u of users) {
    await prisma.user.upsert({
      where:  { email: u.email },
      update: { name: u.name, role: u.role },
      create: u,
    });
    console.log(`   ✓ ${u.name} <${u.email}> [${u.role}]`);
  }

  // Materials + Transactions
  // Transactions are cleared and recreated each run to stay consistent with stock
  console.log('\n→ Seeding materials and transactions...');
  for (const def of materialDefs) {
    const currentStock = computeStock(def.transactions);

    // Upsert material with derived stock
    await prisma.material.upsert({
      where:  { tenantId_name: { tenantId: def.tenantId, name: def.name } },
      update: { unit: def.unit, currentStock, id: def.id },
      create: { id: def.id, tenantId: def.tenantId, name: def.name, unit: def.unit, currentStock },
    });

    // Clear existing seed transactions for this material, then recreate
    await prisma.transaction.deleteMany({ where: { materialId: def.id } });
    await prisma.transaction.createMany({
      data: def.transactions.map((tx) => ({
        tenantId:   def.tenantId,
        materialId: def.id,
        quantity:   tx.quantity,
        type:       tx.type,
      })),
    });

    console.log(`   ✓ ${def.name} (${def.unit}) — stock: ${currentStock}, txns: ${def.transactions.length}`);
  }

  console.log('\n✅ Seed complete!\n');
  console.log('─────────────────────────────────────────');
  console.log('Tenants:');
  tenants.forEach((t) => console.log(`  ${t.name} [${t.plan}]  id: ${t.id}`));
  console.log('\nUsers:');
  users.forEach((u) => console.log(`  ${u.email}  [${u.role}]`));
  console.log('─────────────────────────────────────────');
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
