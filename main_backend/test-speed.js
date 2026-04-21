async function test() {
  const apiKey = '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';
  const url = 'https://integrate.api.nvidia.com/v1/chat/completions';

  console.time('Fetch');
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      model: 'meta/llama-3.1-8b-instruct',
      messages: [
        { role: 'user', content: 'Say hello in 5 words.' }
      ],
      max_tokens: 20
    })
  });
  console.timeEnd('Fetch');
  console.log('Status', res.status);
  const text = await res.text();
  console.log('Result', text);
}
test();
