const db = require('../config/db');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const emailService = require('../utils/emailService');

// Helper: Generate sequential teacher ID
async function generateTeacherId(connection) {
  await connection.execute('UPDATE global_sequences SET `last_value` = `last_value` + 1 WHERE name = "teacher"');
  const [seq] = await connection.execute('SELECT `last_value` FROM global_sequences WHERE name = "teacher"');
  return 'TCH' + seq[0].last_value.toString().padStart(3, '0');
}

// ─── POST /api/admin/teachers ───
exports.createTeacher = async (req, res) => {
  const {
    // User fields
    name, email, phone, address, country, state, district, city,
    // Teacher fields
    department, designation, joining_date, employment_type,
    qualification, specialization, experience_years, previous_school,
    gender, dob, salary_structure_id,
    bank_account_no, bank_ifsc, emergency_contact,
    is_active
  } = req.body;

  if (!name || !email || !designation) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  let connection;
  try {
    connection = await db.getConnection();
    await connection.beginTransaction();

    // Check if email exists
    const [existingUsers] = await connection.execute('SELECT id FROM users WHERE email = ?', [email]);
    if (existingUsers.length > 0) {
      await connection.rollback();
      return res.status(400).json({ error: 'Email already exists' });
    }

    const userId = uuidv4();
    // Auto-generate password
    const rawPassword = Math.random().toString(36).slice(-8);
    const hashedPassword = await bcrypt.hash(rawPassword, 10);
    const active = is_active !== undefined ? is_active : true;

    // 1. Insert into users table
    await connection.execute(`
      INSERT INTO users (id, name, email, password, role, phone, address, country, state, district, city, is_active)
      VALUES (?, ?, ?, ?, 'Teacher', ?, ?, ?, ?, ?, ?, ?)
    `, [userId, name, email, hashedPassword, phone || null, address || null, country || null, state || null, district || null, city || null, active]);

    // 2. Generate teacher ID
    const teacherId = await generateTeacherId(connection);

    // Generate auto employee_id: EMP + teacher sequence number
    const autoEmployeeId = teacherId.replace('TCH', 'EMP');
    
    const profileImg = req.file ? req.file.filename : null;

    // 4. Insert into teachers table
    await connection.execute(`
      INSERT INTO teachers (
        id, user_id, employee_id, department, designation, joining_date, employment_type,
        qualification, specialization, experience_years, previous_school,
        gender, dob, profile_img, salary_structure_id,
        bank_account_no, bank_ifsc, emergency_contact
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `, [
      teacherId, userId, autoEmployeeId, department || null, designation, joining_date || null, employment_type || 'Full-time',
      qualification || null, specialization || null, experience_years || 0, previous_school || null,
      gender || null, dob || null, profileImg, salary_structure_id || null,
      bank_account_no || null, bank_ifsc || null, emergency_contact || null
    ]);

    await connection.commit();
    
    // 5. Send welcome email with credentials (async, don't block response but log error)
    emailService.sendTeacherWelcomeEmail({ name, email }, rawPassword).catch(err => {
      console.error('[EMAIL] Background teacher welcome email failed:', err.message);
    });

    res.status(201).json({ 
      message: 'Teacher created successfully and credentials sent via email', 
      teacher_id: teacherId, 
      user_id: userId 
    });
  } catch (err) {
    if (connection) await connection.rollback();
    console.error('[createTeacher] Error:', err.message);
    res.status(500).json({ error: err.message });
  } finally {
    if (connection) connection.release();
  }
};

