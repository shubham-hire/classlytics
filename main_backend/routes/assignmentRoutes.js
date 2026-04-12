const express = require('express');
const router = express.Router();
const assignmentController = require('../controllers/assignmentController');

router.post('/', assignmentController.createAssignment);
router.get('/:classId', assignmentController.getAssignments);
router.post('/:assignmentId/submit', assignmentController.submitAssignment);
router.get('/:assignmentId/submissions', assignmentController.getSubmissions);

module.exports = router;
