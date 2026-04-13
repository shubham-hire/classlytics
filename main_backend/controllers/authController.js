const db = require('../config/db');

exports.login = async (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({ error: 'Email and password are required' });
    }

    try {
        // Query user and join with student/teacher specific tables if needed
        const [users] = await db.execute('SELECT * FROM users WHERE email = ? AND password = ?', [email, password]);

        if (users.length === 0) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        const user = users[0];
        
        // Fetch extra info based on role
        let extraInfo = {};
        if (user.role === 'Student') {
            const [student] = await db.execute('SELECT * FROM students WHERE user_id = ?', [user.id]);
            if (student.length > 0) extraInfo = student[0];
        }

        res.status(200).json({
            message: 'Login successful',
            user: {
                id: user.id,
                name: user.name,
                email: user.email,
                role: user.role,
                phone: user.phone,
                dept: user.dept,
                ...extraInfo
            }
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};
