/**
 * chatController.js
 * Handles POST /chat/message
 *
 * Flow:
 *  1. Save the sender's message (always).
 *  2. If @classAI is NOT triggered → respond with { ai: false }.
 *  3. If @classAI IS triggered:
 *     a. Extract query and any @STDxxx mentions.
 *     b. Check role-based access (students cannot access other students).
 *     c. Fetch student context if mentioned.
 *     d. Build prompt → call AI → save AI response as "classAI" sender.
 *     e. Respond with { ai: true, response }.
 */

const db = require('../config/db');
const { isAITriggered, extractQuery, extractStudentId } = require('../utils/aiParser');
const { resolveStudentId, getStudentContext } = require('../services/studentService');
const { buildPrompt, callAI } = require('../services/aiService');

// Stable virtual sender ID for ClassAI messages stored in the DB.
// This user must exist (or we insert it once in initDb). See notes below.
const CLASS_AI_SENDER_ID = 'classAI';

/**
 * Ensure the classAI virtual user exists in the users table.
 * Called lazily so we don't block startup.
 */
async function ensureClassAIUser() {
  try {
    const [rows] = await db.execute(`SELECT id FROM users WHERE id = ?`, [CLASS_AI_SENDER_ID]);
    if (rows.length === 0) {
      await db.execute(
        `INSERT INTO users (id, name, role, email, password)
         VALUES (?, 'ClassAI', 'Admin', 'classai@classlytics.internal', '')
         ON CONFLICT (id) DO NOTHING`,
        [CLASS_AI_SENDER_ID]
      );
      console.log('[ChatController] Inserted classAI virtual user.');
    }
  } catch (err) {
    console.warn('[ChatController] Could not ensure classAI user:', err.message);
  }
}

/**
 * Save a message to the messages table.
 * @param {string|number} from  sender_id
 * @param {string|number} to    receiver_id
 * @param {string} body
 */
async function saveMessage(from, to, body) {
  await db.execute(
    'INSERT INTO messages (sender_id, receiver_id, body) VALUES (?, ?, ?)',
    [from, to, body]
  );
}

/**
 * POST /chat/message
 * Body: { from, to, body, role? }
 *   from  — sender user ID (numeric)
 *   to    — receiver user ID (numeric)
 *   body  — the message text
 *   role  — optional: 'student' | 'teacher' (used for RBAC)
 */
exports.handleMessage = async (req, res) => {
  const { from, to, body, role } = req.body;

  if (!from || !to || !body) {
    return res.status(400).json({ error: '`from`, `to`, and `body` are required.' });
  }

  // ── 1. Save the sender's message ──────────────────────────────
  try {
    await saveMessage(from, to, body);
    console.log(`[CHAT] ${from} → ${to}: "${body.slice(0, 60)}"`);
  } catch (err) {
    console.error('[ChatController] saveMessage error:', err.message);
    return res.status(500).json({ error: 'Failed to save message.' });
  }

  // ── 2. Non-AI path ─────────────────────────────────────────────
  if (!isAITriggered(body)) {
    return res.status(201).json({ ai: false, status: 'sent' });
  }

  // ── 3. AI path ─────────────────────────────────────────────────
  const query = extractQuery(body);
  const mentionedStudentRaw = extractStudentId(body); // e.g. "STD005"

  let studentData = null;

  if (mentionedStudentRaw) {
    // RBAC: students cannot query other students' data
    if (role === 'student') {
      return res.status(403).json({ error: 'Students cannot access other students\' data.' });
    }

    const resolvedId = await resolveStudentId(mentionedStudentRaw);
    if (resolvedId) {
      studentData = await getStudentContext(resolvedId);
    } else {
      console.warn(`[ChatController] Could not resolve student mention: ${mentionedStudentRaw}`);
    }
  } else if (role === 'parent') {
    // If a parent uses AI but doesn't mention an ID, assume they want their own child's data
    try {
      const db = require('../config/db');
      const [parentRows] = await db.execute('SELECT child_id FROM parents WHERE user_id = ?', [from]);
      if (parentRows.length > 0 && parentRows[0].child_id) {
        studentData = await getStudentContext(parentRows[0].child_id);
      }
    } catch (err) {
      console.error('[ChatController] Could not fetch parent context:', err.message);
    }
  }

  // Fetch sender name for personalised prompts
  let senderName = null;
  try {
    const [userRows] = await db.execute('SELECT name FROM users WHERE id = ?', [from]);
    senderName = userRows[0]?.name ?? null;
  } catch (_) {}

  // Build & call AI
  const prompt = buildPrompt({ query: query || 'Help me with this.', studentData, senderName });
  const aiResponse = await callAI(prompt);

  // ── 4. Save AI response ────────────────────────────────────────
  try {
    // Bind the AI response to the specific conversation thread
    // We send it from the original sender to the receiver, but inject a hidden HTML-style tag
    // so the frontend knows to render it as a ClassAI bubble. This ensures BOTH users see it
    // seamlessly in their thread history without leaking to other chats.
    const hiddenTag = `<!--CLASS_AI-->\n`;
    await saveMessage(from, to, hiddenTag + aiResponse);
    console.log(`[CHAT-AI-THREAD] ${from} -> ${to}: "${aiResponse.slice(0, 60)}..."`);
  } catch (err) {
    console.error('[ChatController] Could not save AI message:', err.message);
    // Don't fail the request — still return the response to the client
  }

  return res.status(201).json({
    ai: true,
    response: aiResponse,
  });
};
