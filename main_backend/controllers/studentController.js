const db = require('../config/db');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const nodemailer = require('nodemailer');
const crypto = require('crypto');

async function generateStudentId(connection) {
  await connection.execute('UPDATE global_sequences SET `last_value` = `last_value` + 1 WHERE name = "student"');
  const [seq] = await connection.execute('SELECT `last_value` FROM global_sequences WHERE name = "student"');
  return 'STU' + seq[0].last_value.toString().padStart(3, '0');
}

function normalizeRollNo(rollNo) {
  if (rollNo === undefined || rollNo === null || rollNo === '') return null;
  const parsed = Number.parseInt(rollNo, 10);
  return Number.isNaN(parsed) ? null : parsed;
}

async function getNextClassRollNo(connection, classId) {
  const [rows] = await connection.execute(
    'SELECT COALESCE(MAX(roll_no), 0) + 1 AS next_roll_no FROM class_enrollments WHERE class_id = ?',
    [classId]
  );
  return rows[0]?.next_roll_no || 1;
}

async function enrollStudentInClass(connection, classId, studentId, rollNo) {
  if (!classId) return null;

  const [classes] = await connection.execute('SELECT id FROM classes WHERE id = ?', [classId]);
  if (classes.length === 0) {
    throw new Error(`Class not found: ${classId}`);
  }

  const classRollNo = normalizeRollNo(rollNo) || await getNextClassRollNo(connection, classId);
  await connection.execute(
    'INSERT INTO class_enrollments (class_id, student_id, roll_no) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE roll_no = VALUES(roll_no)',
    [classId, studentId, classRollNo]
  );
  return classRollNo;
}

