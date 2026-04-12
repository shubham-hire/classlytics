const express = require('express');
const router = express.Router();
const communicationController = require('../controllers/communicationController');

router.post('/messages', communicationController.sendMessage);
router.get('/messages/:userId', communicationController.getMessages);
router.post('/announcements', communicationController.sendAnnouncement);
router.get('/announcements/:classId', communicationController.getAnnouncements);

module.exports = router;
