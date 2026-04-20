/**
 * studentService.js
 * Fetches rich student context from the DB for building AI prompts.
 * The studentId here is the numeric primary key in the `students` table.
 *
 * Student mention format in chat: @STD005
 * To resolve the mention to a DB row we query students.id LIKE '%005'
 * OR we try matching by the user_id via a loose LIKE. The caller is
 * responsible for numeric resolution when needed.
 */

const db = require('../config/db');

/**
 * Resolve a mention string (e.g. "STD005") to a numeric student.id.
 * Tries an exact suffix match on zero-padded IDs, then falls back to
 * matching the numeric portion against students.id directly.
 * @param {string} mentionId  e.g. "STD005"
 * @returns {Promise<number|null>}
 */
/**
 * Resolve a mention string to a student.id string.
 * Accepts @STU001, @STD001 etc. (case-insensitive).
 * Tries an exact match first, then a LIKE suffix match.
 * @param {string} mentionId  e.g. "STU001" or "STD001"
 * @returns {Promise<string|null>}
 */
async function resolveStudentId(mentionId) {
  // Normalise to STU prefix regardless of whether user typed STD or STU
  const numericPart = mentionId.replace(/^(STU|STD)/i, '').padStart(3, '0');
  const stuId = `STU${numericPart}`;

  // Direct match
  const [rows] = await db.execute('SELECT id FROM students WHERE id = ?', [stuId]);
  if (rows.length > 0) return rows[0].id;

  // Fallback: suffix LIKE match (handles any padding variant)
  const [likeRows] = await db.execute(
    `SELECT id FROM students WHERE id LIKE ? LIMIT 1`,
    [`%${numericPart}`]
  );
  if (likeRows.length > 0) return likeRows[0].id;

  return null;
}

/**
 * Builds a rich context object for a given student (numeric DB id).
 * @param {number} studentId
 * @returns {Promise<object|null>}
 */
async function getStudentContext(studentId) {
  try {
    // Profile
    const [profileRows] = await db.execute(
      `SELECT u.name, u.role, s.dept, s.current_year, s.id AS student_id
       FROM students s
       JOIN users u ON s.user_id = u.id
       WHERE s.id = ?`,
      [studentId]
    );
    if (profileRows.length === 0) return null;
    const profile = profileRows[0];

    // Attendance
    const [attRows] = await db.execute(
      `SELECT status FROM attendance WHERE student_id = ?`,
      [studentId]
    );
    let attendancePct = null;
    if (attRows.length > 0) {
      const present = attRows.filter(r => r.status === 'Present').length;
      attendancePct = Math.round((present / attRows.length) * 100);
    }

    // Marks (last 10 records)
    const [markRows] = await db.execute(
      `SELECT subject, score, max_score, type, date
       FROM marks
       WHERE student_id = ?
       ORDER BY date DESC LIMIT 10`,
      [studentId]
    );
    const avgScore =
      markRows.length > 0
        ? Math.round(
            markRows.reduce((s, m) => s + (m.score / m.max_score) * 100, 0) /
              markRows.length
          )
        : null;
    const weakSubjects = [
      ...new Set(
        markRows
          .filter(m => (m.score / m.max_score) * 100 < 50)
          .map(m => m.subject)
      ),
    ];

    // Pending Assignments
    const [assignRows] = await db.execute(
      `SELECT a.title, a.deadline,
              (SELECT COUNT(*) FROM submissions s WHERE s.assignment_id = a.id AND s.student_id = ?) AS submitted
       FROM assignments a
       JOIN class_enrollments ce ON ce.class_id = a.class_id AND ce.student_id = ?
       WHERE a.deadline > NOW()
       ORDER BY a.deadline ASC LIMIT 5`,
      [studentId, studentId]
    );
    const pendingAssignments = assignRows.filter(a => a.submitted === 0);

    return {
      profile,
      attendancePct,
      avgScore,
      recentMarks: markRows.slice(0, 5),
      weakSubjects,
      pendingAssignments,
    };
  } catch (err) {
    console.error('[StudentService] Error fetching context:', err.message);
    return null;
  }
}

module.exports = { resolveStudentId, getStudentContext };
