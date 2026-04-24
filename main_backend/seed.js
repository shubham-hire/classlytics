/**
 * ============================================================
 * Classlytics — Comprehensive Database Seed Script
 * ============================================================
 * Seeds a complete, realistic dataset:
 *  - 2 Teachers (with profiles)
 *  - 3 Classes (2 assigned, 1 unassigned)
 *  - 10 Students (with full profiles, global sequences, DOBs)
 *  - Class enrollments (students split across classes)
 *  - 60 Attendance records (varied Present/Absent/Late)
 *  - 30 Marks records (multiple subjects, types)
 *  - 5 Assignments (with deadlines spanning past/future)
 *  - 8 Submissions (mix of submitted/not)
 *  - 10 Behavior logs
 *  - 5 Messages (teacher → student and vice versa)
 *  - 4 Announcements
 *  - Fee records for all students
 *
 * Usage:
 *   node seed.js           — Seeds fresh (skips if data exists)
 *   node seed.js --clean   — Drops all rows first, then re-seeds
 * ============================================================
 */

require('dotenv').config();
const db = require('./config/db');
const { v4: uuidv4 } = require('uuid');

const CLEAN = process.argv.includes('--clean');

// ─── Colour helpers ──────────────────────────────────────────
const c = {
  green:  (s) => `\x1b[32m${s}\x1b[0m`,
  yellow: (s) => `\x1b[33m${s}\x1b[0m`,
  blue:   (s) => `\x1b[34m${s}\x1b[0m`,
  cyan:   (s) => `\x1b[36m${s}\x1b[0m`,
  red:    (s) => `\x1b[31m${s}\x1b[0m`,
  bold:   (s) => `\x1b[1m${s}\x1b[0m`,
  dim:    (s) => `\x1b[2m${s}\x1b[0m`,
};

function log(icon, msg) { console.log(`  ${icon}  ${msg}`); }
function ok(msg)        { log(c.green('✓'), msg); }
function info(msg)      { log(c.blue('→'), msg); }
function warn(msg)      { log(c.yellow('!'), msg); }
function section(msg)   { console.log(`\n${c.bold(c.cyan(`── ${msg} ──`))}`); }

// ─── Helpers ─────────────────────────────────────────────────
const dateOffset = (days) => {
  const d = new Date();
  d.setDate(d.getDate() + days);
  return d.toISOString().split('T')[0];
};

const datetimeOffset = (days, hour = 23, minute = 59) => {
  const d = new Date();
  d.setDate(d.getDate() + days);
  return `${d.toISOString().split('T')[0]} ${String(hour).padStart(2,'0')}:${String(minute).padStart(2,'0')}:00`;
};

const randBetween = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;

// ─── Static IDs (predictable, easy to remember) ──────────────
const IDs = {
  // Admin
  adminUser: 'uid-admin-001',
  // Teachers
  teacherUser1: 'uid-teacher-001',
  teacherUser2: 'uid-teacher-002',
  // Classes
  class1: 'cls-10a',
  class2: 'cls-11b',
  class3: 'cls-12c',
  // Students (user IDs)
  studentUsers: Array.from({ length: 10 }, (_, i) => `uid-student-${String(i+1).padStart(3,'0')}`),
  // Students (STU IDs)
  studentIds: Array.from({ length: 10 }, (_, i) => `STU${String(i+1).padStart(3,'0')}`),
  // Parent
  parentUser: 'uid-parent-001',
  parentId: 'PAR001',
};

const ADMIN = {
  userId: IDs.adminUser, name: 'System Admin', email: 'admin@test.com',
  password: 'password123', role: 'Admin', phone: '+91 0000000000',
};

const TEACHERS = [
  {
    userId: IDs.teacherUser1, name: 'Rajesh Kumar', email: 'teacher@test.com',
    password: 'password123', dept: 'Science', phone: '+91 9876543210',
    role: 'Teacher',
  },
  {
    userId: IDs.teacherUser2, name: 'Priya Menon', email: 'teacher2@test.com',
    password: 'password123', dept: 'Mathematics', phone: '+91 8765432109',
    role: 'Teacher',
  },
];

