const fs = require('fs');
const content = fs.readFileSync('studentController.js', 'utf8').split('\n').slice(0, 189).join('\n');
const newContent = content + `\n
exports.createWithParent = async (req, res) => {
  const { studentName, studentEmail, parentName, relation, parentPhone, parentEmail, dept, currentYear, country, state, city, address, dob, rollNo } = req.body;

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

    // 2. Generate STU ID
    await connection.execute('UPDATE global_sequences SET \`last_value\` = \`last_value\` + 1 WHERE name = "student"');
    const [seq] = await connection.execute('SELECT \`last_value\` FROM global_sequences WHERE name = "student"');
    const studentId = 'STU' + seq[0].last_value.toString().padStart(3, '0');

    // 3. Create Parent Record (insert null for student_id first to resolve circular FK constraint)
    await connection.execute(
      'INSERT INTO parents (id, name, relation, phone, email, password, student_id) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [parentId, parentName, relation || 'Guardian', parentPhone, parentEmail, hashedPassword, null]
    );

    // 4. Create Student User Record
    const studentPass = crypto.randomBytes(4).toString('hex');
    await connection.execute(
      'INSERT INTO users (id, name, email, password, role, phone, address, country, state, city) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [studentUserId, studentName, studentEmail || null, studentPass, 'Student', null, address || null, country || null, state || null, city || null]
    );

    // 5. Create Student Record
    await connection.execute(
      'INSERT INTO students (id, user_id, roll_no, dept, current_year, dob, parent_id) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [studentId, studentUserId, rollNo || null, dept || 'General', currentYear || '1st Year', dob || null, parentId]
    );

    // 6. Update Parent Record with Student ID now that Student exists
    await connection.execute('UPDATE parents SET student_id = ? WHERE id = ?', [studentId, parentId]);

    await connection.commit();

    // 7. Send Email using Nodemailer
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
      html: \`
        <div style="font-family: Arial, sans-serif; padding: 20px;">
          <h2>Dear \${parentName},</h2>
          <p>Your parent account has been created in Classlytics.</p>
          <p><strong>Student:</strong> \${studentName}</p>
          <h3>Login Credentials:</h3>
          <div style="background: #f4f4f5; padding: 10px; border-radius: 5px;">
            <p><strong>Email:</strong> \${parentEmail}</p>
            <p><strong>Password:</strong> \${randomPassword}</p>
          </div>
          <p>Login here: <a href="http://localhost:3000/login">http://localhost:3000/login</a></p>
          <p>Please change your password after first login.</p>
          <br/>
          <p>Regards,<br/>Classlytics Team</p>
        </div>
      \`
    };

    transporter.sendMail(mailOptions).catch(e => console.warn('Email warning:', e.message));

    connection.release();
    res.status(201).json({ message: 'Student and parent created successfully', studentId, parentId });
  } catch (err) {
    if (connection) {
      await connection.rollback();
      connection.release();
    }
    console.error('Error creating student with parent:', err);
    res.status(500).json({ error: err.message });
  }
};`;

fs.writeFileSync('studentController.js', newContent);
