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

exports.getHomeworkHelp = async (req, res) => {
  const { query, studentId, imageBase64, imageMimeType } = req.body;
  // imageBase64: raw base64 string (no data URI prefix)
  // imageMimeType: 'image/jpeg' | 'image/png' | 'image/webp'

  if (!query) {
    return res.status(400).json({ error: "Query is required." });
  }

  let apiKey, baseUrl, targetModel;
  
  if (imageBase64) {
    apiKey = process.env.NVIDIA_API_KEY;
    baseUrl = process.env.NVIDIA_BASE_URL || 'https://integrate.api.nvidia.com/v1';
    targetModel = process.env.NVIDIA_VISION_MODEL || 'meta/llama-3.2-90b-vision-instruct';
  } else {
    apiKey = process.env.GROQ_API_KEY || process.env.NVIDIA_API_KEY;
    baseUrl = process.env.GROQ_BASE_URL || 'https://api.groq.com/openai/v1';
    targetModel = process.env.GROQ_API_KEY ? (process.env.GROQ_MODEL || 'llama-3.1-8b-instant') : (process.env.NVIDIA_MODEL || 'meta/llama-3.1-8b-instruct');
  }

  // ── Build student context from DB ─────────────────────────
  let studentContext = '';
  if (studentId) {
    try {
      const [profileRows] = await db.execute(
        `SELECT u.name, s.dept, s.current_year FROM students s JOIN users u ON s.user_id = u.id WHERE s.id = ?`,
        [studentId]
      );
      const profile = profileRows[0];

      const [attRows] = await db.execute('SELECT status FROM attendance WHERE student_id = ?', [studentId]);
      let attendancePct = null;
      if (attRows.length > 0) {
        const present = attRows.filter(r => r.status === 'Present').length;
        attendancePct = Math.round((present / attRows.length) * 100);
      }

      const [markRows] = await db.execute(
        'SELECT subject, score, max_score, type FROM marks WHERE student_id = ? ORDER BY date DESC LIMIT 10',
        [studentId]
      );
      const avgScore = markRows.length > 0
        ? Math.round(markRows.reduce((s, m) => s + (m.score / m.max_score) * 100, 0) / markRows.length)
        : null;
      const weakSubjects = [...new Set(
        markRows.filter(m => (m.score / m.max_score) * 100 < 50).map(m => m.subject)
      )];

      const [assignRows] = await db.execute(
        `SELECT a.title, a.deadline,
                (SELECT COUNT(*) FROM submissions s WHERE s.assignment_id = a.id AND s.student_id = ?) AS submitted
         FROM assignments a
         JOIN class_enrollments ce ON ce.class_id = a.class_id AND ce.student_id = ?
         WHERE a.deadline > NOW() ORDER BY a.deadline ASC LIMIT 5`,
        [studentId, studentId]
      );
      const pendingAssignments = assignRows.filter(a => a.submitted === 0);

      const [feeRows] = await db.execute(
        'SELECT total_fee, paid_amount, (total_fee - paid_amount) AS pending FROM fees WHERE student_id = ?',
        [studentId]
      );
      const fee = feeRows[0];

      if (profile) {
        studentContext = `
=== STUDENT PROFILE (Classlytics Live Data) ===
Name: ${profile.name} | Department: ${profile.dept} | Year: ${profile.current_year}
Attendance: ${attendancePct !== null ? `${attendancePct}% ${attendancePct < 75 ? '(⚠️ Low)' : '(✅ Good)'}` : 'No data'}
Average Score: ${avgScore !== null ? `${avgScore}%` : 'No data'}
Recent Tests: ${markRows.slice(0, 3).map(m => `${m.subject} ${m.type}: ${m.score}/${m.max_score}`).join(', ') || 'None'}
Weak Subjects: ${weakSubjects.length > 0 ? weakSubjects.join(', ') : 'None identified'}
Pending Assignments: ${pendingAssignments.length > 0 ? pendingAssignments.map(a => `"${a.title}" (due ${new Date(a.deadline).toLocaleDateString()})`).join(', ') : 'None'}
Fee Status: ${fee ? `Total ₹${fee.total_fee} | Paid ₹${fee.paid_amount} | Pending ₹${fee.pending}` : 'No data'}
================================================`;
      }
    } catch (ctxErr) {
      console.warn('[AI Context] Could not fetch student data:', ctxErr.message);
    }
  }

  const systemPrompt = `You are Classlytics AI — a warm, smart, and highly personalized academic assistant.
${imageBase64 ? 'The student has shared an assignment image. Analyze it carefully, identify the problem or question, and guide them through solving it step-by-step. Do NOT just give the answer outright — teach the concept.' : ''}
${studentContext ? `\nYou have real-time access to this student's academic data:\n${studentContext}\n\nUse this data actively. Always address the student by name.` : ''}

Guidelines:
- Be warm, encouraging, and personalized. Never harsh.
- Proactively mention weak areas or pending assignments when relevant.
- Give step-by-step solutions for math/science problems.
- Keep responses clear and concise (2–4 paragraphs). Use emojis sparingly.
- Guide students to understand, don't just give answers.`;

  if (!apiKey || apiKey === 'your_nvidia_api_key_here') {
    return res.status(200).json({
      answer: "I'm Classlytics AI! I need a valid API key to provide personalized responses.",
      aiModel: "Classlytics-Fallback-v1",
      timestamp: new Date().toISOString()
    });
  }

  // ── Build message content (text + optional image) ──────────
  let userContent;
  if (imageBase64) {
    const mimeType = imageMimeType || 'image/jpeg';
    userContent = [
      { type: 'text', text: query || 'Please analyze this assignment image and help me understand and solve it.' },
      {
        type: 'image_url',
        image_url: { url: `data:${mimeType};base64,${imageBase64}` },
      },
    ];
  } else {
    userContent = query;
  }

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 15000); // 15 seconds

  try {
    const response = await fetch(`${baseUrl}/chat/completions`, {
      method: 'POST',
      signal: controller.signal,
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: targetModel,
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user',   content: userContent },
        ],
        temperature: 0.7,
        max_tokens: 700,
        stream: false,
      }),
    });
    clearTimeout(timeoutId);

    if (!response.ok) {
      const errBody = await response.text();
      console.error('[NVIDIA AI] Error:', response.status, errBody);
      return res.status(502).json({ error: 'AI service temporarily unavailable.', details: errBody });
    }

    const data = await response.json();
    const answer = data.choices?.[0]?.message?.content || "I couldn't generate a response. Please try rephrasing.";
    const usedModel = data.model || targetModel;

    console.log(`[AI] ${imageBase64 ? '📸 Vision' : '💬 Text'} query answered using ${usedModel}`);
    res.status(200).json({ answer, aiModel: usedModel, hadImage: !!imageBase64, timestamp: new Date().toISOString() });
  } catch (err) {
    if (err.name === 'AbortError') {
      console.error('[AI] Fetch timeout exceeded.');
      return res.status(504).json({ error: 'AI service took too long to respond. Please try again.' });
    }
    console.error('[AI] Fetch error:', err.message);
    res.status(500).json({ error: 'Failed to reach AI service.', details: err.message });
  }
};

