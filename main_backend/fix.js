require('dotenv').config();
const mysql = require('mysql2/promise');

async function fix() {
  const connectionConfig = {
      host: process.env.DB_HOST,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME
  };
  const tempConn = await mysql.createConnection(connectionConfig);
  try {
    await tempConn.query("ALTER TABLE assignments ADD COLUMN media_url VARCHAR(500) DEFAULT NULL;");
    console.log("Added media_url");
  } catch(e) { console.log(e.message); }
  
  try {
    await tempConn.query("ALTER TABLE assignments ADD COLUMN media_type ENUM('image', 'pdf', 'none') DEFAULT 'none';");
    console.log("Added media_type");
  } catch(e) { console.log(e.message); }

  await tempConn.end();
}
fix();
