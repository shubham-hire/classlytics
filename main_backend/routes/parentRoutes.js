const express = require('express');
const router = express.Router();
const parentController = require('../controllers/parentController');

router.post('/leave-request', parentController.submitLeaveRequest);
router.get('/leave-requests/:studentId', parentController.getLeaveRequests);
router.post('/leave-request/:requestId/status', parentController.updateLeaveRequestStatus);
router.post('/study-plan', parentController.generateHomeStudyPlan);
router.get('/child-info/:userId', parentController.getChildInfo);
router.get('/weekly-summary/:studentId', parentController.getWeeklySummary);
router.get('/fees/:studentId', parentController.getChildFees);

module.exports = router;
