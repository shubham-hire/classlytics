const db = require('../config/db');

exports.markAttendance = async (req, res) => {
  const { studentId, date, status } = req.body;

  if (!studentId || !status) {
    return res.status(400).json({ error: "studentId and status are required" });
  }

  const attendanceDate = date || new Date().toISOString().split('T')[0];

  try {
    const [result] = await db.execute(
      'INSERT INTO attendance (student_id, date, status) VALUES (?, ?, ?)',
      [studentId, attendanceDate, status]
    );

    res.status(201).json({
      message: "Attendance recorded successfully",
      record: { id: result.insertId, studentId, date: attendanceDate, status }
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getAttendanceByStudent = async (req, res) => {
  const { studentId } = req.params;

  try {
    const [rows] = await db.execute('SELECT date, status FROM attendance WHERE student_id = ?', [studentId]);
    
    let percentage = 0;
    if (rows.length > 0) {
      const presentCount = rows.filter(r => r.status === 'Present').length;
      percentage = Math.round((presentCount / rows.length) * 100);
    }

    res.status(200).json({
      attendance: rows,
      percentage: percentage
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
