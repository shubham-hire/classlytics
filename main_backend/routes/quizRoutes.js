const express = require('express');
const router = express.Router();
const quizController = require('../controllers/quizController');
const { verifyToken } = require('../middleware/auth');

router.use(verifyToken);

// Teacher
router.post('/', quizController.createQuiz);
router.get('/class/:classId', quizController.getQuizzesByClass);
router.get('/:quizId/results', quizController.getQuizResults);

// Student
router.get('/student/:studentId', quizController.getStudentQuizzes);
router.get('/:quizId/questions', quizController.getQuizQuestions);
router.post('/:quizId/submit', quizController.submitQuiz);

module.exports = router;
