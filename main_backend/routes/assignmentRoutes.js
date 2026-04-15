const express = require('express');
const router = express.Router();
const assignmentController = require('../controllers/assignmentController');
const upload = require('../config/upload');

// GET /assignments/student/:studentId — All assignments for student's enrolled classes
router.get('/student/:studentId', assignmentController.getStudentAssignments);

// GET /assignments/:classId — Get all assignments for a class
router.get('/:classId', assignmentController.getAssignments);

// POST /assignments — Create a new assignment (with optional media upload)
router.post('/', upload.single('media'), assignmentController.createAssignment);

// POST /assignments/:assignmentId/submit — Submit an assignment
router.post('/:assignmentId/submit', assignmentController.submitAssignment);

// GET /assignments/:assignmentId/submissions — Get all submissions
router.get('/:assignmentId/submissions', assignmentController.getSubmissions);

// PUT /assignments/:assignmentId/submissions/:submissionId/grade — Grade a submission
router.put('/:assignmentId/submissions/:submissionId/grade', assignmentController.gradeSubmission);

module.exports = router;
