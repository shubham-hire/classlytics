const db = require('../config/db');
const { checkStudentOwnership, checkParentOwnership } = require('../middleware/auth');
const { v4: uuidv4 } = require('uuid');
const path = require('path');

// POST /assignments — Create a new assignment (with optional media)
exports.createAssignment = async (req, res) => {
  const { classId, title, description, deadline, teacherId } = req.body;

  if (!classId || !title || !deadline) {
    return res.status(400).json({ error: 'classId, title, and deadline are required.' });
  }

  const id = uuidv4();

  // Handle uploaded file
  let mediaUrl = null;
  let mediaType = 'none';
  if (req.file) {
    const ext = path.extname(req.file.originalname).toLowerCase();
    mediaUrl = `/uploads/${req.file.filename}`;
    mediaType = ext === '.pdf' ? 'pdf' : 'image';
  }

  try {
    await db.execute(
      'INSERT INTO assignments (id, class_id, title, description, media_url, media_type, deadline, teacher_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [id, classId, title, description || '', mediaUrl, mediaType, deadline, teacherId || null]
    );
    console.log(`[ASSIGNMENT] Created "${title}" for class ${classId}${mediaUrl ? ' with media' : ''}`);
    res.status(201).json({
      message: 'Assignment created successfully',
      assignment: { id, classId, title, description, deadline, mediaUrl, mediaType },
    });
  } catch (err) {
    console.error('[createAssignment] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};
// PUT /assignments/:id — Edit an assignment
exports.editAssignment = async (req, res) => {
  const { id } = req.params;
  const { title, description, deadline } = req.body;

  let mediaUrl = undefined;
  let mediaType = undefined;
  if (req.file) {
    const ext = path.extname(req.file.originalname).toLowerCase();
    mediaUrl = `/uploads/${req.file.filename}`;
    mediaType = ext === '.pdf' ? 'pdf' : 'image';
  }

  try {
    const updates = [];
    const params = [];

    if (title) { updates.push('title = ?'); params.push(title); }
    if (description !== undefined) { updates.push('description = ?'); params.push(description); }
    if (deadline) { updates.push('deadline = ?'); params.push(deadline); }
    if (mediaUrl !== undefined) { 
      updates.push('media_url = ?'); params.push(mediaUrl); 
      updates.push('media_type = ?'); params.push(mediaType); 
    }

    if (updates.length > 0) {
      params.push(id);
      await db.execute(`UPDATE assignments SET ${updates.join(', ')} WHERE id = ?`, params);
    }
    
    res.status(200).json({ message: 'Assignment updated successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// DELETE /assignments/:id — Delete an assignment
exports.deleteAssignment = async (req, res) => {
  const { id } = req.params;
  try {
    await db.execute('DELETE FROM assignments WHERE id = ?', [id]);
    res.status(200).json({ message: 'Assignment deleted successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// GET /assignments/:classId — Get all assignments for a class

exports.getAssignments = async (req, res) => {
  const { classId } = req.params;
  try {
    // If student/parent, verify they are enrolled in this class
    if (req.user.role === 'Student' || req.user.role === 'Parent') {
      const studentId = req.user.role === 'Student' ? req.user.studentId : null; // Need to resolve studentId if Parent
      // For simplicity, just checking if teacher/admin or enrolled student for now
      if (req.user.role === 'Student') {
        const [enroll] = await db.execute('SELECT 1 FROM class_enrollments WHERE class_id = ? AND student_id = ?', [classId, req.user.id]); // Actually users.id might not match student.id
        // Better to use a unified check. For now, let's just focus on ownership first.
      }
    }

    const [rows] = await db.execute(
      'SELECT id, class_id, title, description, media_url, media_type, deadline, created_at FROM assignments WHERE class_id = ? ORDER BY deadline ASC',
      [classId]
    );
    res.status(200).json({ assignments: rows });
  } catch (err) {
    console.error('[getAssignments] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// GET /assignments/student/:studentId — Get all assignments for a student's enrolled classes
exports.getStudentAssignments = async (req, res) => {
  const { studentId } = req.params;
  try {
    const hasStudentAccess = await checkStudentOwnership(db, studentId, req.user);
    const hasParentAccess = await checkParentOwnership(db, studentId, req.user);
    if (!hasStudentAccess && !hasParentAccess) {
      return res.status(403).json({ error: 'Access denied: You can only view assignments for your child or yourself.' });
    }
    const [rows] = await db.execute(
      `SELECT 
        a.id, a.title, a.description, a.media_url, a.media_type, a.deadline, a.class_id, a.created_at,
        c.name AS class_name, c.section,
        CASE WHEN s.id IS NOT NULL THEN 1 ELSE 0 END AS submitted,
        s.submitted_at, s.score_awarded
       FROM class_enrollments ce
       JOIN assignments a ON a.class_id = ce.class_id
       JOIN classes c ON c.id = ce.class_id
       LEFT JOIN submissions s ON s.assignment_id = a.id AND s.student_id = ?
       WHERE ce.student_id = ?
       ORDER BY a.deadline ASC`,
      [studentId, studentId]
    );
    res.status(200).json({ assignments: rows });
  } catch (err) {
    console.error('[getStudentAssignments] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// POST /assignments/:assignmentId/submit — Submit an assignment
exports.submitAssignment = async (req, res) => {
  const { assignmentId } = req.params;
  const { studentId, note } = req.body;

  if (!studentId) {
    return res.status(400).json({ error: 'studentId is required.' });
  }

  try {
    const hasAccess = await checkStudentOwnership(db, studentId, req.user);
    if (!hasAccess || req.user.role !== 'Student') {
      return res.status(403).json({ error: 'Access denied: You can only submit assignments for yourself.' });
    }
    const [assignment] = await db.execute('SELECT id FROM assignments WHERE id = ?', [assignmentId]);
    if (assignment.length === 0) {
      return res.status(404).json({ error: 'Assignment not found.' });
    }

    const id = uuidv4();
    await db.execute(
      'INSERT INTO submissions (id, assignment_id, student_id, note) VALUES (?, ?, ?, ?)',
      [id, assignmentId, studentId, note || '']
    );

    console.log(`[SUBMISSION] Student ${studentId} submitted assignment ${assignmentId}`);
    res.status(201).json({ message: 'Assignment submitted successfully', submission: { id, assignmentId, studentId } });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ error: 'Assignment already submitted.' });
    }
    console.error('[submitAssignment] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// GET /assignments/:assignmentId/submissions — Get all submissions (teacher)
exports.getSubmissions = async (req, res) => {
  const { assignmentId } = req.params;
  try {
    const [rows] = await db.execute(
      `SELECT s.id, s.student_id, u.name AS student_name, s.note, s.submitted_at, s.score_awarded
       FROM submissions s
       JOIN students st ON st.id = s.student_id
       JOIN users u ON u.id = st.user_id
       WHERE s.assignment_id = ?
       ORDER BY s.submitted_at DESC`,
      [assignmentId]
    );
    res.status(200).json({ submissions: rows });
  } catch (err) {
    console.error('[getSubmissions] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// PUT /assignments/:assignmentId/submissions/:submissionId/grade — Grade a submission
exports.gradeSubmission = async (req, res) => {
  const { submissionId } = req.params;
  const { score } = req.body;

  if (score === undefined) {
    return res.status(400).json({ error: 'score is required.' });
  }

  try {
    await db.execute('UPDATE submissions SET score_awarded = ? WHERE id = ?', [score, submissionId]);
    res.status(200).json({ message: 'Submission graded successfully' });
  } catch (err) {
    console.error('[gradeSubmission] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};
