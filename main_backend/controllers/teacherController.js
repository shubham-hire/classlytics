exports.getDashboardData = (req, res) => {
  const dashboardData = {
    totalStudents: 50,
    avgAttendance: 78,
    avgMarks: 65,
    riskStudents: [
      { name: "Rahul", risk: "HIGH" },
      { name: "Sneha", risk: "MEDIUM" }
    ]
  };

  res.status(200).json(dashboardData);
};
