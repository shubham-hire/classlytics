const http = require('http');

const data = JSON.stringify({
  query: "Please analyze this image",
  imageBase64: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=",
  imageMimeType: "image/png"
});

const req = http.request({
  hostname: '127.0.0.1',
  port: 3000,
  path: '/ai/homework-help',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': data.length
  }
}, res => {
  console.log(`Status: ${res.statusCode}`);
  let body = '';
  res.on('data', chunk => body += chunk);
  res.on('end', () => console.log('Response body:', body));
});

req.on('error', e => console.error(`Problem with request: ${e.message}`));
req.write(data);
req.end();
