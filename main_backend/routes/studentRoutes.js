const express = require('express');
const router = express.Router();
const studentController = require('../controllers/studentController');
const { verifyToken, requireRole } = require('../middleware/auth');

// All student management routes require valid JWT and staff role
router.use(verifyToken);
router.use(requireRole('Teacher', 'Admin'));

// Fetch all registered students (global list)
router.get('/registered', studentController.getRegisteredStudents);

// Fetch students by class
router.get('/:classId/students', studentController.getStudentsByClass);

// Individual Student management
router.post('/add', studentController.addStudent);
router.post('/create-with-parent', studentController.createWithParent);
router.put('/:id', studentController.updateStudent);
router.get('/student/:id', studentController.getStudentById);

module.exports = router;
