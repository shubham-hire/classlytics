const db = require('../config/db');
const bcrypt = require('bcryptjs');

exports.login = async (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({ error: 'Email and password are required' });
    }

    try {
        console.log(`[AUTH] Login attempt for: ${email}`);

        // 1. Check 'users' table (Teacher, Admin, Student)
        let [users] = await db.execute('SELECT * FROM users WHERE email = ?', [email]);
        let user = null;
        let isMatch = false;

        if (users.length > 0) {
            user = users[0];
            // Check password (handle both plain text for legacy seeds and bcrypt)
            if (user.password === password) {
                isMatch = true;
            } else {
                try {
                    isMatch = await bcrypt.compare(password, user.password);
                } catch (e) {
                    isMatch = false;
                }
            }
        } 
        
        // 2. If not found in users, check 'parents' table
        if (!user || (!isMatch && users.length > 0)) {
            const [parents] = await db.execute('SELECT * FROM parents WHERE email = ?', [email]);
            if (parents.length > 0) {
                const parent = parents[0];
                const parentMatch = await bcrypt.compare(password, parent.password);
                if (parentMatch) {
                    user = {
                        ...parent,
                        role: 'Parent' // Parents table might not have role column
                    };
                    isMatch = true;
                }
            }
        }

        if (!user || !isMatch) {
            console.warn(`[AUTH] Login failed for: ${email}`);
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        // 3. Fetch extra info based on role
        let extraInfo = {};
        if (user.role === 'Student') {
            const [student] = await db.execute('SELECT * FROM students WHERE user_id = ?', [user.id]);
            if (student.length > 0) extraInfo = student[0];
        } else if (user.role === 'Parent') {
            // Fetch student_id from parents table if not present (authenticated via users table)
            if (!user.student_id) {
                const [parentData] = await db.execute('SELECT student_id FROM parents WHERE email = ?', [user.email]);
                if (parentData.length > 0) extraInfo = { student_id: parentData[0].student_id };
            } else {
                extraInfo = { student_id: user.student_id };
            }
        }

        console.log(`[AUTH] Login successful: ${email} (${user.role})`);

        res.status(200).json({
            message: 'Login successful',
            user: {
                id: user.id,
                name: user.name,
                email: user.email,
                role: user.role,
                phone: user.phone,
                dept: user.dept || null,
                ...extraInfo
            }
        });
    } catch (err) {
        console.error('[AUTH] Login Error:', err);
        res.status(500).json({ error: err.message });
    }
};
