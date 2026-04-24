const express = require('express');
const router = express.Router();
const assignmentController = require('../controllers/assignmentController');
const upload = require('../config/upload');
const { verifyToken, requireRole } = require('../middleware/auth');

router.use(verifyToken);

// GET /assignments/student/:studentId — All assignments for student's enrolled classes
router.get('/student/:studentId', assignmentController.getStudentAssignments); // Ownership check in controller

// GET /assignments/:classId — Get all assignments for a class
router.get('/:classId', assignmentController.getAssignments); // Ownership/Enrollment check in controller

// POST /assignments — Create a new assignment (with optional media upload)
router.post('/', requireRole('Teacher', 'Admin'), upload.single('media'), assignmentController.createAssignment);

// PUT /assignments/:id — Edit an assignment
router.put('/:id', requireRole('Teacher', 'Admin'), upload.single('media'), assignmentController.editAssignment);

// DELETE /assignments/:id — Delete an assignment
router.delete('/:id', requireRole('Teacher', 'Admin'), assignmentController.deleteAssignment);

// POST /assignments/:assignmentId/submit — Submit an assignment
router.post('/:assignmentId/submit', requireRole('Student'), assignmentController.submitAssignment);

// GET /assignments/:assignmentId/submissions — Get all submissions
router.get('/:assignmentId/submissions', requireRole('Teacher', 'Admin'), assignmentController.getSubmissions);

// PUT /assignments/:assignmentId/submissions/:submissionId/grade — Grade a submission
router.put('/:assignmentId/submissions/:submissionId/grade', requireRole('Teacher', 'Admin'), assignmentController.gradeSubmission);

module.exports = router;
