require('dotenv').config();
const db = require('./config/db');
const bcrypt = require('bcryptjs');

async function debugIds() {
    const email = 'shubham_parent@classlytics.in';
    try {
        const [users] = await db.execute('SELECT id, email FROM users WHERE email = ?', [email]);
        console.log('User ID in users table:', users[0]?.id);

        const [parents] = await db.execute('SELECT id, user_id, email FROM parents WHERE email = ?', [email]);
        console.log('User ID in parents table:', parents[0]?.user_id);
        console.log('Parent ID in parents table:', parents[0]?.id);

        const [students] = await db.execute('SELECT id, user_id, parent_id FROM students WHERE parent_id = ?', [parents[0]?.id]);
        console.log('Linked students:', students);

    } catch (e) {
        console.error(e);
    } finally {
        process.exit();
    }
}

debugIds();
