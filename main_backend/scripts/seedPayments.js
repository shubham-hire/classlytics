require('dotenv').config();
const db = require('../config/db');
const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcryptjs');

async function seedPayments() {
    console.log('🚀 Starting Payment & Fee Seeding...');

    try {
        // --- CLEANUP PREVIOUS TEST DATA ---
        console.log('🧹 Cleaning up previous test data...');
        const testEmails = ['shubham_parent@classlytics.in', 'parent@test.com', 'student@test.com'];
        const testStudentIds = ['STU-PAY-001'];

        await db.query('DELETE FROM student_fee_assignments WHERE student_id IN (?)', [testStudentIds]);
        await db.query('DELETE FROM fee_payments WHERE student_id IN (?)', [testStudentIds]);
        await db.query('DELETE FROM students WHERE id IN (?)', [testStudentIds]);
        await db.query('DELETE FROM parents WHERE email IN (?)', [testEmails]);
        await db.query('DELETE FROM users WHERE email IN (?)', [testEmails]);
        await db.query('DELETE FROM fees WHERE student_id IN (?)', [testStudentIds]);
        // Note: keeping classes and divisions as they are less likely to cause conflicts
        
        // --- START SEEDING ---
        const [deptResult] = await db.execute(
            'INSERT INTO departments (name) VALUES (?) ON DUPLICATE KEY UPDATE name=name',
            ['Computer Science']
        );
        const deptId = deptResult.insertId || 1;

        // 2. Create a Class if not exists
        await db.execute(
            'INSERT INTO classes (id, name, section, teacher_id) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE name=name',
            ['CLS-PAY-10A', 'Class 10', 'A', null]
        );

        // 3. Create a Parent User
        const parentUserId = uuidv4();
        const parentEmail = 'shubham_parent@classlytics.in';
        const parentPass = 'shubham@123';
        const hashedPassword = await bcrypt.hash(parentPass, 10);
        await db.execute(
            'INSERT INTO users (id, name, email, password, role) VALUES (?, ?, ?, ?, ?)',
            [parentUserId, 'Rajesh Sharma', parentEmail, hashedPassword, 'Parent']
        );

        // 4. Create Parent Profile
        const parentId = uuidv4();
        await db.execute(
            'INSERT INTO parents (id, user_id, name, email, password, relation) VALUES (?, ?, ?, ?, ?, ?)',
            [parentId, parentUserId, 'Rajesh Sharma', parentEmail, hashedPassword, 'Father']
        );

        // 5. Create a Student User
        const studentUserId = uuidv4();
        await db.execute(
            'INSERT INTO users (id, name, email, password, role) VALUES (?, ?, ?, ?, ?)',
            [studentUserId, 'Aarav Sharma', 'student@test.com', hashedPassword, 'Student']
        );

        // 6. Create Division for the class
        const [divResult] = await db.execute(
            'INSERT INTO divisions (class_id, division_name) VALUES (?, ?) ON DUPLICATE KEY UPDATE division_name=division_name',
            ['CLS-PAY-10A', 'A']
        );
        let divId;
        if (divResult.insertId) {
            divId = divResult.insertId;
        } else {
            const [divRows] = await db.execute('SELECT id FROM divisions WHERE class_id = ? AND division_name = ?', ['CLS-PAY-10A', 'A']);
            divId = divRows[0].id;
        }

        // 7. Create Student Profile
        const studentId = 'STU-PAY-001';
        await db.execute(
            'INSERT INTO students (id, user_id, parent_id, division_id, dept, current_year) VALUES (?, ?, ?, ?, ?, ?)',
            [studentId, studentUserId, parentId, divId, 'Computer Science', '1']
        );

        // Link child_id in parents
        await db.execute('UPDATE parents SET child_id = ? WHERE id = ?', [studentId, parentId]);

        // 8. Create Fee Structure for the class
        const [feeStructResult] = await db.execute(
            `INSERT INTO fee_structures (class_id, academic_year, title, tuition_fee, exam_fee, transport_fee, library_fee) 
             VALUES (?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE title=title`,
            ['CLS-PAY-10A', '2024-25', 'Annual School Fees', 45000.00, 2000.00, 5000.00, 1000.00]
        );
        
        const [structRows] = await db.execute('SELECT id FROM fee_structures WHERE class_id = ? AND academic_year = ?', ['CLS-PAY-10A', '2024-25']);
        const feeStructId = structRows[0].id;

        // 9. Assign Fee to Student (New Structure)
        const totalAmount = 53000.00; // sum of fees
        const paidAmount = 20000.00; // partial payment
        await db.execute(
            `INSERT IGNORE INTO student_fee_assignments (student_id, fee_structure_id, total_amount, paid_amount, status, due_date) 
             VALUES (?, ?, ?, ?, ?, ?)`,
            [studentId, feeStructId, totalAmount, paidAmount, 'Partial', '2025-03-31']
        );

        // 10. Assign Fee to Student (Old Structure - fees table)
        await db.execute('DELETE FROM fees WHERE student_id = ?', [studentId]);
        await db.execute(
            `INSERT INTO fees (student_id, total_fee, paid_amount, due_date, semester)
             VALUES (?, ?, ?, ?, ?)`,
             [studentId, totalAmount, paidAmount, '2025-03-31', 'Sem 1']
        );

        console.log('✅ Seeding completed successfully!');
        console.log('--- TEST CREDENTIALS ---');
        console.log(`Parent Email: ${parentEmail}`);
        console.log(`Password: ${parentPass}`);
        console.log('Student ID: STU-PAY-001');
        console.log(`Total Fees: ₹${totalAmount}`);
        console.log(`Paid Amount: ₹${paidAmount}`);
        console.log(`Remaining: ₹${totalAmount - paidAmount}`);
        console.log('------------------------');

    } catch (error) {
        console.error('❌ Seeding failed:', error);
    } finally {
        process.exit();
    }
}

seedPayments();
