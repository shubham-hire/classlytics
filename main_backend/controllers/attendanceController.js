const db = require('../config/db');
const { checkStudentOwnership } = require('../middleware/auth');

// POST /attendance — Mark attendance for a single student
exports.markAttendance = async (req, res) => {
  const { studentId, date, status } = req.body;

  if (!studentId || !status) {
    return res.status(400).json({ error: "studentId and status are required" });
  }

  const attendanceDate = date || new Date().toISOString().split('T')[0];

  try {
    const [result] = await db.execute(
      'INSERT INTO attendance (student_id, date, status) VALUES (?, ?, ?) RETURNING id',
      [studentId, attendanceDate, status]
    );

    res.status(201).json({
      message: "Attendance recorded successfully",
      record: { id: result[0].id, studentId, date: attendanceDate, status }
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// POST /attendance/batch — Mark attendance for multiple students at once
exports.markBatchAttendance = async (req, res) => {
  const { records } = req.body; // [{studentId, status, date?}]

  if (!Array.isArray(records) || records.length === 0) {
    return res.status(400).json({ error: "records array is required" });
  }

  const attendanceDate = new Date().toISOString().split('T')[0];
  let successful = 0;
  let failed = 0;

  try {
    for (const rec of records) {
      if (!rec.studentId || !rec.status) { failed++; continue; }
      try {
        await db.execute(
          'INSERT INTO attendance (student_id, date, status) VALUES (?, ?, ?)',
          [rec.studentId, rec.date || attendanceDate, rec.status]
        );
        successful++;
      } catch (e) {
        console.warn(`[batchAttendance] Failed for ${rec.studentId}: ${e.message}`);
        failed++;
      }
    }

    res.status(201).json({
      message: `Batch attendance recorded: ${successful} success, ${failed} failed`,
      successful,
      failed,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// GET /attendance/:studentId — Fetch attendance history and percentage
exports.getAttendanceByStudent = async (req, res) => {
  const { studentId } = req.params;

  try {
    const hasAccess = await checkStudentOwnership(db, studentId, req.user);
    if (!hasAccess) {
      return res.status(403).json({ error: 'Access denied: You can only view your own attendance' });
    }

    const [rows] = await db.execute(
      'SELECT date, status FROM attendance WHERE student_id = ? ORDER BY date DESC',
      [studentId]
    );
    
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

// GET /attendance/class/:classId — Fetch attendance summary for all students in a class
exports.getClassAttendanceSummary = async (req, res) => {
  const { classId } = req.params;
  const { date } = req.query; // Optional: filter by specific date

  try {
    let query = `
      SELECT 
        s.id AS student_id, u.name, ce.roll_no,
        COUNT(a.id) AS total_days,
        SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END) AS present_days,
        ROUND(100.0 * SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END) / NULLIF(COUNT(a.id), 0), 0) AS percentage
      FROM class_enrollments ce
      JOIN students s ON s.id = ce.student_id
      JOIN users u ON u.id = s.user_id
      LEFT JOIN attendance a ON a.student_id = s.id
    `;
    const params = [classId];
    if (date) {
      query += ' AND a.date = ?';
      params.push(date);
    }
    query += ' WHERE ce.class_id = ? GROUP BY s.id, u.name, ce.roll_no ORDER BY ce.roll_no';
    // Fix param order: classId needs to be last after date
    const finalParams = date ? [classId, date] : [classId];
    const fixedQuery = `
      SELECT 
        s.id AS student_id, u.name, ce.roll_no,
        COUNT(a.id) AS total_days,
        SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END) AS present_days,
        ROUND(100.0 * SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END) / NULLIF(COUNT(a.id), 0), 0) AS percentage
      FROM class_enrollments ce
      JOIN students s ON s.id = ce.student_id
      JOIN users u ON u.id = s.user_id
      LEFT JOIN attendance a ON a.student_id = s.id ${date ? 'AND a.date = ?' : ''}
      WHERE ce.class_id = ?
      GROUP BY s.id, u.name, ce.roll_no
      ORDER BY ce.roll_no
    `;

    const [rows] = await db.execute(fixedQuery, finalParams);
    res.status(200).json({ classId, date: date || 'all', summary: rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
