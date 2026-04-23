const db = require('../config/db');

// ─── Helper: Recalculate status ────────────────────────────────────────────────
function calcStatus(paidAmount, totalAmount) {
  const paid = parseFloat(paidAmount);
  const total = parseFloat(totalAmount);
  if (paid <= 0) return 'Pending';
  if (paid >= total) return 'Paid';
  return 'Partial';
}

// ─── GET /api/fees/assignments ─────────────────────────────────────────────────
// List all student fee assignments (with optional filters)
exports.getAssignments = async (req, res) => {
  const { student_id, fee_structure_id, status, class_id } = req.query;
  try {
    let query = `
      SELECT 
        sfa.id, sfa.student_id, sfa.fee_structure_id,
        sfa.total_amount, sfa.paid_amount, sfa.status, sfa.due_date, sfa.assigned_at,
        (sfa.total_amount - sfa.paid_amount) AS pending_amount,
        u.name AS student_name, u.email AS student_email,
        s.current_year, s.dept, s.roll_no,
        fs.title AS structure_title, fs.academic_year,
        c.id AS class_id, c.name AS class_name, c.section AS class_section
      FROM student_fee_assignments sfa
      INNER JOIN students s ON sfa.student_id = s.id
      INNER JOIN users u ON s.user_id = u.id
      INNER JOIN fee_structures fs ON sfa.fee_structure_id = fs.id
      INNER JOIN classes c ON fs.class_id = c.id
    `;
    const params = [];
    const conditions = [];

    if (student_id) { conditions.push('sfa.student_id = ?'); params.push(student_id); }
    if (fee_structure_id) { conditions.push('sfa.fee_structure_id = ?'); params.push(fee_structure_id); }
    if (status) { conditions.push('sfa.status = ?'); params.push(status); }
    if (class_id) { conditions.push('c.id = ?'); params.push(class_id); }
    if (conditions.length) query += ` WHERE ${conditions.join(' AND ')}`;
    query += ' ORDER BY sfa.assigned_at DESC';

    const [rows] = await db.execute(query, params);
    res.status(200).json(rows);
  } catch (err) {
    console.error('[getAssignments] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// ─── GET /api/fees/assignments/student/:studentId ──────────────────────────────
// Get all fee assignments for a specific student
exports.getStudentAssignments = async (req, res) => {
  const { studentId } = req.params;
  try {
    const [rows] = await db.execute(`
      SELECT 
        sfa.id, sfa.student_id, sfa.fee_structure_id,
        sfa.total_amount, sfa.paid_amount, sfa.status, sfa.due_date, sfa.assigned_at,
        (sfa.total_amount - sfa.paid_amount) AS pending_amount,
        fs.title AS structure_title, fs.academic_year,
        fs.tuition_fee, fs.exam_fee, fs.transport_fee,
        fs.library_fee, fs.sports_fee, fs.miscellaneous_fee,
        c.name AS class_name, c.section AS class_section
      FROM student_fee_assignments sfa
      INNER JOIN fee_structures fs ON sfa.fee_structure_id = fs.id
      INNER JOIN classes c ON fs.class_id = c.id
      WHERE sfa.student_id = ?
      ORDER BY sfa.assigned_at DESC
    `, [studentId]);
    res.status(200).json(rows);
  } catch (err) {
    console.error('[getStudentAssignments] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// ─── POST /api/fees/assignments ────────────────────────────────────────────────
// Assign a fee structure to a specific student (or override if already assigned)
exports.assignFee = async (req, res) => {
  const { student_id, fee_structure_id } = req.body;
  if (!student_id || !fee_structure_id) {
    return res.status(400).json({ error: 'student_id and fee_structure_id are required' });
  }
  try {
    // Validate student exists
    const [stuRows] = await db.execute('SELECT id FROM students WHERE id = ?', [student_id]);
    if (stuRows.length === 0) return res.status(404).json({ error: 'Student not found' });

    // Get fee structure total
    const [fsRows] = await db.execute(
      'SELECT *, (tuition_fee + exam_fee + transport_fee + library_fee + sports_fee + miscellaneous_fee) AS total_fee, due_date FROM fee_structures WHERE id = ?',
      [fee_structure_id]
    );
    if (fsRows.length === 0) return res.status(404).json({ error: 'Fee structure not found' });
    const fs = fsRows[0];

    await db.execute(`
      INSERT INTO student_fee_assignments (student_id, fee_structure_id, total_amount, paid_amount, status, due_date)
      VALUES (?, ?, ?, 0, 'Pending', ?)
      ON DUPLICATE KEY UPDATE
        total_amount = VALUES(total_amount),
        due_date = VALUES(due_date),
        status = IF(paid_amount >= VALUES(total_amount), 'Paid', IF(paid_amount > 0, 'Partial', 'Pending'))
    `, [student_id, fee_structure_id, fs.total_fee, fs.due_date || null]);

    res.status(201).json({ message: 'Fee assigned successfully' });
  } catch (err) {
    console.error('[assignFee] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// ─── POST /api/fees/assignments/bulk ──────────────────────────────────────────
// Assign a fee structure to ALL students enrolled in its linked class
exports.bulkAssignByClass = async (req, res) => {
  const { fee_structure_id } = req.body;
  if (!fee_structure_id) return res.status(400).json({ error: 'fee_structure_id is required' });

  try {
    // Get the fee structure (with total + class_id)
    const [fsRows] = await db.execute(
      'SELECT *, (tuition_fee + exam_fee + transport_fee + library_fee + sports_fee + miscellaneous_fee) AS total_fee FROM fee_structures WHERE id = ?',
      [fee_structure_id]
    );
    if (fsRows.length === 0) return res.status(404).json({ error: 'Fee structure not found' });
    const fs = fsRows[0];

    // Get all students enrolled in this class
    const [students] = await db.execute(
      'SELECT student_id FROM class_enrollments WHERE class_id = ?',
      [fs.class_id]
    );
    if (students.length === 0) {
      return res.status(200).json({ message: 'No students enrolled in this class', assigned: 0, skipped: 0 });
    }

    let assigned = 0;
    let skipped = 0;
    for (const { student_id } of students) {
      try {
        await db.execute(`
          INSERT INTO student_fee_assignments (student_id, fee_structure_id, total_amount, paid_amount, status, due_date)
          VALUES (?, ?, ?, 0, 'Pending', ?)
          ON DUPLICATE KEY UPDATE total_amount = VALUES(total_amount), due_date = VALUES(due_date)
        `, [student_id, fee_structure_id, fs.total_fee, fs.due_date || null]);
        assigned++;
      } catch (_) {
        skipped++;
      }
    }

    res.status(201).json({
      message: `Bulk assignment complete`,
      total_students: students.length,
      assigned,
      skipped,
    });
  } catch (err) {
    console.error('[bulkAssignByClass] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// ─── DELETE /api/fees/assignments/:id ─────────────────────────────────────────
exports.removeAssignment = async (req, res) => {
  try {
    const [rows] = await db.execute('SELECT id FROM student_fee_assignments WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ error: 'Assignment not found' });

    await db.execute('DELETE FROM student_fee_assignments WHERE id = ?', [req.params.id]);
    res.status(200).json({ message: 'Assignment removed successfully' });
  } catch (err) {
    console.error('[removeAssignment] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// ─── GET /api/fees/assignments/:id/payments ────────────────────────────────────
exports.getPaymentHistory = async (req, res) => {
  try {
    const [rows] = await db.execute(
      'SELECT * FROM fee_payments WHERE assignment_id = ? ORDER BY paid_at DESC',
      [req.params.id]
    );
    res.status(200).json(rows);
  } catch (err) {
    console.error('[getPaymentHistory] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// ─── POST /api/fees/assignments/:id/payment ────────────────────────────────────
exports.recordPayment = async (req, res) => {
  const { id } = req.params;
  const { amount, payment_mode, reference_no, note } = req.body;

  if (!amount || amount <= 0) {
    return res.status(400).json({ error: 'Valid payment amount is required' });
  }

  let connection;
  try {
    connection = await db.getConnection();
    await connection.beginTransaction();

    // 1. Get current assignment state
    const [assignments] = await connection.execute(
      'SELECT student_id, total_amount, paid_amount FROM student_fee_assignments WHERE id = ? FOR UPDATE',
      [id]
    );
    if (assignments.length === 0) {
      await connection.rollback();
      return res.status(404).json({ error: 'Assignment not found' });
    }

    const assignment = assignments[0];
    const newPaidAmount = parseFloat(assignment.paid_amount) + parseFloat(amount);
    const newStatus = calcStatus(newPaidAmount, assignment.total_amount);

    // 2. Insert payment record
    await connection.execute(`
      INSERT INTO fee_payments (assignment_id, student_id, amount, payment_mode, reference_no, note)
      VALUES (?, ?, ?, ?, ?, ?)
    `, [id, assignment.student_id, amount, payment_mode || 'Cash', reference_no || null, note || null]);

    // 3. Update assignment totals and status
    await connection.execute(`
      UPDATE student_fee_assignments 
      SET paid_amount = ?, status = ? 
      WHERE id = ?
    `, [newPaidAmount, newStatus, id]);

    // 4. (Optional) Sync with legacy fees table for backward compatibility
    await connection.execute(`
      INSERT INTO fees (student_id, total_fee, paid_amount, due_date)
      VALUES (?, ?, ?, NULL)
      ON DUPLICATE KEY UPDATE paid_amount = paid_amount + ?
    `, [assignment.student_id, assignment.total_amount, amount, amount]);

    await connection.commit();
    res.status(201).json({ 
      message: 'Payment recorded successfully',
      new_paid_amount: newPaidAmount,
      status: newStatus
    });
  } catch (err) {
    if (connection) await connection.rollback();
    console.error('[recordPayment] Error:', err.message);
    res.status(500).json({ error: err.message });
  } finally {
    if (connection) connection.release();
  }
};

// ─── GET /api/fees/reports ────────────────────────────────────────────────────
exports.getFeeReports = async (req, res) => {
  try {
    // 1. Overall Summary
    const [overall] = await db.execute(`
      SELECT 
        COUNT(id) as total_assignments,
        SUM(total_amount) as expected_revenue,
        SUM(paid_amount) as collected_revenue,
        SUM(total_amount - paid_amount) as pending_revenue
      FROM student_fee_assignments
    `);

    // 2. Class-wise Breakdown
    const [classBreakdown] = await db.execute(`
      SELECT 
        c.name AS class_name, 
        c.section AS class_section,
        COUNT(sfa.id) as assignments,
        SUM(sfa.total_amount) as expected,
        SUM(sfa.paid_amount) as collected,
        SUM(sfa.total_amount - sfa.paid_amount) as pending
      FROM student_fee_assignments sfa
      INNER JOIN fee_structures fs ON sfa.fee_structure_id = fs.id
      INNER JOIN classes c ON fs.class_id = c.id
      GROUP BY c.id, c.name, c.section
      ORDER BY c.name, c.section
    `);

    // 3. Status Breakdown
    const [statusBreakdown] = await db.execute(`
      SELECT status, COUNT(*) as count, SUM(total_amount) as amount
      FROM student_fee_assignments
      GROUP BY status
    `);

    res.status(200).json({
      summary: overall[0] || { total_assignments: 0, expected_revenue: 0, collected_revenue: 0, pending_revenue: 0 },
      by_class: classBreakdown,
      by_status: statusBreakdown,
    });
  } catch (err) {
    console.error('[getFeeReports] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// ─── GET /api/fees/insights ───────────────────────────────────────────────────
exports.getFeeInsights = async (req, res) => {
  try {
    const [overall] = await db.execute(`
      SELECT 
        SUM(total_amount) as expected,
        SUM(paid_amount) as collected,
        SUM(total_amount - paid_amount) as pending
      FROM student_fee_assignments
    `);

    const expected = parseFloat(overall[0]?.expected || 0);
    const collected = parseFloat(overall[0]?.collected || 0);
    const pending = parseFloat(overall[0]?.pending || 0);
    const percentage = expected > 0 ? ((collected / expected) * 100).toFixed(1) : 0;

    const [classBreakdown] = await db.execute(`
      SELECT c.name, SUM(sfa.total_amount - sfa.paid_amount) as pending
      FROM student_fee_assignments sfa
      INNER JOIN fee_structures fs ON sfa.fee_structure_id = fs.id
      INNER JOIN classes c ON fs.class_id = c.id
      GROUP BY c.id, c.name
      ORDER BY pending DESC LIMIT 3
    `);

    const classData = classBreakdown.map(c => `${c.name}: ₹${parseFloat(c.pending).toFixed(2)}`).join(', ');

    const systemPrompt = `You are a financial AI assistant for a school ERP. Provide exactly 3 short, actionable bullet points analyzing the fee collection status. Format as a strict markdown list with no bold text and no headers. Keep it brief.`;
    const userPrompt = `Data: Total Expected: ₹${expected.toFixed(2)} | Collected: ₹${collected.toFixed(2)} (${percentage}%) | Pending: ₹${pending.toFixed(2)}. Top classes with pending fees: ${classData || 'None'}.`;

    const nvidiaApiKey = process.env.NVIDIA_API_KEY;
    const nvidiaBaseUrl = process.env.NVIDIA_BASE_URL || 'https://integrate.api.nvidia.com/v1';
    const nvidiaModel = process.env.NVIDIA_MODEL || 'meta/llama-3.1-70b-instruct';

    if (!nvidiaApiKey || nvidiaApiKey === 'your_nvidia_api_key_here') {
       return res.status(200).json({
          insights: "• Collection rate is " + percentage + "%.\n• Focus collection efforts on classes with highest pending amounts.\n• Consider sending automated reminders to parents with overdue fees."
       });
    }

    const response = await fetch(`${nvidiaBaseUrl}/chat/completions`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${nvidiaApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: nvidiaModel,
        messages: [{ role: 'system', content: systemPrompt }, { role: 'user', content: userPrompt }],
        max_tokens: 150,
      }),
    });

    if (!response.ok) throw new Error(await response.text());
    
    const data = await response.json();
    const insights = data.choices?.[0]?.message?.content || "• Collection rate is normal.\n• Monitor pending fees.\n• Send reminders.";

    res.status(200).json({ insights });
  } catch (err) {
    console.error('[getFeeInsights] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};
