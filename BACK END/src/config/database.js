const { Sequelize } = require('sequelize');
const mysql = require('mysql2/promise');
const dotenv = require('dotenv');
const path = require('path');

dotenv.config({ path: path.join(__dirname, '../../.env') });

const host = process.env.DB_HOST || '127.0.0.1';
const port = parseInt(process.env.DB_PORT || '3306');
const user = process.env.DB_USER || 'root';
const password = process.env.DB_PASS || '';
const dbName = process.env.DB_NAME || 'NOVARA';

// Helper function to auto-create MySQL database if it doesn't exist
const ensureDatabaseExists = async () => {
  try {
    const connection = await mysql.createConnection({ host, port, user, password });
    await connection.query(`CREATE DATABASE IF NOT EXISTS \`${dbName}\`;`);
    await connection.end();
    console.log(` MySQL database '${dbName}' verified/created in XAMPP.`);
  } catch (error) {
    console.error(` Notice: Could not connect to MySQL server at ${host}:${port}. Make sure MySQL is running in XAMPP Control Panel. Error:`, error.message);
  }
};

// Immediately execute DB verification for MySQL
ensureDatabaseExists();

const sequelize = new Sequelize(dbName, user, password, {
  host,
  port,
  dialect: 'mysql',
  logging: process.env.NODE_ENV === 'development' ? console.log : false,
  pool: {
    max: 5,
    min: 0,
    acquire: 30000,
    idle: 10000
  }
});

module.exports = sequelize;