const CLASSES = [
  { id: IDs.class1, name: 'Class 10', section: 'A', teacherId: IDs.teacherUser1 },
  { id: IDs.class2, name: 'Class 11', section: 'B', teacherId: IDs.teacherUser2 },
  { id: IDs.class3, name: 'Class 12', section: 'C', teacherId: null },
];

const STUDENTS = [
  { name: 'Rahul Sharma',   email: 'student@test.com',     dept: 'Science',     year: '10th Grade', dob: '2006-03-15', classIdx: 0, roll: 1 },
  { name: 'Sneha Patel',    email: 'sneha@test.com',        dept: 'Science',     year: '10th Grade', dob: '2006-07-22', classIdx: 0, roll: 2 },
  { name: 'Arjun Nair',     email: 'arjun@test.com',        dept: 'Science',     year: '10th Grade', dob: '2006-01-10', classIdx: 0, roll: 3 },
  { name: 'Meera Iyer',     email: 'meera@test.com',        dept: 'Commerce',    year: '10th Grade', dob: '2006-09-05', classIdx: 0, roll: 4 },
  { name: 'Vikram Singh',   email: 'vikram@test.com',       dept: 'Science',     year: '10th Grade', dob: '2005-12-30', classIdx: 0, roll: 5 },
  { name: 'Kavya Reddy',    email: 'kavya@test.com',        dept: 'Arts',        year: '11th Grade', dob: '2005-05-18', classIdx: 1, roll: 1 },
  { name: 'Rohan Mehta',    email: 'rohan@test.com',        dept: 'Mathematics', year: '11th Grade', dob: '2005-08-25', classIdx: 1, roll: 2 },
  { name: 'Divya Krishnan', email: 'divya@test.com',        dept: 'Science',     year: '11th Grade', dob: '2005-02-14', classIdx: 1, roll: 3 },
  { name: 'Aditya Joshi',   email: 'aditya@test.com',       dept: 'Commerce',    year: '11th Grade', dob: '2005-11-07', classIdx: 1, roll: 4 },
  { name: 'Pooja Desai',    email: 'pooja@test.com',        dept: 'Arts',        year: '11th Grade', dob: '2005-06-28', classIdx: 1, roll: 5 },
];

const PARENTS = [
  {
    userId: IDs.parentUser,
    parentId: IDs.parentId,
    name: 'Vikram Sharma',
    email: 'parent@test.com',
    password: 'password123',
    role: 'Parent',
    phone: '+91 9123456780',
    occupation: 'Software Engineer',
    childId: IDs.studentIds[0], // Linked to Rahul Sharma (STU001)
  },
];

// Subjects per class
const SUBJECTS_10 = ['Mathematics', 'Physics', 'Chemistry', 'Biology', 'English'];
const SUBJECTS_11 = ['Mathematics', 'Physics', 'Computer Science', 'English', 'PE'];

// Assignment data
const ASSIGNMENTS = [
  { classIdx: 0, teacherId: IDs.teacherUser1, title: 'Algebra Worksheet — Quadratic Equations',  description: 'Solve all 20 problems from Chapter 4. Show all working steps.', deadlineDays: -5 },
  { classIdx: 0, teacherId: IDs.teacherUser1, title: 'Physics Practicals Report',                 description: 'Write a detailed report on the refraction experiment conducted in lab.', deadlineDays: 3 },
  { classIdx: 0, teacherId: IDs.teacherUser1, title: 'Chemistry: Periodic Table Quiz Prep',       description: 'Memorise Groups 1-18 elements and their symbols for the upcoming quiz.', deadlineDays: 7 },
  { classIdx: 1, teacherId: IDs.teacherUser2, title: 'Integration Practice Set — Calculus',       description: 'Complete exercise set 5.3 from the textbook. 15 problems total.', deadlineDays: -2 },
  { classIdx: 1, teacherId: IDs.teacherUser2, title: 'Programming Assignment: Sorting Algorithms', description: 'Implement Bubble Sort, Merge Sort and Quick Sort in Python. Include time complexity analysis.', deadlineDays: 10 },
];

