class FeeStructure {
  final int id;
  final String classId;
  final String className;
  final String classSection;
  final String academicYear;
  final String title;
  final double tuitionFee;
  final double examFee;
  final double transportFee;
  final double libraryFee;
  final double sportsFee;
  final double miscellaneousFee;
  final double totalFee;
  final String? dueDate;
  final String? createdAt;

  const FeeStructure({
    required this.id,
    required this.classId,
    required this.className,
    required this.classSection,
    required this.academicYear,
    required this.title,
    required this.tuitionFee,
    required this.examFee,
    required this.transportFee,
    required this.libraryFee,
    required this.sportsFee,
    required this.miscellaneousFee,
    required this.totalFee,
    this.dueDate,
    this.createdAt,
  });

  factory FeeStructure.fromJson(Map<String, dynamic> json) {
    double parse(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;
    return FeeStructure(
      id: json['id'] as int,
      classId: json['class_id'] ?? '',
      className: json['class_name'] ?? '',
      classSection: json['class_section'] ?? '',
      academicYear: json['academic_year'] ?? '',
      title: json['title'] ?? '',
      tuitionFee: parse(json['tuition_fee']),
      examFee: parse(json['exam_fee']),
      transportFee: parse(json['transport_fee']),
      libraryFee: parse(json['library_fee']),
      sportsFee: parse(json['sports_fee']),
      miscellaneousFee: parse(json['miscellaneous_fee']),
      totalFee: parse(json['total_fee']),
      dueDate: json['due_date']?.toString().split('T').first,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'class_id': classId,
    'academic_year': academicYear,
    'title': title,
    'tuition_fee': tuitionFee,
    'exam_fee': examFee,
    'transport_fee': transportFee,
    'library_fee': libraryFee,
    'sports_fee': sportsFee,
    'miscellaneous_fee': miscellaneousFee,
    'due_date': dueDate,
  };

  FeeStructure copyWith({
    String? title, String? academicYear, double? tuitionFee, double? examFee,
    double? transportFee, double? libraryFee, double? sportsFee,
    double? miscellaneousFee, String? dueDate,
  }) => FeeStructure(
    id: id, classId: classId, className: className, classSection: classSection,
    academicYear: academicYear ?? this.academicYear,
    title: title ?? this.title,
    tuitionFee: tuitionFee ?? this.tuitionFee,
    examFee: examFee ?? this.examFee,
    transportFee: transportFee ?? this.transportFee,
    libraryFee: libraryFee ?? this.libraryFee,
    sportsFee: sportsFee ?? this.sportsFee,
    miscellaneousFee: miscellaneousFee ?? this.miscellaneousFee,
    totalFee: (tuitionFee ?? this.tuitionFee) + (examFee ?? this.examFee) +
              (transportFee ?? this.transportFee) + (libraryFee ?? this.libraryFee) +
              (sportsFee ?? this.sportsFee) + (miscellaneousFee ?? this.miscellaneousFee),
    dueDate: dueDate ?? this.dueDate,
    createdAt: createdAt,
  );
}
