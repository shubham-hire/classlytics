const express = require('express');
const router = express.Router();
const marksController = require('../controllers/marksController');

// POST /marks/batch — Add marks for multiple students
router.post('/batch', marksController.addBatchMarks);

// POST /marks — Add marks for a student
router.post('/', marksController.addMarks);

// GET /marks/:studentId/quiz-results — Quiz results grouped by subject
router.get('/:studentId/quiz-results', marksController.getQuizResults);

// GET /marks/:studentId/subject/:subject — Marks for a specific subject
router.get('/:studentId/subject/:subject', marksController.getMarksBySubject);

// GET /marks/:studentId — Full marks history
router.get('/:studentId', marksController.getMarksByStudent);

module.exports = router;
