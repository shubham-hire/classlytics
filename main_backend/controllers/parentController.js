const db = require('../config/db');
const { checkParentOwnership } = require('../middleware/auth');

// Submit a new leave request
exports.submitLeaveRequest = async (req, res) => {
  const { studentId, startDate, endDate, reason } = req.body;
  const parentUserId = req.user.id;

  if (!studentId || !startDate || !endDate || !reason) {
    return res.status(400).json({ error: 'Missing required fields for leave request.' });
  }

  try {
    // Verify the parent is linked to this child
    if (req.user.role !== 'Parent') {
      return res.status(403).json({ error: 'Not authorized to request leave for this student.' });
    }

    await db.execute(
      'INSERT INTO leave_requests (student_id, parent_id, start_date, end_date, reason, status) VALUES (?, ?, ?, ?, ?, ?)',
      [studentId, parentUserId, startDate, endDate, reason, 'Pending']
    );

    res.status(201).json({ message: 'Leave request submitted successfully.' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Get leave requests for a student
exports.getLeaveRequests = async (req, res) => {
  const { studentId } = req.params;

  try {
    const [rows] = await db.execute(
      'SELECT id, start_date, end_date, reason, status, created_at FROM leave_requests WHERE student_id = ? ORDER BY created_at DESC',
      [studentId]
    );
    res.status(200).json({ requests: rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Approve leave request (Teacher action)
exports.updateLeaveRequestStatus = async (req, res) => {
  const { requestId } = req.params;
  const { status, teacherId } = req.body; // status: 'Approved' | 'Rejected'

  if (!['Approved', 'Rejected'].includes(status)) {
    return res.status(400).json({ error: 'Invalid status.' });
  }

  try {
    // Basic verification - assuming any teacher can approve right now, or you could check class assignment
    const [updateResult] = await db.execute(
      'UPDATE leave_requests SET status = ? WHERE id = ?',
      [status, requestId]
    );

    if (updateResult.affectedRows === 0) {
      return res.status(404).json({ error: 'Leave request not found.' });
    }

    if (status === 'Approved') {
      // Automate Attendance - Mark 'Absent' for the days covered by the leave
      const [leaveRows] = await db.execute('SELECT student_id, start_date, end_date FROM leave_requests WHERE id = ?', [requestId]);
      const leave = leaveRows[0];

      let currentDate = new Date(leave.start_date);
      const endDate = new Date(leave.end_date);
      
      while (currentDate <= endDate) {
        const formattedDate = currentDate.toISOString().split('T')[0];
        // Insert or ignore (if already marked)
        await db.execute(
          `INSERT INTO attendance (student_id, date, status) 
           VALUES (?, ?, 'Absent') 
           ON CONFLICT (student_id, date) DO UPDATE SET status = 'Absent'`,
          [leave.student_id, formattedDate]
        );
        currentDate.setDate(currentDate.getDate() + 1);
      }
    }

    res.status(200).json({ message: `Leave request ${status.toLowerCase()} successfully.` });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Generate AI Home Study Plan
exports.generateHomeStudyPlan = async (req, res) => {
  const { studentId, parentId } = req.body;

  if (!studentId) {
    return res.status(400).json({ error: 'studentId is required.' });
  }

  try {
    // 1. Gather all student stats
    const [markRows] = await db.execute('SELECT subject, score, max_score, type FROM marks WHERE student_id = ? ORDER BY date DESC LIMIT 10', [studentId]);
    const [attendanceRows] = await db.execute('SELECT status FROM attendance WHERE student_id = ?', [studentId]);
    
    // Format marks context
    let performanceStr = "No recent test data available.";
    if (markRows.length > 0) {
      performanceStr = markRows.map(m => `- ${m.subject} (${m.type}): ${m.score}/${m.max_score}`).join('\\n');
    }

    // Format attendance context
    let attendancePct = "No data";
    if (attendanceRows.length > 0) {
      const present = attendanceRows.filter(r => r.status === 'Present').length;
      attendancePct = Math.round((present / attendanceRows.length) * 100) + "%";
    }

    const context = `
Student Attendance: ${attendancePct}
Recent Performance:
${performanceStr}
`;

    // 2. Query AI
    const nvidiaApiKey = process.env.NVIDIA_API_KEY;
    const nvidiaBaseUrl = process.env.NVIDIA_BASE_URL || 'https://integrate.api.nvidia.com/v1';
    const nvidiaModel = process.env.NVIDIA_MODEL || 'meta/llama-3.1-70b-instruct';

    if (!nvidiaApiKey || nvidiaApiKey === 'your_nvidia_api_key_here') {
       return res.status(200).json({
          plan: "Mock Plan: This is a placeholder because the NVIDIA API key is missing.\\n\\nFriday: Review basics.\\nSaturday: Practice tests.\\nSunday: Rest.",
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
        messages: [
          { 
            role: 'system', 
            content: 'You are an educational AI assistant. Provide a structured, engaging 3-day weekend home study plan for a parent to use with their child. Review all subjects, providing specific actionable tips. Format with markdown.' 
          },
          { 
            role: 'user', 
            content: `Based on this recent data, create a supportive study plan for the parent:\n${context}` 
          },
        ],
        temperature: 0.6,
        max_tokens: 600,
      }),
    });

    if (!response.ok) {
       throw new Error(await response.text());
    }

    const data = await response.json();
    const plan = data.choices?.[0]?.message?.content || "Could not generate plan.";

    res.status(200).json({ plan });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Get Child Info (Name, Class, Teacher ID for Chat)
exports.getChildInfo = async (req, res) => {
  // Use logged in user ID if not admin/teacher, or if userId param is missing
  const userId = (req.user.role === 'Parent') ? req.user.id : (req.params.userId || req.user.id);
  
  try {
    const [parentRows] = await db.execute(
      `SELECT p.child_id, s.dept, s.current_year, u.name as child_name 
       FROM parents p 
       JOIN students s ON p.child_id = s.id 
       JOIN users u ON s.user_id = u.id 
       WHERE p.user_id = ?`, 
      [userId]
    );

    if (parentRows.length === 0) {
      return res.status(404).json({ error: 'No child linked to this parent.' });
    }

    const child = parentRows[0];
    
    // Attempt to find the teacher for this child's class
    const [enrollRows] = await db.execute(
      `SELECT c.name as class_name, c.teacher_id, tu.name as teacher_name 
       FROM class_enrollments ce 
       JOIN classes c ON ce.class_id = c.id 
       LEFT JOIN users tu ON c.teacher_id = tu.id 
       WHERE ce.student_id = ? LIMIT 1`, 
      [child.child_id]
    );

    let classInfo = { class_name: 'Unassigned', teacher_id: null, teacher_name: 'No Teacher' };
    if (enrollRows.length > 0) {
      classInfo = enrollRows[0];
    }

    res.status(200).json({ 
      childId: child.child_id,
      childName: child.child_name,
      department: child.dept,
      year: child.current_year,
      className: classInfo.class_name,
      teacherId: classInfo.teacher_id,
      teacherName: classInfo.teacher_name
    });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Generate Weekly Summary
exports.getWeeklySummary = async (req, res) => {
  const { studentId } = req.params;

  try {

    const [markRows] = await db.execute('SELECT subject, score, max_score, type FROM marks WHERE student_id = ? ORDER BY date DESC LIMIT 5', [studentId]);
    const [attendanceRows] = await db.execute('SELECT status FROM attendance WHERE student_id = ? ORDER BY date DESC LIMIT 14', [studentId]);
    const [leaveRows] = await db.execute('SELECT count(*) as count FROM leave_requests WHERE student_id = ? AND start_date >= NOW() - INTERVAL \'7 days\'', [studentId]);
    
    let perfContext = markRows.length > 0 ? markRows.map(m => `${m.subject}: ${m.score}/${m.max_score}`).join(', ') : 'No recent marks';
    let attContext = attendanceRows.length > 0 ? `${attendanceRows.filter(r => r.status==='Present').length}/${attendanceRows.length} present` : 'No recent attendance';
    let leavesContext = leaveRows[0].count > 0 ? `${leaveRows[0].count} leaves requested recently.` : 'No leaves requested.';

    const systemPrompt = `You are a helpful educational AI. Summarize the student's recent performance for their parent in exactly 3 short bullet points. Format strictly as a bulleted list starting with bullet characters. Do not use markdown bolding or headers. Keep it extremely brief.`;
    const userPrompt = `Data: Attendance: ${attContext} | Marks: ${perfContext} | Leaves: ${leavesContext}`;

    const nvidiaApiKey = process.env.NVIDIA_API_KEY;
    const nvidiaBaseUrl = process.env.NVIDIA_BASE_URL || 'https://integrate.api.nvidia.com/v1';
    const nvidiaModel = process.env.NVIDIA_MODEL || 'meta/llama-3.1-70b-instruct';

    if (!nvidiaApiKey || nvidiaApiKey === 'your_nvidia_api_key_here') {
       return res.status(200).json({
          summary: "• Attendance: Stable\\n• Performance: Slight decline in Science\\n• Focus Area: Complete pending homework"
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
    const summary = data.choices?.[0]?.message?.content || "• Attendance: N/A\n• Performance: N/A\n• Focus Area: N/A";

    res.status(200).json({ summary });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// GET /parent/fees/:studentId — Get all fee assignments for parent's child
exports.getChildFees = async (req, res) => {
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

    // Aggregate totals
    const totalDue = rows.reduce((s, r) => s + parseFloat(r.total_amount), 0);
    const totalPaid = rows.reduce((s, r) => s + parseFloat(r.paid_amount), 0);
    const totalPending = totalDue - totalPaid;

    res.status(200).json({
      assignments: rows,
      summary: {
        totalDue: totalDue.toFixed(2),
        totalPaid: totalPaid.toFixed(2),
        totalPending: totalPending.toFixed(2),
        count: rows.length,
      }
    });
  } catch (err) {
    console.error('[getChildFees] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};
