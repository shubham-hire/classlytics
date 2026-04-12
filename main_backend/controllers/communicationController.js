const { messages, announcements } = require('../data/storage');
const { v4: uuidv4 } = require('uuid');

// POST /messages — Send a message
exports.sendMessage = (req, res) => {
  const { from, to, body } = req.body;
  if (!from || !to || !body) {
    return res.status(400).json({ error: 'from, to, and body are required.' });
  }
  const msg = { id: uuidv4(), from, to, body, timestamp: new Date().toISOString(), isRead: false };
  messages.push(msg);
  console.log(`[MESSAGE] ${from} → ${to}: "${body}"`);
  res.status(201).json({ message: 'Message sent', data: msg });
};

// GET /messages/:userId — Get inbox for a user
exports.getMessages = (req, res) => {
  const { userId } = req.params;
  const inbox = messages.filter(m => m.to === userId);
  res.status(200).json({ messages: inbox });
};

// POST /announcements — Broadcast to class
exports.sendAnnouncement = (req, res) => {
  const { classId, title, body } = req.body;
  if (!classId || !title || !body) {
    return res.status(400).json({ error: 'classId, title, and body are required.' });
  }
  const ann = { id: uuidv4(), classId, title, body, createdAt: new Date().toISOString() };
  announcements.push(ann);
  console.log(`[ANNOUNCEMENT] Class ${classId}: "${title}"`);
  res.status(201).json({ message: 'Announcement sent', announcement: ann });
};

// GET /announcements/:classId — Get announcements for a class
exports.getAnnouncements = (req, res) => {
  const { classId } = req.params;
  const result = announcements.filter(a => a.classId === classId);
  res.status(200).json({ announcements: result });
};
