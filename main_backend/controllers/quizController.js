const db = require('../config/db');
const { v4: uuidv4 } = require('uuid');

// ─── TEACHER ACTIONS ─────────────────────────────────────────────────────────

// POST /quizzes — Create quiz with questions
exports.createQuiz = async (req, res) => {
  const { classId, teacherId, title, description, durationMinutes, questions } = req.body;

  if (!classId || !title || !questions || !Array.isArray(questions) || questions.length === 0) {
    return res.status(400).json({ error: 'classId, title, and at least one question are required.' });
  }

  const quizId = uuidv4();
  const conn = await db.getConnection();
  try {
    await conn.beginTransaction();

    await conn.execute(
      'INSERT INTO quizzes (id, class_id, teacher_id, title, description, duration_minutes) VALUES (?, ?, ?, ?, ?, ?)',
      [quizId, classId, teacherId || null, title, description || '', durationMinutes || 30]
    );

    for (const q of questions) {
      if (!q.question || !q.optionA || !q.optionB || !q.optionC || !q.optionD || !q.correctOption) {
        throw new Error('Each question must have question text, 4 options, and the correct option.');
      }
      await conn.execute(
        'INSERT INTO quiz_questions (id, quiz_id, question, option_a, option_b, option_c, option_d, correct_option, marks) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [uuidv4(), quizId, q.question, q.optionA, q.optionB, q.optionC, q.optionD, q.correctOption.toUpperCase(), q.marks || 1]
      );
    }

    await conn.commit();
    console.log(`[QUIZ] Created "${title}" for class ${classId} with ${questions.length} questions`);
    res.status(201).json({ message: 'Quiz created successfully', quizId, title, questionCount: questions.length });
  } catch (err) {
    await conn.rollback();
    console.error('[createQuiz] Error:', err.message);
    res.status(500).json({ error: err.message });
  } finally {
    conn.release();
  }
};

