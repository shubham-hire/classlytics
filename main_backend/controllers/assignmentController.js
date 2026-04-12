const { assignments, submissions } = require('../data/storage');
const { v4: uuidv4 } = require('uuid');

// POST /assignments — Create a new assignment
exports.createAssignment = (req, res) => {
  const { classId, title, description, deadline } = req.body;

  if (!classId || !title || !deadline) {
    return res.status(400).json({ error: 'classId, title, and deadline are required.' });
  }

  const newAssignment = {
    id: uuidv4(),
    classId,
    title,
    description: description || '',
    deadline,
    createdAt: new Date().toISOString(),
  };

  assignments.push(newAssignment);
  console.log(`[ASSIGNMENT] Created "${title}" for class ${classId}`);
  res.status(201).json({ message: 'Assignment created successfully', assignment: newAssignment });
};

// GET /assignments/:classId — Get all assignments for a class
exports.getAssignments = (req, res) => {
  const { classId } = req.params;
  const classAssignments = assignments.filter(a => a.classId === classId);
  res.status(200).json({ assignments: classAssignments });
};

// POST /assignments/:assignmentId/submit — Submit an assignment
exports.submitAssignment = (req, res) => {
  const { assignmentId } = req.params;
  const { studentId, note } = req.body;

  if (!studentId) {
    return res.status(400).json({ error: 'studentId is required.' });
  }

  const assignment = assignments.find(a => a.id === assignmentId);
  if (!assignment) {
    return res.status(404).json({ error: 'Assignment not found.' });
  }

  const submission = {
    id: uuidv4(),
    assignmentId,
    studentId,
    note: note || '',
    submittedAt: new Date().toISOString(),
  };

  submissions.push(submission);
  console.log(`[SUBMISSION] Student ${studentId} submitted assignment ${assignmentId}`);
  res.status(201).json({ message: 'Assignment submitted successfully', submission });
};

// GET /assignments/:assignmentId/submissions — Get all submissions for an assignment
exports.getSubmissions = (req, res) => {
  const { assignmentId } = req.params;
  const assignmentSubmissions = submissions.filter(s => s.assignmentId === assignmentId);
  res.status(200).json({ submissions: assignmentSubmissions });
};
