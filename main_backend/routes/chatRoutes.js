const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');

// POST /chat/message — unified message handler (normal + @classAI)
router.post('/message', chatController.handleMessage);

module.exports = router;
