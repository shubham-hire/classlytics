const express = require('express');
const router = express.Router();
const commController = require('../controllers/communicationController');
const { verifyToken, requireRole } = require('../middleware/auth');

router.use(verifyToken);

// Messages
router.post('/messages', commController.sendMessage);
router.get('/messages/:userId', commController.getMessages); // Ownership check in controller
router.put('/messages/:messageId/read', commController.markMessageRead); // Ownership check in controller

// Announcements
router.post('/announcements', requireRole('Teacher', 'Admin'), commController.sendAnnouncement);
router.get('/announcements/student/:studentId', commController.getStudentAnnouncements); // Ownership check in controller
router.get('/announcements/:classId', commController.getAnnouncements); // Enrollment check in controller

// Contacts
router.get('/contacts/:userId', commController.getContacts); // Ownership check in controller

module.exports = router;
