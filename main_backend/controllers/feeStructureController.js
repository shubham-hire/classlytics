const db = require('../config/db');

// ─── Helper: Calculate total from components ──────────────────────────────────
const calcTotal = ({ tuition_fee = 0, exam_fee = 0, transport_fee = 0, library_fee = 0, sports_fee = 0, miscellaneous_fee = 0 }) =>
  [tuition_fee, exam_fee, transport_fee, library_fee, sports_fee, miscellaneous_fee]
    .reduce((sum, v) => sum + parseFloat(v || 0), 0);

// ─── GET /api/fees/structure ──────────────────────────────────────────────────
// Returns all fee structures joined with class info
exports.getAllStructures = async (req, res) => {
  try {
    const { class_id, academic_year } = req.query;
    let query = `
      SELECT 
        fs.*,
        c.name AS class_name,
        c.section AS class_section,
        (fs.tuition_fee + fs.exam_fee + fs.transport_fee + fs.library_fee + fs.sports_fee + fs.miscellaneous_fee) AS total_fee
      FROM fee_structures fs
      INNER JOIN classes c ON fs.class_id = c.id
    `;
    const params = [];
    const conditions = [];

    if (class_id) { conditions.push('fs.class_id = ?'); params.push(class_id); }
    if (academic_year) { conditions.push('fs.academic_year = ?'); params.push(academic_year); }
    if (conditions.length) query += ` WHERE ${conditions.join(' AND ')}`;
    query += ' ORDER BY fs.created_at DESC';

    const [rows] = await db.execute(query, params);
    res.status(200).json(rows);
  } catch (err) {
    console.error('[getAllStructures] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// ─── GET /api/fees/structure/:id ─────────────────────────────────────────────
exports.getStructureById = async (req, res) => {
  try {
    const [rows] = await db.execute(`
      SELECT 
        fs.*,
        c.name AS class_name,
        c.section AS class_section,
        (fs.tuition_fee + fs.exam_fee + fs.transport_fee + fs.library_fee + fs.sports_fee + fs.miscellaneous_fee) AS total_fee
      FROM fee_structures fs
      INNER JOIN classes c ON fs.class_id = c.id
      WHERE fs.id = ?
    `, [req.params.id]);

    if (rows.length === 0) return res.status(404).json({ error: 'Fee structure not found' });
    res.status(200).json(rows[0]);
  } catch (err) {
    console.error('[getStructureById] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// ─── POST /api/fees/structure ─────────────────────────────────────────────────
exports.createStructure = async (req, res) => {
  const {
    class_id, academic_year, title,
    tuition_fee = 0, exam_fee = 0, transport_fee = 0,
    library_fee = 0, sports_fee = 0, miscellaneous_fee = 0,
    due_date
  } = req.body;

  if (!class_id || !academic_year || !title) {
    return res.status(400).json({ error: 'class_id, academic_year, and title are required' });
  }

  try {
    // Verify class exists
    const [cls] = await db.execute('SELECT id FROM classes WHERE id = ?', [class_id]);
    if (cls.length === 0) return res.status(404).json({ error: 'Class not found' });

    const [result] = await db.execute(`
      INSERT INTO fee_structures 
        (class_id, academic_year, title, tuition_fee, exam_fee, transport_fee, library_fee, sports_fee, miscellaneous_fee, due_date)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      RETURNING id
    `, [class_id, academic_year, title,
        tuition_fee, exam_fee, transport_fee, library_fee, sports_fee, miscellaneous_fee,
        due_date || null]);

    const [created] = await db.execute(`
      SELECT fs.*, c.name AS class_name, c.section AS class_section,
        (fs.tuition_fee + fs.exam_fee + fs.transport_fee + fs.library_fee + fs.sports_fee + fs.miscellaneous_fee) AS total_fee
      FROM fee_structures fs INNER JOIN classes c ON fs.class_id = c.id
      WHERE fs.id = ?
    `, [result[0].id]);

    res.status(201).json(created[0]);
  } catch (err) {
    if (err.code === '23505' || err.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ error: 'A fee structure for this class and academic year already exists' });
    }
    console.error('[createStructure] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// ─── PUT /api/fees/structure/:id ──────────────────────────────────────────────
exports.updateStructure = async (req, res) => {
  const {
    title, tuition_fee, exam_fee, transport_fee,
    library_fee, sports_fee, miscellaneous_fee, due_date, academic_year
  } = req.body;

  try {
    const [existing] = await db.execute('SELECT id FROM fee_structures WHERE id = ?', [req.params.id]);
    if (existing.length === 0) return res.status(404).json({ error: 'Fee structure not found' });

    await db.execute(`
      UPDATE fee_structures SET
        title = COALESCE(?, title),
        academic_year = COALESCE(?, academic_year),
        tuition_fee = COALESCE(?, tuition_fee),
        exam_fee = COALESCE(?, exam_fee),
        transport_fee = COALESCE(?, transport_fee),
        library_fee = COALESCE(?, library_fee),
        sports_fee = COALESCE(?, sports_fee),
        miscellaneous_fee = COALESCE(?, miscellaneous_fee),
        due_date = COALESCE(?, due_date)
      WHERE id = ?
    `, [title, academic_year, tuition_fee, exam_fee, transport_fee, library_fee, sports_fee, miscellaneous_fee, due_date || null, req.params.id]);

    const [updated] = await db.execute(`
      SELECT fs.*, c.name AS class_name, c.section AS class_section,
        (fs.tuition_fee + fs.exam_fee + fs.transport_fee + fs.library_fee + fs.sports_fee + fs.miscellaneous_fee) AS total_fee
      FROM fee_structures fs INNER JOIN classes c ON fs.class_id = c.id
      WHERE fs.id = ?
    `, [req.params.id]);

    res.status(200).json(updated[0]);
  } catch (err) {
    console.error('[updateStructure] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// ─── DELETE /api/fees/structure/:id ──────────────────────────────────────────
exports.deleteStructure = async (req, res) => {
  try {
    const [existing] = await db.execute('SELECT id FROM fee_structures WHERE id = ?', [req.params.id]);
    if (existing.length === 0) return res.status(404).json({ error: 'Fee structure not found' });

    await db.execute('DELETE FROM fee_structures WHERE id = ?', [req.params.id]);
    res.status(200).json({ message: 'Fee structure deleted successfully' });
  } catch (err) {
    console.error('[deleteStructure] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};
