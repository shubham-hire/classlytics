require('dotenv').config();
const db = require('./config/db');
const { v4: uuidv4 } = require('uuid');

async function seed() {
    try {
        console.log("Seeding database with test users...");
        
        // 1. Teacher account
        const teacherId = uuidv4();
        await db.execute(
            "INSERT INTO users (id, name, email, password, role) VALUES (?, ?, ?, ?, ?)",
            [teacherId, "Rajesh Kumar (Teacher)", "teacher@test.com", "password123", "Teacher"]
        );

        // 2. Class for the teacher
        const classId = uuidv4();
        await db.execute(
            "INSERT INTO classes (id, name, section, teacher_id) VALUES (?, ?, ?, ?)",
            [classId, "Class 10", "A", teacherId]
        );

        // 3. Student account
        const studentUserId = uuidv4();
        await db.execute(
            "INSERT INTO users (id, name, email, password, role) VALUES (?, ?, ?, ?, ?)",
            [studentUserId, "Rahul Sharma (Student)", "student@test.com", "password123", "Student"]
        );

        // Student details
        const studentId = "STU001";
        await db.execute(
            "INSERT INTO students (id, user_id, dept, current_year, dob) VALUES (?, ?, ?, ?, ?)",
            [studentId, studentUserId, "Science", "1st Year", "2005-05-10"]
        );

        // Enroll student in class
        await db.execute(
            "INSERT INTO class_enrollments (class_id, student_id, roll_no) VALUES (?, ?, ?)",
            [classId, studentId, 1]
        );

        console.log("✅ Seeding completed!");
        console.log("\nYou can now login with:");
        console.log("🎓 TEACHER : teacher@test.com / password123");
        console.log("🎒 STUDENT : student@test.com / password123\n");

        process.exit(0);
    } catch (err) {
        console.error("❌ Seeding failed:", err.message);
        process.exit(1);
    }
}

seed();
