import 'package:flutter/material.dart';

class ClassReportScreen extends StatefulWidget {
  final String classId;
  final String subject;

  const ClassReportScreen({super.key, required this.classId, required this.subject});

  @override
  State<ClassReportScreen> createState() => _ClassReportScreenState();
}

class _ClassReportScreenState extends State<ClassReportScreen> {
  String _searchQuery = '';
  String _activeFilter = 'All';
  String _activeSort = 'Name (A-Z)';
  int? _sortColumnIndex;
  bool _isAscending = true;

  final List<Map<String, dynamic>> _allData = [
    {'name': 'Parth Shinde', 'midSem': 85, 'oral': 18, 'internal': 22, 'total': 125, 'max': 150},
    {'name': 'Rahul Gupta', 'midSem': 78, 'oral': 15, 'internal': 20, 'total': 113, 'max': 150},
    {'name': 'Sneha Patil', 'midSem': 92, 'oral': 19, 'internal': 24, 'total': 135, 'max': 150},
    {'name': 'Amit Verma', 'midSem': 45, 'oral': 10, 'internal': 12, 'total': 67, 'max': 150},
    {'name': 'Priya Rai', 'midSem': 88, 'oral': 17, 'internal': 21, 'total': 126, 'max': 150},
    {'name': 'Vikram Seth', 'midSem': 35, 'oral': 8, 'internal': 10, 'total': 53, 'max': 150},
  ];

  List<Map<String, dynamic>> get _filteredData {
    List<Map<String, dynamic>> filtered = _allData.where((student) {
      final matchesSearch = student['name'].toLowerCase().contains(_searchQuery.toLowerCase());
      final percentage = (student['total'] / student['max']) * 100;
      
      bool matchesFilter = true;
      if (_activeFilter == 'Toppers') {
        matchesFilter = percentage >= 80;
      } else if (_activeFilter == 'At Risk') {
        matchesFilter = percentage < 50;
      }
      
      return matchesSearch && matchesFilter;
    }).toList();

    // Explicit Sort Dropdown Logic
    switch (_activeSort) {
      case 'High Marks':
        filtered.sort((a, b) => b['total'].compareTo(a['total']));
        break;
      case 'Low Marks':
        filtered.sort((a, b) => a['total'].compareTo(b['total']));
        break;
      case 'Name (A-Z)':
        filtered.sort((a, b) => a['name'].compareTo(b['name']));
        break;
      case 'Name (Z-A)':
        filtered.sort((a, b) => b['name'].compareTo(a['name']));
        break;
    }

    // Column Header Sorting (Override if active)
    if (_sortColumnIndex != null) {
      filtered.sort((a, b) {
        dynamic aVal = _getSortValue(a, _sortColumnIndex!);
        dynamic bVal = _getSortValue(b, _sortColumnIndex!);
        int result = aVal is String ? aVal.compareTo(bVal) : aVal.compareTo(bVal);
        return _isAscending ? result : -result;
      });
    }

    return filtered;
  }