exports.getTeacherHelp = async (req, res) => {
  const { query, teacherId } = req.body;

  if (!query) {
    return res.status(400).json({ error: "Query is required." });
  }

  const apiKey = process.env.GROQ_API_KEY || process.env.NVIDIA_API_KEY;
  const baseUrl = process.env.GROQ_BASE_URL || 'https://api.groq.com/openai/v1';
  const textModel = process.env.GROQ_MODEL || 'llama-3.1-8b-instant';

  let teacherContext = '';
  if (teacherId) {
    try {
      const db = require('../config/db');
      // Get all classes taught by teacher
      const [classRows] = await db.execute('SELECT id, name, section FROM classes WHERE teacher_id = ?', [teacherId]);
      
      if (classRows.length > 0) {
        const classIds = classRows.map(c => c.id);
        const placeholders = classIds.map(() => '?').join(',');
        
        // Total students
        const [enrollRows] = await db.execute(`SELECT COUNT(*) as total FROM class_enrollments WHERE class_id IN (${placeholders})`, classIds);
        const totalStudents = enrollRows[0].total;

        // Average scores grouped by subject
        const [marksRows] = await db.execute(`
            SELECT m.subject, AVG(m.score/m.max_score*100) as avg_score 
            FROM marks m 
            JOIN students s ON m.student_id = s.id 
            JOIN class_enrollments ce ON s.id = ce.student_id
            WHERE ce.class_id IN (${placeholders})
            GROUP BY m.subject
        `, classIds);
        const subjectStats = marksRows.map(m => `${m.subject}: ${Math.round(m.avg_score)}% avg`).join(', ');

        const classListTxt = classRows.map(c => `${c.name} (Sec ${c.section})`).join(', ');

        teacherContext = `
=== TEACHER CONTEXT (Classlytics Live Data) ===
Classes Taught: ${classListTxt}
Total Students Enrolled: ${totalStudents}
Subject Performance: ${subjectStats}
=== END TEACHER CONTEXT ===

`;
      } else {
        teacherContext = "No classes assigned yet.\n";
      }
    } catch (e) {
      console.warn('Failed to build teacher context', e);
    }
  }

  const userMessage = teacherContext + "TEACHER QUERY: " + query;

  try {
    const payload = {
      model: textModel,
      messages: [
        { role: 'system', content: 'You are a helpful teaching assistant built into the Classlytics platform. Use the provided context to answer the teacher\'s questions about their classes, students, or suggest teaching strategies. Be concise and professional.' },
        { role: 'user', content: userMessage }
      ],
      temperature: 0.5,
      max_tokens: 800
    };

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 15000);

    const response = await fetch(`${baseUrl}/chat/completions`, {
      method: 'POST',
      signal: controller.signal,
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)
    });
    clearTimeout(timeoutId);

    const data = await response.json();
    if (data.choices && data.choices[0] && data.choices[0].message) {
      res.status(200).json({ answer: data.choices[0].message.content });
    } else {
      res.status(500).json({ error: 'Invalid response from model' });
    }
  } catch (err) {
    if (err.name === 'AbortError') {
      return res.status(504).json({ error: 'AI took too long to answer' });
    }
    res.status(500).json({ error: err.message });
  }
};

