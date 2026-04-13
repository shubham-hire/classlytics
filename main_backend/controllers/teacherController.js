const { schedule } = require('../data/storage');

exports.getDashboardData = (req, res) => {
  const dashboardData = {
    totalStudents: 50,
    avgAttendance: 78,
    avgMarks: 65,
    riskStudents: [
      { id: "S101", name: "Rahul", risk: "HIGH" },
      { id: "S102", name: "Sneha", risk: "MEDIUM" }
    ],
    schedule: schedule,
  };

  res.status(200).json(dashboardData);
};

exports.getSchedule = (req, res) => {
  res.status(200).json({ schedule });
};

exports.getProfile = (req, res) => {
  res.status(200).json({
    id: "T1001",
    name: "Rajesh Kumar",
    designation: "Head of Science Department (HOD)",
    email: "rajesh.kumar@classlytics.school",
    department: "Science",
    phone: "+91 9876543210",
    joinDate: "2021-08-15",
    qualifications: "M.Sc. Physics, B.Ed."
  });
};
