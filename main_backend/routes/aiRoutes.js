const express = require('express');
const router = express.Router();
const aiController = require('../controllers/aiController');

// Map GET /student/:studentId/insights to controller
router.get('/:studentId/insights', aiController.getStudentInsights);

// Map GET /student/:studentId/risk to controller
router.get('/:studentId/risk', aiController.getStudentRisk);

// Map GET /student/:studentId/suggestions to controller
router.get('/:studentId/suggestions', aiController.getStudentSuggestions);

// Map GET /student/:studentId/study-plan to controller
router.get('/:studentId/study-plan', aiController.getStudentStudyPlan);

// Map GET /student/:studentId/notifications to controller
router.get('/:studentId/notifications', aiController.getStudentNotifications);

// Map POST /student/homework-help to controller
router.post('/homework-help', aiController.getHomeworkHelp);

// Map POST /teacher-help to controller
router.post('/teacher-help', aiController.getTeacherHelp);

module.exports = router;
