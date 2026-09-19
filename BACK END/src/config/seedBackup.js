const path = require('path');
const fs = require('fs');

/**
 * Automatically seeds pre-existing backup data (Users, Farms, Products, Devices, etc.)
 * into the database if the Users table is currently empty.
 * 
 * @param {boolean} force - If true, runs seed even if users exist (using INSERT IGNORE)
 * @returns {Promise<object>} Results of the seed operation
 */
const autoSeedBackup = async (force = false) => {
  const { sequelize } = require('../models');
  if (!sequelize) {
    throw new Error('Sequelize instance not found');
  }

  // Load backup data
  const backupPath = path.join(__dirname, 'seedData.json');
  if (!fs.existsSync(backupPath)) {
    console.warn('Seed notice: seedData.json does not exist at', backupPath);
    return { status: 'skipped', reason: 'seedData.json not found' };
  }

  const seedData = JSON.parse(fs.readFileSync(backupPath, 'utf8'));

  // Get all existing tables in the database to match casing (e.g. Users vs users)
  const [tableRows] = await sequelize.query('SHOW TABLES;');
  const actualTables = tableRows.map(row => Object.values(row)[0]);

  const findActualTable = (name) => {
    return actualTables.find(t => t.toLowerCase() === name.toLowerCase()) || name;
  };

  const usersTable = findActualTable('users');

  // Check if users already exist
  try {
    const [countResult] = await sequelize.query(`SELECT COUNT(*) as cnt FROM \`${usersTable}\`;`);
    const count = parseInt(countResult[0]?.cnt || 0, 10);

    if (count > 0 && !force) {
      console.log(`Database already populated with ${count} users. Skipping auto-seed.`);
      return { status: 'skipped', userCount: count };
    }
  } catch (err) {
    console.log('Notice checking user count, continuing with seed:', err.message);
  }

  console.log('Starting cloud database backup restoration...');

  const results = {};

  try {
    // Temporarily disable foreign key checks during import
    await sequelize.query('SET FOREIGN_KEY_CHECKS = 0;');

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
      if (!tableData || !tableData.columns || !tableData.rawValues) {
        continue;
      }

      const actualName = findActualTable(tableName);
      const colsList = tableData.columns.map(c => `\`${c}\``).join(', ');
      const sql = `INSERT IGNORE INTO \`${actualName}\` (${colsList}) VALUES ${tableData.rawValues};`;

      try {
        await sequelize.query(sql);
        const rowCount = (tableData.rawValues.match(/\(/g) || []).length;
        results[actualName] = { status: 'seeded', rows: rowCount };
        console.log(` Restored table \`${actualName}\` (${rowCount} records)`);
      } catch (tableErr) {
        console.error(` Error seeding table \`${actualName}\`:`, tableErr.message);
        results[actualName] = { status: 'error', error: tableErr.message };
      }
    }
  } finally {
    // Always re-enable foreign key checks
    await sequelize.query('SET FOREIGN_KEY_CHECKS = 1;');
  }

  console.log('Cloud database restoration completed successfully.');
  return { status: 'success', details: results };
};

module.exports = {
  autoSeedBackup
};
