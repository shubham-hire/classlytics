/**
 * aiService.js
 * Builds LLM prompts and calls the NVIDIA API.
 * Model: meta/llama-3.1-8b-instruct
 */

const GROQ_BASE_URL = process.env.GROQ_BASE_URL || 'https://api.groq.com/openai/v1';
const GROQ_MODEL = process.env.GROQ_MODEL || 'llama-3.1-8b-instant';
const AI_REQUEST_TIMEOUT_MS = Number(process.env.AI_REQUEST_TIMEOUT_MS || 20000);

/**
 * Builds the system + user prompt strings based on available context.
 * @param {{ query: string, studentData?: object|null, senderName?: string }} opts
 * @returns {{ system: string, user: string }}
 */
function buildPrompt({ query, studentData, senderName }) {
  if (studentData) {
    const { profile, attendancePct, avgScore, recentMarks, weakSubjects, pendingAssignments } =
      studentData;

    const marksText =
      recentMarks.length > 0
        ? recentMarks
            .map(m => `${m.subject} (${m.type}): ${m.score}/${m.max_score}`)
            .join(', ')
        : 'No data';

    const weakText = weakSubjects.length > 0 ? weakSubjects.join(', ') : 'None';
    const pendingText =
      pendingAssignments.length > 0
        ? pendingAssignments
            .map(a => `"${a.title}" (due ${new Date(a.deadline).toLocaleDateString()})`)
            .join(', ')
        : 'None';

    const system = `You are ClassAI, an intelligent academic assistant embedded in the Classlytics platform.
You have access to live student data. Provide warm, concise, actionable insights.
Always address the teacher by name if known, and use the student's data directly.
Keep responses under 200 words. Use bullet points for clarity.`;

    const user = `=== STUDENT PROFILE ===
Name: ${profile.name}
Department: ${profile.dept} | Year: ${profile.current_year}
Attendance: ${attendancePct !== null ? `${attendancePct}%${attendancePct < 75 ? ' ⚠️ Low' : ' ✅'}` : 'No data'}
Average Score: ${avgScore !== null ? `${avgScore}%` : 'No data'}
Recent Marks: ${marksText}
Weak Subjects: ${weakText}
Pending Assignments: ${pendingText}
======================

${senderName ? `Teacher (${senderName}) asks: ` : ''}${query}`;

    return { system, user };
  }

  // General tutor mode (no student data)
  const system = `You are ClassAI, a helpful and friendly academic tutor in the Classlytics platform.
Answer clearly and concisely. Use simple language. Keep responses under 150 words.`;

  const user = query;

  return { system, user };
}

/**
 * Calls the NVIDIA LLM API with the given prompt and returns the AI response string.
 * @param {{ system: string, user: string }} prompt
 * @returns {Promise<string>}
 */
async function callAI(prompt) {
  const apiKey = process.env.GROQ_API_KEY;

  if (!apiKey || apiKey === 'your_nvidia_api_key_here') {
    console.warn('[AIService] No valid API key found. Returning fallback response.');
    return "ClassAI is currently unavailable. Please check the server configuration.";
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), AI_REQUEST_TIMEOUT_MS);

  try {
    const response = await fetch(`${GROQ_BASE_URL}/chat/completions`, {
      method: 'POST',
      signal: controller.signal,
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: GROQ_MODEL,
        messages: [
          { role: 'system', content: prompt.system },
          { role: 'user', content: prompt.user },
        ],
        temperature: 0.7,
        max_tokens: 300,
        stream: false,
      }),
    });

    if (!response.ok) {
      const errBody = await response.text();
      console.error('[AIService] NVIDIA API error:', response.status, errBody);
      return "Sorry, I couldn't process that right now. Please try again later.";
    }

    const data = await response.json();
    const content = data?.choices?.[0]?.message?.content;
    if (!content) {
      console.warn('[AIService] Empty AI response body.');
      return "Sorry, I couldn't generate a response. Please try rephrasing.";
    }

    return content.trim();
  } catch (err) {
    if (err.name === 'AbortError') {
      console.error(`[AIService] AI API request timed out after ${AI_REQUEST_TIMEOUT_MS}ms.`);
      return "ClassAI is taking too long to respond right now. Please try again in a moment.";
    }

    console.error('[AIService] Fetch error:', err.message);
    return "Sorry, I couldn't reach the AI service right now.";
  } finally {
    clearTimeout(timeout);
  }
}

module.exports = { buildPrompt, callAI };
