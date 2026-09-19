const { Sequelize } = require('sequelize');
const mysql = require('mysql2/promise');
const dotenv = require('dotenv');
const path = require('path');

dotenv.config({ path: path.join(__dirname, '../../.env') });

const connectionUri = process.env.MYSQL_URL || process.env.DATABASE_URL;
const host = process.env.MYSQLHOST || process.env.DB_HOST || '127.0.0.1';
const port = parseInt(process.env.MYSQLPORT || process.env.DB_PORT || '3306');
const user = process.env.MYSQLUSER || process.env.DB_USER || 'root';
const password = process.env.MYSQLPASSWORD || process.env.DB_PASS || '';
const dbName = process.env.MYSQLDATABASE || process.env.DB_NAME || 'NOVARA';

// Helper function to auto-create MySQL database & patch missing columns
const ensureDatabaseExists = async () => {
  try {
    let connection;
    try {
      if (connectionUri) {
        connection = await mysql.createConnection(connectionUri);
      } else {
        try {
          connection = await mysql.createConnection({ host, port, user, password });
          await connection.query(`CREATE DATABASE IF NOT EXISTS \`${dbName}\`;`);
          await connection.changeUser({ database: dbName });
        } catch (connErr) {
          connection = await mysql.createConnection({ host, port, user, password, database: dbName });
        }
      }
    } catch (createErr) {
      console.log('Notice: Connecting directly to database without root create rights.');
      return;
    }

    const currentDb = connection.config?.database || dbName;

    // Check and add missing columns for existing MySQL tables
    const safeAddColumn = async (table, column, definition) => {
      try {
        const [rows] = await connection.query(
          `SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? AND COLUMN_NAME = ?`,
          [currentDb, table, column]
        );
        if (rows.length === 0) {
          await connection.query(`ALTER TABLE \`${table}\` ADD COLUMN \`${column}\` ${definition}`);
          console.log(` Added missing column '${column}' to table '${table}'.`);
        }
      } catch (err) {
        // Table might not exist yet before first sync, which is fine
      }
    };

    await safeAddColumn('Users', 'status', "ENUM('pending', 'active', 'rejected', 'suspended', 'blocked') NOT NULL DEFAULT 'active'");
    // In case column exists with old enum, modify it safely
    try {
      await connection.query("ALTER TABLE `Users` MODIFY COLUMN `status` ENUM('pending', 'active', 'rejected', 'suspended', 'blocked') NOT NULL DEFAULT 'active'");
    } catch (e) {}

    await safeAddColumn('Users', 'rejectionReason', 'TEXT NULL');
    await safeAddColumn('Users', 'approvedAt', 'DATETIME NULL');
    await safeAddColumn('Users', 'approvedBy', 'CHAR(36) NULL');
    await safeAddColumn('Users', 'avatarUrl', 'VARCHAR(255) NULL');
    await safeAddColumn('Users', 'lastLoginAt', 'DATETIME NULL');

    await safeAddColumn('Farms', 'status', "ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'approved'");
    try {
      await connection.query("ALTER TABLE `Farms` MODIFY COLUMN `status` ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'approved'");
      await connection.query("UPDATE `Farms` SET `status` = 'approved' WHERE `status` IS NULL OR `status` = ''");
    } catch (e) {}
    await safeAddColumn('Farms', 'rejectionReason', 'TEXT NULL');
    await safeAddColumn('Farms', 'approvedAt', 'DATETIME NULL');
    await safeAddColumn('Farms', 'approvedBy', 'CHAR(36) NULL');

    await safeAddColumn('Orders', 'currency', "VARCHAR(255) DEFAULT 'FCFA'");
    await safeAddColumn('Orders', 'paymentStatus', "ENUM('pending', 'paid', 'failed') DEFAULT 'pending'");
    await safeAddColumn('Orders', 'paymentMethod', 'VARCHAR(255) NULL');

    await safeAddColumn('Deliveries', 'isDelayed', 'TINYINT(1) DEFAULT 0');
    await safeAddColumn('Deliveries', 'delayReason', 'TEXT NULL');
    await safeAddColumn('Deliveries', 'confirmedAt', 'DATETIME NULL');

    await safeAddColumn('Devices', 'autoMode', 'TINYINT(1) DEFAULT 1');
    await safeAddColumn('Devices', 'healthStatus', "ENUM('excellent', 'good', 'warning', 'critical') DEFAULT 'good'");

    await connection.end();
    console.log(`MySQL database '${dbName}' verified and synchronized.`);
  } catch (error) {
    console.error(`Notice: Could not connect to MySQL server at ${host}:${port}. Make sure MySQL is running in XAMPP. Error:`, error.message);
  }
};

const sequelize = connectionUri
  ? new Sequelize(connectionUri, {
      dialect: 'mysql',
      logging: false,
      pool: {
        max: 5,
        min: 0,
        acquire: 30000,
        idle: 10000
      }
    })
  : new Sequelize(dbName, user, password, {
      host,
      port,
      dialect: 'mysql',
      logging: false,
      pool: {
        max: 5,
        min: 0,
        acquire: 30000,
        idle: 10000
      }
    });

module.exports = sequelize;
module.exports.ensureDatabaseExists = ensureDatabaseExists;