exports.getAdminCommandCenter = async (req, res) => {
  const { query } = req.body;

  if (!query) {
    return res.status(400).json({ error: "Query is required." });
  }

  const apiKey = process.env.GROQ_API_KEY || process.env.NVIDIA_API_KEY;
  const baseUrl = process.env.GROQ_BASE_URL || 'https://api.groq.com/openai/v1';
  const textModel = process.env.GROQ_MODEL || 'llama-3.1-8b-instant';

  let adminContext = '';
  try {
    const db = require('../config/db');
    // Gather basic stats for context
    const [userRows] = await db.execute('SELECT role, COUNT(*) as count FROM users GROUP BY role');
    const userStats = userRows.map(r => `${r.role}: ${r.count}`).join(', ');

    const [studentRows] = await db.execute('SELECT COUNT(*) as total FROM students');
    const totalStudents = studentRows[0].total;

    const [teacherRows] = await db.execute('SELECT COUNT(*) as total FROM teachers');
    const totalTeachers = teacherRows[0].total;

    const [feeRows] = await db.execute('SELECT SUM(total_fee) as expected, SUM(paid_amount) as collected FROM fees');
    const expectedFee = feeRows[0].expected || 0;
    const collectedFee = feeRows[0].collected || 0;
    const pendingFee = expectedFee - collectedFee;

    // --- NEW: Attendance Context ---
    const [attRows] = await db.execute('SELECT status FROM attendance WHERE date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)');
    let avgAttendance = 0;
    if (attRows.length > 0) {
      const present = attRows.filter(r => r.status === 'Present').length;
      avgAttendance = Math.round((present / attRows.length) * 100);
    }

    // --- NEW: Academic Context ---
    const [marksRows] = await db.execute('SELECT score, max_score FROM marks');
    let schoolAvgScore = 0;
    if (marksRows.length > 0) {
      const totalPct = marksRows.reduce((sum, m) => sum + (m.score / m.max_score) * 100, 0);
      schoolAvgScore = Math.round(totalPct / marksRows.length);
    }

    adminContext = `
=== ADMIN CONTEXT (Classlytics Live Data) ===
Total Students: ${totalStudents} | Total Teachers: ${totalTeachers}
User Roles Breakdown: ${userStats}

Financial Overview:
- Expected: ₹${expectedFee} | Collected: ₹${collectedFee} | Pending: ₹${pendingFee}

Performance & Attendance (Last 30 Days):
- School-wide Avg Attendance: ${avgAttendance}%
- School-wide Avg Academic Score: ${schoolAvgScore}%
=== END ADMIN CONTEXT ===
`;

    // --- NEW: Individual Lookup Phase ---
    // If the query looks like it's asking about a person, search for them
    const potentialNames = query.split(' ').filter(word => word.length > 2 && !['show', 'tell', 'about', 'what', 'who', 'is', 'the'].includes(word.toLowerCase()));
    
    if (potentialNames.length > 0) {
      let individualInfo = '\n=== MATCHING INDIVIDUALS ===\n';
      for (const name of potentialNames.slice(0, 2)) { // Look up first 2 potential names
        const [users] = await db.execute(
          'SELECT u.name, u.role, u.email, s.dept as s_dept, t.department as t_dept FROM users u LEFT JOIN students s ON u.id = s.user_id LEFT JOIN teachers t ON u.id = t.user_id WHERE u.name LIKE ? LIMIT 3',
          [`%${name}%`]
        );
        
        users.forEach(user => {
          individualInfo += `- ${user.name} (${user.role}): Email: ${user.email}, Dept: ${user.s_dept || user.t_dept || 'N/A'}\n`;
        });
      }
      if (individualInfo.length > 30) {
        adminContext += individualInfo + '=== END MATCHING INDIVIDUALS ===\n';
      }
    }
  } catch (e) {
    console.warn('Failed to build admin context', e);
  }

  const userMessage = adminContext + "ADMIN QUERY: " + query;

  try {
    const payload = {
      model: textModel,
      messages: [
        { role: 'system', content: 'You are the central AI Administrative Assistant for the Classlytics platform. Use the provided live database context to answer the school administrator\'s questions. Provide concise, actionable insights and data summaries. If the query asks to perform an action (e.g. "send an email"), kindly explain that you are currently in "advisory mode" and can only provide information.' },
        { role: 'user', content: userMessage }
      ],
      temperature: 0.5,
      max_tokens: 800
    };

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 15000);

    const response = await fetch(`${baseUrl}/chat/completions`, {
      method: 'POST',
      signal: controller.signal,
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)
    });
    clearTimeout(timeoutId);

    const data = await response.json();
    if (data.choices && data.choices[0] && data.choices[0].message) {
      res.status(200).json({ answer: data.choices[0].message.content });
    } else {
      res.status(500).json({ error: 'Invalid response from model' });
    }
  } catch (err) {
    if (err.name === 'AbortError') {
      return res.status(504).json({ error: 'AI took too long to answer' });
    }
    res.status(500).json({ error: err.message });
  }
};

