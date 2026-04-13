const db = require('../config/db');

exports.getStudentInsights = async (req, res) => {
  const { studentId } = req.params;
  const insights = [];

  try {
    // 1. Fetch data for this student
    const [attendance] = await db.execute('SELECT status FROM attendance WHERE student_id = ?', [studentId]);
    const [marks] = await db.execute('SELECT subject, score, date FROM marks WHERE student_id = ?', [studentId]);

    // A. Attendance Insights
    if (attendance.length > 0) {
      const presentCount = attendance.filter(r => r.status === 'Present').length;
      const percentage = (presentCount / attendance.length) * 100;
      
      if (percentage < 75) {
        insights.push(`Attendance is below 75% (${Math.round(percentage)}%)`);
      } else if (percentage >= 95) {
          insights.push("Excellent attendance record!");
      }
    }

    // B. Performance Insights (Marks)
    if (marks.length > 0) {
      const totalScore = marks.reduce((sum, m) => sum + m.score, 0);
      const average = totalScore / marks.length;

      if (average < 50) {
        insights.push("Overall performance is low (Below 50%)");
      }

      // Trend Analysis
      if (marks.length >= 2) {
        const sortedMarks = [...marks].sort((a, b) => new Date(b.date) - new Date(a.date));
        const latest = sortedMarks[0].score;
        const previous = sortedMarks[1].score;

        if (latest < previous) {
          insights.push("Performance declining in recent tests");
        } else if (latest > previous) {
            insights.push("Showing improvement in recent scores");
        }
      }

      // Subject weaknesses
      marks.forEach(record => {
        if (record.score < 40) {
          insights.push(`Needs improvement in ${record.subject}`);
        }
      });
    }

    if (insights.length === 0) {
      insights.push("Student performance is stable.");
    }

    res.status(200).json({ insights });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getStudentRisk = async (req, res) => {
  const { studentId } = req.params;

  try {
    const [attendance] = await db.execute('SELECT status FROM attendance WHERE student_id = ?', [studentId]);
    const [marks] = await db.execute('SELECT score FROM marks WHERE student_id = ?', [studentId]);

    let attendancePct = 100;
    if (attendance.length > 0) {
      const presentCount = attendance.filter(r => r.status === 'Present').length;
      attendancePct = (presentCount / attendance.length) * 100;
    }

    let avgMarks = 100;
    if (marks.length > 0) {
      const totalScore = marks.reduce((sum, m) => sum + m.score, 0);
      avgMarks = totalScore / marks.length;
    }

    let risk = "LOW";
    if (avgMarks < 35 || attendancePct < 60) {
      risk = "HIGH";
    } else if (avgMarks < 50 || attendancePct < 75) {
      risk = "MEDIUM";
    }

    res.status(200).json({ risk });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getStudentSuggestions = async (req, res) => {
  const { studentId } = req.params;
  const suggestions = [];

  try {
    const [attendance] = await db.execute('SELECT status FROM attendance WHERE student_id = ?', [studentId]);
    const [marks] = await db.execute('SELECT subject, score FROM marks WHERE student_id = ?', [studentId]);

    let attendancePct = 100;
    if (attendance.length > 0) {
      const presentCount = attendance.filter(r => r.status === 'Present').length;
      attendancePct = (presentCount / attendance.length) * 100;
    }

    let avgMarks = 100;
    if (marks.length > 0) {
      const totalScore = marks.reduce((sum, m) => sum + m.score, 0);
      avgMarks = totalScore / marks.length;
    }

    if (attendancePct < 75) suggestions.push("Attend classes regularly to improve attendance.");
    if (avgMarks < 50) suggestions.push("Revise basic concepts daily to build a stronger foundation.");
    
    marks.forEach(record => {
      if (record.score < 40) suggestions.push(`Focus more on ${record.subject} and practice exercises.`);
    });

    if (suggestions.length === 0) suggestions.push("Maintain your current healthy study habits!");

    res.status(200).json({ suggestions });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getStudentStudyPlan = async (req, res) => {
  const { studentId } = req.params;
  
  try {
    const [marks] = await db.execute('SELECT subject, score FROM marks WHERE student_id = ?', [studentId]);
    const weakSubjects = [...new Set(marks.filter(m => m.score < 50).map(m => m.subject))];
    
    const plan = [
      { day: "Monday", focus: weakSubjects[0] || "General Revision", duration: "1.5 hrs", activity: "Concept Review" },
      { day: "Tuesday", focus: weakSubjects[1] || "Core Subjects", duration: "2 hrs", activity: "Active Recall" },
      { day: "Wednesday", focus: "All Subjects", duration: "1 hr", activity: "Quick Notes Summary" },
      { day: "Thursday", focus: weakSubjects[0] || "Problem Solving", duration: "1.5 hrs", activity: "Mock Test Practice" },
      { day: "Friday", focus: weakSubjects[1] || "Logic/Theory", duration: "1.5 hrs", activity: "Feynman Technique" },
      { day: "Saturday", focus: "Weak Subject Marathon", duration: "3 hrs", activity: "Deep Work Session" },
      { day: "Sunday", focus: "Mindfulness & Goals", duration: "30 mins", activity: "Next Week Planning" }
    ];

    res.status(200).json({ studentId, plan, message: weakSubjects.length > 0 ? `Plan focused on: ${weakSubjects.join(', ')}` : "Balanced plan." });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getStudentNotifications = async (req, res) => {
  const { studentId } = req.params;
  
  try {
    const [attendance] = await db.execute('SELECT status FROM attendance WHERE student_id = ?', [studentId]);
    const [marks] = await db.execute('SELECT subject, score, date FROM marks WHERE student_id = ?', [studentId]);
    const [assignments] = await db.execute('SELECT id FROM assignments');
    const [submissions] = await db.execute('SELECT assignment_id FROM submissions WHERE student_id = ?', [studentId]);

    const notifications = [];

    if (attendance.length > 0) {
      const pct = (attendance.filter(r => r.status === 'Present').length / attendance.length) * 100;
      if (pct < 75) notifications.push({ type: 'CRITICAL', title: 'Low Attendance', message: `Attendance dropped to ${Math.round(pct)}%.` });
    }

    if (marks.length >= 2) {
      const sorted = [...marks].sort((a, b) => new Date(b.date) - new Date(a.date));
      if (sorted[0].score < sorted[1].score - 15) notifications.push({ type: 'WARNING', title: 'Performance Drop', message: `Significant decrease in ${sorted[0].subject}.` });
    }

    const submittedIds = submissions.map(s => s.assignment_id);
    const missedCount = assignments.filter(a => !submittedIds.includes(a.id)).length;
    if (missedCount > 0) notifications.push({ type: 'INFO', title: 'Missing Assignments', message: `You have ${missedCount} pending assignments.` });

    res.status(200).json({ notifications });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getHomeworkHelp = (req, res) => {
  const { query } = req.body;
  
  if (!query) {
    return res.status(400).json({ error: "Query is required." });
  }

  // Mock AI response logic
  let answer = "I'm still learning about that topic. Could you provide more context?";
  
  if (query.toLowerCase().includes("math") || query.toLowerCase().includes("calculate")) {
    answer = "To solve this math problem, remember to follow the Order of Operations (PEMDAS/BODMAS). First solve Brackets, then Orders (Exponents), then Division/Multiplication from left to right, and finally Addition/Subtraction.";
  } else if (query.toLowerCase().includes("science") || query.toLowerCase().includes("molecule")) {
    answer = "That sounds like a Science question! Atoms combine to form molecules. For example, two hydrogen atoms and one oxygen atom form H2O (water).";
  } else if (query.toLowerCase().includes("history")) {
    answer = "History is all about understanding the context of the past. Try to look at the cause-and-effect relationship of the events you're studying!";
  }

  res.status(200).json({ 
    answer,
    aiModel: "Classlytics-AIBot-v1",
    timestamp: new Date().toISOString()
  });
};
