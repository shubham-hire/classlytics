const express = require('express');
const router = express.Router();
const aiController = require('../controllers/aiController');

// Map GET /student/:studentId/insights to controller
router.get('/:studentId/insights', aiController.getStudentInsights);

// Map GET /student/:studentId/risk to controller
router.get('/:studentId/risk', aiController.getStudentRisk);

// Map GET /student/:studentId/suggestions to controller
router.get('/:studentId/suggestions', aiController.getStudentSuggestions);

module.exports = router;
