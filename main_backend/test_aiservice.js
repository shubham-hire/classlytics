require('dotenv').config();
const aiService = require('./services/aiService');

(async () => {
  const prompt = aiService.buildPrompt({
    query: "@classAI can you tell me which is the most reactive element",
    studentData: null,
    senderName: "Student"
  });
  console.log("Testing callAI...");
  console.time("callAI");
  const result = await aiService.callAI(prompt);
  console.timeEnd("callAI");
  console.log("Result:", result);
})();
