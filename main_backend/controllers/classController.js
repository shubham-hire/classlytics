const db = require('../config/db');

exports.getClasses = async (req, res) => {
  try {
    const [rows] = await db.query('SELECT classId, className, subject FROM classes');
    res.status(200).json(rows);
  } catch (err) {
    console.error('Error fetching classes:', err);
    res.status(500).json({ error: 'Failed to fetch classes' });
  }
};
