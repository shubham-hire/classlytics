import 'package:flutter/material.dart';

class TimetableManagementScreen extends StatefulWidget {
  const TimetableManagementScreen({super.key});

  @override
  State<TimetableManagementScreen> createState() => _TimetableManagementScreenState();
}

class _TimetableManagementScreenState extends State<TimetableManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  int _selectedDayIndex = 0;

  final Map<String, List<Map<String, dynamic>>> _schedule = {
    'Monday': [
      {'time': '8:00 - 9:00', 'subject': 'Mathematics', 'class': 'TE IT A', 'room': 'Room 201', 'color': Colors.blue},
      {'time': '9:00 - 10:00', 'subject': 'Physics', 'class': 'TE IT B', 'room': 'Lab 02', 'color': Colors.orange},
      {'time': '10:30 - 11:30', 'subject': 'Computer Science', 'class': 'BE IT A', 'room': 'Room 305', 'color': Colors.teal},
      {'time': '11:30 - 12:30', 'subject': 'Free Period', 'class': '', 'room': '', 'color': Colors.grey},
    ],
    'Tuesday': [
      {'time': '8:00 - 9:00', 'subject': 'Chemistry', 'class': 'TE IT A', 'room': 'Lab 01', 'color': Colors.green},
      {'time': '9:00 - 10:00', 'subject': 'Mathematics', 'class': 'BE IT A', 'room': 'Room 201', 'color': Colors.blue},
    ],
    'Wednesday': [
      {'time': '10:00 - 11:00', 'subject': 'Physics', 'class': 'TE IT A', 'room': 'Lab 02', 'color': Colors.orange},
      {'time': '11:00 - 12:00', 'subject': 'Computer Science', 'class': 'TE IT B', 'room': 'Room 305', 'color': Colors.teal},
    ],
    'Thursday': [
      {'time': '8:00 - 9:00', 'subject': 'Mathematics', 'class': 'TE IT A', 'room': 'Room 201', 'color': Colors.blue},
    ],
    'Friday': [
      {'time': '9:00 - 10:00', 'subject': 'Chemistry', 'class': 'BE IT A', 'room': 'Lab 01', 'color': Colors.green},
      {'time': '11:00 - 12:00', 'subject': 'Physics Lab', 'class': 'TE IT B', 'room': 'Lab 02', 'color': Colors.orange},
    ],
    'Saturday': [],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddPeriodSheet() {
    String selectedSubject = 'Mathematics';
    String selectedClass = 'TE IT A';
    String selectedRoom = 'Room 201';
    String selectedTime = '8:00 - 9:00';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 24, left: 24, right: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Period — ${_days[_selectedDayIndex]}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                ),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedTime,
              decoration: _inputDeco('Time Slot', Icons.schedule_rounded),
              items: ['8:00 - 9:00', '9:00 - 10:00', '10:30 - 11:30', '11:30 - 12:30', '2:00 - 3:00', '3:00 - 4:00']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => selectedTime = v!,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedSubject,
              decoration: _inputDeco('Subject', Icons.book_rounded),
              items: ['Mathematics', 'Physics', 'Chemistry', 'Computer Science', 'History', 'Free Period']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => selectedSubject = v!,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedClass,
              decoration: _inputDeco('Class', Icons.class_rounded),
              items: ['TE IT A', 'TE IT B', 'BE IT A', 'BE IT B']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => selectedClass = v!,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedRoom,
              decoration: _inputDeco('Room', Icons.room_rounded),
              items: ['Room 201', 'Room 305', 'Lab 01', 'Lab 02', 'Auditorium']
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => selectedRoom = v!,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                final colors = [Colors.blue, Colors.orange, Colors.teal, Colors.green, Colors.grey, Colors.purple];
                final colorMap = {
                  'Mathematics': Colors.blue,
                  'Physics': Colors.orange,
                  'Chemistry': Colors.green,
                  'Computer Science': Colors.teal,
                  'History': Colors.purple,
                  'Free Period': Colors.grey,
                };
                setState(() {
                  _schedule[_days[_selectedDayIndex]]!.add({
                    'time': selectedTime,
                    'subject': selectedSubject,
                    'class': selectedClass,
                    'room': selectedRoom,
                    'color': colorMap[selectedSubject] ?? colors[0],
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Period added!'), backgroundColor: Colors.green),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Period', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, color: Colors.grey),
    filled: true,
    fillColor: const Color(0xFFF1F5F9),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  @override
  Widget build(BuildContext context) {
    final currentDayPeriods = _schedule[_days[_selectedDayIndex]] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Timetable', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'My Schedule'),
            Tab(text: 'Class-wise View'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPeriodSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Period'),
        backgroundColor: const Color(0xFF1E3A8A),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: My Schedule (Day-by-day view) ──
          Column(
            children: [
              // Day selector horizontal scroll
              Container(
                color: const Color(0xFF1E3A8A),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _days.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final isSelected = _selectedDayIndex == index;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDayIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Text(
                            _days[index].substring(0, 3),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              Expanded(
                child: currentDayPeriods.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.free_breakfast_rounded, size: 56, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            const Text('No classes scheduled', style: TextStyle(color: Colors.grey, fontSize: 16)),
                            const SizedBox(height: 8),
                            const Text('Tap + to add a period', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: currentDayPeriods.length,
                        itemBuilder: (context, index) {
                          final period = currentDayPeriods[index];
                          final isFree = period['subject'] == 'Free Period';
                          final color = period['color'] as Color;

                          return Dismissible(
                            key: Key('${_days[_selectedDayIndex]}-$index'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                            ),
                            onDismissed: (_) {
                              setState(() => currentDayPeriods.removeAt(index));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Period removed.')),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border(left: BorderSide(color: color, width: 4)),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 72,
                                    child: Text(
                                      period['time'],
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                    child: Icon(
                                      isFree ? Icons.coffee_rounded : Icons.class_rounded,
                                      color: color,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(period['subject'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        if (!isFree) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            '${period['class']} • ${period['room']}',
                                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (!isFree)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                      child: Text(period['room'], style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),

          // ── Tab 2: Class-wise Weekly View ──
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Weekly Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 16),
                ..._days.where((d) => (_schedule[d] ?? []).isNotEmpty).map((day) {
                  final periods = _schedule[day]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A).withOpacity(0.07),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF1E3A8A)),
                            const SizedBox(width: 8),
                            Text(day, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A8A))),
                            const Spacer(),
                            Text('${periods.length} period(s)', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      ...periods.map((p) {
                        final color = p['color'] as Color;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8, left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border(left: BorderSide(color: color, width: 3)),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 3))],
                          ),
                          child: Row(
                            children: [
                              Text(p['time'], style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 16),
                              Expanded(child: Text(p['subject'], style: const TextStyle(fontWeight: FontWeight.bold))),
                              if ((p['class'] as String).isNotEmpty)
                                Text(p['class'], style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
