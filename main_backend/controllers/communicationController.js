const db = require('../config/db');
const { checkStudentOwnership, checkParentOwnership } = require('../middleware/auth');

// POST /communication/messages — Send a message
exports.sendMessage = async (req, res) => {
  const { to, body } = req.body;
  const from = req.user.id; // Enforce sender is the logged in user

  if (!to || !body) {
    return res.status(400).json({ error: 'to and body are required.' });
  }

  try {
    const [result] = await db.execute(
      'INSERT INTO messages (sender_id, receiver_id, body) VALUES (?, ?, ?)',
      [from, to, body]
    );
    console.log(`[MESSAGE] ${from} → ${to}: "${body}"`);
    res.status(201).json({ message: 'Message sent', data: { id: result.insertId, from, to, body, timestamp: new Date().toISOString(), isRead: false } });
  } catch (err) {
    console.error('[sendMessage] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// GET /communication/contacts/:userId — Get available users to message
exports.getContacts = async (req, res) => {
  const { userId } = req.params;
  try {
    if (req.user.id !== userId && req.user.role !== 'Admin') {
      return res.status(403).json({ error: 'Access denied.' });
    }
    const [rows] = await db.execute(
      'SELECT id, name, role FROM users WHERE id != ? ORDER BY role DESC, name ASC',
      [userId]
    );
    res.status(200).json({ contacts: rows });
  } catch (err) {
    console.error('[getContacts] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// GET /communication/messages/:userId — Get full inbox + sent for a user
exports.getMessages = async (req, res) => {
  const { userId } = req.params;
  try {
    if (req.user.id !== userId && req.user.role !== 'Admin') {
      return res.status(403).json({ error: 'Access denied.' });
    }
    const [rows] = await db.execute(
      `SELECT 
          m.id,
          m.sender_id,
          s.name AS sender_name,
          m.receiver_id,
          r.name AS receiver_name,
          m.body,
          m.timestamp,
          m.is_read
       FROM messages m
       JOIN users s ON s.id = m.sender_id
       JOIN users r ON r.id = m.receiver_id
       WHERE m.sender_id = ? OR m.receiver_id = ?
       ORDER BY m.timestamp ASC`,
      [userId, userId]
    );
    res.status(200).json({ messages: rows });
  } catch (err) {
    console.error('[getMessages] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// PUT /communication/messages/:messageId/read — Mark a message as read
exports.markMessageRead = async (req, res) => {
  const { messageId } = req.params;
  try {
    await db.execute('UPDATE messages SET is_read = TRUE WHERE id = ?', [messageId]);
    res.status(200).json({ message: 'Marked as read' });
  } catch (err) {
    console.error('[markMessageRead] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// POST /communication/announcements — Broadcast to class
exports.sendAnnouncement = async (req, res) => {
  const { classId, title, body } = req.body;
  if (!classId || !title || !body) {
    return res.status(400).json({ error: 'classId, title, and body are required.' });
  }

  try {
    const [result] = await db.execute(
      'INSERT INTO announcements (class_id, title, body) VALUES (?, ?, ?)',
      [classId, title, body]
    );
    console.log(`[ANNOUNCEMENT] Class ${classId}: "${title}"`);
    res.status(201).json({ message: 'Announcement sent', announcement: { id: result.insertId, classId, title, body, createdAt: new Date().toISOString() } });
  } catch (err) {
    console.error('[sendAnnouncement] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// GET /communication/announcements/:classId — Get announcements for a class
exports.getAnnouncements = async (req, res) => {
  const { classId } = req.params;
  try {
    const [rows] = await db.execute(
      'SELECT id, class_id, title, body, created_at FROM announcements WHERE class_id = ? ORDER BY created_at DESC',
      [classId]
    );
    res.status(200).json({ announcements: rows });
  } catch (err) {
    console.error('[getAnnouncements] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// GET /communication/announcements/student/:studentId — Get all announcements for student's enrolled classes
exports.getStudentAnnouncements = async (req, res) => {
  const { studentId } = req.params;
  try {
    const hasStudentAccess = await checkStudentOwnership(db, studentId, req.user);
    const hasParentAccess = await checkParentOwnership(db, studentId, req.user);
    if (!hasStudentAccess && !hasParentAccess) {
      return res.status(403).json({ error: 'Access denied.' });
    }
    const [rows] = await db.execute(
      `SELECT a.id, a.class_id, c.name AS class_name, a.title, a.body, a.created_at
       FROM announcements a
       JOIN class_enrollments ce ON ce.class_id = a.class_id
       JOIN classes c ON c.id = a.class_id
       WHERE ce.student_id = ?
       ORDER BY a.created_at DESC`,
      [studentId]
    );
    res.status(200).json({ announcements: rows });
  } catch (err) {
    console.error('[getStudentAnnouncements] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};
