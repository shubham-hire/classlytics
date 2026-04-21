async function test() {
  const apiKey = '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';
  const url = 'https://integrate.api.nvidia.com/v1/chat/completions';
  const emptyBase64Image = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=";

  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      model: 'meta/llama-3.2-90b-vision-instruct',
      messages: [
        { role: 'user', content: [
          { type: 'text', text: 'What is this image?' },
          { type: 'image_url', image_url: { url: `data:image/png;base64,${emptyBase64Image}` } }
        ]}
      ],
      max_tokens: 50
    })
  });
  console.log('Status', res.status);
  const text = await res.text();
  console.log('Result', text);
}
test();
