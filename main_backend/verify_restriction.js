require('dotenv/config');
const db = require('./config/db');

async function run() {
  const [students] = await db.query("SELECT id, user_id FROM students LIMIT 2");
  const [teachers] = await db.query("SELECT id FROM users WHERE role='Teacher' LIMIT 1");
  
  if (students.length < 2 || teachers.length < 1) {
    console.error("Need at least 2 students and 1 teacher to test.");
    process.exit(1);
  }
  
  const student1UserId = students[0].user_id;
  const student2Id = students[1].id;
  const teacherId = teachers[0].id;
  const student2Mention = `@${student2Id}`;

  console.log("Student 1 User ID (Sender):", student1UserId);
  console.log("Student 2 ID (Target/Mentioned):", student2Id);
  console.log("Teacher ID (Receiver):", teacherId);

  const fetch = global.fetch || require('node-fetch');

  const sendMessage = async (body, role) => {
    const res = await fetch('http://localhost:3000/chat/message', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        from: student1UserId,
        to: teacherId,
        body: body,
        role: role
      })
    });
    return { status: res.status, data: await res.json() };
  };

  console.log("\n--- Testing Student querying other student ---");
  const result1 = await sendMessage(`@classAI how is ${student2Mention} doing?`, 'student');
  console.log("Status:", result1.status);
  console.log("Response:", result1.data);

  console.log("\n--- Testing Student querying themselves (Should be blocked by CURRENT logic) ---");
  const result2 = await sendMessage(`@classAI how is @${students[0].id} doing?`, 'student');
  console.log("Status:", result2.status);
  console.log("Response:", result2.data);

  console.log("\n--- Testing Teacher querying student (Should be allowed) ---");
  const result3 = await sendMessage(`@classAI how is ${student2Mention} doing?`, 'teacher');
  console.log("Status:", result3.status);
  console.log("Response:", result3.data);

  process.exit(0);
}

run().catch(console.error);
