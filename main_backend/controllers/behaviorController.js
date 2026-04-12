const { behaviorLogs } = require('../data/storage');
const { v4: uuidv4 } = require('uuid');

// POST /student/:studentId/behavior — Add a behavior log
exports.addBehaviorLog = (req, res) => {
  const { studentId } = req.params;
  const { type, remark } = req.body; // type: "positive" | "negative"

  if (!type || !remark) {
    return res.status(400).json({ error: 'type and remark are required.' });
  }
  if (!['positive', 'negative', 'neutral'].includes(type)) {
    return res.status(400).json({ error: 'type must be positive, negative, or neutral.' });
  }

  const log = {
    id: uuidv4(),
    studentId,
    type,
    remark,
    date: new Date().toISOString().split('T')[0],
  };

  behaviorLogs.push(log);
  console.log(`[BEHAVIOR] Logged "${type}" for student ${studentId}: ${remark}`);
  res.status(201).json({ message: 'Behavior log added', log });
};

// GET /student/:studentId/behavior — Get all behavior logs for a student
exports.getBehaviorLogs = (req, res) => {
  const { studentId } = req.params;
  const logs = behaviorLogs.filter(l => l.studentId === studentId);
  res.status(200).json({ behaviorLogs: logs });
};
