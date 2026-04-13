const db = require('./config/db');
async function test() {
  const [classes] = await db.query('SELECT * FROM classes');
  console.log("CLASSES:", classes);
  const [students] = await db.query('SELECT * FROM users WHERE role="Student"');
  console.log("STUDENT USERS:", students);
  process.exit(0);
}
test();