// --- NEW: Smart Communication Drafter ---
exports.draftAnnouncement = async (req, res) => {
  const { prompt } = req.body;

  if (!prompt) {
    return res.status(400).json({ error: "Prompt is required." });
  }

  const apiKey = process.env.GROQ_API_KEY || process.env.NVIDIA_API_KEY;
  const baseUrl = process.env.GROQ_BASE_URL || 'https://api.groq.com/openai/v1';
  const textModel = process.env.GROQ_MODEL || 'llama-3.1-8b-instant';

  try {
    const payload = {
      model: textModel,
      messages: [
        { 
          role: 'system', 
          content: 'You are an expert school administrative copywriter. Your job is to take rough ideas and turn them into professional, polite, and official school announcements or notices. Do not include subject lines like "Subject:" unless asked. Output ONLY the drafted message, ready to be sent to parents or teachers.' 
        },
        { role: 'user', content: `Draft a school announcement based on this idea: ${prompt}` }
      ],
      temperature: 0.7,
      max_tokens: 500
    };

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 15000);

    const response = await fetch(`${baseUrl}/chat/completions`, {
      method: 'POST',
      signal: controller.signal,
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)
    });
    clearTimeout(timeoutId);

    const data = await response.json();
    if (data.choices && data.choices[0] && data.choices[0].message) {
      res.status(200).json({ draft: data.choices[0].message.content.trim() });
    } else {
      res.status(500).json({ error: 'Invalid response from model' });
    }
  } catch (err) {
    if (err.name === 'AbortError') {
      return res.status(504).json({ error: 'AI took too long to answer' });
    }
    res.status(500).json({ error: err.message });
  }
};

