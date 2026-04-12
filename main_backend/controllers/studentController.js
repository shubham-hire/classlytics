exports.getStudentsByClass = (req, res) => {
  const { classId } = req.params;

  // Mock data - for now returns same list for any classId
  const students = [
    { id: "S1", name: "Rahul", rollNo: "01" },
    { id: "S2", name: "Sneha", rollNo: "02" },
    { id: "S3", name: "Amit", rollNo: "03" }
  ];

  console.log(`[STUDENT] Fetching students for Class ID: ${classId}`);
  res.status(200).json(students);
};
