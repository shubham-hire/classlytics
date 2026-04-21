async function test() {
  const apiKey = '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';
  const url = 'https://integrate.api.nvidia.com/v1/models';
  
  const res = await fetch(url, {
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
    }
  });
  const data = await res.json();
  const visionModels = data.data?.filter(m => m.id.toLowerCase().includes('vision')).map(m => m.id);
  console.log('Vision Models:', visionModels);
}
test();
