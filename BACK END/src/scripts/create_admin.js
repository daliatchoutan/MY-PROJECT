const { User, sequelize } = require('../models');
const dotenv = require('dotenv');
const path = require('path');

dotenv.config({ path: path.join(__dirname, '../../.env') });

/**
 * CLI script to create an Administrator account directly
 * Usage: node src/scripts/create_admin.js "Full Name" "email@example.com" "password123" "phone (optional)"
 */
async function createAdmin() {
  const args = process.argv.slice(2);
  const name = args[0] || 'System Administrator';
  const email = args[1];
  const password = args[2];
  const phone = args[3] || '';

  if (!email || !password) {
    console.log('Usage: node src/scripts/create_admin.js "<name>" "<email>" "<password>" "[phone]"');
    console.log('Example: node src/scripts/create_admin.js "Super Admin" "admin@novara.com" "AdminPass123" "690000000"');
    process.exit(1);
  }

  try {
    await sequelize.authenticate();
    console.log(' Database connection verified.');

    // Check if user already exists
    const existing = await User.findOne({ where: { email } });
    if (existing) {
      existing.role = 'Administrator';
      existing.status = 'active';
      existing.password = password;
      await existing.save();
      console.log(` Updated existing user '${email}' with new password and Administrator role.`);
      process.exit(0);
    }

    // Create new Administrator
    const newAdmin = await User.create({
      name,
      email,
      password, // Password hook will automatically hash it
      role: 'Administrator',
      status: 'active',
      phone
    });

    console.log(` Successfully created Administrator account:`);
    console.log(`  - ID: ${newAdmin.id}`);
    console.log(`  - Name: ${newAdmin.name}`);
    console.log(`  - Email: ${newAdmin.email}`);
    console.log(`  - Role: ${newAdmin.role}`);
    console.log(`  - Status: ${newAdmin.status}`);
  } catch (error) {
    console.error(' Error creating administrator:', error.message);
    process.exit(1);
  } finally {
    await sequelize.close();
  }
}

createAdmin();
