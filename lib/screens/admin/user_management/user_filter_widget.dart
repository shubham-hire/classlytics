import 'package:flutter/material.dart';

class UserFilterWidget extends StatelessWidget {
  final String selectedRole;
  final String selectedDept;
  final String selectedStatus;
  final String selectedSort;
  final Function(String role, String dept, String status, String sort) onFiltersChanged;

  const UserFilterWidget({
    super.key,
    required this.selectedRole,
    required this.selectedDept,
    required this.selectedStatus,
    required this.selectedSort,
    required this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildDropdown(
              label: 'User Type',
              value: selectedRole,
              items: ['', 'Student', 'Teacher', 'Parent', 'Admin'],
              onChanged: (val) => onFiltersChanged(val ?? '', selectedDept, selectedStatus, selectedSort),
            ),
            const SizedBox(width: 10),
            _buildDropdown(
              label: 'Department',
              value: selectedDept,
              items: [
                '',
                'Computer Science',
                'Information Technology',
                'Mechanical Engineering',
                'Electronics & TC',
                'Civil Engineering',
                'Applied Sciences'
              ],
              onChanged: (val) => onFiltersChanged(selectedRole, val ?? '', selectedStatus, selectedSort),
            ),
            const SizedBox(width: 10),
            _buildDropdown(
              label: 'Status',
              value: selectedStatus,
              items: ['', 'active', 'inactive'],
              onChanged: (val) => onFiltersChanged(selectedRole, selectedDept, val ?? '', selectedSort),
            ),
            const SizedBox(width: 10),
            _buildDropdown(
              label: 'Sort By',
              value: selectedSort,
              items: ['', 'name_asc', 'name_desc', 'newest', 'oldest'],
              onChanged: (val) => onFiltersChanged(selectedRole, selectedDept, selectedStatus, val ?? ''),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    String getDisplayLabel(String item) {
      if (item.isEmpty) return 'All $label';
      switch (item) {
        case 'name_asc': return 'Name (A-Z)';
        case 'name_desc': return 'Name (Z-A)';
        case 'newest': return 'Recently Added';
        case 'oldest': return 'Oldest';
        case 'active': return 'Active';
        case 'inactive': return 'Inactive';
        default: return item;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                getDisplayLabel(item),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
