const db = require('../config/db');

exports.getClasses = async (req, res) => {
  try {
    const [rows] = await db.execute('SELECT id, name, section, teacher_id FROM classes');
    res.status(200).json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};


exports.enrollStudents = async (req, res) => {
  const { classId, studentIds } = req.body; // studentIds: ['STU001', 'STU002']
  if (!classId || !Array.isArray(studentIds)) {
    return res.status(400).json({ error: 'classId and studentIds array required' });
  }

  try {
    // 1. Get current max roll number in this class
    const [rollRes] = await db.execute('SELECT MAX(roll_no) as max_roll FROM class_enrollments WHERE class_id = ?', [classId]);
    let currentMax = rollRes[0].max_roll || 0;

    for (const studentId of studentIds) {
      currentMax++;
      await db.execute(
        'INSERT INTO class_enrollments (class_id, student_id, roll_no) VALUES (?, ?, ?) ON CONFLICT (class_id, student_id) DO NOTHING',
        [classId, studentId, currentMax]
      );
    }
    res.status(201).json({ message: `Successfully enrolled ${studentIds.length} students with auto roll numbers.` });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
