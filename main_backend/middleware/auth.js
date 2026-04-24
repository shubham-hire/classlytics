const jwt = require('jsonwebtoken');

// ─── Verify JWT Token ──────────────────────────────────────────────────────
exports.verifyToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.startsWith('Bearer ') 
    ? authHeader.split(' ')[1] 
    : null;

  if (!token) {
    return res.status(401).json({ error: 'Access denied. No token provided.' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded; // { id, name, email, role }
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token expired. Please log in again.' });
    }
    return res.status(403).json({ error: 'Invalid token.' });
  }
};

// ─── Require a specific role ───────────────────────────────────────────────
exports.requireRole = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ error: 'Not authenticated.' });
    }
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ 
        error: `Access forbidden. Required role: ${roles.join(' or ')}. Your role: ${req.user.role}` 
      });
    }
    next();
  };
};

// ─── Check if student can access a resource ──────────────────────────────
// Allows Admin, Teacher, the Student themselves, or their Parent.
exports.checkStudentOwnership = async (db, studentId, requester) => {
  if (requester.role === 'Admin' || requester.role === 'Teacher') {
    return true; // Staff can see all
  }
  
  if (requester.role === 'Student') {
    const [studentRow] = await db.execute('SELECT user_id FROM students WHERE id = ?', [studentId]);
    return studentRow.length > 0 && studentRow[0].user_id === requester.id;
  }

  if (requester.role === 'Parent') {
    // Check 'parents' junction table
    const [parentRow] = await db.execute(
      'SELECT id FROM parents WHERE user_id = ? AND child_id = ?', 
      [requester.id, studentId]
    );
    if (parentRow.length > 0) return true;

    // Fallback: check students table for parent_id link
    const [studentRow] = await db.execute('SELECT parent_id FROM students WHERE id = ?', [studentId]);
    if (studentRow.length > 0 && studentRow[0].parent_id) {
      const parentId = studentRow[0].parent_id;
      const [parentRecord] = await db.execute('SELECT user_id FROM parents WHERE id = ?', [parentId]);
      return parentRecord.length > 0 && parentRecord[0].user_id === requester.id;
    }
  }

  return false;
};

// ─── Check if parent can access a student's resource ──────────────────────
// (Kept for backwards compatibility if needed, but checkStudentOwnership is now more general)
exports.checkParentOwnership = exports.checkStudentOwnership;

// ─── Middleware: Verify Ownership ─────────────────────────────────────────
// Extracts studentId from params or body, then verifies if the requester
// (Student or Parent) has access to that specific student's records.
exports.verifyOwnership = (db) => {
  return async (req, res, next) => {
    const studentId = req.params.studentId || req.body.studentId;
    
    if (!studentId) {
      return res.status(400).json({ error: 'Missing studentId for ownership verification.' });
    }

    try {
      const hasAccess = await exports.checkStudentOwnership(db, studentId, req.user);
      if (!hasAccess) {
        return res.status(403).json({ error: 'Access denied: You do not have permission to access records for this student.' });
      }
      next();
    } catch (err) {
      res.status(500).json({ error: 'Security verification failed: ' + err.message });
    }
  };
};

// ─── Deprecated Middlewares (kept for route compatibility) ────────────────
exports.verifyParentOwnership = exports.verifyOwnership;
exports.verifyStudentOwnership = exports.verifyOwnership;
