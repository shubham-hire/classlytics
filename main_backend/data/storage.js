// Centralized in-memory storage for Classlytics
// In a real application, this would be a database (MongoDB/PostgreSQL).

const attendanceRecords = [];
const markRecords = [];
const assignments = [];      // { id, classId, title, description, deadline, createdAt }
const submissions = [];      // { id, assignmentId, studentId, note, submittedAt }
const behaviorLogs = [];     // { id, studentId, type, remark, date }
const messages = [];         // { id, from, to, body, timestamp, isRead }
const announcements = [];    // { id, classId, title, body, createdAt }
const schedule = [
  { id: 'L1', time: '09:00 AM', subject: 'Mathematics', classId: 'C1', className: 'Class 10-A', room: 'Room 101' },
  { id: 'L2', time: '11:30 AM', subject: 'Physics Lab', classId: 'C2', className: 'Class 12-B', room: 'Lab 3' },
];

module.exports = {
  attendanceRecords,
  markRecords,
  assignments,
  submissions,
  behaviorLogs,
  messages,
  announcements,
  schedule,
};
