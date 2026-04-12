const { markRecords } = require('../data/storage');

exports.addMarks = (req, res) => {
  const { studentId, subject, score, date } = req.body;

  // 1. Validation
  if (!studentId) {
    return res.status(400).json({ error: "studentId is required" });
  }

  if (!subject) {
    return res.status(400).json({ error: "subject is required" });
  }

  const numericScore = Number(score);
  if (isNaN(numericScore) || numericScore < 0 || numericScore > 100) {
    return res.status(400).json({ error: "Score must be a number between 0 and 100" });
  }

  // 2. Data processing
  const record = {
    studentId,
    subject,
    score: numericScore,
    date: date || new Date().toISOString().split('T')[0],
    timestamp: new Date()
  };

  markRecords.push(record);
  console.log(`[MARKS] Added for ${studentId}: ${score} in ${subject}`);

  // 3. Success Response
  res.status(201).json({
    message: "Marks added successfully",
    record: record
  });
};

exports.getMarksByStudent = (req, res) => {
  const { studentId } = req.params;
  const studentMarks = markRecords.filter(m => m.studentId === studentId);
  
  let average = 0;
  if (studentMarks.length > 0) {
    const totalScore = studentMarks.reduce((sum, m) => sum + m.score, 0);
    average = Math.round(totalScore / studentMarks.length);
  }

  res.status(200).json({
    marks: studentMarks.map(m => ({
      subject: m.subject,
      score: m.score,
      date: m.date
    })),
    average: average
  });
};
