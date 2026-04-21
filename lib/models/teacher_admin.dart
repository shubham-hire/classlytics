import 'dart:convert';

class TeacherAdmin {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String employeeId;
  final String? department;
  final String designation;
  final String joiningDate;
  final String employmentType;
  final String qualification;
  final String specialization;
  final int experienceYears;
  final String previousSchool;
  final String gender;
  final String dob;
  final String? profileImg;
  final String? salaryStructureId;
  final String? bankAccountNo;
  final String? bankIfsc;
  final String? emergencyContact;
  final bool isActive;

  TeacherAdmin({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.employeeId,
    this.department,
    required this.designation,
    required this.joiningDate,
    required this.employmentType,
    required this.qualification,
    required this.specialization,
    required this.experienceYears,
    required this.previousSchool,
    required this.gender,
    required this.dob,
    this.profileImg,
    this.salaryStructureId,
    this.bankAccountNo,
    this.bankIfsc,
    this.emergencyContact,
    required this.isActive,
  });

  factory TeacherAdmin.fromJson(Map<String, dynamic> json) {
    return TeacherAdmin(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      employeeId: json['employee_id'] ?? '',
      department: json['department'],
      designation: json['designation'] ?? '',
      joiningDate: json['joining_date']?.toString().split('T').first ?? '',
      employmentType: json['employment_type'] ?? 'Full-time',
      qualification: json['qualification'] ?? '',
      specialization: json['specialization'] ?? '',
      experienceYears: json['experience_years'] ?? 0,
      previousSchool: json['previous_school'] ?? '',
      gender: json['gender'] ?? '',
      dob: json['dob']?.toString().split('T').first ?? '',
      profileImg: json['profile_img'],
      salaryStructureId: json['salary_structure_id'],
      bankAccountNo: json['bank_account_no'],
      bankIfsc: json['bank_ifsc'],
      emergencyContact: json['emergency_contact'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }
}
