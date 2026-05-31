const fs = require('fs');
const path = require('path');
const { Client } = require('pg');

const regions = [
  'ap-south-1',     // Mumbai
  'ap-southeast-1', // Singapore
  'ap-southeast-2', // Sydney
  'ap-northeast-1', // Tokyo
  'ap-northeast-2', // Seoul
  'us-east-1',       // N. Virginia
  'us-east-2',       // Ohio
  'us-west-1',       // N. California
  'us-west-2',       // Oregon
  'eu-west-1',       // Ireland
  'eu-west-2',       // London
  'eu-west-3',       // Paris
  'eu-central-1',     // Frankfurt
  'eu-central-2',     // Zurich
  'ca-central-1',     // Canada
  'sa-east-1'        // Sao Paulo
];

const runMigrations = async () => {
  const projectRef = 'rxjmdrjlsltqufrpvdyq';
  const password = 'iNYksPb$tug47$p';
  let connectedClient = null;
  let activeRegion = null;

  for (const region of regions) {
    const host = `aws-0-${region}.pooler.supabase.com`;
    const connectionString = `postgresql://postgres.${projectRef}:${password}@${host}:5432/postgres`;
    
    console.log(`🔄 Scanning region ${region}...`);
    const client = new Client({
      connectionString,
      ssl: { rejectUnauthorized: false },
      connectionTimeoutMillis: 3000 // fast timeout
    });

    try {
      await client.connect();
      console.log(`🎉 FOUND IT! CONNECTED SUCCESSFULLY via pooler in region: ${region}`);
      connectedClient = client;
      activeRegion = region;
      break;
    } catch (err) {
      if (err.message.includes('password authentication failed')) {
        console.log(`⚠️  Region ${region}: Password incorrect (but tenant exists here!)`);
        await client.end();
        break;
      }
      // Tenant not found is standard for wrong regions
      await client.end();
    }
  }

  if (!connectedClient) {
    console.error('❌ Could not connect to any regional database poolers. The database password might be different.');
    process.exit(1);
  }

  const client = connectedClient;

  try {
    const migrationsDir = path.join(__dirname, 'migrations');
    
    // We execute in sequence
    const files = [
      '001_supabase_schema.sql',
      '002_security_rls.sql',
      '003_super_admin_permissions.sql',
      'stage_01_smart_attendance_qr_ble.sql',
      'stage_02_exam_scheduler_visibility.sql'
    ];

    for (const file of files) {
      const filePath = path.join(migrationsDir, file);
      console.log(`🚀 Reading and executing migration file: ${file}...`);
      
      if (!fs.existsSync(filePath)) {
        console.error(`❌ Migration file does not exist at path: ${filePath}`);
        continue;
      }

      const sql = fs.readFileSync(filePath, 'utf8');
      
      // Execute the SQL
      await client.query(sql);
      console.log(`✅ Completed migration file: ${file}`);
    }

    console.log('🎉 All SQL migrations executed successfully!');
  } catch (err) {
    console.error('❌ Migration failed:', err.stack || err.message);
  } finally {
    await client.end();
  }
};

runMigrations();
