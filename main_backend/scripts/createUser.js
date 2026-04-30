require('dotenv').config();
const db = require('../config/db');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

async function createUser() {
    const args = process.argv.slice(2);
    if (args.length < 3) {
        console.log('Usage: node scripts/createUser.js <email> <password> <role> [name]');
        process.exit(1);
    }

    const [email, password, role, name = 'Test User'] = args;

    try {
        const hashedPassword = await bcrypt.hash(password, 10);
        const userId = uuidv4();

        await db.execute(
            'INSERT INTO users (id, name, email, password, role) VALUES (?, ?, ?, ?, ?)',
            [userId, name, email, hashedPassword, role]
        );

        console.log(`✅ User created successfully!`);
        console.log(`Email: ${email}`);
        console.log(`Password: ${password}`);
        console.log(`Role: ${role}`);
        console.log(`ID: ${userId}`);

    } catch (error) {
        console.error('❌ Failed to create user:', error.message);
    } finally {
        process.exit();
    }
}

createUser();
