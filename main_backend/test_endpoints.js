const http = require('http');

setTimeout(() => {
  console.log('Sending request to teacher-help...');
  const req = http.request({
    hostname: '127.0.0.1',
    port: 3000,
    path: '/ai/teacher-help',
    method: 'POST',
    headers: { 'Content-Type': 'application/json' }
  }, res => {
    console.log(`Teacher-help Status: ${res.statusCode}`);
    res.on('data', chunk => console.log('Teacher-help chunk:', chunk.toString()));
  });
  req.write(JSON.stringify({ query: 'Hello', teacherId: 'uid-teacher-001' }));
  req.end();

  console.log('Sending request to chat/message (@classAI)...');
  const req2 = http.request({
    hostname: '127.0.0.1',
    port: 3000,
    path: '/chat/message',
    method: 'POST',
    headers: { 'Content-Type': 'application/json' }
  }, res => {
    console.log(`Chat Status: ${res.statusCode}`);
    res.on('data', chunk => console.log('Chat chunk:', chunk.toString()));
  });
  req2.write(JSON.stringify({ from: 'uid-student-001', to: 'uid-teacher-001', body: '@classAI hello' }));
  req2.end();
}, 2000);
