
-- Global Sequences for IDs
CREATE TABLE IF NOT EXISTS global_sequences (
    name VARCHAR(50) PRIMARY KEY,
    `last_value` INT DEFAULT 0
);

INSERT IGNORE INTO global_sequences (name, `last_value`) VALUES ('student', 0);

-- Users Table (Handles Admin, Teacher, Student, Parent)
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('Admin', 'Teacher', 'Student', 'Parent') NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    country VARCHAR(100),
    state VARCHAR(100),
    district VARCHAR(100),
    city VARCHAR(100),
    dept VARCHAR(50), -- Added for Teachers/Admins to manage students in same dept
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Classes Table
CREATE TABLE IF NOT EXISTS classes (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    section VARCHAR(10) NOT NULL,
    teacher_id VARCHAR(50),
    FOREIGN KEY (teacher_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Students Table (Global Registration)
CREATE TABLE IF NOT EXISTS students (
    id VARCHAR(50) PRIMARY KEY, -- Permanent Sequential ID (e.g. STU001)
    user_id VARCHAR(50),
    dept VARCHAR(50) NOT NULL,
    current_year VARCHAR(20) NOT NULL,
    dob DATE,
    profile_img VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Class Enrollments (Links Students to specific Divisions/Subjects)
CREATE TABLE IF NOT EXISTS class_enrollments (
    class_id VARCHAR(50),
    student_id VARCHAR(50),
    roll_no INT,
    enrolled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (class_id, student_id),
    FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
);

-- Attendance Table
CREATE TABLE IF NOT EXISTS attendance (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id VARCHAR(50),
    date DATE NOT NULL,
    status ENUM('Present', 'Absent', 'Late') NOT NULL,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
);

-- Marks Table
CREATE TABLE IF NOT EXISTS marks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id VARCHAR(50),
    subject VARCHAR(50) NOT NULL,
    score FLOAT NOT NULL,
    max_score FLOAT NOT NULL,
    type ENUM('Quiz', 'Midterm', 'Final', 'Assignment') NOT NULL,
    date DATE NOT NULL,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
);

-- Assignments Table
CREATE TABLE IF NOT EXISTS assignments (
    id VARCHAR(50) PRIMARY KEY,
    class_id VARCHAR(50),
    teacher_id VARCHAR(50),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    media_url VARCHAR(500) DEFAULT NULL,
    media_type ENUM('image', 'pdf', 'none') DEFAULT 'none',
    deadline DATETIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Submissions Table
CREATE TABLE IF NOT EXISTS submissions (
    id VARCHAR(50) PRIMARY KEY,
    assignment_id VARCHAR(50),
    student_id VARCHAR(50),
    note TEXT,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    score_awarded FLOAT DEFAULT NULL,
    FOREIGN KEY (assignment_id) REFERENCES assignments(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
);

-- Quizzes Table
CREATE TABLE IF NOT EXISTS quizzes (
    id VARCHAR(50) PRIMARY KEY,
    class_id VARCHAR(50),
    teacher_id VARCHAR(50),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    duration_minutes INT NOT NULL DEFAULT 30,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Quiz Questions Table
CREATE TABLE IF NOT EXISTS quiz_questions (
    id VARCHAR(50) PRIMARY KEY,
    quiz_id VARCHAR(50) NOT NULL,
    question TEXT NOT NULL,
    option_a VARCHAR(500) NOT NULL,
    option_b VARCHAR(500) NOT NULL,
    option_c VARCHAR(500) NOT NULL,
    option_d VARCHAR(500) NOT NULL,
    correct_option ENUM('A','B','C','D') NOT NULL,
    marks INT NOT NULL DEFAULT 1,
    FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE
);

-- Quiz Submissions Table
CREATE TABLE IF NOT EXISTS quiz_submissions (
    id VARCHAR(50) PRIMARY KEY,
    quiz_id VARCHAR(50) NOT NULL,
    student_id VARCHAR(50) NOT NULL,
    score INT NOT NULL DEFAULT 0,
    total_marks INT NOT NULL DEFAULT 0,
    time_taken_seconds INT DEFAULT NULL,
    answers JSON DEFAULT NULL,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_quiz_student (quiz_id, student_id),
    FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
);

-- Behavior Logs
CREATE TABLE IF NOT EXISTS behavior_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id VARCHAR(50),
    type ENUM('Positive', 'Negative') NOT NULL,
    remark TEXT,
    date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
);

-- Messages
CREATE TABLE IF NOT EXISTS messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sender_id VARCHAR(50),
    receiver_id VARCHAR(50),
    body TEXT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_read BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Announcements
CREATE TABLE IF NOT EXISTS announcements (
    id INT AUTO_INCREMENT PRIMARY KEY,
    class_id VARCHAR(50),
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE
);

-- Fees Table
CREATE TABLE IF NOT EXISTS fees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id VARCHAR(50) NOT NULL,
    total_fee DECIMAL(10,2) NOT NULL DEFAULT 50000.00,
    paid_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    due_date DATE,
    semester VARCHAR(20) DEFAULT 'Sem 1',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
);
