# Classlytics — Complete Teacher Module (Industry Level)
**Status: Phase 3 Development (Advanced Modules)**

The system is being built on an MVC architecture with a Flutter frontend and Node.js/Express backend. Data persistence is currently managed via an in-memory `data/storage.js` layer (designed for an easy future transition to MongoDB).

---

## ✅ Phase 1: Core Foundation (Completed)

### Module 1: Teacher Dashboard
- **Backend**: `GET /teacher/dashboard` 
- **Frontend**: `TeacherDashboardScreen` displaying overall stats (Total Students, Avg Attendance, Avg Marks).
- **Recent Upgrades**: Added industry-level UI sections: *Today's Schedule*, *Quick Actions*, *Pending Tasks*, and *Announcements Feed*.

### Module 2: Class Management
- **Backend**: `GET /teacher/classes`
- **Frontend**: `ClassListScreen` serving as a dynamic list of classes managed by the teacher.

### Module 3: Student Management
- **Backend**: `GET /class/:classId/students`
- **Frontend**: `StudentListScreen` with filtering and rapid search.

---

## ✅ Phase 2: Actionable Data & Insights (Completed)

### Module 4: Student Detail (Core Hub)
- **Frontend**: `StudentDetailScreen` completely revamped into a 360-view dashboard linking all tracking metrics dynamically.

### Module 5: Attendance System
- **Backend**: `POST /attendance` & `GET /attendance/:studentId`
- **Frontend**: Interactive presence setting, status indication, percentage calculation (Real-time).

### Module 6: Marks / Assessment System
- **Backend**: `POST /marks` & `GET /marks/:studentId`
- **Frontend**: Evaluation entry form, history list view, and live average score computation.

### Module 7: AI Intelligence Layer
- **Backend**: 
   - `GET /student/:id/insights` (Trend finding)
   - `GET /student/:id/risk` (Low/Med/High analysis)
   - `GET /student/:id/suggestions` (Actionable smart tips)
- **Frontend**: Proactive AI cards integrated directly into the `StudentDetailScreen` which refresh automatically upon new data entry.

---

## 🛠️ Phase 3: Reports & Communication (Up Next)

### 📈 Module 8: Reports System
**Backend Target**: 
 - `GET /reports/attendance/:classId` (Class-wide summary)
 - `GET /reports/performance/:studentId` (Full term progression)
 
**Frontend Target**: 
 - `ReportsScreen` showing visual charts, graphs, and exportable data (mocked PDF outputs or simply tabular formatted screens).

### 💬 Module 9: Communication System
**Backend Target**: 
 - `POST /announcements/class/:classId` (Send broadcast)
 - `POST /messages/student/:studentId` (Send direct note)
 - `GET /messages` (Teacher inbox)
 
**Frontend Target**: 
 - `CommunicationHub` or `MessagesScreen`.
 - Integration into the Quick Actions bar on the main Dashboard to send messages efficiently.

---

## ⚙️ Development Rules Maintained:
- **Clean Architecture**: Strong Separation of Concerns (Routes -> Controllers -> Data storage).
- **Responsive UI**: Flutter Stateful logic combined with `FutureBuilder` rendering and `go_router` navigation.
- **REST Compliance**: Clean JSON handshakes and predictable HTTP status behavior.
