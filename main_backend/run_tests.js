require('dotenv/config');
const db = require('./config/db');

async function run() {
  const [users] = await db.query("SELECT id FROM users WHERE role='Teacher' LIMIT 1");
  const [students] = await db.query("SELECT id FROM users WHERE role='Student' LIMIT 1");
  
  const teacherId = users[0].id;
  const studentFullId = students[0].id; // e.g. STU001
  const studentMention = `@${studentFullId}`;

  console.log("Teacher ID:", teacherId);
  console.log("Student ID:", studentFullId);

  const fetch = global.fetch || require('node-fetch');

  const sendMessage = async (body) => {
    const res = await fetch('http://localhost:3000/chat/message', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        from: teacherId,
        to: studentFullId,
        body: body,
        role: "teacher"
      })
    });
    return res.json();
  };

  console.log("\n--- Testing Normal Message ---");
  console.log(await sendMessage('Hello student!'));

  console.log("\n--- Testing AI Pattern (no mention) ---");
  console.log(await sendMessage('@classAI what is gravity?'));

  console.log(`\n--- Testing AI Pattern (with mention: ${studentMention}) ---`);
  console.log(await sendMessage(`@classAI how is ${studentMention} doing?`));

  console.log("\n--- Final Messages in DB ---");
  const [messages] = await db.query('SELECT sender_id, receiver_id, body FROM messages ORDER BY id DESC LIMIT 6');
  console.log(messages.map(m => `[${m.sender_id}] -> [${m.receiver_id}]: ${m.body.substring(0, 50)}...`));

  process.exit(0);
}

run().catch(console.error);
