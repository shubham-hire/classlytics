const db = require('../config/db');

// POST /student/:studentId/behavior — Add a behavior log
exports.addBehaviorLog = async (req, res) => {
  const { studentId } = req.params;
  const { type, remark } = req.body;

  if (!type || !remark) {
    return res.status(400).json({ error: 'type and remark are required.' });
  }

  const normalizedType = type.charAt(0).toUpperCase() + type.slice(1).toLowerCase();
  if (!['Positive', 'Negative'].includes(normalizedType)) {
    return res.status(400).json({ error: 'type must be Positive or Negative.' });
  }

  try {
    const [result] = await db.execute(
      'INSERT INTO behavior_logs (student_id, type, remark) VALUES (?, ?, ?) RETURNING id',
      [studentId, normalizedType, remark]
    );
    console.log(`[BEHAVIOR] Logged "${type}" for student ${studentId}: ${remark}`);
    res.status(201).json({ message: 'Behavior log added', log: { id: result[0].id, studentId, type: normalizedType, remark, date: new Date().toISOString() } });
  } catch (err) {
    console.error('[addBehaviorLog] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// GET /student/:studentId/behavior — Get all behavior logs for a student
exports.getBehaviorLogs = async (req, res) => {
  const { studentId } = req.params;
  try {
    const [rows] = await db.execute(
      'SELECT id, student_id, type, remark, date FROM behavior_logs WHERE student_id = ? ORDER BY date DESC',
      [studentId]
    );
    res.status(200).json({ behaviorLogs: rows });
  } catch (err) {
    console.error('[getBehaviorLogs] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};
