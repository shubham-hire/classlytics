const express = require('express');
const router = express.Router();
const parentController = require('../controllers/parentController');
const db = require('../config/db');
const { verifyToken, requireRole, verifyParentOwnership } = require('../middleware/auth');

router.use(verifyToken);

// Leave requests
router.post('/leave-request', requireRole('Parent'), verifyParentOwnership(db), parentController.submitLeaveRequest);
router.get('/leave-requests/:studentId', verifyParentOwnership(db), parentController.getLeaveRequests); 
router.post('/leave-request/:requestId/status', requireRole('Teacher', 'Admin'), parentController.updateLeaveRequestStatus);

// Analytics & Info
router.post('/study-plan', requireRole('Parent', 'Teacher', 'Admin'), parentController.generateHomeStudyPlan);
router.get('/child-info/:userId', parentController.getChildInfo); // userId based check still in controller for now
router.get('/weekly-summary/:studentId', verifyParentOwnership(db), parentController.getWeeklySummary); 
router.get('/fees/:studentId', verifyParentOwnership(db), parentController.getChildFees); 

module.exports = router;
