class StudentFeeAssignment {
  final int id;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final int feeStructureId;
  final String structureTitle;
  final String academicYear;
  final String classId;
  final String className;
  final String classSection;
  final String? dept;
  final String? currentYear;
  final int? rollNo;
  final double totalAmount;
  final double paidAmount;
  final double pendingAmount;
  final String status;
  final String? dueDate;
  final String? assignedAt;

  // ─── Fee component breakdown (from backend join) ───
  final double tuitionFee;
  final double examFee;
  final double transportFee;
  final double libraryFee;
  final double sportsFee;
  final double miscellaneousFee;

  const StudentFeeAssignment({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.feeStructureId,
    required this.structureTitle,
    required this.academicYear,
    required this.classId,
    required this.className,
    required this.classSection,
    this.dept,
    this.currentYear,
    this.rollNo,
    required this.totalAmount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.status,
    this.dueDate,
    this.assignedAt,
    this.tuitionFee = 0,
    this.examFee = 0,
    this.transportFee = 0,
    this.libraryFee = 0,
    this.sportsFee = 0,
    this.miscellaneousFee = 0,
  });

  factory StudentFeeAssignment.fromJson(Map<String, dynamic> json) {
    double parse(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;
    return StudentFeeAssignment(
      id: json['id'] as int,
      studentId: json['student_id'] ?? '',
      studentName: json['student_name'] ?? '',
      studentEmail: json['student_email'] ?? '',
      feeStructureId: json['fee_structure_id'] as int,
      structureTitle: json['structure_title'] ?? '',
      academicYear: json['academic_year'] ?? '',
      classId: json['class_id'] ?? '',
      className: json['class_name'] ?? '',
      classSection: json['class_section'] ?? '',
      dept: json['dept'],
      currentYear: json['current_year'],
      rollNo: json['roll_no'] != null ? int.tryParse(json['roll_no'].toString()) : null,
      totalAmount: parse(json['total_amount']),
      paidAmount: parse(json['paid_amount']),
      pendingAmount: parse(json['pending_amount']),
      status: json['status'] ?? 'Pending',
      dueDate: json['due_date']?.toString().split('T').first,
      assignedAt: json['assigned_at']?.toString(),
      tuitionFee: parse(json['tuition_fee']),
      examFee: parse(json['exam_fee']),
      transportFee: parse(json['transport_fee']),
      libraryFee: parse(json['library_fee']),
      sportsFee: parse(json['sports_fee']),
      miscellaneousFee: parse(json['miscellaneous_fee']),
    );
  }

  /// Status → Color mapping
  static const Map<String, int> statusColors = {
    'Paid': 0xFF10B981,
    'Partial': 0xFFF59E0B,
    'Pending': 0xFF3B82F6,
    'Overdue': 0xFFEF4444,
  };

  int get statusColor => statusColors[status] ?? 0xFF6B7280;
  double get progressPercent => totalAmount > 0 ? (paidAmount / totalAmount).clamp(0.0, 1.0) : 0.0;
}

class FeePayment {
  final int id;
  final int assignmentId;
  final String studentId;
  final double amount;
  final String paymentMode;
  final String? referenceNo;
  final String? note;
  final String? paidAt;

  const FeePayment({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.amount,
    required this.paymentMode,
    this.referenceNo,
    this.note,
    this.paidAt,
  });

  factory FeePayment.fromJson(Map<String, dynamic> json) => FeePayment(
    id: json['id'] as int,
    assignmentId: json['assignment_id'] as int,
    studentId: json['student_id'] ?? '',
    amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
    paymentMode: json['payment_mode'] ?? 'Cash',
    referenceNo: json['reference_no'],
    note: json['note'],
    paidAt: json['paid_at']?.toString(),
  );
}
