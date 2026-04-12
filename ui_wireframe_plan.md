# CLASSLYTICS — TEACHER ERP UX & WIREFRAME BLUEPRINT 🎨📐

To ensure a seamless, industry-level User Experience (UX), we need to standardize the layout, navigation, and module interaction across the application. 

Below is the definitive Wireframe and UI Flow guide for every module we build.

---

## 🎨 GLOBAL DESIGN SYSTEM
- **Primary Color:** Deep Blue (`#1E3A8A`) - Represents trust and professionalism.
- **Accent Color:** Bright Orange (`#F97316`) - Highlights actionable buttons (Add Marks, Submit).
- **Backgrounds:** Off-white (`#F8F9FA`) to reduce eye strain, with crisp White (`#FFFFFF`) content cards.
- **Typography:** Modern Sans-Serif (Inter or Roboto default), large headings (`w800` weight) for scannability.
- **Card Styling:** Soft borders (`BorderRadius.circular(16)`), subtle drop shadows (`blurRadius: 10, offset: (0,4)`).

---

## 🧭 SYSTEM NAVIGATION FLOW
```text
[ LOGIN ]
   ⬇
[ TEACHER DASHBOARD (Home Base) ]
   ├── Quick Actions ──────────▶ [ Gradebook ] / [ Assignments ] / [ Messages ]
   ├── Today's Schedule 
   ├── Pending Tasks
   └── My Classes Button ──────▶ [ CLASS LIST SCREEN ]
                                       ⬇
                                 [ STUDENT LIST SCREEN ]
                                       ⬇
                                 [ STUDENT DETAIL (CORE HUB) ]
                                   ├── 1. Profile & Medical
                                   ├── 2. Behavior Logs
                                   ├── 3. Attendance Section
                                   ├── 4. Academic History
                                   └── 5. AI Insights & Risk Prediction
```

---

## 📱 SCREEN WIREFRAMES & MODULE SPECIFICATIONS

### 1. Teacher Dashboard (Home Base)
**Goal:** Answer "What do I need to do right now?" 
```text
+---------------------------------------------------+
|  [≡]  Teacher Dashboard                     [🔔]  |
+---------------------------------------------------+
|  [ Overview Metrics ]                             |
|  ( 👥 30 Students ) ( ✅ 85% Att. ) ( 📊 72 Avg )   |
|                                                   |
|  [ Today's Schedule ]                             |
|  +---------------------------------------------+  |
|  | 09:00 AM | Math (10-A)     | Room 101       |  |
|  | 11:30 AM | Free Slot       | Staff Rm       |  |
|  +---------------------------------------------+  |
|                                                   |
|  [ Quick Actions (Grid) ]                         |
|  [📋 Mark Att.] [📝 Gradebook]                    |
|  [✉️ Msg Class] [➕ Assignment]                   |
|                                                   |
|  [ Pending Tasks ]                                |
|  - Grade Physics (High Priority)     [Resolve]    |
|                                                   |
|  [ At-Risk Students (AI) ]                        |
|  - Parth (High Risk 🔴)              [ > ]        |
+---------------------------------------------------+
```

### 2. Advanced Gradebook Screen
**Goal:** Spreadsheet efficiency on a mobile/tablet screen.
```text
+---------------------------------------------------+
|  [<]  Gradebook (Class 10-A)            [ SAVE ]  |
+---------------------------------------------------+
|  Filters: [ Midterm ▾ ] [ Mathematics ▾ ]         |
|                                                   |
|  +----------+-------------------+---------------+ |
|  | Roll No. | Student Name      | Grade Entry   | |
|  +----------+-------------------+---------------+ |
|  | 1        | Parth             | [ ___ ] / 100 | |
|  | 2        | Alice             | [ ___ ] / 100 | |
|  | 3        | Bob               | [ ___ ] / 100 | |
|  +----------+-------------------+---------------+ |
|                                                   |
|  (Scrolls Horizontally/Vertically like Excel)     |
+---------------------------------------------------+
```

### 3. Student Detail Hub (360° View)
**Goal:** The Ultimate Profile view combining static data and dynamic AI feedback.
```text
+---------------------------------------------------+
|  [<]  Student Profile                       [⋮]   |
+---------------------------------------------------+
|  [ Profile Header ]                               |
|  (Avatar) Parth | ID: S1 | Class 10-A             |
|  ⚠️ Allergy: Peanuts  (Health Banner)             |
|                                                   |
|  [ Smart Suggestions & Risk Level ]               |
|  | Risk: HIGH 🔴 | "Revise basic concepts"      | |
|                                                   |
|  [ Academic Summary ]                             |
|  Average: 55% | Attendance: 60%                   |
|                                                   |
|  [ Behavior Logs module ]                         |
|  + "Helped peer" (Green tag)                      |
|  - "Forgot textbook" (Red tag)           [ +Add ] |
|                                                   |
|  [ Quick Operations ]                             |
|  [ Mark Attendance (P/A) ]  [ Add Single Test ]   |
|                                                   |
|  [ AI Insights (Expandable) ]                     |
|  ✨ Performance declining in Math                 |
+---------------------------------------------------+
```

### 4. Assignments & Homework Manager
**Goal:** Track digital tasks and due dates.
```text
+---------------------------------------------------+
|  [<]  Assignments (Class 10-A)              [+]   |
+---------------------------------------------------+
|  [ Active ]   [ Past Due ]   [ Graded ]           |
|                                                   |
|  [ Assignment Card ]                              |
|  | Chapter 4 Physics  (Due: Tomorrow)           | |
|  | 24/30 Submitted                      [ Grade ] | |
|  +----------------------------------------------+ |
|                                                   |
|   ( + Button opens "Create Task" overlay )        |
+---------------------------------------------------+
```

### 5. Communication / Messaging Inbox
**Goal:** Clean, chat-like interface.
```text
+---------------------------------------------------+
|  [<]  Messages / Announcements              [+]   |
+---------------------------------------------------+
|  [ Announcements (Broadcast) ]                    |
|  - "Sports Day Tomorrow!" - Admin                 |
|                                                   |
|  [ Direct Messages ]                              |
|  +----------------------------------------------+ |
|  | (Avatar) Parent of Parth                     | |
|  | "Is he improving in Math?"          (10:00AM)| |
|  +----------------------------------------------+ |
+---------------------------------------------------+
```

---

## ⚡ NEXT ENGINEERING STEPS (Code Implementation)
Now that the UI parameters and wireframes are rigidly defined:

1. **Refining Existing UI:** We will ensure `ClassListScreen` and `StudentListScreen` natively follow the global design system (proper soft corner cards instead of generic list tiles).
2. **Implementing Behavior Tracking:** Build the `Behavior Logs module` into the `StudentDetailScreen` hub (as drawn in wireframe #3).
3. **Communication Screen Design:** Convert Wireframe #5 into actual Flutter code (`messages_screen.dart`).
