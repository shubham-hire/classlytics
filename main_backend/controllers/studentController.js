const db = require('../config/db');
const { v4: uuidv4 } = require('uuid');
const nodemailer = require('nodemailer');
const crypto = require('crypto');

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
  const { name, email, phone, address, country, state, district, city, rollNo, dob, currentYear, dept } = req.body;
  
  if (!name || !email || !dept || !currentYear) {
    return res.status(400).json({ error: 'name, email, dept, and currentYear are required' });
  }

  const userId = uuidv4();
  const randomPassword = crypto.randomBytes(4).toString('hex');

  try {
    // 1. Generate Sequential ID
    await db.execute('UPDATE global_sequences SET `last_value` = `last_value` + 1 WHERE name = "student"');
    const [seq] = await db.execute('SELECT `last_value` FROM global_sequences WHERE name = "student"');
    const studentId = 'STU' + seq[0].last_value.toString().padStart(3, '0');

    // 2. Create User
    await db.execute(
      'INSERT INTO users (id, name, email, password, role, phone, address, country, state, district, city) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [userId, name, email, randomPassword, 'Student', phone || null, address || null, country || null, state || null, district || null, city || null]
    );

    // 3. Create Student record
    await db.execute(
      'INSERT INTO students (id, user_id, roll_no, dept, current_year, dob) VALUES (?, ?, ?, ?, ?, ?)',
      [studentId, userId, rollNo || null, dept, currentYear, dob || null]
    );

    // 4. Send Email & Log Fallback
    console.log(`[AUTH] New Student Registered: ${email} | Temp Password: ${randomPassword}`);

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

    await transporter.sendMail(mailOptions).catch(e => console.warn('Email failed but user created:', e.message));

    res.status(201).json({ 
      message: 'Student registered successfully', 
      studentId, 
      id: studentId 
    });
  } catch (err) {
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
  const { name, rollNo } = req.body;

  try {
    // Update students table
    if (rollNo !== undefined) {
      await db.execute('UPDATE students SET roll_no = ? WHERE id = ?', [rollNo, id]);
    }

    // Update users table (if name provided)
    if (name) {
      const [student] = await db.execute('SELECT user_id FROM students WHERE id = ?', [id]);
      if (student.length > 0) {
        await db.execute('UPDATE users SET name = ? WHERE id = ?', [name, student[0].user_id]);
      }
    }

    res.status(200).json({ message: 'Student updated successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.bulkAddStudents = async (req, res) => {
  const { studentList } = req.body; // studentList: [{name, email, rollNo, dept, year}]

  if (!Array.isArray(studentList)) {
    return res.status(400).json({ error: 'studentList array is required' });
  }

  try {
    for (const s of studentList) {
      const userId = uuidv4();
      
      await db.execute('UPDATE global_sequences SET `last_value` = `last_value` + 1 WHERE name = "student"');
      const [seq] = await db.execute('SELECT `last_value` FROM global_sequences WHERE name = "student"');
      const studentId = 'STU' + seq[0].last_value.toString().padStart(3, '0');

      await db.execute(
        'INSERT INTO users (id, name, email, password, role) VALUES (?, ?, ?, ?, ?)',
        [userId, s.name, s.email, 'student123', 'Student']
      );
      await db.execute(
        'INSERT INTO students (id, user_id, roll_no, dept, current_year) VALUES (?, ?, ?, ?, ?)',
        [studentId, userId, s.rollNo || null, s.dept || 'General', s.year || '1st Year']
      );
    }
    res.status(201).json({ message: `Successfully registered ${studentList.length} students` });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
