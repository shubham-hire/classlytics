
📄 PRODUCT REQUIREMENTS DOCUMENT (PRD)

Product Name (working)

Classlytics (renamed from StudentSafe AI)

⸻

1. 🎯 Product Overview

Problem

Current school systems are:
	•	Fragmented (attendance in one place, assignments in another)
	•	Passive (they show data, don’t act on it)
	•	Useless for parents until it’s too late

Solution

An AI-powered student monitoring platform that:
	•	Tracks academic + behavioral data in real time
	•	Predicts performance trends early
	•	Gives actionable insights (not just charts)

👉 If your app only shows graphs = dead product
👉 If your app tells parents what to do next = valuable product

⸻

2. 👥 Target Users

Primary Users
	•	Students (13–22 years)
	•	Parents
	•	Teachers

Secondary Users
	•	School admins / institutions

⸻

3. 🧩 Core Value Proposition
	•	Parents: “Know before it’s too late”
	•	Teachers: “Identify weak students automatically”
	•	Students: “Get personalized study help without asking”

⸻

4. 🚀 Key Features Breakdown

4.1 Authentication & Roles
	•	Multi-role login:
	•	Admin
	•	Teacher
	•	Student
	•	Parent
	•	Role-based dashboards

⸻

4.2 Student Module
	•	View assignments
	•	Submit homework (file/image/text)
	•	Take quizzes/exams
	•	AI study planner
	•	AI homework assistant (chat-based)

⸻

4.3 Teacher Module
	•	Create assignments/quizzes
	•	Mark attendance
	•	Upload results
	•	View class analytics
	•	Flag students manually

⸻

4.4 Parent Module
	•	Real-time attendance tracking
	•	Performance dashboard
	•	Alerts (low scores, absence)
	•	AI insights:
	•	“Your child is likely to score below average in math”

⸻

4.5 Admin Module
	•	Manage users (CRUD)
	•	Assign roles
	•	Monitor system usage
	•	School-level analytics

⸻

5. 🧠 AI Features (THIS is where you win or lose)

5.1 Performance Prediction
	•	Input:
	•	Attendance
	•	Past scores
	•	Assignment completion
	•	Output:
	•	Predicted score
	•	Risk level (Low / Medium / High)

👉 Use simple models first:
	•	Linear regression
	•	Decision trees

Don’t overcomplicate this.

⸻

5.2 Early Warning System

Triggers:
	•	Attendance < 70%
	•	Scores dropping continuously
	•	Missing assignments

Output:
	•	Alerts to parents & teachers

⸻

5.3 AI Study Planner
	•	Input:
	•	Subjects
	•	Weak areas
	•	Exam dates
	•	Output:
	•	Daily schedule

⸻

5.4 AI Homework Assistant
	•	Chat-based assistant:
	•	Solve doubts
	•	Explain concepts
	•	Powered by LLM API (OpenAI / Claude)

⸻

5.5 Smart Notifications
	•	“Your child missed 2 assignments this week”
	•	“Performance declining in Science”

👉 Notifications must feel human, not robotic

⸻

6. 🧱 System Architecture

Frontend
	•	Flutter / React Native (choose ONE, don’t be confused)
	•	My recommendation: Flutter (faster for beginners)

Backend
	•	Firebase:
	•	Auth
	•	Firestore (DB)
	•	Cloud Functions

AI Layer
	•	Python microservice OR API-based
	•	Use:
	•	OpenAI API for assistant
	•	Simple ML models for prediction

Dashboard
	•	Charts using:
	•	Chart.js / Flutter charts

⸻

7. 🔄 User Flow

Student Flow

Login → Dashboard → Assignments → Submit → Get AI feedback

Teacher Flow

Login → Create Assignment → Track submissions → View analytics

Parent Flow

Login → View child dashboard → Get alerts → See predictions

⸻

8. 📊 Data Model (Simplified)

Users
	•	id
	•	role
	•	name
	•	email

Students
	•	userId
	•	class
	•	subjects

Attendance
	•	studentId
	•	date
	•	status

Assignments
	•	id
	•	teacherId
	•	subject
	•	deadline

Submissions
	•	studentId
	•	assignmentId
	•	file/url

Scores
	•	studentId
	•	subject
	•	marks

⸻

9. 📈 Success Metrics (KPIs)
	•	Daily active users
	•	Assignment completion rate
	•	Parent engagement rate
	•	Prediction accuracy
	•	Notification click rate

⸻

10. ⚠️ Risks (Don’t ignore this)
	•	Schools already use ERP systems → competition
	•	AI predictions may be inaccurate → trust issues
	•	Too many features → you won’t finish anything

👉 Biggest risk: you try to build everything and ship nothing

⸻

11. 🧪 MVP Scope (What you ACTUALLY build)

Cut the fluff. Build this:

Must-have:
	•	Login system
	•	Student dashboard
	•	Teacher uploads assignments
	•	Student submits
	•	Parent sees data
	•	Basic analytics (no AI yet)

Add later:
	•	Prediction model
	•	Study planner
	•	AI assistant

👉 If you try to build AI first, you’ll fail.

⸻

12. 🛠 Development Roadmap

Phase 1 (Week 1–2)
	•	Auth + roles
	•	Basic UI

Phase 2 (Week 3–4)
	•	Assignments + submissions
	•	Attendance

Phase 3 (Week 5)
	•	Dashboards + charts

Phase 4 (Week 6+)
	•	AI features

⸻

13. 💣 Brutal Truth

Your idea is NOT unique.

What makes it strong:
	•	Execution
	•	Simplicity
	•	Useful AI (not fake AI)

If your app becomes:

“just another school app with charts”

→ It’s garbage.

If your app becomes:

“an assistant that actually helps parents act early”
