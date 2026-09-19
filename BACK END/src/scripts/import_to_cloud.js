const mysql = require('mysql2/promise');
const path = require('path');
const fs = require('fs');

/**
 * Direct CLI importer to populate Railway Cloud MySQL from backup data
 * Usage: node src/scripts/import_to_cloud.js "<PUBLIC_MYSQL_URL>"
 */
async function importData() {
  const connectionUri = process.argv[2] || process.env.MYSQL_PUBLIC_URL || process.env.MYSQL_URL;

  if (!connectionUri) {
    console.error('Error: Please provide your Railway MySQL Public Connection URL as an argument.');
    console.error('Example: node src/scripts/import_to_cloud.js "mysql://root:password@roundhouse.proxy.rlwy.net:12345/railway"');
    process.exit(1);
  }

  console.log('Connecting to cloud MySQL database...');
  let connection;
  try {
    connection = await mysql.createConnection(connectionUri);
    console.log(' Successfully connected to Cloud MySQL!');
  } catch (connErr) {
    console.error(' Failed to connect:', connErr.message);
    process.exit(1);
  }

  try {
    const backupPath = path.join(__dirname, '../config/seedData.json');
    if (!fs.existsSync(backupPath)) {
      throw new Error(`seedData.json not found at ${backupPath}`);
    }

    const seedData = JSON.parse(fs.readFileSync(backupPath, 'utf8'));

    // Check existing tables
    const [tableRows] = await connection.query('SHOW TABLES;');
    const actualTables = tableRows.map(row => Object.values(row)[0]);
    console.log('Found cloud tables:', actualTables.join(', '));

    const findActualTable = (name) => {
      return actualTables.find(t => t.toLowerCase() === name.toLowerCase()) || name;
    };

    console.log('Disabling foreign key checks...');
    await connection.query('SET FOREIGN_KEY_CHECKS = 0;');

    const tableOrder = [
      'users',
      'farms',
      'devices',
      'sensorreadings',
      'products',
      'orders',
      'orderitems',
      'deliveries',
      'notifications'
    ];

    for (const tableName of tableOrder) {
      const tableData = seedData[tableName];
      if (!tableData || !tableData.columns || !tableData.rawValues) continue;

      const actualName = findActualTable(tableName);
      const colsList = tableData.columns.map(c => `\`${c}\``).join(', ');
      const sql = `INSERT IGNORE INTO \`${actualName}\` (${colsList}) VALUES ${tableData.rawValues};`;

      try {
        await connection.query(sql);
        const rowCount = (tableData.rawValues.match(/\(/g) || []).length;
        console.log(` Restored table \`${actualName}\` (${rowCount} records)`);
      } catch (err) {
        console.error(` Error on \`${actualName}\`:`, err.message);
      }
    }

    await connection.query('SET FOREIGN_KEY_CHECKS = 1;');
    console.log(' Cloud database import completed successfully!');

    // Show summary of users
    const usersTable = findActualTable('users');
    const [users] = await connection.query(`SELECT id, name, email, role, status FROM \`${usersTable}\`;`);
    console.log(`\nImported ${users.length} Users into Cloud DB:`);
    console.table(users);

  } finally {
    await connection.end();
  }
}

importData().catch(err => {
  console.error('Fatal error during import:', err);
  process.exit(1);
});
