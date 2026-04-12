const express = require('express');
const router = express.Router();
const studentController = require('../controllers/studentController');

// Map GET /class/:classId/students to controller
router.get('/test', (req, res) => res.send('Student Router is working!'));
router.get('/:classId/students', studentController.getStudentsByClass);

module.exports = router;
