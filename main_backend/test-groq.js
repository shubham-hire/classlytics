require('dotenv').config();
const apiKey = process.env.GROQ_API_KEY;
const baseUrl = process.env.GROQ_BASE_URL;
const model = process.env.GROQ_MODEL;
console.log('Testing with:', baseUrl, model, apiKey ? 'KEY PRESENT' : 'NO KEY');
async function test() {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 10000);
  try {
    console.time('fetch');
    const res = await fetch(`${baseUrl}/chat/completions`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      },
      signal: controller.signal,
      body: JSON.stringify({
        model: model,
        messages: [{ role: 'user', content: 'Say hello' }],
        max_tokens: 10
      })
    });
    clearTimeout(timeoutId);
    console.timeEnd('fetch');
    console.log('Status:', res.status);
    const json = await res.json();
    console.log('Response:', JSON.stringify(json).substring(0, 100));
  } catch (err) {
    console.error('Error:', err.message);
  }
}
test();
