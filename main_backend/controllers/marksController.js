const db = require('../config/db');

// POST /marks — Add marks for a student
exports.addMarks = async (req, res) => {
  const { studentId, subject, score, type, date, maxScore } = req.body;

  if (!studentId || !subject || score === undefined) {
    return res.status(400).json({ error: "studentId, subject, and score are required" });
  }

  const marksDate = date || new Date().toISOString().split('T')[0];
  const examType = type || 'Quiz';

  try {
    const [result] = await db.execute(
      'INSERT INTO marks (student_id, subject, score, max_score, type, date) VALUES (?, ?, ?, ?, ?, ?) RETURNING id',
      [studentId, subject, score, maxScore || 100, examType, marksDate]
    );

    res.status(201).json({
      message: "Marks added successfully",
      record: { id: result[0].id, studentId, subject, score, type: examType, date: marksDate }
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// GET /marks/:studentId — Get full marks history and average
exports.getMarksByStudent = async (req, res) => {
  const { studentId } = req.params;

  try {
    const [rows] = await db.execute(
      'SELECT subject, score, max_score, date, type FROM marks WHERE student_id = ? ORDER BY date DESC',
      [studentId]
    );
    
    let average = 0;
    if (rows.length > 0) {
      const totalScore = rows.reduce((sum, m) => sum + m.score, 0);
      average = Math.round(totalScore / rows.length);
    }

    res.status(200).json({
      marks: rows,
      average: average
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// GET /marks/:studentId/quiz-results — Get quiz results grouped by subject
exports.getQuizResults = async (req, res) => {
  const { studentId } = req.params;

  try {
    const [rows] = await db.execute(
      `SELECT 
        subject,
        COUNT(*) AS total_quizzes,
        ROUND(AVG(score)::numeric, 1) AS avg_score,
        MAX(score) AS best_score,
        MIN(score) AS lowest_score,
        jsonb_agg(jsonb_build_object('score', score, 'date', date, 'max', max_score)) AS quiz_list
       FROM marks
       WHERE student_id = ? AND type = 'Quiz'
       GROUP BY subject
       ORDER BY avg_score DESC`,
      [studentId]
    );

    // Also fetch the raw quiz records for timeline display
    const [recentQuizzes] = await db.execute(
      `SELECT subject, score, max_score, date, type
       FROM marks
       WHERE student_id = ? AND type = 'Quiz'
       ORDER BY date DESC
       LIMIT 20`,
      [studentId]
    );

    res.status(200).json({
      bySubject: rows,
      recentQuizzes,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// GET /marks/:studentId/subject/:subject — Get marks for a specific subject
exports.getMarksBySubject = async (req, res) => {
  const { studentId, subject } = req.params;

  try {
    const [rows] = await db.execute(
      `SELECT score, max_score, date, type FROM marks
       WHERE student_id = ? AND subject = ?
       ORDER BY date ASC`,
      [studentId, subject]
    );

    const avg = rows.length > 0
      ? Math.round(rows.reduce((s, m) => s + m.score, 0) / rows.length)
      : 0;

    res.status(200).json({ subject, marks: rows, average: avg });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// POST /marks/batch — Add marks for multiple students (for a teacher)
exports.addBatchMarks = async (req, res) => {
  const { records } = req.body; // [{studentId, subject, score, type, date}]

  if (!Array.isArray(records) || records.length === 0) {
    return res.status(400).json({ error: 'records array is required' });
  }

  const marksDate = new Date().toISOString().split('T')[0];
  let successful = 0, failed = 0;

  try {
    for (const rec of records) {
      if (!rec.studentId || !rec.subject || rec.score === undefined) { failed++; continue; }
      try {
        await db.execute(
          'INSERT INTO marks (student_id, subject, score, max_score, type, date) VALUES (?, ?, ?, ?, ?, ?)',
          [rec.studentId, rec.subject, rec.score, rec.maxScore || 100, rec.type || 'Quiz', rec.date || marksDate]
        );
        successful++;
      } catch (e) {
        console.warn(`[batchMarks] Failed for ${rec.studentId}: ${e.message}`);
        failed++;
      }
    }
    res.status(201).json({ message: `Batch marks recorded: ${successful} success, ${failed} failed`, successful, failed });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
