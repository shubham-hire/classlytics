const db = require('../config/db');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

// ─── Helper: Verify Department Admin owns the department ──────────────────
async function verifyDeptOwnership(req, res, department_id) {
  // ADMIN can manage any department
  if (req.user.role === 'ADMIN' || req.user.role === 'Admin') return true;

  const [admin] = await db.execute(
    'SELECT department_id FROM users WHERE id = ?',
    [req.user.id]
  );
  if (admin.length === 0 || admin[0].department_id != department_id) {
    res.status(403).json({ error: 'Access denied: You can only manage your own department.' });
    return false;
  }
  return true;
}

// ─── Helper: Get admin's own department_id ────────────────────────────────
async function getAdminDeptId(userId) {
  const [rows] = await db.execute('SELECT department_id FROM users WHERE id = ?', [userId]);
  return rows.length > 0 ? rows[0].department_id : null;
}

// ─── GET /dept-admin/profile ──────────────────────────────────────────────
exports.getProfile = async (req, res) => {
  try {
    const [rows] = await db.execute(`
      SELECT u.id, u.name, u.email, u.role,
             d.id AS department_id, d.name AS department_name
      FROM users u
      LEFT JOIN departments d ON u.department_id = d.id
      WHERE u.id = ? AND u.role = 'DEPARTMENT_ADMIN'
    `, [req.user.id]);

    if (rows.length === 0) return res.status(404).json({ error: 'Profile not found' });

    const user = rows[0];
    res.status(200).json({
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      department: {
        id: user.department_id,
        name: user.department_name
      }
    });
  } catch (err) {
    console.error('[DEPT_ADMIN getProfile] Error:', err);
    res.status(500).json({ error: err.message });
  }
};


// ===========================================================================
// DEPARTMENT MANAGEMENT
// ===========================================================================

// POST /dept-admin/department
exports.createDepartment = async (req, res) => {
  const { name } = req.body;
  if (!name) return res.status(400).json({ error: 'Department name is required' });

  try {
    const [result] = await db.execute('INSERT INTO departments (name) VALUES (?)', [name]);
    res.status(201).json({ message: 'Department created', id: result.insertId, name });
  } catch (err) {
    console.error('[DEPT_ADMIN createDepartment] Error:', err);
    res.status(500).json({ error: err.message });
  }
};

