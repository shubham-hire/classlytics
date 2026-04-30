const db = require('../config/db');

// GET /departments
exports.getAllDepartments = async (req, res) => {
  try {
    const [rows] = await db.execute('SELECT * FROM departments ORDER BY name ASC');
    res.status(200).json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// GET /departments/:id
exports.getDepartmentById = async (req, res) => {
  try {
    const [rows] = await db.execute('SELECT * FROM departments WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ error: 'Department not found' });
    res.status(200).json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// POST /departments
exports.createDepartment = async (req, res) => {
  const { name } = req.body;
  if (!name) return res.status(400).json({ error: 'Department name is required' });

  try {
    const [result] = await db.execute('INSERT INTO departments (name) VALUES (?)', [name]);
    res.status(201).json({ 
      message: 'Department created successfully', 
      id: result.insertId, 
      name 
    });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(400).json({ error: 'A department with this name already exists' });
    }
    res.status(500).json({ error: err.message });
  }
};

// DELETE /departments/:id
exports.deleteDepartment = async (req, res) => {
  try {
    // Check if any users or classes are linked
    const [users] = await db.execute('SELECT id FROM users WHERE department_id = ? LIMIT 1', [req.params.id]);
    const [classes] = await db.execute('SELECT id FROM classes WHERE department_id = ? LIMIT 1', [req.params.id]);
    
    if (users.length > 0 || classes.length > 0) {
      return res.status(400).json({ error: 'Cannot delete department: It has linked users or classes.' });
    }

    await db.execute('DELETE FROM departments WHERE id = ?', [req.params.id]);
    res.status(200).json({ message: 'Department deleted successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
