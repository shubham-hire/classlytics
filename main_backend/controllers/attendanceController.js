const { attendanceRecords } = require('../data/storage');

exports.markAttendance = (req, res) => {
  const { studentId, date, status } = req.body;

  // 1. Validation
  if (!studentId) {
    return res.status(400).json({ error: "studentId is required" });
  }

  if (!status || !["Present", "Absent"].includes(status)) {
    return res.status(400).json({ error: "Status must be 'Present' or 'Absent'" });
  }

  // 2. Record data
  const record = {
    studentId,
    date: date || new Date().toISOString().split('T')[0], // Use provides date or today
    status,
    timestamp: new Date()
  };

  attendanceRecords.push(record);

  console.log(`[ATTENDANCE] Recorded for ${studentId}: ${status} on ${record.date}`);
  console.log(`Total records: ${attendanceRecords.length}`);

  // 3. Success Response
  res.status(201).json({
    message: "Attendance recorded successfully",
    record: record
  });
};

exports.getAttendanceByStudent = (req, res) => {
  const { studentId } = req.params;

  // Filter records for the specific student
  const studentRecords = attendanceRecords.filter(r => r.studentId === studentId);

  // Calculate percentage
  let percentage = 0;
  if (studentRecords.length > 0) {
    const presentCount = studentRecords.filter(r => r.status === 'Present').length;
    percentage = Math.round((presentCount / studentRecords.length) * 100);
  }

  res.status(200).json({
    attendance: studentRecords.map(r => ({ date: r.date, status: r.status })),
    percentage: percentage
  });
};
