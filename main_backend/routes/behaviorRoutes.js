const express = require('express');
const router = express.Router();
const behaviorController = require('../controllers/behaviorController');

router.post('/:studentId/behavior', behaviorController.addBehaviorLog);
router.get('/:studentId/behavior', behaviorController.getBehaviorLogs);

module.exports = router;