exports.getStudentsByClass = async (req, res) => {
  const { classId } = req.params;

  try {
    const [rows] = await db.execute(
      `SELECT s.id, u.name, ce.roll_no, u.email, s.dept, s.current_year
       FROM class_enrollments ce
       JOIN students s ON s.id = ce.student_id
       JOIN users u ON s.user_id = u.id
       WHERE ce.class_id = ?`,
      [classId]
    );
    res.status(200).json(rows);
  } catch (err) {
    console.error('[getStudentsByClass] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

exports.addStudent = async (req, res) => {
  const { name, email, phone, address, country, state, district, city, classId, rollNo, dob, currentYear, dept, department_id, category } = req.body;
  
  if (!name || !email) {
    return res.status(400).json({ error: 'name and email are required' });
  }

  const userId = uuidv4();
  const randomPassword = crypto.randomBytes(4).toString('hex');
  let connection;

  try {
    connection = await db.getConnection();
    await connection.beginTransaction();

    const studentId = await generateStudentId(connection);

    const hashedPassword = await bcrypt.hash(randomPassword, 10);
    await connection.execute(
      'INSERT INTO users (id, name, email, password, role, phone, address, country, state, district, city) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [userId, name, email, hashedPassword, 'Student', phone || null, address || null, country || null, state || null, district || null, city || null]
    );

    const studentCat = category || 'OPEN';
    const studentRollNo = normalizeRollNo(rollNo);
    await connection.execute(
      'INSERT INTO students (id, user_id, roll_no, dept, current_year, dob, category) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [studentId, userId, studentRollNo, dept || 'General', currentYear || '1st Year', dob || null, studentCat]
    );

    // Auto-assign category fee
    if (department_id) {
      const [structures] = await connection.execute(
        'SELECT id, amount FROM category_fee_structures WHERE department_id = ? AND year = ? AND category = ?',
        [department_id, currentYear || '1st Year', studentCat]
      );
      if (structures.length > 0) {
        await connection.execute(
          'INSERT INTO student_category_fees (student_id, fee_structure_id, total_amount, status) VALUES (?, ?, ?, "PENDING")',
          [studentId, structures[0].id, structures[0].amount]
        );
      }
    }

    const classRollNo = await enrollStudentInClass(connection, classId, studentId, studentRollNo);
    await connection.commit();
    connection.release();
    connection = null;

    console.log(`[AUTH] New Student Registered: ${email} | Temp Password: ${randomPassword}`);

    // Respond immediately — do not block on email
    res.status(201).json({ 
      message: 'Student registered successfully', 
      studentId, 
      id: studentId,
      classId: classId || null,
      rollNo: classRollNo || studentRollNo,
    });

    // Fire-and-forget email (skip in test environment to avoid open handles)
    if (process.env.NODE_ENV !== 'test') {
      const transporter = nodemailer.createTransport({
        host: process.env.SMTP_HOST,
        port: process.env.SMTP_PORT,
        secure: false,
        auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS },
      });
      const mailOptions = {
        from: '"Classlytics Admin" <' + process.env.SMTP_USER + '>',
        to: email,
        subject: 'Welcome to Classlytics - Your Permanent Student ID',
        html: `
          <div style="font-family: Arial, sans-serif; padding: 20px; border: 1px solid #eee;">
            <h2 style="color: #1E3A8A;">Account Created!</h2>
            <p>Your permanent Student ID is: <strong>${studentId}</strong></p>
            <div style="background: #f8f9fa; padding: 15px; border-radius: 8px;">
              <p><strong>Login ID (Email):</strong> ${email}</p>
              <p><strong>Temporary Password:</strong> ${randomPassword}</p>
            </div>
          </div>
        `,
      };
      transporter.sendMail(mailOptions)
        .then(() => transporter.close())
        .catch(e => { console.warn('Email failed but user created:', e.message); transporter.close(); });
    }
  } catch (err) {
    if (connection) {
      await connection.rollback();
      connection.release();
    }
    console.error('Registration error:', err);
    res.status(500).json({ error: err.message });
  }
};

exports.getRegisteredStudents = async (req, res) => {
  const { dept, year } = req.query;
  try {
    let query = 'SELECT s.id, u.name, s.dept, s.current_year, u.email FROM students s JOIN users u ON s.user_id = u.id';
    const params = [];
    
    if (dept || year) {
      query += ' WHERE';
      if (dept) { query += ' s.dept = ?'; params.push(dept); }
      if (dept && year) query += ' AND';
      if (year) { query += ' s.current_year = ?'; params.push(year); }
    }

    const [rows] = await db.execute(query, params);
    res.status(200).json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.updateStudent = async (req, res) => {
  const { id } = req.params;
  const { name, rollNo, classId } = req.body;

  try {
    const [student] = await db.execute('SELECT user_id FROM students WHERE id = ?', [id]);
    if (student.length === 0) {
      return res.status(404).json({ error: 'Student not found' });
    }

    if (rollNo !== undefined) {
      const normalizedRollNo = normalizeRollNo(rollNo);
      await db.execute('UPDATE students SET roll_no = ? WHERE id = ?', [normalizedRollNo, id]);
      if (classId) {
        await db.execute(
          'UPDATE class_enrollments SET roll_no = ? WHERE class_id = ? AND student_id = ?',
          [normalizedRollNo, classId, id]
        );
      }
    }

    if (name) {
      await db.execute('UPDATE users SET name = ? WHERE id = ?', [name, student[0].user_id]);
    }

    res.status(200).json({ message: 'Student updated successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.bulkAddStudents = async (req, res) => {
  const { classId, studentList } = req.body; // studentList: [{name, email, rollNo, dept, year}]

  if (!Array.isArray(studentList)) {
    return res.status(400).json({ error: 'studentList array is required' });
  }

  let connection;
  try {
    connection = await db.getConnection();
    await connection.beginTransaction();
    const created = [];

    for (const s of studentList) {
      if (!s.name || !s.email) {
        throw new Error('Every student must include name and email');
      }

      const userId = uuidv4();
      const studentId = await generateStudentId(connection);

      const hashedPassword = await bcrypt.hash('student123', 10);
      await connection.execute(
        'INSERT INTO users (id, name, email, password, role) VALUES (?, ?, ?, ?, ?)',
        [userId, s.name, s.email, hashedPassword, 'Student']
      );

      const studentRollNo = normalizeRollNo(s.rollNo);
      await connection.execute(
        'INSERT INTO students (id, user_id, roll_no, dept, current_year) VALUES (?, ?, ?, ?, ?)',
        [studentId, userId, studentRollNo, s.dept || 'General', s.year || '1st Year']
      );

      const classRollNo = await enrollStudentInClass(connection, classId, studentId, studentRollNo);
      created.push({ id: studentId, name: s.name, email: s.email, rollNo: classRollNo || studentRollNo });
    }

    await connection.commit();
    connection.release();
    connection = null;

    res.status(201).json({
      message: `Successfully registered ${created.length} students`,
      students: created,
    });
  } catch (err) {
    if (connection) {
      await connection.rollback();
      connection.release();
    }
    res.status(500).json({ error: err.message });
  }
};

exports.getStudentById = async (req, res) => {
  const { id } = req.params;
  try {
    const [rows] = await db.execute(
      `SELECT s.id, u.name, u.email, u.phone, u.address, u.country, u.state, u.district, u.city, 
              s.dept, s.current_year, s.dob, ce.roll_no
       FROM students s
       JOIN users u ON s.user_id = u.id
       LEFT JOIN class_enrollments ce ON s.id = ce.student_id
       WHERE s.id = ?`,
      [id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: 'Student not found' });
    }

    res.status(200).json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};


exports.createWithParent = async (req, res) => {
  const { studentName, studentEmail, parentName, relation, parentPhone, parentEmail, classId, dept, department_id, currentYear, country, state, city, address, dob, rollNo, category } = req.body;

  if (!studentName || !parentName || !parentPhone || !parentEmail) {
    return res.status(400).json({ error: 'Required fields missing' });
  }

  // Generate strong random password (8-10 chars, uppercase, lowercase, numbers)
  const generatePassword = () => {
    const uc = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lc = 'abcdefghijklmnopqrstuvwxyz';
    const num = '0123456789';
    let pass = uc[Math.floor(Math.random() * uc.length)] + 
               lc[Math.floor(Math.random() * lc.length)] + 
               num[Math.floor(Math.random() * num.length)];
    const all = uc + lc + num;
    for (let i = 0; i < 6; i++) pass += all[Math.floor(Math.random() * all.length)];
    return pass.split('').sort(() => 0.5 - Math.random()).join('');
  };

  const randomPassword = generatePassword();
  const hashedPassword = await bcrypt.hash(randomPassword, 10);

  const parentId = uuidv4();
  const studentUserId = uuidv4();

  let connection;
  try {
    connection = await db.getConnection();
    await connection.beginTransaction();

    // 1. Validate parent email
    const [existingParents] = await connection.execute('SELECT id FROM parents WHERE email = ?', [parentEmail]);
    if (existingParents.length > 0) {
      await connection.rollback();
      connection.release();
      return res.status(400).json({ error: 'Parent with this email already exists' });
    }

    if (studentEmail) {
      const [existingStudents] = await connection.execute('SELECT id FROM users WHERE email = ?', [studentEmail]);
      if (existingStudents.length > 0) {
        await connection.rollback();
        connection.release();
        return res.status(400).json({ error: 'Student with this email already exists' });
      }
    }

    // 2. Generate STU ID
    const studentId = await generateStudentId(connection);

    // 3. Create Parent Records
    // a) Add to users table for authentication
    await connection.execute(
      'INSERT INTO users (id, name, email, password, role, phone, address, country, state, city) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [parentId, parentName, parentEmail, hashedPassword, 'Parent', parentPhone, address || null, country || null, state || null, city || null]
    );

    // b) Add to parents table for relationship data
    await connection.execute(
      'INSERT INTO parents (id, user_id, name, relation, phone, email, password, child_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [parentId, parentId, parentName, relation || 'Guardian', parentPhone, parentEmail, hashedPassword, null]
    );

    // 4. Create Student User Record (Hashed Password)
    const studentPass = crypto.randomBytes(4).toString('hex');
    const hashedStudentPass = await bcrypt.hash(studentPass, 10);
    await connection.execute(
      'INSERT INTO users (id, name, email, password, role, phone, address, country, state, city) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [studentUserId, studentName, studentEmail || null, hashedStudentPass, 'Student', null, address || null, country || null, state || null, city || null]
    );

    // 5. Create Student Record
    const studentCat = category || 'OPEN';
    const studentRollNo = normalizeRollNo(rollNo);
    await connection.execute(
      'INSERT INTO students (id, user_id, roll_no, dept, current_year, dob, parent_id, category) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [studentId, studentUserId, studentRollNo, dept || 'General', currentYear || '1st Year', dob || null, parentId, studentCat]
    );

    // Auto-assign category fee
    if (department_id) {
      const [structures] = await connection.execute(
        'SELECT id, amount FROM category_fee_structures WHERE department_id = ? AND year = ? AND category = ?',
        [department_id, currentYear || '1st Year', studentCat]
      );
      if (structures.length > 0) {
        await connection.execute(
          'INSERT INTO student_category_fees (student_id, fee_structure_id, total_amount, status) VALUES (?, ?, ?, "PENDING")',
          [studentId, structures[0].id, structures[0].amount]
        );
      }
    }

    // 6. Update Parent Record with Student ID now that Student exists
    await connection.execute('UPDATE parents SET child_id = ? WHERE id = ?', [studentId, parentId]);
    const classRollNo = await enrollStudentInClass(connection, classId, studentId, studentRollNo);

    await connection.commit();
    connection.release();
    connection = null;

    // Log fallback for debugging when Email fails
    console.log(`\n[AUTH] NEW REGISTRATION (WITH PARENT) SUCCESSFUL:`);
    console.log(`[AUTH] Student: ID=${studentId} | Email=${studentEmail || 'None'} | Temp Pass=${studentPass}`);
    console.log(`[AUTH] Parent: Email=${parentEmail} | Temp Pass=${randomPassword}\n`);

    // Respond immediately — do not block on email
    res.status(201).json({
      message: 'Student and parent created successfully',
      studentId,
      parentId,
      classId: classId || null,
      rollNo: classRollNo || studentRollNo,
    });

    // Fire-and-forget email (skip in test environment to avoid open handles)
    if (process.env.NODE_ENV !== 'test') {
      const transporter = nodemailer.createTransport({
        host: process.env.SMTP_HOST,
        port: process.env.SMTP_PORT,
        secure: false,
        auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS }
      });
      const mailOptions = {
        from: '"Classlytics Admin" <' + process.env.SMTP_USER + '>',
        to: parentEmail,
        subject: 'Welcome to Classlytics – Parent Account Created',
        html: `
          <div style="font-family: Arial, sans-serif; padding: 20px;">
            <h2>Dear ${parentName},</h2>
            <p>Your parent account has been created in Classlytics.</p>
            <p><strong>Student:</strong> ${studentName}</p>
            <h3>Login Credentials:</h3>
            <div style="background: #f4f4f5; padding: 10px; border-radius: 5px;">
              <p><strong>Email:</strong> ${parentEmail}</p>
              <p><strong>Password:</strong> ${randomPassword}</p>
            </div>
            <p>Login here: <a href="http://localhost:3000/login">http://localhost:3000/login</a></p>
            <p>Please change your password after first login.</p>
            <br/>
            <p>Regards,<br/>Classlytics Team</p>
          </div>
        `
      };
      transporter.sendMail(mailOptions)
        .then(() => transporter.close())
        .catch(e => { console.warn('Email warning:', e.message); transporter.close(); });
    }
  } catch (err) {
    if (connection) {
      await connection.rollback();
      connection.release();
    }
    console.error('Error creating student with parent:', err);
    res.status(500).json({ error: err.message });
  }
};

// ─── GET /api/student/my-fees ───
exports.getMyFees = async (req, res) => {
  let studentId = req.user.studentId || req.user.id; // Depending on how user is attached
  
  if (req.user.role === 'Parent' && req.query.childId) {
    studentId = req.query.childId;
  }

  try {
    const [rows] = await db.execute(`
      SELECT f.total_amount, f.paid_amount, f.status, s.year, s.category, d.name as department_name
      FROM student_category_fees f
      JOIN category_fee_structures s ON f.fee_structure_id = s.id
      LEFT JOIN departments d ON s.department_id = d.id
      WHERE f.student_id = ?
    `, [studentId]);

    if (rows.length === 0) {
      return res.status(200).json({ total_amount: 0, paid_amount: 0, status: 'NO_FEE_ASSIGNED' });
    }

    res.status(200).json(rows[0]);
  } catch (err) {
    console.error('[Student getMyFees] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};