// ─── GET /api/admin/teachers ───
exports.getTeachers = async (req, res) => {
  try {
    const [rows] = await db.execute(`
      SELECT t.*, u.name, u.email, u.phone, u.is_active
      FROM teachers t
      INNER JOIN users u ON t.user_id = u.id
      ORDER BY t.created_at DESC
    `);
    res.status(200).json(rows);
  } catch (err) {
    console.error('[getTeachers] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// ─── GET /api/admin/teachers/:id ───
exports.getTeacherById = async (req, res) => {
  const { id } = req.params;
  try {
    const [rows] = await db.execute(`
      SELECT t.*, u.name, u.email, u.phone, u.is_active, u.address, u.city, u.state, u.country
      FROM teachers t
      INNER JOIN users u ON t.user_id = u.id
      WHERE t.id = ?
    `, [id]);
    
    if (rows.length === 0) return res.status(404).json({ error: 'Teacher not found' });
    res.status(200).json(rows[0]);
  } catch (err) {
    console.error('[getTeacherById] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// ─── PUT /api/admin/teachers/:id ───
exports.updateTeacher = async (req, res) => {
  const { id } = req.params;
  const {
    name, phone, address, country, state, district, city,
    department, designation, joining_date, employment_type,
    qualification, specialization, experience_years, previous_school,
    gender, dob, salary_structure_id,
    bank_account_no, bank_ifsc, emergency_contact,
    is_active
  } = req.body;

  let connection;
  try {
    connection = await db.getConnection();
    await connection.beginTransaction();

    const [teacherRows] = await connection.execute('SELECT user_id FROM teachers WHERE id = ?', [id]);
    if (teacherRows.length === 0) {
      await connection.rollback();
      return res.status(404).json({ error: 'Teacher not found' });
    }
    const userId = teacherRows[0].user_id;


    // Update Users Table
    const updateUsers = [];
    const userParams = [];
    if (name !== undefined) { updateUsers.push('name = ?'); userParams.push(name); }
    if (phone !== undefined) { updateUsers.push('phone = ?'); userParams.push(phone || null); }
    if (address !== undefined) { updateUsers.push('address = ?'); userParams.push(address || null); }
    if (city !== undefined) { updateUsers.push('city = ?'); userParams.push(city || null); }
    if (state !== undefined) { updateUsers.push('state = ?'); userParams.push(state || null); }
    if (country !== undefined) { updateUsers.push('country = ?'); userParams.push(country || null); }
    if (district !== undefined) { updateUsers.push('district = ?'); userParams.push(district || null); }
    if (is_active !== undefined) { updateUsers.push('is_active = ?'); userParams.push(is_active); }

    if (updateUsers.length > 0) {
      userParams.push(userId);
      await connection.execute(`UPDATE users SET ${updateUsers.join(', ')} WHERE id = ?`, userParams);
    }

    // Update Teachers Table
    const updateTeachers = [];
    const teacherParams = [];
    
    if (department !== undefined) { updateTeachers.push('department = ?'); teacherParams.push(department || null); }
    if (designation !== undefined) { updateTeachers.push('designation = ?'); teacherParams.push(designation); }
    if (joining_date !== undefined) { updateTeachers.push('joining_date = ?'); teacherParams.push(joining_date || null); }
    if (employment_type !== undefined) { updateTeachers.push('employment_type = ?'); teacherParams.push(employment_type); }
    if (qualification !== undefined) { updateTeachers.push('qualification = ?'); teacherParams.push(qualification || null); }
    if (specialization !== undefined) { updateTeachers.push('specialization = ?'); teacherParams.push(specialization || null); }
    if (experience_years !== undefined) { updateTeachers.push('experience_years = ?'); teacherParams.push(experience_years || 0); }
    if (previous_school !== undefined) { updateTeachers.push('previous_school = ?'); teacherParams.push(previous_school || null); }
    if (gender !== undefined) { updateTeachers.push('gender = ?'); teacherParams.push(gender || null); }
    if (dob !== undefined) { updateTeachers.push('dob = ?'); teacherParams.push(dob || null); }
    if (salary_structure_id !== undefined) { updateTeachers.push('salary_structure_id = ?'); teacherParams.push(salary_structure_id || null); }
    if (bank_account_no !== undefined) { updateTeachers.push('bank_account_no = ?'); teacherParams.push(bank_account_no || null); }
    if (bank_ifsc !== undefined) { updateTeachers.push('bank_ifsc = ?'); teacherParams.push(bank_ifsc || null); }
    if (emergency_contact !== undefined) { updateTeachers.push('emergency_contact = ?'); teacherParams.push(emergency_contact || null); }

    if (req.file) {
      updateTeachers.push('profile_img = ?');
      teacherParams.push(req.file.filename);
    }

    if (updateTeachers.length > 0) {
      teacherParams.push(id);
      await connection.execute(`UPDATE teachers SET ${updateTeachers.join(', ')} WHERE id = ?`, teacherParams);
    }

    await connection.commit();
    res.status(200).json({ message: 'Teacher updated successfully' });
  } catch (err) {
    if (connection) await connection.rollback();
    console.error('[updateTeacher] Error:', err.message);
    res.status(500).json({ error: err.message });
  } finally {
    if (connection) connection.release();
  }
};

// ─── DELETE /api/admin/teachers/:id ───
exports.deleteTeacher = async (req, res) => {
  const { id } = req.params;
  try {
    const [teacherRows] = await db.execute('SELECT user_id FROM teachers WHERE id = ?', [id]);
    if (teacherRows.length === 0) {
      return res.status(404).json({ error: 'Teacher not found' });
    }
    
    // Deleting the user will cascade and delete the teacher record as well
    await db.execute('DELETE FROM users WHERE id = ?', [teacherRows[0].user_id]);
    res.status(200).json({ message: 'Teacher deleted successfully' });
  } catch (err) {
    console.error('[deleteTeacher] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};
