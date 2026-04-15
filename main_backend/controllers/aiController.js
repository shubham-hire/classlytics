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

  const nvidiaApiKey = process.env.NVIDIA_API_KEY;
  const nvidiaBaseUrl = process.env.NVIDIA_BASE_URL || 'https://integrate.api.nvidia.com/v1';
  // Use vision model when image is provided, text model otherwise
  const textModel   = process.env.NVIDIA_MODEL        || 'meta/llama-3.1-70b-instruct';
  const visionModel = process.env.NVIDIA_VISION_MODEL || 'meta/llama-3.2-11b-vision-instruct';
  const nvidiaModel = imageBase64 ? visionModel : textModel;

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

  if (!nvidiaApiKey || nvidiaApiKey === 'your_nvidia_api_key_here') {
    return res.status(200).json({
      answer: "I'm Classlytics AI! I need a valid NVIDIA API key to analyze images and provide personalized responses.",
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

  try {
    const response = await fetch(`${nvidiaBaseUrl}/chat/completions`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${nvidiaApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: nvidiaModel,
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user',   content: userContent },
        ],
        temperature: 0.7,
        max_tokens: 700,
        stream: false,
      }),
    });

    if (!response.ok) {
      const errBody = await response.text();
      console.error('[NVIDIA AI] Error:', response.status, errBody);
      return res.status(502).json({ error: 'AI service temporarily unavailable.', details: errBody });
    }

    const data = await response.json();
    const answer = data.choices?.[0]?.message?.content || "I couldn't generate a response. Please try rephrasing.";
    const usedModel = data.model || nvidiaModel;

    console.log(`[AI] ${imageBase64 ? '📸 Vision' : '💬 Text'} query answered using ${usedModel}`);
    res.status(200).json({ answer, aiModel: usedModel, hadImage: !!imageBase64, timestamp: new Date().toISOString() });
  } catch (err) {
    console.error('[NVIDIA AI] Fetch error:', err.message);
    res.status(500).json({ error: 'Failed to reach AI service.', details: err.message });
  }
};

exports.getTeacherHelp = async (req, res) => {
  const { query, teacherId } = req.body;

  if (!query) {
    return res.status(400).json({ error: "Query is required." });
  }

  const nvidiaApiKey = process.env.NVIDIA_API_KEY;
  const nvidiaBaseUrl = process.env.NVIDIA_BASE_URL || 'https://integrate.api.nvidia.com/v1';
  const textModel = process.env.NVIDIA_MODEL || 'meta/llama-3.1-70b-instruct';

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

    const response = await fetch(`${nvidiaBaseUrl}/chat/completions`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${nvidiaApiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)
    });

    const data = await response.json();
    if (data.choices && data.choices[0] && data.choices[0].message) {
      res.status(200).json({ answer: data.choices[0].message.content });
    } else {
      res.status(500).json({ error: 'Invalid response from model' });
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
