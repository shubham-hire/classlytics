require('dotenv').config();
const http = require('http');

const data = JSON.stringify({
  query: "Who is my best student?",
  teacherId: "uid-teacher-001"
});

const req = http.request({
  hostname: '127.0.0.1',
  port: 3000,
  path: '/ai/teacher-help',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(data)
  }
}, res => {
  console.log(`Status: ${res.statusCode}`);
  let body = '';
  res.on('data', chunk => body += chunk);
  res.on('end', () => console.log('Response body:', body));
});

req.on('error', e => console.error(`Problem: ${e.message}`));
req.write(data);
req.end();
