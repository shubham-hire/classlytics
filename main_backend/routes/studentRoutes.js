const express = require('express');
const router = express.Router();
const studentController = require('../controllers/studentController');

// Fetch all registered students (global list)
router.get('/registered', studentController.getRegisteredStudents);

// Fetch students by class
router.get('/:classId/students', studentController.getStudentsByClass);

// Individual Student management
router.post('/add', studentController.addStudent);
router.put('/:id', studentController.updateStudent);
router.get('/student/:id', studentController.getStudentById);


// Bulk management
router.post('/bulk-add', studentController.bulkAddStudents);

module.exports = router;
