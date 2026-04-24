const express = require('express');
const router = express.Router();
const marksController = require('../controllers/marksController');
const db = require('../config/db');
const { verifyToken, requireRole, verifyOwnership } = require('../middleware/auth');

router.use(verifyToken);

// Adding/Batching marks is restricted to staff
router.post('/batch', requireRole('Teacher', 'Admin'), marksController.addBatchMarks);
router.post('/', requireRole('Teacher', 'Admin'), marksController.addMarks);

// Viewing marks history is accessible to staff OR the student themselves OR their parent
router.get('/:studentId/quiz-results', verifyOwnership(db), marksController.getQuizResults);
router.get('/:studentId/subject/:subject', verifyOwnership(db), marksController.getMarksBySubject);
router.get('/:studentId', verifyOwnership(db), marksController.getMarksByStudent);

module.exports = router;