// Marks templates — (subject, score, type, daysAgo)
const MARKS_TEMPLATES = [
  ['Mathematics', 72, 'Quiz',     -30],
  ['Mathematics', 68, 'Midterm',  -45],
  ['Physics',     81, 'Quiz',     -20],
  ['Chemistry',   55, 'Quiz',     -15],
  ['English',     90, 'Final',    -60],
  ['Mathematics', 78, 'Quiz',     -10],
  ['Physics',     65, 'Midterm',  -50],
  ['Biology',     88, 'Quiz',     -25],
];

// ─── Clean function ───────────────────────────────────────────
async function cleanDatabase() {
  section('Cleaning existing seed data');
  const tables = [
    'fees', 'submissions', 'assignments', 'behavior_logs',
    'messages', 'announcements', 'marks', 'attendance',
    'class_enrollments', 'parents', 'students', 'classes',
    'global_sequences',
  ];
  // Only delete users that are part of our seed (teachers + students)
  const seedEmails = [
    ADMIN.email,
    ...TEACHERS.map(t => t.email),
    ...STUDENTS.map(s => s.email),
    ...PARENTS.map(p => p.email),
  ];

  for (const table of tables) {
    try {
      await db.execute(`DELETE FROM \`${table}\``);
      ok(`Cleared table: ${table}`);
    } catch (e) {
      warn(`Could not clear ${table}: ${e.message}`);
    }
  }

  try {
    const emailPlaceholders = seedEmails.map(() => '?').join(',');
    await db.execute(`DELETE FROM users WHERE email IN (${emailPlaceholders})`, seedEmails);
    ok('Cleared seed users from users table');
  } catch (e) {
    warn(`Could not clean users: ${e.message}`);
  }
}

