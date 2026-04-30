require('dotenv').config();
const db = require('./config/db');

async function checkStudents() {
    try {
        const [students] = await db.execute('SELECT id, user_id FROM students');
        console.log('Students in DB:', students);
        
        const [users] = await db.execute('SELECT id, email, role FROM users WHERE role = "Student"');
        console.log('Student Users in DB:', users);

        const [parents] = await db.execute('SELECT id, user_id, email FROM parents');
        console.log('Parents in DB:', parents);

    } catch (e) {
        console.error(e);
    } finally {
        process.exit();
    }
}

checkStudents();
