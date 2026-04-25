const db = require('./main_backend/config/db');

async function updateDb() {
  try {
    await db.execute("ALTER TABLE users MODIFY COLUMN role ENUM('ADMIN','Admin','Teacher','TEACHER','Student','STUDENT','Parent','DEPARTMENT_ADMIN')");
    await db.execute("UPDATE users SET role = 'ADMIN' WHERE role = 'SUPER_ADMIN'");
    await db.execute("ALTER TABLE users MODIFY COLUMN role ENUM('ADMIN','Admin','Teacher','Student','Parent','DEPARTMENT_ADMIN')");
    console.log("DB Updated Successfully!");
    process.exit(0);
  } catch (e) {
    console.error(e);
    process.exit(1);
  }
}

updateDb();