  dynamic _getSortValue(Map<String, dynamic> student, int columnIndex) {
    switch (columnIndex) {
      case 0: return student['name'];
      case 1: return student['midSem'];
      case 2: return student['oral'];
      case 3: return student['internal'];
      case 4: return student['total'];
      default: return 0;
    }
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _isAscending = ascending;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Marks Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            onPressed: () => _showExportDialog(context, 'PDF'),
            tooltip: 'Export as PDF',
          ),
          IconButton(
            icon: const Icon(Icons.grid_on_rounded),
            onPressed: () => _showExportDialog(context, 'Excel'),
            tooltip: 'Export as Excel',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Fixed Header Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildReportHeader(),
                const SizedBox(height: 16),
                _buildSearchBar(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildFilterChips()),
                    _buildSortDropdown(),
                  ],
                ),
              ],
            ),
          ),
          
          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  _buildAIHeatmap(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Student Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                      Text('${_filteredData.length} records found', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildReportTable(_filteredData),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (val) => setState(() => _searchQuery = val),
      decoration: InputDecoration(
        hintText: 'Search student name...',
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['All', 'Toppers', 'At Risk'].map((filter) {
          final isSelected = _activeFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(filter, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _activeFilter = filter);
              },
              selectedColor: const Color(0xFF1E3A8A),
              backgroundColor: Colors.grey.shade200,
              showCheckmark: false,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _activeSort,
          icon: const Icon(Icons.sort_rounded, size: 18, color: Color(0xFF1E3A8A)),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
          items: ['Name (A-Z)', 'Name (Z-A)', 'High Marks', 'Low Marks'].map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          onChanged: (val) {
            setState(() {
              _activeSort = val!;
              _sortColumnIndex = null; // Clear column sort when using dropdown
            });
          },
        ),
      ),
    );
  }

  Widget _buildReportHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
          child: const Icon(Icons.assessment_rounded, color: Color(0xFF1E3A8A), size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.subject, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Class: ${widget.classId} • Term 1 Report', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        _buildStatCard('Class Avg', '76.2%', Colors.blue),
        const SizedBox(width: 10),
        _buildStatCard('Passed', '82%', Colors.green),
        const SizedBox(width: 10),
        _buildStatCard('Low Perf', '2', Colors.red),
      ],
    );
  }

  Widget _buildAIHeatmap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
           children: [
             Icon(Icons.auto_awesome, color: Colors.purple.shade300, size: 20),
             const SizedBox(width: 8),
             const Text('AI Predictive Heatmap', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
           ]
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purple.withOpacity(0.2)),
            boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Students identified at risk of failing based on trajectory and attendance.', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _allData.map((student) {
                  final percentage = (student['total'] / student['max']) * 100;
                  Color heatColor = Colors.green.shade400;
                  String reason = "Stable trajectory. Good engagement.";
                  
                  if (percentage < 50) { 
                    heatColor = Colors.redAccent; 
                    reason = "Critical risk: 15% drop in last two tests."; 
                  } else if (percentage < 80 && student['name'] == 'Rahul Gupta') {
                     // Artificial AI trigger for demo
                     heatColor = Colors.orangeAccent;
                     reason = "Moderate risk: 7% attendance drop detected recently.";
                  }

                  return Tooltip(
                    message: '${student['name']}\n$reason',
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black87, 
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                    ),
                    textStyle: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                    triggerMode: TooltipTriggerMode.tap,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: heatColor.withOpacity(0.15),
                        border: Border.all(color: heatColor, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          student['name'].split(' ').map((e) => e[0]).join().substring(0, 2),
                          style: TextStyle(color: heatColor, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ]
          )
        )
      ]
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTable(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              const Text('No students match your filters', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DataTable(
        columnSpacing: 10,
        horizontalMargin: 12,
        headingRowHeight: 40,
        dataRowHeight: 48,
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _isAscending,
        headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
        columns: [
          DataColumn(label: const Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), onSort: _onSort),
          DataColumn(label: const Text('Mid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), onSort: _onSort, numeric: true),
          DataColumn(label: const Text('Oral', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), onSort: _onSort, numeric: true),
          DataColumn(label: const Text('Int', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), onSort: _onSort, numeric: true),
          DataColumn(label: const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), onSort: _onSort, numeric: true),
        ],
        rows: data.map((item) {
          final isAtRisk = (item['total'] / item['max']) < 0.5;
          return DataRow(cells: [
            DataCell(Text(item['name'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
            DataCell(Text(item['midSem'].toString(), style: const TextStyle(fontSize: 12))),
            DataCell(Text(item['oral'].toString(), style: const TextStyle(fontSize: 12))),
            DataCell(Text(item['internal'].toString(), style: const TextStyle(fontSize: 12))),
            DataCell(Text(
              item['total'].toString(), 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isAtRisk ? Colors.red : Colors.blueAccent)
            )),
          ]);
        }).toList(),
      ),
    );
  }

  void _showExportDialog(BuildContext context, String format) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export as $format'),
        content: Text('Do you want to download the filtered marks report (${_filteredData.length} students) in $format format?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Exporting Report as $format... Please check your downloads.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }
}
