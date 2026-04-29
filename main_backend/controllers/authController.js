const db = require('../config/db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

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
            const [parent] = await db.execute(`
                SELECT p.*, u.name as child_name 
                FROM parents p 
                LEFT JOIN students s ON p.child_id = s.id 
                LEFT JOIN users u ON s.user_id = u.id 
                WHERE p.id = ? OR p.user_id = ?
            `, [user.id, user.id]);
            if (parent.length > 0) extraInfo = parent[0];
        }

        const userPayload = {
            id: user.id,
            name: user.name,
            email: user.email,
            role: user.role,
            phone: user.phone,
            dept: user.dept || null,
            ...extraInfo
        };

        // 4. Sign JWT
        const token = jwt.sign(
            { 
                id: user.id, 
                name: user.name, 
                email: user.email, 
                role: user.role,
                department_id: user.department_id || null 
            },
            process.env.JWT_SECRET,
            { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
        );

        console.log(`[AUTH] Login success for: ${email} (${user.role})`);

        res.status(200).json({
            message: 'Login successful',
            token,
            user: userPayload
        });
    } catch (err) {
        console.error('[AUTH] Login Error:', err);
        res.status(500).json({ error: err.message });
    }
};

// ─── GET /auth/me — Verify token and return current user ─────────────────
exports.getMe = (req, res) => {
    // req.user is populated by verifyToken middleware
    res.status(200).json({ user: req.user });
};

