const db = require('./config/db');

async function migrate() {
  try {
    await db.execute(`
      CREATE TABLE IF NOT EXISTS parents (
        id VARCHAR(50) PRIMARY KEY,
        user_id VARCHAR(50),
        name VARCHAR(255) NOT NULL,
        relation VARCHAR(100),
        phone VARCHAR(50) NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        child_id VARCHAR(50),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    `);

    // Add user_id to parents if it doesn't exist (Migration for existing tables)
    try {
      await db.execute('ALTER TABLE parents ADD COLUMN user_id VARCHAR(50) AFTER id');
      await db.execute('ALTER TABLE parents ADD CONSTRAINT fk_parent_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE');
    } catch(e) {
       // if column exists, ignore
    }
    
    // Add parent_id to students if it doesn't exist
    try {
      await db.execute('ALTER TABLE students ADD COLUMN parent_id VARCHAR(50)');
      await db.execute('ALTER TABLE students ADD CONSTRAINT fk_student_parent FOREIGN KEY (parent_id) REFERENCES parents(id)');
    } catch(e) {
      if (e.code !== 'ER_DUP_FIELDNAME') {
        throw e;
      }
    }
    
    // Add fk for child_id in parents
    try {
      await db.execute('ALTER TABLE parents ADD CONSTRAINT fk_parent_student FOREIGN KEY (child_id) REFERENCES students(id)');
    } catch(e) {
       // if constraint exists or duplicate, ignore
    }

    console.log('Migration successful');
    process.exit(0);
  } catch (err) {
    console.error('Migration failed:', err);
    process.exit(1);
  }
}

migrate();
