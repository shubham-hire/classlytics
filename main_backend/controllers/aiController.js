const { attendanceRecords, markRecords } = require('../data/storage');

exports.getStudentInsights = (req, res) => {
  const { studentId } = req.params;
  const insights = [];

  // 1. Fetch data for this student
  const studentAttendance = attendanceRecords.filter(r => r.studentId === studentId);
  const studentMarks = markRecords.filter(m => m.studentId === studentId);

  // A. Attendance Insights
  if (studentAttendance.length > 0) {
    const presentCount = studentAttendance.filter(r => r.status === 'Present').length;
    const percentage = (presentCount / studentAttendance.length) * 100;
    
    if (percentage < 75) {
      insights.push(`Attendance is below 75% (${Math.round(percentage)}%)`);
    } else if (percentage >= 95) {
        insights.push("Excellent attendance record!");
    }
  } else {
    insights.push("No attendance data recorded yet.");
  }

  // B. Performance Insights (Marks)
  if (studentMarks.length > 0) {
    const totalScore = studentMarks.reduce((sum, m) => sum + m.score, 0);
    const average = totalScore / studentMarks.length;

    if (average < 50) {
      insights.push("Overall performance is low (Below 50%)");
    }

    // Trend Analysis (Last vs Previous)
    if (studentMarks.length >= 2) {
      const sortedMarks = [...studentMarks].sort((a, b) => new Date(b.date) - new Date(a.date));
      const latest = sortedMarks[0].score;
      const previous = sortedMarks[1].score;

      if (latest < previous) {
        insights.push("Performance declining in recent tests");
      } else if (latest > previous) {
          insights.push("Showing improvement in recent scores");
      }
    }

    // Subject weaknesses
    studentMarks.forEach(record => {
      if (record.score < 40) {
        insights.push(`Needs improvement in ${record.subject}`);
      }
    });
  } else {
      insights.push("No academic marks recorded yet.");
  }

  // C. Final Default if no issues found but data exists
  if (insights.length === 0 && (studentAttendance.length > 0 || studentMarks.length > 0)) {
      insights.push("Student performance is stable.");
  }

  res.status(200).json({ insights });
};

exports.getStudentRisk = (req, res) => {
  const { studentId } = req.params;

  // 1. Fetch data
  const studentAttendance = attendanceRecords.filter(r => r.studentId === studentId);
  const studentMarks = markRecords.filter(m => m.studentId === studentId);

  // 2. Calculate percentage and average
  let attendancePct = 100; // Default to 100 if no data
  if (studentAttendance.length > 0) {
    const presentCount = studentAttendance.filter(r => r.status === 'Present').length;
    attendancePct = (presentCount / studentAttendance.length) * 100;
  }

  let avgMarks = 100; // Default to 100 if no data
  if (studentMarks.length > 0) {
    const totalScore = studentMarks.reduce((sum, m) => sum + m.score, 0);
    avgMarks = totalScore / studentMarks.length;
  }

  // 3. Risk Rules
  let risk = "LOW";

  if (avgMarks < 35 || attendancePct < 60) {
    risk = "HIGH";
  } else if (avgMarks < 50 || attendancePct < 75) {
    risk = "MEDIUM";
  }

  res.status(200).json({ risk });
};

exports.getStudentSuggestions = (req, res) => {
  const { studentId } = req.params;
  const suggestions = [];

  // 1. Fetch data
  const studentAttendance = attendanceRecords.filter(r => r.studentId === studentId);
  const studentMarks = markRecords.filter(m => m.studentId === studentId);

  // Helper Logic
  let attendancePct = 100;
  if (studentAttendance.length > 0) {
    const presentCount = studentAttendance.filter(r => r.status === 'Present').length;
    attendancePct = (presentCount / studentAttendance.length) * 100;
  }

  let avgMarks = 100;
  if (studentMarks.length > 0) {
    const totalScore = studentMarks.reduce((sum, m) => sum + m.score, 0);
    avgMarks = totalScore / studentMarks.length;
  }

  // A. Attendance Suggestion
  if (attendancePct < 75) {
    suggestions.push("Attend classes regularly to improve attendance.");
  }

  // B. Academic Suggestions
  if (avgMarks < 50) {
    suggestions.push("Revise basic concepts daily to build a stronger foundation.");
  }

  // C. Subject Specific Suggestions
  studentMarks.forEach(record => {
    if (record.score < 40) {
      suggestions.push(`Focus more on ${record.subject} subject and practice exercises.`);
    }
  });

  // D. Risk-based Suggestions
  if (avgMarks < 35 || attendancePct < 60) {
    suggestions.push("Schedule extra study time and consultation with the instructor.");
  }

  // Default if no issues
  if (suggestions.length === 0) {
      suggestions.push("Maintain your current healthy study habits!");
  }

  res.status(200).json({ suggestions });
};