// --- NEW: AI Personalized Feedback Generation ---
exports.generateStudentFeedback = async (req, res) => {
  const { studentId } = req.body;

  if (!studentId) {
    return res.status(400).json({ error: "Student ID is required." });
  }

  const apiKey = process.env.GROQ_API_KEY || process.env.NVIDIA_API_KEY;
  const baseUrl = process.env.GROQ_BASE_URL || 'https://api.groq.com/openai/v1';
  const textModel = process.env.GROQ_MODEL || 'llama-3.1-8b-instant';

  try {
    // 1. Gather Student Performance Data
    const [profileRows] = await db.execute(
      `SELECT u.name, s.dept, s.current_year FROM students s JOIN users u ON s.user_id = u.id WHERE s.id = ?`,
      [studentId]
    );
    const profile = profileRows[0];

    if (!profile) return res.status(404).json({ error: "Student not found" });

    const [attRows] = await db.execute('SELECT status FROM attendance WHERE student_id = ?', [studentId]);
    let attendancePct = 0;
    if (attRows.length > 0) {
      const present = attRows.filter(r => r.status === 'Present').length;
      attendancePct = Math.round((present / attRows.length) * 100);
    }

    const [marks] = await db.execute(
      'SELECT subject, score, max_score, type FROM marks WHERE student_id = ? ORDER BY date DESC LIMIT 10',
      [studentId]
    );
    
    // 2. Build Context for AI
    const performanceContext = marks.map(m => `- ${m.subject} (${m.type}): ${m.score}/${m.max_score}`).join('\n');
    const systemPrompt = `You are an expert Educational Counselor at Classlytics. Your task is to write a personalized, professional, and balanced feedback note for the parents of ${profile.name}.
    
    Academic Data:
    - Attendance: ${attendancePct}%
    - Recent Scores:
    ${performanceContext}
    
    Guidelines:
    - Be professional yet empathetic.
    - If scores are high, praise the effort.
    - If scores are low, suggest specific areas for improvement in a supportive way.
    - Mention attendance if it's a concern (below 75%).
    - Keep it under 200 words.
    - End with a professional sign-off.`;

    const payload = {
      model: textModel,
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: `Generate a feedback note for ${profile.name}'s parents based on the data above.` }
      ],
      temperature: 0.6,
      max_tokens: 500
    };

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 15000);

    const response = await fetch(`${baseUrl}/chat/completions`, {
      method: 'POST',
      signal: controller.signal,
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)
    });
    clearTimeout(timeoutId);

    const data = await response.json();
    if (data.choices && data.choices[0] && data.choices[0].message) {
      res.status(200).json({ 
        studentName: profile.name,
        feedback: data.choices[0].message.content.trim() 
      });
    } else {
      res.status(500).json({ error: 'Invalid response from AI' });
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// --- NEW: Phase 3 - Proactive Risk Analysis ---
exports.getRiskAnalysis = async (req, res) => {
  const apiKey = process.env.GROQ_API_KEY || process.env.NVIDIA_API_KEY;
  const baseUrl = process.env.GROQ_BASE_URL || 'https://api.groq.com/openai/v1';
  const textModel = process.env.GROQ_MODEL || 'llama-3.1-8b-instant';

  try {
    // 1. Fetch data for all students to find anomalies
    const [students] = await db.execute(`
      SELECT s.id, u.name, s.dept,
        (SELECT COUNT(*) FROM attendance a WHERE a.student_id = s.id AND a.status = 'Present') / 
        NULLIF((SELECT COUNT(*) FROM attendance a WHERE a.student_id = s.id), 0) * 100 as attendance_pct,
        (SELECT AVG(m.score/m.max_score*100) FROM marks m WHERE m.student_id = s.id) as avg_score
      FROM students s
      JOIN users u ON s.user_id = u.id
    `);

    // 2. Filter students who are below thresholds
    const atRiskStudents = students.filter(s => 
      (s.attendance_pct !== null && s.attendance_pct < 75) || 
      (s.avg_score !== null && s.avg_score < 50)
    ).map(s => ({
      ...s,
      attendance_pct: Math.round(s.attendance_pct || 0),
      avg_score: Math.round(s.avg_score || 0)
    }));

    if (atRiskStudents.length === 0) {
      return res.status(200).json({ status: 'Healthy', message: 'No students currently meet at-risk criteria.', students: [] });
    }

    // 3. Ask AI to analyze these students and provide intervention steps
    const studentsDataTxt = atRiskStudents.map(s => 
      `- ${s.name} (${s.id}): Attendance ${s.attendance_pct}%, Avg Score ${s.avg_score}%`
    ).join('\n');

    const systemPrompt = `You are a Senior Academic Intervention Officer at Classlytics. Analyze the following list of at-risk students and provide a summary report.
    
    Data:
    ${studentsDataTxt}
    
    For each student, provide:
    1. Primary Risk factor (Attendance, Performance, or Both).
    2. A 1-sentence intervention strategy.
    
    Keep the overall tone professional and focused on student success.`;

    const response = await fetch(`${baseUrl}/chat/completions`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: textModel,
        messages: [{ role: 'system', content: systemPrompt }],
        temperature: 0.5,
        max_tokens: 1000
      })
    });

    const data = await response.json();
    const analysis = data.choices?.[0]?.message?.content || "Could not generate analysis.";

    res.status(200).json({ 
      timestamp: new Date().toISOString(),
      riskCount: atRiskStudents.length,
      students: atRiskStudents,
      aiAnalysis: analysis 
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// --- Phase 4: Teacher AI Upgrades ---
exports.getClassAnalysis = async (req, res) => {
  const { classId } = req.params;
  const apiKey = process.env.GROQ_API_KEY || process.env.NVIDIA_API_KEY;
  const baseUrl = process.env.GROQ_BASE_URL || 'https://api.groq.com/openai/v1';
  const textModel = process.env.GROQ_MODEL || 'llama-3.1-8b-instant';

  try {
    // 1. Fetch class details
    const [classDetails] = await db.execute('SELECT name, section FROM classes WHERE id = ?', [classId]);
    if (classDetails.length === 0) return res.status(404).json({ error: 'Class not found' });

    // 2. Fetch marks for all students in this class
    const [marks] = await db.execute(`
      SELECT m.subject, m.topic, m.score, m.max_score, u.name as student_name
      FROM marks m
      JOIN students s ON m.student_id = s.id
      JOIN class_enrollments ce ON ce.student_id = s.id
      JOIN users u ON s.user_id = u.id
      WHERE ce.class_id = ?
    `, [classId]);

    if (marks.length === 0) {
      return res.status(200).json({ 
        className: classDetails[0].name,
        section: classDetails[0].section,
        message: 'No test data available for this class yet.',
        insights: null 
      });
    }

    // 3. Aggregate data by subject/topic for AI
    const summary = {};
    marks.forEach(m => {
      const key = `${m.subject} - ${m.topic}`;
      if (!summary[key]) summary[key] = { total: 0, count: 0 };
      summary[key].total += (m.score / m.max_score) * 100;
      summary[key].count += 1;
    });

    const topicStats = Object.keys(summary).map(key => ({
      topic: key,
      avg: Math.round(summary[key].total / summary[key].count)
    })).sort((a, b) => a.avg - b.avg); // Weakest topics first

    // 4. Generate AI Insights
    const statsTxt = topicStats.map(t => `${t.topic}: ${t.avg}% average`).join('\n');
    const systemPrompt = `You are an AI Teaching Assistant for Classlytics. Analyze the following topic averages for Class ${classDetails[0].name} (${classDetails[0].section}).
    
    Data:
    ${statsTxt}
    
    Provide:
    1. A "Knowledge Gap" summary (top 2 weakest areas).
    2. 3 specific actionable tips for the teacher to improve these scores in the next lesson.
    3. 1 "Top Performer" topic to encourage the class.
    
    Tone: Encouraging, data-driven, and brief. Use bullet points.`;

    const response = await fetch(`${baseUrl}/chat/completions`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: textModel,
        messages: [{ role: 'system', content: systemPrompt }],
        temperature: 0.6
      })
    });

    const data = await response.json();
    const insights = data.choices?.[0]?.message?.content || "Analysis unavailable.";

    res.status(200).json({
      className: classDetails[0].name,
      section: classDetails[0].section,
      topicStats,
      aiInsights: insights
    });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getStudentWeeklySummary = async (req, res) => {
  const { studentId } = req.params;
  const apiKey = process.env.GROQ_API_KEY || process.env.NVIDIA_API_KEY;
  const baseUrl = process.env.GROQ_BASE_URL || 'https://api.groq.com/openai/v1';
  const textModel = process.env.GROQ_MODEL || 'llama-3.1-8b-instant';

  try {
    const [profile] = await db.execute('SELECT u.name FROM students s JOIN users u ON s.user_id = u.id WHERE s.id = ?', [studentId]);
    if (!profile[0]) return res.status(404).json({ error: 'Student not found' });

    const [marks] = await db.execute('SELECT subject, score, max_score, date FROM marks WHERE student_id = ? AND date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)', [studentId]);
    const [attendance] = await db.execute('SELECT status FROM attendance WHERE student_id = ? AND date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)', [studentId]);

    const stats = `Student: ${profile[0].name}\nRecent Marks: ${marks.map(m => `${m.subject}: ${m.score}/${m.max_score}`).join(', ') || 'None'}\nRecent Attendance: ${attendance.length} records.`;

    const systemPrompt = `You are a helpful AI Assistant for parents. Write a warm, professional weekly progress summary (Markdown) for ${profile[0].name}'s parents. Focus on: Overall Mood, Academic Spotlight, and 1 Home Tip. Be encouraging.`;

    const response = await fetch(`${baseUrl}/chat/completions`, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ model: textModel, messages: [{ role: 'system', content: systemPrompt }, { role: 'user', content: stats }], temperature: 0.7 })
    });

    const data = await response.json();
    res.status(200).json({ summary: data.choices?.[0]?.message?.content || 'Summary unavailable.' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getAdminStrategicAdvice = async (req, res) => {
  const apiKey = process.env.GROQ_API_KEY || process.env.NVIDIA_API_KEY;
  const baseUrl = process.env.GROQ_BASE_URL || 'https://api.groq.com/openai/v1';
  const textModel = process.env.GROQ_MODEL || 'llama-3.1-8b-instant';

  try {
    const [feeStats] = await db.execute('SELECT SUM(total_fee) as expected, SUM(paid_amount) as collected FROM fees');
    const [attStats] = await db.execute('SELECT ROUND(SUM(CASE WHEN status = "Present" THEN 1 ELSE 0 END) / COUNT(*) * 100) as avg FROM attendance WHERE date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)');
    const [marksStats] = await db.execute('SELECT ROUND(AVG(score/max_score * 100)) as avg FROM marks');

    const globalStats = `Expected Fee: ₹${feeStats[0].expected}, Collected: ₹${feeStats[0].collected}, Attendance: ${attStats[0].avg}%, Academics: ${marksStats[0].avg}%`;

    const systemPrompt = `You are a Strategic AI Consultant for school administrators. Analyze the provided school data and give a 2-paragraph strategic recommendation (Markdown). Paragraph 1: Operational Health. Paragraph 2: Growth Strategy. Be data-driven and professional.`;

    const response = await fetch(`${baseUrl}/chat/completions`, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ model: textModel, messages: [{ role: 'system', content: systemPrompt }, { role: 'user', content: globalStats }], temperature: 0.5 })
    });

    const data = await response.json();
    res.status(200).json({ advice: data.choices?.[0]?.message?.content || 'Strategy advice unavailable.' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
