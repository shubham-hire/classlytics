const db = require('../config/db');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const crypto = require('crypto');
const emailService = require('../utils/emailService');

// ─── Helper: Generate sequential student ID ───
async function generateStudentId(connection) {
  await connection.execute("UPDATE global_sequences SET last_value = last_value + 1 WHERE name = 'student'");
  const [seq] = await connection.execute("SELECT last_value FROM global_sequences WHERE name = 'student'");
  return 'STU' + seq[0].last_value.toString().padStart(3, '0');
}

// ─── GET /api/admin/stats ───
exports.getStats = async (req, res) => {
  try {
    const [totalRows] = await db.execute('SELECT COUNT(*) as total FROM users');
    const [roleRows] = await db.execute('SELECT role, COUNT(*) as count FROM users GROUP BY role');
    const [activeRows] = await db.execute('SELECT COUNT(*) as count FROM users WHERE is_active = TRUE OR is_active IS NULL');
    const [inactiveRows] = await db.execute('SELECT COUNT(*) as count FROM users WHERE is_active = FALSE');
    const [classRows] = await db.execute('SELECT COUNT(*) as count FROM classes');

    const byRole = {};
    roleRows.forEach(r => { byRole[r.role] = r.count; });

    res.status(200).json({
      totalUsers: totalRows[0].total,
      byRole,
      activeUsers: activeRows[0].count,
      inactiveUsers: inactiveRows[0].count,
      totalClasses: classRows[0].count,
    });
  } catch (err) {
    console.error('[Admin Stats] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// ─── GET /api/admin/users ───
exports.getUsers = async (req, res) => {
  const { role, search, status, dept, page = 1, limit = 50 } = req.query;
  try {
    let query = `
      SELECT u.id, u.name, u.email, u.role, u.phone, u.dept, u.is_active, u.created_at,
             s.id AS student_id, s.current_year, s.dob, s.roll_no,
             p_link.child_id, p_link.relation
      FROM users u
      LEFT JOIN students s ON s.user_id = u.id
      LEFT JOIN parents p_link ON p_link.user_id = u.id
    `;
    const conditions = [];
    const params = [];

    if (role) { conditions.push(`u.role = $${params.length + 1}`); params.push(role); }
    if (dept) { conditions.push(`u.dept = $${params.length + 1}`); params.push(dept); }
    if (status === 'active') { conditions.push('(u.is_active = TRUE OR u.is_active IS NULL)'); }
    if (status === 'inactive') { conditions.push('u.is_active = FALSE'); }
    if (search) {
      const term = `%${search}%`;
      conditions.push(`(u.name ILIKE $${params.length + 1} OR u.email ILIKE $${params.length + 2} OR u.id ILIKE $${params.length + 3})`);
      params.push(term, term, term);
    }

    if (conditions.length > 0) {
      query += ' WHERE ' + conditions.join(' AND ');
    }

    query += ' ORDER BY u.created_at DESC';

    const offset = (parseInt(page) - 1) * parseInt(limit);
    // For pg shim: append LIMIT/OFFSET as literals (safe: parseInt)
    query += ` LIMIT ${parseInt(limit)} OFFSET ${offset}`;

    const [rows] = await db.execute(query, params);

    // Get total count for pagination
    let countQuery = 'SELECT COUNT(*) as total FROM users u';
    if (conditions.length > 0) {
      countQuery += ' WHERE ' + conditions.join(' AND ');
    }
    const [countRows] = await db.execute(countQuery, params);

    res.status(200).json({
      users: rows,
      total: countRows[0].total,
      page: parseInt(page),
      limit: parseInt(limit),
    });
  } catch (err) {
    console.error('[Admin getUsers] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// ─── GET /api/admin/users/:id ───
exports.getUserById = async (req, res) => {
  const { id } = req.params;
  try {
    // 1. Try finding by User UUID
    let [users] = await db.execute('SELECT * FROM users WHERE id = ?', [id]);

    // 2. If not found, try finding by Student ID (STUxxx)
    if (users.length === 0) {
      [users] = await db.execute(`
        SELECT u.* FROM users u
        JOIN students s ON s.user_id = u.id
        WHERE s.id = ?
      `, [id]);
    }

    if (users.length === 0) return res.status(404).json({ error: 'User not found' });

    const user = users[0];
    let extra = {};

    if (user.role === 'Student') {
      const [studentRows] = await db.execute(`
        SELECT s.*, ce.class_id, c.name as class_name, c.section
        FROM students s
        LEFT JOIN class_enrollments ce ON ce.student_id = s.id
        LEFT JOIN classes c ON c.id = ce.class_id
        WHERE s.user_id = ?
      `, [id]);
      if (studentRows.length > 0) extra = studentRows[0];
    } else if (user.role === 'Parent') {
      const [parentRows] = await db.execute(`
        SELECT p.*, u_child.name as child_name
        FROM parents p
        LEFT JOIN students s ON p.child_id = s.id
        LEFT JOIN users u_child ON s.user_id = u_child.id
        WHERE p.user_id = ?
      `, [id]);
      if (parentRows.length > 0) extra = parentRows[0];
    } else if (user.role === 'Teacher') {
      const [classRows] = await db.execute('SELECT id, name, section FROM classes WHERE teacher_id = ?', [id]);
      extra = { classes: classRows };
    }

    // Remove password from response
    delete user.password;
    res.status(200).json({ ...user, ...extra });
  } catch (err) {
    console.error('[Admin getUserById] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// ─── POST /api/admin/users ───
exports.createUser = async (req, res) => {
  const { name, email, role, phone, address, country, state, district, city, dept,
    // Student-specific
    classId, rollNo, dob, currentYear,
    // Parent-specific
    childId, relation,
    // Teacher-specific (classId reused for assignment)
  } = req.body;

  if (!name || !email || !role) {
    return res.status(400).json({ error: 'name, email, and role are required' });
  }

  if (!['Student', 'Teacher', 'Parent', 'Admin'].includes(role)) {
    return res.status(400).json({ error: 'Invalid role. Must be Student, Teacher, Parent, or Admin' });
  }

  const userId = uuidv4();
  const rawPassword = crypto.randomBytes(4).toString('hex');
  const hashedPassword = await bcrypt.hash(rawPassword, 10);
  let connection;

  try {
    connection = await db.getConnection();
    await connection.beginTransaction();

    // Check duplicate email
    const [existing] = await connection.execute('SELECT id FROM users WHERE email = ?', [email]);
    if (existing.length > 0) {
      await connection.rollback();
      connection.release();
      return res.status(400).json({ error: 'A user with this email already exists' });
    }

    // 1. Insert into users table
    await connection.execute(
      'INSERT INTO users (id, name, email, password, role, phone, address, country, state, district, city, dept, is_active) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, TRUE)',
      // Note: pg shim converts ? → $N automatically
      [userId, name, email, hashedPassword, role, phone || null, address || null, country || null, state || null, district || null, city || null, dept || null]
    );

    let studentId = null;

    // 2. Role-specific inserts
    if (role === 'Student') {
      studentId = await generateStudentId(connection);
      const studentRollNo = rollNo ? parseInt(rollNo) : null;
      await connection.execute(
        'INSERT INTO students (id, user_id, roll_no, dept, current_year, dob) VALUES (?, ?, ?, ?, ?, ?)',
        [studentId, userId, studentRollNo, dept || 'General', currentYear || '1st Year', dob || null]
      );

      // Enroll in class if provided
      if (classId) {
        const nextRoll = studentRollNo || 1;
        await connection.execute(
          'INSERT INTO class_enrollments (class_id, student_id, roll_no) VALUES (?, ?, ?) ON CONFLICT (class_id, student_id) DO UPDATE SET roll_no = EXCLUDED.roll_no',
          [classId, studentId, nextRoll]
        );
      }
    } else if (role === 'Parent') {
      const parentId = userId; // Use same ID for simplicity
      await connection.execute(
        'INSERT INTO parents (id, user_id, name, relation, phone, email, password, child_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        [parentId, userId, name, relation || 'Guardian', phone || null, email, hashedPassword, childId || null]
      );
    }
    // Teacher and Admin only need the users table entry (no extra table)

    await connection.commit();
    connection.release();
    connection = null;

    console.log(`[Admin] Created ${role}: ${email} | Temp Password: ${rawPassword}`);

    // Send welcome email asynchronously
    emailService.sendUserWelcomeEmail({ name, email }, rawPassword, role)
      .catch(err => console.error(`[AUTH] Failed to send welcome email to ${role}:`, err.message));

    res.status(201).json({
      message: `${role} created successfully`,
      userId,
      studentId,
      tempPassword: rawPassword,
    });
  } catch (err) {
    if (connection) {
      await connection.rollback();
      connection.release();
    }
    console.error('[Admin createUser] Error:', err);
    res.status(500).json({ error: err.message });
  }
};

// ─── PUT /api/admin/users/:id ───
exports.updateUser = async (req, res) => {
  const { id } = req.params;
  const { name, email, phone, address, country, state, district, city, dept,
    // Student-specific
    rollNo, dob, currentYear, classId,
    // Parent-specific
    childId, relation } = req.body;

  try {
    const [users] = await db.execute('SELECT * FROM users WHERE id = ?', [id]);
    if (users.length === 0) return res.status(404).json({ error: 'User not found' });

    const user = users[0];

    // Update users table
    await db.execute(
      `UPDATE users SET 
        name = COALESCE(?, name),
        email = COALESCE(?, email),
        phone = COALESCE(?, phone),
        address = COALESCE(?, address),
        country = COALESCE(?, country),
        state = COALESCE(?, state),
        district = COALESCE(?, district),
        city = COALESCE(?, city),
        dept = COALESCE(?, dept)
      WHERE id = ?`,
      [name || null, email || null, phone || null, address || null, country || null,
      state || null, district || null, city || null, dept || null, id]
    );

    // Role-specific updates
    if (user.role === 'Student') {
      const updates = [];
      const params = [];
      if (rollNo !== undefined) { updates.push('roll_no = ?'); params.push(parseInt(rollNo) || null); }
      if (dob !== undefined) { updates.push('dob = ?'); params.push(dob || null); }
      if (currentYear !== undefined) { updates.push('current_year = ?'); params.push(currentYear); }
      if (dept !== undefined) { updates.push('dept = ?'); params.push(dept); }

      if (updates.length > 0) {
        params.push(id);
        await db.execute(`UPDATE students SET ${updates.join(', ')} WHERE user_id = ?`, params);
      }

      // Update class enrollment if classId provided
      if (classId) {
        const [studentRows] = await db.execute('SELECT id FROM students WHERE user_id = ?', [id]);
        if (studentRows.length > 0) {
          const studentId = studentRows[0].id;
          // Remove old enrollments and add new one
          await db.execute('DELETE FROM class_enrollments WHERE student_id = ?', [studentId]);
          await db.execute(
            'INSERT INTO class_enrollments (class_id, student_id, roll_no) VALUES (?, ?, ?)',
            [classId, studentId, parseInt(rollNo) || 1]
          );
        }
      }
    } else if (user.role === 'Parent') {
      const updates = [];
      const params = [];
      if (name) { updates.push('name = ?'); params.push(name); }
      if (relation) { updates.push('relation = ?'); params.push(relation); }
      if (phone) { updates.push('phone = ?'); params.push(phone); }
      if (childId !== undefined) { updates.push('child_id = ?'); params.push(childId || null); }

      if (updates.length > 0) {
        params.push(id);
        await db.execute(`UPDATE parents SET ${updates.join(', ')} WHERE user_id = ?`, params);
      }
    }

    res.status(200).json({ message: 'User updated successfully' });
  } catch (err) {
    console.error('[Admin updateUser] Error:', err);
    res.status(500).json({ error: err.message });
  }
};

// ─── DELETE /api/admin/users/:id ───
exports.deleteUser = async (req, res) => {
  const { id } = req.params;
  try {
    const [users] = await db.execute('SELECT role FROM users WHERE id = ?', [id]);
    if (users.length === 0) return res.status(404).json({ error: 'User not found' });

    // CASCADE will handle related records (students, parents, enrollments, etc.)
    await db.execute('DELETE FROM users WHERE id = ?', [id]);
    res.status(200).json({ message: 'User deleted successfully' });
  } catch (err) {
    console.error('[Admin deleteUser] Error:', err);
    res.status(500).json({ error: err.message });
  }
};

// ─── PATCH /api/admin/users/:id/status ───
exports.toggleUserStatus = async (req, res) => {
  const { id } = req.params;
  const { isActive } = req.body; // true or false

  if (isActive === undefined) {
    return res.status(400).json({ error: 'isActive is required (true/false)' });
  }

  try {
    const [users] = await db.execute('SELECT id FROM users WHERE id = ?', [id]);
    if (users.length === 0) return res.status(404).json({ error: 'User not found' });

    await db.execute('UPDATE users SET is_active = ? WHERE id = ?', [isActive ? true : false, id]);
    res.status(200).json({ message: `User ${isActive ? 'activated' : 'deactivated'} successfully` });
  } catch (err) {
    console.error('[Admin toggleStatus] Error:', err);
    res.status(500).json({ error: err.message });
  }
};

// ─── POST /api/admin/users/bulk ───
exports.bulkCreateUsers = async (req, res) => {
  const { users: userList } = req.body; // Array of { name, email, role, dept, ... }

  if (!Array.isArray(userList) || userList.length === 0) {
    return res.status(400).json({ error: 'users array is required and must not be empty' });
  }

  let connection;
  try {
    connection = await db.getConnection();
    await connection.beginTransaction();

    const created = [];
    const errors = [];

    for (let i = 0; i < userList.length; i++) {
      const u = userList[i];
      try {
        if (!u.name || !u.email || !u.role) {
          errors.push({ row: i + 1, error: 'Missing name, email, or role' });
          continue;
        }

        // Check duplicate
        const [existing] = await connection.execute('SELECT id FROM users WHERE email = ?', [u.email]);
        if (existing.length > 0) {
          errors.push({ row: i + 1, error: `Email ${u.email} already exists` });
          continue;
        }

        const userId = uuidv4();
        const rawPassword = crypto.randomBytes(4).toString('hex');
        const hashedPassword = await bcrypt.hash(rawPassword, 10);

        await connection.execute(
          'INSERT INTO users (id, name, email, password, role, phone, dept, is_active) VALUES (?, ?, ?, ?, ?, ?, ?, TRUE)',
          [userId, u.name, u.email, hashedPassword, u.role, u.phone || null, u.dept || null]
        );

        let studentId = null;
        if (u.role === 'Student') {
          studentId = await generateStudentId(connection);
          await connection.execute(
            'INSERT INTO students (id, user_id, roll_no, dept, current_year) VALUES (?, ?, ?, ?, ?)',
            [studentId, userId, u.rollNo ? parseInt(u.rollNo) : null, u.dept || 'General', u.currentYear || '1st Year']
          );
        }

        created.push({ row: i + 1, userId, studentId, name: u.name, email: u.email, role: u.role, tempPassword: rawPassword });

        // Send welcome email asynchronously
        emailService.sendUserWelcomeEmail({ name: u.name, email: u.email }, rawPassword, u.role)
          .catch(err => console.error(`[AUTH] Failed to send welcome email to ${u.role}:`, err.message));
      } catch (innerErr) {
        errors.push({ row: i + 1, error: innerErr.message });
      }
    }

    await connection.commit();
    connection.release();
    connection = null;

    res.status(201).json({
      message: `Processed ${userList.length} records. Created: ${created.length}, Errors: ${errors.length}`,
      created,
      errors,
    });
  } catch (err) {
    if (connection) {
      await connection.rollback();
      connection.release();
    }
    console.error('[Admin bulkCreate] Error:', err);
    res.status(500).json({ error: err.message });
  }
};

// ─── GET /api/admin/classes ─── (for dropdowns)
exports.getClasses = async (req, res) => {
  try {
    const [rows] = await db.execute(`
      SELECT c.id, c.name, c.section, u.name as teacher_name
      FROM classes c
      LEFT JOIN users u ON c.teacher_id = u.id
    `);
    res.status(200).json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ─── GET /api/admin/students/list ─── (for parent→child linking dropdown)
exports.getStudentsList = async (req, res) => {
  try {
    const [rows] = await db.execute(`
      SELECT s.id, u.name, u.email, s.dept, s.current_year
      FROM students s
      JOIN users u ON s.user_id = u.id
      ORDER BY u.name
    `);
    res.status(200).json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ─── GET /api/admin/visual-analytics ───
exports.getVisualAnalytics = async (req, res) => {
  try {
    // 1. Fee Trends (Monthly Collection - Last 6 Months)
    // Cast to FLOAT to avoid String results in JSON
    const [feeRows] = await db.execute(`
      SELECT 
        TO_CHAR(created_at, 'Mon YYYY') as month,
        SUM(paid_amount)::FLOAT as total
      FROM fees
      WHERE created_at >= NOW() - INTERVAL '6 months'
      GROUP BY TO_CHAR(created_at, 'Mon YYYY'), DATE_TRUNC('month', created_at)
      ORDER BY DATE_TRUNC('month', MIN(created_at)) ASC
    `);

    // 2. Attendance Daily (Last 14 days)
    const [attRows] = await db.execute(`
      SELECT 
        TO_CHAR(date, 'DD Mon') as day,
        ROUND(SUM(CASE WHEN status = 'Present' THEN 1 ELSE 0 END)::FLOAT / COUNT(*) * 100)::FLOAT as pct
      FROM attendance
      WHERE date >= CURRENT_DATE - INTERVAL '14 days'
      GROUP BY TO_CHAR(date, 'DD Mon'), date
      ORDER BY date ASC
    `);

    // 3. Subject Performance (Averages)
    const [marksRows] = await db.execute(`
      SELECT 
        subject,
        ROUND(AVG(score/max_score * 100))::FLOAT as avg
      FROM marks
      GROUP BY subject
      ORDER BY avg DESC
      LIMIT 6
    `);

    // 4. Role Distribution (Pie chart data)
    const [roleRows] = await db.execute('SELECT role, COUNT(*) as count FROM users GROUP BY role');

    res.status(200).json({
      feeTrends: feeRows,
      attendanceDaily: attRows,
      subjectPerformance: marksRows,
      roleDistribution: roleRows
    });
  } catch (err) {
    console.error('[Admin Visual Analytics] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// ─── Department Admin Management ───
exports.createDepartmentAdmin = async (req, res) => {
  const { name, email, department_id } = req.body;
  if (!name || !email || !department_id) {
    return res.status(400).json({ error: 'Name, email, and department_id are required' });
  }

  try {
    const userId = uuidv4();
    const rawPassword = Math.random().toString(36).slice(-8);
    const hashedPassword = await bcrypt.hash(rawPassword, 10);

    const [existing] = await db.execute('SELECT id FROM users WHERE email = ?', [email]);
    if (existing.length > 0) return res.status(400).json({ error: 'Email already exists' });

    await db.execute(
      "INSERT INTO users (id, name, email, password, role, is_active, department_id) VALUES (?, ?, ?, ?, 'DEPARTMENT_ADMIN', TRUE, ?)",
      [userId, name, email, hashedPassword, department_id]
    );

    // 5. Send welcome email (async)
    const [depts] = await db.execute('SELECT name FROM departments WHERE id = ?', [department_id]);
    const departmentName = depts.length > 0 ? depts[0].name : 'N/A';
    emailService.sendDeptAdminWelcomeEmail({ name, email }, rawPassword, departmentName)
      .catch(err => console.error('[AUTH] Failed to send welcome email:', err.message));

    console.log(`[Admin] Dept Admin created: ${email} | Password: ${rawPassword}`);

    res.status(201).json({
      message: 'Department Admin created successfully',
      userId,
      emailSent: true,
      tempPassword: rawPassword
    });
  } catch (err) {
    console.error('[Admin createDepartmentAdmin] Error:', err);
    res.status(500).json({ error: err.message });
  }
};

exports.getDepartmentAdmins = async (req, res) => {
  try {
    const query = `
      SELECT u.id, u.name, u.email, u.department_id, d.name AS department_name
      FROM users u
      LEFT JOIN departments d ON u.department_id = d.id
      WHERE u.role = 'DEPARTMENT_ADMIN'
    `;
    const [rows] = await db.execute(query);
    res.status(200).json({ departmentAdmins: rows });
  } catch (err) {
    console.error('[Admin getDepartmentAdmins] Error:', err);
    res.status(500).json({ error: err.message });
  }
};


exports.deleteDepartmentAdmin = async (req, res) => {
  const { id } = req.params;
  try {
    await db.execute("DELETE FROM users WHERE id = ? AND role = 'DEPARTMENT_ADMIN'", [id]);
    res.status(200).json({ message: 'Department Admin deleted successfully' });
  } catch (err) {
    console.error('[Admin deleteDepartmentAdmin] Error:', err);
    res.status(500).json({ error: err.message });
  }
};

// ─── FEE STRUCTURES (Category-Based) ───
exports.createFeeStructure = async (req, res) => {
  const { department_id, year, category, amount } = req.body;

  if (!department_id || !year || !category || amount === undefined) {
    return res.status(400).json({ error: 'department_id, year, category, amount are required' });
  }

  try {
    const [existing] = await db.execute(
      'SELECT id FROM category_fee_structures WHERE department_id = ? AND year = ? AND category = ?',
      [department_id, year, category]
    );

    if (existing.length > 0) {
      return res.status(400).json({ error: 'Fee structure for this combination already exists' });
    }

    const [result] = await db.execute(
      'INSERT INTO category_fee_structures (department_id, year, category, amount) VALUES (?, ?, ?, ?) RETURNING id',
      [department_id, year, category, amount]
    );

    res.status(201).json({ message: 'Fee structure created successfully', id: result[0].id });
  } catch (err) {
    console.error('[Admin createFeeStructure] Error:', err);
    res.status(500).json({ error: err.message });
  }
};

exports.getFeeStructures = async (req, res) => {
  try {
    const [rows] = await db.execute(`
      SELECT f.*, d.name as department_name 
      FROM category_fee_structures f
      LEFT JOIN departments d ON f.department_id = d.id
      ORDER BY f.created_at DESC
    `);
    res.status(200).json({ feeStructures: rows });
  } catch (err) {
    console.error('[Admin getFeeStructures] Error:', err);
    res.status(500).json({ error: err.message });
  }
};