// ─── Main seed function ───────────────────────────────────────
async function seed() {
  console.log(c.bold('\n╔══════════════════════════════════════════╗'));
  console.log(c.bold('║   Classlytics — Database Seed Script     ║'));
  console.log(c.bold('╚══════════════════════════════════════════╝\n'));

  if (CLEAN) {
    await cleanDatabase();
  }

  // ─── 1. Global Sequences ─────────────────────────────────
  section('Global Sequences');
  try {
    await db.execute(`INSERT IGNORE INTO global_sequences (name, \`last_value\`) VALUES ('student', ${STUDENTS.length})`);
    await db.execute(`UPDATE global_sequences SET \`last_value\` = ${STUDENTS.length} WHERE name = 'student'`);
    ok(`Sequence seeded → student = ${STUDENTS.length}`);
  } catch (e) {
    warn(`Sequences: ${e.message}`);
  }

  // ─── 1.5 Admin ──────────────────────────────────────────
  section('Admin');
  try {
    await db.execute(
      'INSERT IGNORE INTO users (id, name, email, password, role, phone) VALUES (?, ?, ?, ?, ?, ?)',
      [ADMIN.userId, ADMIN.name, ADMIN.email, ADMIN.password, ADMIN.role, ADMIN.phone]
    );
    ok(`Admin: ${ADMIN.name} (${ADMIN.email})`);
  } catch (e) {
    warn(`Admin: ${e.message}`);
  }

  // ─── 2. Teachers ─────────────────────────────────────────
  section('Teachers');
  for (const t of TEACHERS) {
    try {
      await db.execute(
        'INSERT IGNORE INTO users (id, name, email, password, role, phone, dept) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [t.userId, t.name, t.email, t.password, t.role, t.phone, t.dept]
      );
      ok(`Teacher: ${t.name} (${t.email})`);
    } catch (e) {
      warn(`Teacher ${t.name}: ${e.message}`);
    }
  }

  // ─── 3. Classes ──────────────────────────────────────────
  section('Classes');
  for (const cls of CLASSES) {
    try {
      await db.execute(
        'INSERT IGNORE INTO classes (id, name, section, teacher_id) VALUES (?, ?, ?, ?)',
        [cls.id, cls.name, cls.section, cls.teacherId]
      );
      ok(`Class: ${cls.name}-${cls.section} ${cls.teacherId ? `(${cls.teacherId === IDs.teacherUser1 ? 'Rajesh Kumar' : 'Priya Menon'})` : '(unassigned)'}`);
    } catch (e) {
      warn(`Class ${cls.name}: ${e.message}`);
    }
  }

  // ─── 4. Students ─────────────────────────────────────────
  section('Students');
  for (let i = 0; i < STUDENTS.length; i++) {
    const s = STUDENTS[i];
    const userId = IDs.studentUsers[i];
    const studentId = IDs.studentIds[i];
    const classId = CLASSES[s.classIdx].id;

    try {
      await db.execute(
        'INSERT IGNORE INTO users (id, name, email, password, role, phone) VALUES (?, ?, ?, ?, ?, ?)',
        [userId, s.name, s.email, 'password123', 'Student', `+91 900000${String(i+1).padStart(4,'0')}`]
      );
      await db.execute(
        'INSERT IGNORE INTO students (id, user_id, dept, current_year, dob) VALUES (?, ?, ?, ?, ?)',
        [studentId, userId, s.dept, s.year, s.dob]
      );
      await db.execute(
        'INSERT IGNORE INTO class_enrollments (class_id, student_id, roll_no) VALUES (?, ?, ?)',
        [classId, studentId, s.roll]
      );
      ok(`Student: ${s.name} → ${studentId} in ${CLASSES[s.classIdx].name}-${CLASSES[s.classIdx].section} [Roll: ${s.roll}]`);
    } catch (e) {
      warn(`Student ${s.name}: ${e.message}`);
    }
  }

  // ─── 4.5 Parents ─────────────────────────────────────────
  section('Parents');
  for (const p of PARENTS) {
    try {
      await db.execute(
        'INSERT IGNORE INTO users (id, name, email, password, role, phone) VALUES (?, ?, ?, ?, ?, ?)',
        [p.userId, p.name, p.email, p.password, p.role, p.phone]
      );
      await db.execute(
        'INSERT IGNORE INTO parents (id, user_id, child_id, occupation) VALUES (?, ?, ?, ?)',
        [p.parentId, p.userId, p.childId, p.occupation]
      );
      ok(`Parent: ${p.name} (${p.email}) → Child: ${p.childId}`);
    } catch (e) {
      warn(`Parent ${p.name}: ${e.message}`);
    }
  }

  // ─── 5. Attendance ───────────────────────────────────────
  section('Attendance Records');
  const STATUSES = ['Present', 'Present', 'Present', 'Present', 'Absent', 'Late']; // ~67% present
  let attCount = 0;

  for (let i = 0; i < STUDENTS.length; i++) {
    const studentId = IDs.studentIds[i];
    const subjects = i < 5 ? SUBJECTS_10 : SUBJECTS_11;

    // 6 attendance records per student (over past 30 days)
    for (let d = 0; d < 6; d++) {
      const daysAgo = -(d * 5 + randBetween(0, 4)); // scattered past days
      const date = dateOffset(daysAgo);
      // Students 4 & 8 (index 3 & 7) have low attendance
      const adjustedStatuses = (i === 3 || i === 7)
        ? ['Absent', 'Absent', 'Absent', 'Present', 'Absent', 'Late']
        : STATUSES;
      const status = adjustedStatuses[d % adjustedStatuses.length];

      try {
        await db.execute(
          'INSERT IGNORE INTO attendance (student_id, date, status) VALUES (?, ?, ?)',
          [studentId, date, status]
        );
        attCount++;
      } catch (e) { /* skip duplicate */ }
    }
  }
  ok(`${attCount} attendance records seeded`);

  // ─── 6. Marks ────────────────────────────────────────────
  section('Marks / Exam Results');
  let marksCount = 0;
  const maxScores = { 'Quiz': 100, 'Midterm': 100, 'Final': 100, 'Assignment': 50 };

  for (let i = 0; i < STUDENTS.length; i++) {
    const studentId = IDs.studentIds[i];
    const subjects = i < 5 ? SUBJECTS_10 : SUBJECTS_11;

    // 3 marks records per student
    const records = [
      [subjects[0], randBetween(i === 3 ? 20 : 55, 95), 'Quiz',     dateOffset(-10)],
      [subjects[1], randBetween(i === 7 ? 25 : 50, 90), 'Midterm',  dateOffset(-30)],
      [subjects[2], randBetween(60, 100),               'Quiz',     dateOffset(-5)],
    ];

    for (const [subject, score, type, date] of records) {
      try {
        await db.execute(
          'INSERT INTO marks (student_id, subject, score, max_score, type, date) VALUES (?, ?, ?, ?, ?, ?)',
          [studentId, subject, score, maxScores[type] || 100, type, date]
        );
        marksCount++;
      } catch (e) {
        warn(`Marks for ${studentId}: ${e.message}`);
      }
    }
  }
  ok(`${marksCount} marks records seeded`);

  // ─── 7. Assignments ──────────────────────────────────────
  section('Assignments');
  const assignmentIds = [];
  for (const a of ASSIGNMENTS) {
    const id = uuidv4();
    assignmentIds.push(id);
    const classId = CLASSES[a.classIdx].id;

    try {
      await db.execute(
        'INSERT INTO assignments (id, class_id, teacher_id, title, description, deadline) VALUES (?, ?, ?, ?, ?, ?)',
        [id, classId, a.teacherId, a.title, a.description, datetimeOffset(a.deadlineDays)]
      );
      const status = a.deadlineDays < 0 ? c.red('past') : c.green('upcoming');
      ok(`Assignment: "${a.title.substring(0, 40)}..." [${status}]`);
    } catch (e) {
      warn(`Assignment "${a.title}": ${e.message}`);
    }
  }

  // ─── 8. Submissions ──────────────────────────────────────
  section('Submissions');
  // For past assignments (index 0, 3), submit for some students
  const pastAssignments = [
    { aIdx: 0, studentIndices: [0, 1, 2, 4] },  // Class 10-A assignment — 4 students submitted
    { aIdx: 3, studentIndices: [5, 7, 9] },      // Class 11-B assignment — 3 students submitted
  ];
  let subCount = 0;

  for (const { aIdx, studentIndices } of pastAssignments) {
    for (const sIdx of studentIndices) {
      const assignmentId = assignmentIds[aIdx];
      const studentId = IDs.studentIds[sIdx];
      const submissionId = uuidv4();
      const score = randBetween(30, 48); // out of 50

      try {
        await db.execute(
          'INSERT INTO submissions (id, assignment_id, student_id, note, score_awarded) VALUES (?, ?, ?, ?, ?)',
          [submissionId, assignmentId, studentId, 'Submitted on time.', score]
        );
        subCount++;
      } catch (e) {
        warn(`Submission ${studentId}: ${e.message}`);
      }
    }
  }
  ok(`${subCount} submissions seeded (assignment 1 and 4 are past)`);

  // ─── 9. Behavior Logs ────────────────────────────────────
  section('Behavior Logs');
  const BEHAVIOR_LOGS = [
    { sIdx: 0, type: 'Positive', remark: 'Excellent participation in class discussion.' },
    { sIdx: 1, type: 'Positive', remark: 'Helped peers during group project.' },
    { sIdx: 2, type: 'Negative', remark: 'Repeatedly distracted other students during lecture.' },
    { sIdx: 3, type: 'Negative', remark: 'Missing homework for 3 consecutive days.' },
    { sIdx: 3, type: 'Negative', remark: 'Low attendance — parents to be notified.' },
    { sIdx: 4, type: 'Positive', remark: 'Scored highest in class quiz.' },
    { sIdx: 5, type: 'Positive', remark: 'Won inter-class debate competition.' },
    { sIdx: 6, type: 'Negative', remark: 'Late to class without valid reason.' },
    { sIdx: 7, type: 'Negative', remark: 'Incomplete lab report submitted.' },
    { sIdx: 9, type: 'Positive', remark: 'Proactive in volunteering for school events.' },
  ];

  for (const b of BEHAVIOR_LOGS) {
    try {
      await db.execute(
        'INSERT INTO behavior_logs (student_id, type, remark) VALUES (?, ?, ?)',
        [IDs.studentIds[b.sIdx], b.type, b.remark]
      );
    } catch (e) {
      warn(`Behavior log: ${e.message}`);
    }
  }
  ok(`${BEHAVIOR_LOGS.length} behavior logs seeded`);

  // ─── 10. Messages ─────────────────────────────────────────
  section('Messages');
  const MESSAGES = [
    { from: IDs.teacherUser1, to: IDs.studentUsers[0], body: 'Rahul, please submit your algebra worksheet by tomorrow.' },
    { from: IDs.studentUsers[0], to: IDs.teacherUser1, body: 'Sir, I will submit it by tonight. Thanks for the reminder!' },
    { from: IDs.teacherUser1, to: IDs.studentUsers[3], body: 'Meera, your attendance is very low. Please come to class regularly.' },
    { from: IDs.teacherUser2, to: IDs.studentUsers[6], body: 'Rohan, great work on the calculus problem set! Keep it up.' },
    { from: IDs.studentUsers[5], to: IDs.teacherUser2, body: 'Ma\'am, I had a doubt about integration by parts. Can we discuss tomorrow?' },
  ];

  for (const m of MESSAGES) {
    try {
      await db.execute(
        'INSERT INTO messages (sender_id, receiver_id, body) VALUES (?, ?, ?)',
        [m.from, m.to, m.body]
      );
    } catch (e) {
      warn(`Message: ${e.message}`);
    }
  }
  ok(`${MESSAGES.length} messages seeded`);

  // ─── 11. Announcements ────────────────────────────────────
  section('Announcements');
  const ANNOUNCEMENTS = [
    { classIdx: 0, title: '📚 Unit Test Scheduled — 20th April', body: 'Dear students, Unit Test for all subjects will be held on 20th April. Syllabus: Chapters 1 to 5. Bring your hall ticket.' },
    { classIdx: 0, title: '🏖 School Picnic — Approval Pending',  body: 'A school trip is being planned for next month. Please submit the consent form by Friday. Cost: ₹800 per student.' },
    { classIdx: 1, title: '🖥 Science Exhibition — Register Now', body: 'Annual Science Exhibition on 25th April. Class 11 students must register a project by 18th April. Max team size: 3.' },
    { classIdx: 1, title: '📋 Internal Assessment Dates Released', body: 'Internal Assessment for Class 11 will be held: Maths (22 Apr), CS (23 Apr), Physics (24 Apr). Refer to the portal for timings.' },
  ];

  for (const a of ANNOUNCEMENTS) {
    try {
      await db.execute(
        'INSERT INTO announcements (class_id, title, body) VALUES (?, ?, ?)',
        [CLASSES[a.classIdx].id, a.title, a.body]
      );
    } catch (e) {
      warn(`Announcement: ${e.message}`);
    }
  }
  ok(`${ANNOUNCEMENTS.length} announcements seeded`);

  // ─── 12. Fee Records ─────────────────────────────────────
  section('Fee Records');
  const FEE_DATA = [
    { sIdx: 0, total: 52000, paid: 52000 }, // fully paid
    { sIdx: 1, total: 52000, paid: 39000 }, // partially paid (₹13K pending)
    { sIdx: 2, total: 52000, paid: 26000 }, // half paid
    { sIdx: 3, total: 52000, paid: 0 },     // not paid at all
    { sIdx: 4, total: 52000, paid: 52000 }, // fully paid
    { sIdx: 5, total: 48000, paid: 48000 }, // fully paid (different tier)
    { sIdx: 6, total: 48000, paid: 36000 }, // partially paid
    { sIdx: 7, total: 48000, paid: 12000 }, // mostly unpaid
    { sIdx: 8, total: 48000, paid: 48000 }, // fully paid
    { sIdx: 9, total: 48000, paid: 24000 }, // half paid
  ];

  for (const f of FEE_DATA) {
    try {
      await db.execute(
        'INSERT IGNORE INTO fees (student_id, total_fee, paid_amount, due_date, semester) VALUES (?, ?, ?, ?, ?)',
        [IDs.studentIds[f.sIdx], f.total, f.paid, datetimeOffset(30).split(' ')[0], 'Sem 2 (2025-26)']
      );
      const pending = f.total - f.paid;
      const pendingStr = pending > 0 ? c.yellow(`₹${pending.toLocaleString('en-IN')} pending`) : c.green('Fully Paid');
      ok(`Fee: ${STUDENTS[f.sIdx].name} — ${pendingStr}`);
    } catch (e) {
      warn(`Fee for ${IDs.studentIds[f.sIdx]}: ${e.message}`);
    }
  }

  // ─── Done! ────────────────────────────────────────────────
  console.log(c.green(c.bold('\n╔══════════════════════════════════════════╗')));
  console.log(c.green(c.bold('║       ✅  Seeding Complete!               ║')));
  console.log(c.green(c.bold('╚══════════════════════════════════════════╝')));

  console.log(`\n${c.bold('📋 What was seeded:')}`);
  console.log(c.dim(`  • ${TEACHERS.length} teachers`));
  console.log(c.dim(`  • ${CLASSES.length} classes`));
  console.log(c.dim(`  • ${STUDENTS.length} students (enrolled in respective classes)`));
  console.log(c.dim(`  • 6 attendance records × ${STUDENTS.length} students`));
  console.log(c.dim(`  • 3 marks records × ${STUDENTS.length} students`));
  console.log(c.dim(`  • ${ASSIGNMENTS.length} assignments (2 past, 3 upcoming)`));
  console.log(c.dim(`  • ${subCount} submissions`));
  console.log(c.dim(`  • ${BEHAVIOR_LOGS.length} behavior logs`));
  console.log(c.dim(`  • ${MESSAGES.length} messages`));
  console.log(c.dim(`  • ${ANNOUNCEMENTS.length} announcements`));
  console.log(c.dim(`  • ${FEE_DATA.length} fee records`));

  console.log(c.bold('\n🔐 Login Credentials:\n'));
  console.log(`  ${c.cyan('ROLE')}       ${c.cyan('EMAIL')}                   ${c.cyan('PASSWORD')}`);
  console.log(`  ${'─'.repeat(55)}`);
  console.log(`  Admin      admin@test.com            password123`);
  console.log(`  Teacher    teacher@test.com          password123`);
  console.log(`  Teacher    teacher2@test.com         password123`);
  console.log(`  Student    student@test.com          password123   ${c.dim('(Rahul Sharma — STU001)')}`);
  console.log(`  Student    sneha@test.com            password123   ${c.dim('(Sneha Patel   — STU002)')}`);
  console.log(`  Student    kavya@test.com            password123   ${c.dim('(Kavya Reddy   — STU006)')}`);
  console.log(`  ${c.dim('(all 10 students use password123)')}`);

  console.log(c.bold('\n⚠️  At-Risk Students (seeded for testing AI):'));
  console.log(`  ${c.red('HIGH RISK')} : Meera Iyer (STU004) — low attendance & low marks`);
  console.log(`  ${c.yellow('MEDIUM RISK')}: Divya Krishnan (STU008) — low marks`);
  console.log();
}

// ─── Run ─────────────────────────────────────────────────────
seed()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(c.red('\n❌ Seed failed:'), err.message);
    console.error(err.stack);
    process.exit(1);
  });
