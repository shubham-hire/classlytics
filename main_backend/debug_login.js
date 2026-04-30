require('dotenv').config();
const db = require('./config/db');
const bcrypt = require('bcryptjs');

async function debug() {
    const testCases = [
        { email: 'parent@test.com', pass: 'password123' },
        { email: 'shubham_parent@classlytics.in', pass: 'shubham@123' },
        { email: 'admin@test.com', pass: 'password123' },
        { email: 'teacher@test.com', pass: 'password123' }
    ];

    try {
        for (const test of testCases) {
            console.log(`\n--- Checking ${test.email} ---`);
            
            const [users] = await db.execute('SELECT * FROM users WHERE email = ?', [test.email]);
            if (users.length === 0) {
                console.log('User not found in users table');
            } else {
                const user = users[0];
                console.log('User found in users table:', { email: user.email, role: user.role });
                const match = await bcrypt.compare(test.pass, user.password);
                console.log('Bcrypt match (users):', match);
            }

            const [parents] = await db.execute('SELECT * FROM parents WHERE email = ?', [test.email]);
            if (parents.length === 0) {
                console.log('User not found in parents table');
            } else {
                const parent = parents[0];
                console.log('User found in parents table:', { email: parent.email });
                const match = await bcrypt.compare(test.pass, parent.password);
                console.log('Bcrypt match (parents):', match);
            }
        }

    } catch (e) {
        console.error(e);
    } finally {
        process.exit();
    }
}

debug();
