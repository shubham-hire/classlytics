const express = require('express');
const router = express.Router();
const aiController = require('../controllers/aiController');
const db = require('../config/db');
const { verifyToken, requireRole, verifyOwnership } = require('../middleware/auth');

router.use(verifyToken);

// Student specific routes (require ownership check)
router.get('/:studentId/insights', verifyOwnership(db), aiController.getStudentInsights);
router.get('/:studentId/risk', verifyOwnership(db), aiController.getStudentRisk);
router.get('/:studentId/suggestions', verifyOwnership(db), aiController.getStudentSuggestions);
router.get('/:studentId/study-plan', verifyOwnership(db), aiController.getStudentStudyPlan);
router.get('/:studentId/notifications', verifyOwnership(db), aiController.getStudentNotifications);
router.get('/parent/weekly-summary/:studentId', verifyOwnership(db), aiController.getStudentWeeklySummary);

// Homework help is generally for students or teachers
router.post('/homework-help', aiController.getHomeworkHelp);

// Teacher specific routes
router.post('/teacher-help', requireRole('Teacher', 'Admin'), aiController.getTeacherHelp);
router.get('/teacher/class-analysis/:classId', requireRole('Teacher', 'Admin'), aiController.getClassAnalysis);

// Admin specific routes
router.post('/admin/command-center', requireRole('Admin'), aiController.getAdminCommandCenter);
router.post('/admin/draft-announcement', requireRole('Admin'), aiController.draftAnnouncement);
router.post('/admin/student-feedback', requireRole('Admin'), aiController.generateStudentFeedback);
router.get('/admin/risk-analysis', requireRole('Admin'), aiController.getRiskAnalysis);
router.get('/admin/strategic-advice', requireRole('Admin'), aiController.getAdminStrategicAdvice);

module.exports = router;
