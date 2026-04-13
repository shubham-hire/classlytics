const db = require('../config/db');

exports.addMarks = async (req, res) => {
  const { studentId, subject, score, type, date } = req.body;

  if (!studentId || !subject || score === undefined) {
    return res.status(400).json({ error: "studentId, subject, and score are required" });
  }

  const marksDate = date || new Date().toISOString().split('T')[0];
  const examType = type || 'Quiz';

  try {
    const [result] = await db.execute(
      'INSERT INTO marks (student_id, subject, score, max_score, type, date) VALUES (?, ?, ?, ?, ?, ?)',
      [studentId, subject, score, 100, examType, marksDate]
    );

    res.status(201).json({
      message: "Marks added successfully",
      record: { id: result.insertId, studentId, subject, score, type: examType, date: marksDate }
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getMarksByStudent = async (req, res) => {
  const { studentId } = req.params;

  try {
    const [rows] = await db.execute('SELECT subject, score, date, type FROM marks WHERE student_id = ?', [studentId]);
    
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
