const db = require('../config/db');

// GET /teacher/dashboard?teacherId=<id>
exports.getDashboardData = async (req, res) => {
  const { teacherId } = req.query;

  try {
    // 1. Get classes managed by this teacher
    let classQuery = 'SELECT id, name, section FROM classes';
    let classParams = [];
    if (teacherId) {
      classQuery += ' WHERE teacher_id = ?';
      classParams = [teacherId];
    }
    const [classes] = await db.execute(classQuery, classParams);
    const classIds = classes.map(c => c.id);

    // 2. Total students enrolled in teacher's classes
    let totalStudents = 0;
    let avgAttendance = 0;
    let avgMarks = 0;
    let riskStudents = [];
    let recentSubmissions = [];

    if (classIds.length > 0) {
      const placeholders = classIds.map(() => '?').join(',');

      // Total unique students
      const [studentCount] = await db.execute(
        `SELECT COUNT(DISTINCT student_id) AS total FROM class_enrollments WHERE class_id IN (${placeholders})`,
        classIds
      );
      totalStudents = studentCount[0].total;

      // Get all student IDs in these classes
      const [studentIds] = await db.execute(
        `SELECT DISTINCT student_id FROM class_enrollments WHERE class_id IN (${placeholders})`,
        classIds
      );
      const ids = studentIds.map(s => s.student_id);

      if (ids.length > 0) {
        const idPlaceholders = ids.map(() => '?').join(',');

        // Average attendance
        const [attRows] = await db.execute(
          `SELECT COUNT(*) AS total, SUM(CASE WHEN status = 'Present' THEN 1 ELSE 0 END) AS present
           FROM attendance WHERE student_id IN (${idPlaceholders})`,
          ids
        );
        if (attRows[0].total > 0) {
          avgAttendance = Math.round((attRows[0].present / attRows[0].total) * 100);
        }

        // Average marks
        const [marksRows] = await db.execute(
          `SELECT AVG(score) AS avg FROM marks WHERE student_id IN (${idPlaceholders})`,
          ids
        );
        avgMarks = Math.round(marksRows[0].avg || 0);

        // At-risk students
        const [atRiskRows] = await db.execute(
          `SELECT 
            s.id AS student_id, u.name,
            ROUND(100.0 * SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END) / NULLIF(COUNT(a.id), 0), 0) AS attendance_pct,
            ROUND(AVG(m.score), 0) AS avg_marks
           FROM students s
           JOIN users u ON u.id = s.user_id
           LEFT JOIN attendance a ON a.student_id = s.id
           LEFT JOIN marks m ON m.student_id = s.id
           WHERE s.id IN (${idPlaceholders})
           GROUP BY s.id, u.name
           HAVING attendance_pct < 75 OR avg_marks < 50`,
          ids
        );

        riskStudents = atRiskRows.map(r => ({
          id: r.student_id,
          name: r.name,
          risk: (r.attendance_pct < 60 || r.avg_marks < 35) ? 'HIGH' :
                (r.attendance_pct < 75 || r.avg_marks < 50) ? 'MEDIUM' : 'LOW',
          attendancePct: r.attendance_pct,
          avgMarks: r.avg_marks,
        }));

        // Recent submissions
        const [submRows] = await db.execute(
          `SELECT s.id, u.name AS student_name, a.title AS assignment_title, s.submitted_at
           FROM submissions s
           JOIN students st ON st.id = s.student_id
           JOIN users u ON u.id = st.user_id
           JOIN assignments a ON a.id = s.assignment_id
           WHERE st.id IN (${idPlaceholders})
           ORDER BY s.submitted_at DESC
           LIMIT 5`,
          ids
        );
        recentSubmissions = submRows;
      }
    }

    res.status(200).json({
      totalStudents,
      avgAttendance,
      avgMarks,
      riskStudents,
      recentSubmissions,
      classCount: classes.length,
      classes: classes, // List of {id, name, section}
    });
  } catch (err) {
    console.error('[getDashboardData] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// GET /teacher/schedule — returns static schedule (can be DB-backed later)
exports.getSchedule = (req, res) => {
  const schedule = [
    { time: '09:00 AM', subject: 'Mathematics', class: '10-A', room: '101' },
    { time: '11:00 AM', subject: 'Physics', class: '11-B', room: '202' },
    { time: '02:00 PM', subject: 'Chemistry', class: '12-C', room: '301' },
  ];
  res.status(200).json({ schedule });
};

// GET /teacher/profile?teacherId=<id>
exports.getProfile = async (req, res) => {
  const { teacherId } = req.query;

  if (!teacherId) {
    // Fallback static profile if no teacherId provided
    return res.status(200).json({
      id: 'T1001',
      name: 'Rajesh Kumar',
      designation: 'Head of Science Department (HOD)',
      email: 'rajesh.kumar@classlytics.school',
      department: 'Science',
      phone: '+91 9876543210',
      joinDate: '2021-08-15',
      qualifications: 'M.Sc. Physics, B.Ed.',
    });
  }

  try {
    const [rows] = await db.execute(
      `SELECT u.id, u.name, u.email, u.phone, u.dept, u.created_at
       FROM users u
       WHERE u.id = ? AND u.role = 'Teacher'`,
      [teacherId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: 'Teacher not found' });
    }

    const t = rows[0];
    res.status(200).json({
      id: t.id,
      name: t.name,
      email: t.email,
      phone: t.phone || 'N/A',
      department: t.dept || 'General',
      joinDate: t.created_at ? t.created_at.toISOString().split('T')[0] : 'N/A',
    });
  } catch (err) {
    console.error('[getProfile] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// GET /teacher/classes/stats?teacherId=<id>  — per-class stats
exports.getClassStats = async (req, res) => {
  const { teacherId } = req.query;
  try {
    let query = `
      SELECT 
        c.id, c.name, c.section,
        COUNT(DISTINCT ce.student_id) AS student_count,
        COUNT(DISTINCT a.id) AS assignment_count
      FROM classes c
      LEFT JOIN class_enrollments ce ON ce.class_id = c.id
      LEFT JOIN assignments a ON a.class_id = c.id
    `;
    const params = [];
    if (teacherId) {
      query += ' WHERE c.teacher_id = ?';
      params.push(teacherId);
    }
    query += ' GROUP BY c.id, c.name, c.section';

    const [rows] = await db.execute(query, params);
    res.status(200).json(rows);
  } catch (err) {
    console.error('[getClassStats] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};