// GET /quizzes/class/:classId — Get all quizzes for a class (for teacher/student listing)
exports.getQuizzesByClass = async (req, res) => {
  const { classId } = req.params;
  try {
    const [quizzes] = await db.execute(
      `SELECT q.id, q.title, q.description, q.duration_minutes, q.created_at,
              u.name AS teacher_name,
              COUNT(DISTINCT qq.id) AS question_count
       FROM quizzes q
       LEFT JOIN users u ON u.id = q.teacher_id
       LEFT JOIN quiz_questions qq ON qq.quiz_id = q.id
       WHERE q.class_id = ?
       GROUP BY q.id, q.title, q.description, q.duration_minutes, q.created_at, u.name
       ORDER BY q.created_at DESC`,
      [classId]
    );
    res.status(200).json({ quizzes });
  } catch (err) {
    console.error('[getQuizzesByClass] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// GET /quizzes/student/:studentId — Get quizzes for all classes a student is enrolled in
exports.getStudentQuizzes = async (req, res) => {
  const { studentId } = req.params;
  try {
    const [quizzes] = await db.execute(
      `SELECT q.id, q.title, q.description, q.duration_minutes, q.created_at,
              c.name AS class_name, u.name AS teacher_name,
              COUNT(DISTINCT qq.id) AS question_count,
              qs.score, qs.total_marks, qs.submitted_at AS completed_at
       FROM class_enrollments ce
       JOIN quizzes q ON q.class_id = ce.class_id
       JOIN classes c ON c.id = q.class_id
       LEFT JOIN users u ON u.id = q.teacher_id
       LEFT JOIN quiz_questions qq ON qq.quiz_id = q.id
       LEFT JOIN quiz_submissions qs ON qs.quiz_id = q.id AND qs.student_id = ?
       WHERE ce.student_id = ?
       GROUP BY q.id, q.title, q.description, q.duration_minutes, q.created_at, c.name, u.name, qs.id, qs.score, qs.total_marks, qs.submitted_at
       ORDER BY q.created_at DESC`,
      [studentId, studentId]
    );
    res.status(200).json({ quizzes });
  } catch (err) {
    console.error('[getStudentQuizzes] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// GET /quizzes/:quizId/questions — Get questions for a quiz (WITHOUT correct answers for students)
exports.getQuizQuestions = async (req, res) => {
  const { quizId } = req.params;
  const { role } = req.query; // 'teacher' gets correct_option too

  try {
    const [quiz] = await db.execute('SELECT * FROM quizzes WHERE id = ?', [quizId]);
    if (quiz.length === 0) return res.status(404).json({ error: 'Quiz not found.' });

    const cols = role === 'teacher'
      ? 'id, question, option_a, option_b, option_c, option_d, correct_option, marks'
      : 'id, question, option_a, option_b, option_c, option_d, marks';

    const [questions] = await db.execute(
      `SELECT ${cols} FROM quiz_questions WHERE quiz_id = ?`,
      [quizId]
    );

    res.status(200).json({
      quiz: quiz[0],
      questions,
    });
  } catch (err) {
    console.error('[getQuizQuestions] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// POST /quizzes/:quizId/submit — Student submits answers; auto-graded
exports.submitQuiz = async (req, res) => {
  const { quizId } = req.params;
  const { studentId, answers, timeTakenSeconds } = req.body;
  // answers: { questionId: 'A'|'B'|'C'|'D', ... }

  if (!studentId || !answers) {
    return res.status(400).json({ error: 'studentId and answers are required.' });
  }

  try {
    // Check already submitted
    const [existing] = await db.execute(
      'SELECT id FROM quiz_submissions WHERE quiz_id = ? AND student_id = ?',
      [quizId, studentId]
    );
    if (existing.length > 0) {
      return res.status(409).json({ error: 'Quiz already submitted.' });
    }

    // Fetch correct answers
    const [questions] = await db.execute(
      'SELECT id, correct_option, marks FROM quiz_questions WHERE quiz_id = ?',
      [quizId]
    );
    if (questions.length === 0) {
      return res.status(400).json({ error: 'Quiz has no questions.' });
    }

    let score = 0;
    let totalMarks = 0;
    const resultBreakdown = {};

    for (const q of questions) {
      totalMarks += q.marks;
      const studentAnswer = answers[q.id];
      const isCorrect = studentAnswer && studentAnswer.toUpperCase() === q.correct_option;
      if (isCorrect) score += q.marks;
      resultBreakdown[q.id] = {
        studentAnswer: studentAnswer || null,
        correctAnswer: q.correct_option,
        correct: isCorrect,
        marks: q.marks,
      };
    }

    const submissionId = uuidv4();
    await db.execute(
      'INSERT INTO quiz_submissions (id, quiz_id, student_id, score, total_marks, time_taken_seconds, answers) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [submissionId, quizId, studentId, score, totalMarks, timeTakenSeconds || null, JSON.stringify(answers)]
    );

    console.log(`[QUIZ] ${studentId} scored ${score}/${totalMarks} on quiz ${quizId}`);
    res.status(201).json({
      message: 'Quiz submitted successfully',
      score,
      totalMarks,
      percentage: Math.round((score / totalMarks) * 100),
      resultBreakdown,
    });
  } catch (err) {
    console.error('[submitQuiz] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// GET /quizzes/:quizId/results — Teacher view of all results
exports.getQuizResults = async (req, res) => {
  const { quizId } = req.params;
  try {
    const [results] = await db.execute(
      `SELECT qs.id, qs.student_id, u.name AS student_name,
              qs.score, qs.total_marks, qs.time_taken_seconds, qs.submitted_at
       FROM quiz_submissions qs
       JOIN students s ON s.id = qs.student_id
       JOIN users u ON u.id = s.user_id
       WHERE qs.quiz_id = ?
       ORDER BY qs.score DESC`,
      [quizId]
    );
    res.status(200).json({ results });
  } catch (err) {
    console.error('[getQuizResults] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};