// GET /dept-admin/department
exports.getDepartments = async (req, res) => {
  try {
    // DEPARTMENT_ADMIN only sees their own department
    if (req.user.role === 'DEPARTMENT_ADMIN') {
      const deptId = await getAdminDeptId(req.user.id);
      const [rows] = await db.execute('SELECT * FROM departments WHERE id = ?', [deptId]);
      return res.status(200).json(rows);
    }
    const [rows] = await db.execute('SELECT * FROM departments ORDER BY name');
    res.status(200).json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ===========================================================================
// CLASS MANAGEMENT
// ===========================================================================

// POST /dept-admin/class
exports.createClass = async (req, res) => {
  const { name, section, teacher_id } = req.body;
  if (!name || !section) return res.status(400).json({ error: 'name and section are required' });

  try {
    let department_id = req.body.department_id;

    if (req.user.role === 'DEPARTMENT_ADMIN') {
      department_id = await getAdminDeptId(req.user.id);
      if (!department_id) return res.status(403).json({ error: 'Admin has no assigned department' });
    }

    if (!department_id) return res.status(400).json({ error: 'department_id is required' });

    const classId = uuidv4();
    await db.execute(
      'INSERT INTO classes (id, name, section, teacher_id, department_id) VALUES (?, ?, ?, ?, ?)',
      [classId, name, section, teacher_id || null, department_id]
    );
    res.status(201).json({ message: 'Class created', classId, name, section, department_id });
  } catch (err) {
    console.error('[DEPT_ADMIN createClass] Error:', err);
    res.status(500).json({ error: err.message });
  }
};

// GET /dept-admin/department/:id/classes
exports.getClassesByDepartment = async (req, res) => {
  const { id } = req.params;
  try {
    if (!(await verifyDeptOwnership(req, res, id))) return;

    const [rows] = await db.execute(`
      SELECT c.*, u.name AS teacher_name,
             (SELECT COUNT(*) FROM divisions d WHERE d.class_id = c.id) AS division_count
      FROM classes c
      LEFT JOIN users u ON c.teacher_id = u.id
      WHERE c.department_id = ?
      ORDER BY c.name
    `, [id]);
    res.status(200).json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ===========================================================================
// DIVISION MANAGEMENT
// ===========================================================================

// POST /dept-admin/division
exports.createDivision = async (req, res) => {
  const { class_id, division_name } = req.body;
  if (!class_id || !division_name) {
    return res.status(400).json({ error: 'class_id and division_name are required' });
  }

  try {
    // Verify the class belongs to admin's department
    const [classes] = await db.execute('SELECT department_id FROM classes WHERE id = ?', [class_id]);
    if (classes.length === 0) return res.status(404).json({ error: 'Class not found' });

    if (!(await verifyDeptOwnership(req, res, classes[0].department_id))) return;

    const [result] = await db.execute(
      'INSERT INTO divisions (class_id, division_name) VALUES (?, ?)',
      [class_id, division_name]
    );
    res.status(201).json({ message: 'Division created', id: result.insertId, class_id, division_name });
  } catch (err) {
    console.error('[DEPT_ADMIN createDivision] Error:', err);
    res.status(500).json({ error: err.message });
  }
};

// GET /dept-admin/class/:id/divisions
exports.getDivisionsByClass = async (req, res) => {
  const { id } = req.params;
  try {
    const [classes] = await db.execute('SELECT department_id FROM classes WHERE id = ?', [id]);
    if (classes.length === 0) return res.status(404).json({ error: 'Class not found' });

    if (!(await verifyDeptOwnership(req, res, classes[0].department_id))) return;

    const [rows] = await db.execute(`
      SELECT d.*,
             (SELECT COUNT(*) FROM students s WHERE s.division_id = d.id) AS student_count
      FROM divisions d
      WHERE d.class_id = ?
      ORDER BY d.division_name
    `, [id]);
    res.status(200).json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ===========================================================================
// STUDENT MANAGEMENT
// ===========================================================================

// POST /dept-admin/student
exports.addStudent = async (req, res) => {
  const { name, email, division_id, roll_no, dob, current_year } = req.body;
  if (!name || !email || !division_id) {
    return res.status(400).json({ error: 'name, email, and division_id are required' });
  }

  try {
    // Verify division's class belongs to admin's department
    const [divRows] = await db.execute(
      'SELECT d.id, c.department_id FROM divisions d JOIN classes c ON d.class_id = c.id WHERE d.id = ?',
      [division_id]
    );
    if (divRows.length === 0) return res.status(404).json({ error: 'Division not found' });

    if (!(await verifyDeptOwnership(req, res, divRows[0].department_id))) return;

    // Check duplicate email
    const [existing] = await db.execute('SELECT id FROM users WHERE email = ?', [email]);
    if (existing.length > 0) return res.status(400).json({ error: 'Email already registered' });

    let connection;
    try {
      connection = await db.getConnection();
      await connection.beginTransaction();

      // Get dept name for student record
      const [deptRows] = await connection.execute(
        'SELECT d.name FROM departments d JOIN classes c ON c.department_id = d.id JOIN divisions div ON div.class_id = c.id WHERE div.id = ?',
        [division_id]
      );
      const deptName = deptRows.length > 0 ? deptRows[0].name : 'General';

      // Generate student sequence ID
      await connection.execute('UPDATE global_sequences SET `last_value` = `last_value` + 1 WHERE name = "student"');
      const [seq] = await connection.execute('SELECT `last_value` FROM global_sequences WHERE name = "student"');
      const studentId = 'STU' + seq[0].last_value.toString().padStart(3, '0');

      const userId = uuidv4();
      const rawPassword = require('crypto').randomBytes(4).toString('hex');
      const hashedPassword = await bcrypt.hash(rawPassword, 10);

      await connection.execute(
        'INSERT INTO users (id, name, email, password, role, is_active) VALUES (?, ?, ?, ?, "Student", 1)',
        [userId, name, email, hashedPassword]
      );

      await connection.execute(
        'INSERT INTO students (id, user_id, roll_no, dept, current_year, dob, division_id) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [studentId, userId, roll_no || null, deptName, current_year || '1st Year', dob || null, division_id]
      );

      await connection.commit();
      connection.release();

      res.status(201).json({
        message: 'Student added successfully',
        studentId, userId,
        tempPassword: rawPassword,
      });
    } catch (innerErr) {
      if (connection) { await connection.rollback(); connection.release(); }
      throw innerErr;
    }
  } catch (err) {
    console.error('[DEPT_ADMIN addStudent] Error:', err);
    res.status(500).json({ error: err.message });
  }
};

// GET /dept-admin/division/:id/students
exports.getStudentsByDivision = async (req, res) => {
  const { id } = req.params;
  try {
    const [divRows] = await db.execute(
      'SELECT d.id, c.department_id FROM divisions d JOIN classes c ON d.class_id = c.id WHERE d.id = ?',
      [id]
    );
    if (divRows.length === 0) return res.status(404).json({ error: 'Division not found' });

    if (!(await verifyDeptOwnership(req, res, divRows[0].department_id))) return;

    const [rows] = await db.execute(`
      SELECT s.id AS student_id, u.name, u.email, u.phone, s.roll_no, s.dob, s.current_year, s.dept
      FROM students s
      JOIN users u ON s.user_id = u.id
      WHERE s.division_id = ?
      ORDER BY s.roll_no, u.name
    `, [id]);
    res.status(200).json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ===========================================================================
// TIMETABLE MANAGEMENT
// ===========================================================================

// POST /dept-admin/timetable — with time conflict validation
exports.createTimetableEntry = async (req, res) => {
  const { class_id, division_id, subject, teacher_id, day_of_week, start_time, end_time } = req.body;
  if (!class_id || !subject || !day_of_week || !start_time || !end_time) {
    return res.status(400).json({ error: 'class_id, subject, day_of_week, start_time, end_time are required' });
  }

  try {
    const [classes] = await db.execute('SELECT department_id FROM classes WHERE id = ?', [class_id]);
    if (classes.length === 0) return res.status(404).json({ error: 'Class not found' });

    if (!(await verifyDeptOwnership(req, res, classes[0].department_id))) return;

    // Conflict check: same class + division + day, overlapping time
    const [conflicts] = await db.execute(`
      SELECT id FROM timetable
      WHERE class_id = ?
        AND (division_id = ? OR (division_id IS NULL AND ? IS NULL))
        AND day_of_week = ?
        AND NOT (end_time <= ? OR start_time >= ?)
    `, [class_id, division_id || null, division_id || null, day_of_week, start_time, end_time]);

    if (conflicts.length > 0) {
      return res.status(409).json({ error: 'Time conflict detected: Another entry overlaps with the given time slot.' });
    }

    // Conflict check: same teacher + day + overlapping time
    if (teacher_id) {
      const [teacherConflicts] = await db.execute(`
        SELECT id FROM timetable
        WHERE teacher_id = ?
          AND day_of_week = ?
          AND NOT (end_time <= ? OR start_time >= ?)
      `, [teacher_id, day_of_week, start_time, end_time]);

      if (teacherConflicts.length > 0) {
        return res.status(409).json({ error: 'Teacher time conflict: This teacher already has a class in this time slot.' });
      }
    }

    const [result] = await db.execute(
      'INSERT INTO timetable (class_id, division_id, subject, teacher_id, day_of_week, start_time, end_time) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [class_id, division_id || null, subject, teacher_id || null, day_of_week, start_time, end_time]
    );

    res.status(201).json({ message: 'Timetable entry created', id: result.insertId });
  } catch (err) {
    console.error('[DEPT_ADMIN createTimetableEntry] Error:', err);
    res.status(500).json({ error: err.message });
  }
};

// GET /dept-admin/timetable/:classId/:divisionId
exports.getTimetable = async (req, res) => {
  const { classId, divisionId } = req.params;
  try {
    const [classes] = await db.execute('SELECT department_id FROM classes WHERE id = ?', [classId]);
    if (classes.length === 0) return res.status(404).json({ error: 'Class not found' });

    if (!(await verifyDeptOwnership(req, res, classes[0].department_id))) return;

    const divisionFilter = divisionId && divisionId !== 'null' ? divisionId : null;

    let query = `
      SELECT t.*, u.name AS teacher_name
      FROM timetable t
      LEFT JOIN users u ON t.teacher_id = u.id
      WHERE t.class_id = ?
    `;
    const params = [classId];

    if (divisionFilter) {
      query += ' AND t.division_id = ?';
      params.push(divisionFilter);
    }

    query += ' ORDER BY FIELD(day_of_week,"Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"), t.start_time';

    const [rows] = await db.execute(query, params);
    res.status(200).json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// DELETE /dept-admin/timetable/:id
exports.deleteTimetableEntry = async (req, res) => {
  const { id } = req.params;
  try {
    const [rows] = await db.execute(
      'SELECT t.id, c.department_id FROM timetable t JOIN classes c ON t.class_id = c.id WHERE t.id = ?',
      [id]
    );
    if (rows.length === 0) return res.status(404).json({ error: 'Timetable entry not found' });

    if (!(await verifyDeptOwnership(req, res, rows[0].department_id))) return;

    await db.execute('DELETE FROM timetable WHERE id = ?', [id]);
    res.status(200).json({ message: 'Timetable entry deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
