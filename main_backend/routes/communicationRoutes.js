const express = require('express');
const router = express.Router();
const commController = require('../controllers/communicationController');

// Messages
router.post('/messages', commController.sendMessage);
router.get('/messages/:userId', commController.getMessages);
router.put('/messages/:messageId/read', commController.markMessageRead);

// Announcements
router.post('/announcements', commController.sendAnnouncement);
router.get('/announcements/student/:studentId', commController.getStudentAnnouncements); // Must be BEFORE /:classId
router.get('/announcements/:classId', commController.getAnnouncements);

// Contacts
router.get('/contacts/:userId', commController.getContacts);

module.exports = router;
