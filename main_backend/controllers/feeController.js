const db = require('../config/db');
const { checkStudentOwnership, checkParentOwnership } = require('../middleware/auth');

// GET /fee/:studentId — Get fee status for a student
exports.getFeeStatus = async (req, res) => {
  const { studentId } = req.params;

  try {
    const hasStudentAccess = await checkStudentOwnership(db, studentId, req.user);
    const hasParentAccess = await checkParentOwnership(db, studentId, req.user);
    if (!hasStudentAccess && !hasParentAccess) {
      return res.status(403).json({ error: 'Access denied: You can only view your own fee status.' });
    }
    const [rows] = await db.execute(
      `SELECT id, student_id, total_fee, paid_amount, due_date, semester,
              (total_fee - paid_amount) AS pending_amount
       FROM fees
       WHERE student_id = ?
       ORDER BY semester DESC`,
      [studentId]
    );

    if (rows.length === 0) {
      // Return a default structure if not set up yet
      return res.status(200).json({
        studentId,
        totalFee: 50000,
        paidAmount: 0,
        pendingAmount: 50000,
        dueDate: null,
        semester: 'Sem 1',
        history: [],
      });
    }

    const latest = rows[0];
    res.status(200).json({
      studentId,
      totalFee: parseFloat(latest.total_fee),
      paidAmount: parseFloat(latest.paid_amount),
      pendingAmount: parseFloat(latest.pending_amount),
      dueDate: latest.due_date,
      semester: latest.semester,
      history: rows,
    });
  } catch (err) {
    console.error('[getFeeStatus] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// POST /fee/:studentId — Create/update fee record for a student (Admin use)
exports.setFeeRecord = async (req, res) => {
  const { studentId } = req.params;
  const { totalFee, paidAmount, dueDate, semester } = req.body;

  if (totalFee === undefined || paidAmount === undefined) {
    return res.status(400).json({ error: 'totalFee and paidAmount are required' });
  }

  try {
    await db.execute(
      `INSERT INTO fees (student_id, total_fee, paid_amount, due_date, semester)
       VALUES (?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE paid_amount = ?, due_date = ?, semester = ?`,
      [studentId, totalFee, paidAmount, dueDate || null, semester || 'Sem 1',
       paidAmount, dueDate || null, semester || 'Sem 1']
    );
    res.status(201).json({ message: 'Fee record updated successfully' });
  } catch (err) {
    console.error('[setFeeRecord] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// POST /fee/:studentId/payment — Record a new payment
exports.recordPayment = async (req, res) => {
  const { studentId } = req.params;
  const { amount } = req.body;

  if (!amount || amount <= 0) {
    return res.status(400).json({ error: 'Valid payment amount is required' });
  }

  try {
    const [rows] = await db.execute('SELECT id, paid_amount, total_fee FROM fees WHERE student_id = ? ORDER BY semester DESC LIMIT 1', [studentId]);
    if (rows.length === 0) {
      return res.status(404).json({ error: 'No fee record found for this student' });
    }

    const fee = rows[0];
    const newPaid = Math.min(parseFloat(fee.paid_amount) + parseFloat(amount), parseFloat(fee.total_fee));
    await db.execute('UPDATE fees SET paid_amount = ? WHERE id = ?', [newPaid, fee.id]);

    res.status(200).json({ message: 'Payment recorded', paidAmount: newPaid, pendingAmount: fee.total_fee - newPaid });
  } catch (err) {
    console.error('[recordPayment] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};
