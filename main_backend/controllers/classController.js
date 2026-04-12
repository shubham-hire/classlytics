exports.getClasses = (req, res) => {
  const classes = [
    {
      classId: "C1",
      className: "TE IT A",
      subject: "Software Engineering"
    },
    {
      classId: "C2",
      className: "TE IT B",
      subject: "Database Management"
    }
  ];

  res.status(200).json(classes);
};
