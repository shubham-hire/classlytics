const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');

const initDb = async () => {
    // 1. Create a temporary connection without database name to ensure DB exists
    const connectionConfig = {
        host: process.env.DB_HOST || 'localhost',
        user: process.env.DB_USER || 'root',
        password: process.env.DB_PASSWORD || '',
    };

    try {
        const tempConn = await mysql.createConnection(connectionConfig);
        await tempConn.query(`CREATE DATABASE IF NOT EXISTS \`${process.env.DB_NAME || 'classlytics_db'}\``);
        await tempConn.end();
        console.log(`✅ [DB INIT] Database ensured: ${process.env.DB_NAME || 'classlytics_db'}`);
    } catch (err) {
        console.error('❌ [DB INIT ERROR] Could not create/check database:', err.message);
        return; // Stop if we can't even ensure the database exists
    }

    // 2. Now use the exported promisePool from db.js to create tables
    const db = require('./db');
    try {
        console.log('⏳ [DB INIT] Creating tables...');
        const schemaPath = path.join(__dirname, 'schema.sql');
        const schema = fs.readFileSync(schemaPath, 'utf8');

        // Split schema into individual queries and strip comments
        const queries = schema
            .split(';')
            .map(q => q
                .split('\n')
                .filter(line => !line.trim().startsWith('--'))
                .join('\n')
                .trim()
            )
            .filter(q => q.length > 0);

        for (let query of queries) {
            await db.execute(query);
        }

        console.log('✅ [DB INIT] All tables initialized successfully.');

        // 3. Migration: Add missing columns if they don't exist
        const columnsToEnsure = [
            { table: 'users', col: 'phone', type: 'VARCHAR(20)' },
            { table: 'users', col: 'address', type: 'TEXT' },
            { table: 'users', col: 'country', type: 'VARCHAR(100)' },
            { table: 'users', col: 'state', type: 'VARCHAR(100)' },
            { table: 'users', col: 'district', type: 'VARCHAR(100)' },
            { table: 'users', col: 'city', type: 'VARCHAR(100)' },
            { table: 'users', col: 'dept', type: 'VARCHAR(50)' },
            { table: 'students', col: 'roll_no', type: 'INT' },
            { table: 'students', col: 'dob', type: 'DATE' },
            { table: 'students', col: 'current_year', type: 'VARCHAR(20)' },
            { table: 'students', col: 'dept', type: 'VARCHAR(50)' },
            { table: 'students', col: 'parent_id', type: 'VARCHAR(50)' },
            { table: 'parents', col: 'name', type: 'VARCHAR(255)' },
            { table: 'parents', col: 'relation', type: 'VARCHAR(100)' },
            { table: 'parents', col: 'phone', type: 'VARCHAR(50)' },
            { table: 'parents', col: 'email', type: 'VARCHAR(255)' },
            { table: 'parents', col: 'password', type: 'VARCHAR(255)' },
            { table: 'parents', col: 'occupation', type: 'VARCHAR(100)' },
        ];

        // Ensure class_enrollments has roll_no column
        try {
            await db.execute('ALTER TABLE class_enrollments ADD COLUMN roll_no INT');
            console.log('📡 [DB MIGRATION] Added column roll_no to class_enrollments');
        } catch (e) { /* already exists */ }

        // Ensure assignments has teacher_id column
        try {
            await db.execute('ALTER TABLE assignments ADD COLUMN teacher_id VARCHAR(50)');
            console.log('📡 [DB MIGRATION] Added column teacher_id to assignments');
        } catch (e) { /* already exists */ }

        for (const c of columnsToEnsure) {
            try {
                await db.execute(`ALTER TABLE ${c.table} ADD COLUMN ${c.col} ${c.type}`);
                console.log(`📡 [DB MIGRATION] Added column ${c.col} to ${c.table}`);
            } catch (e) {
                // Column likely already exists
            }
        }

        // Ensure users.is_active column exists for Admin activate/deactivate
        try {
            await db.execute('ALTER TABLE users ADD COLUMN is_active BOOLEAN DEFAULT TRUE');
            console.log('📡 [DB MIGRATION] Added column is_active to users');
        } catch (e) { /* already exists */ }

        // Ensure parent email is unique if present
        try {
            await db.execute('ALTER TABLE parents ADD UNIQUE KEY unique_parent_email (email)');
            console.log('📡 [DB MIGRATION] Added unique index unique_parent_email to parents(email)');
        } catch (e) { /* already exists */ }

        // Ensure students.parent_id can reference parents(id)
        try {
            await db.execute('ALTER TABLE students ADD CONSTRAINT fk_student_parent FOREIGN KEY (parent_id) REFERENCES parents(id) ON DELETE SET NULL');
            console.log('📡 [DB MIGRATION] Added FK fk_student_parent (students.parent_id -> parents.id)');
        } catch (e) { /* already exists */ }

        // Ensure fee_structures table exists (fee module)
        try {
            await db.execute(`CREATE TABLE IF NOT EXISTS fee_structures (
                id INT AUTO_INCREMENT PRIMARY KEY,
                class_id VARCHAR(50) NOT NULL,
                academic_year VARCHAR(20) NOT NULL,
                title VARCHAR(255) NOT NULL,
                tuition_fee DECIMAL(10,2) NOT NULL DEFAULT 0.00,
                exam_fee DECIMAL(10,2) NOT NULL DEFAULT 0.00,
                transport_fee DECIMAL(10,2) NOT NULL DEFAULT 0.00,
                library_fee DECIMAL(10,2) NOT NULL DEFAULT 0.00,
                sports_fee DECIMAL(10,2) NOT NULL DEFAULT 0.00,
                miscellaneous_fee DECIMAL(10,2) NOT NULL DEFAULT 0.00,
                due_date DATE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
                UNIQUE KEY unique_class_year (class_id, academic_year)
            )`);
            console.log('✅ [DB MIGRATION] fee_structures table ensured.');
        } catch (e) { /* already exists */ }

        // Ensure student_fee_assignments table exists
        try {
            await db.execute(`CREATE TABLE IF NOT EXISTS student_fee_assignments (
                id INT AUTO_INCREMENT PRIMARY KEY,
                student_id VARCHAR(50) NOT NULL,
                fee_structure_id INT NOT NULL,
                total_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
                paid_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
                status ENUM('Pending', 'Partial', 'Paid', 'Overdue') DEFAULT 'Pending',
                due_date DATE,
                assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                UNIQUE KEY unique_student_structure (student_id, fee_structure_id),
                FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
                FOREIGN KEY (fee_structure_id) REFERENCES fee_structures(id) ON DELETE CASCADE
            )`);
            console.log('✅ [DB MIGRATION] student_fee_assignments table ensured.');
        } catch (e) { /* already exists */ }

        // Ensure fee_payments table exists
        try {
            await db.execute(`CREATE TABLE IF NOT EXISTS fee_payments (
                id INT AUTO_INCREMENT PRIMARY KEY,
                assignment_id INT NOT NULL,
                student_id VARCHAR(50) NOT NULL,
                amount DECIMAL(10,2) NOT NULL,
                payment_mode ENUM('Cash', 'Online', 'Cheque', 'DD', 'Simulated') DEFAULT 'Cash',
                reference_no VARCHAR(100),
                note TEXT,
                paid_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (assignment_id) REFERENCES student_fee_assignments(id) ON DELETE CASCADE,
                FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
            )`);
            console.log('✅ [DB MIGRATION] fee_payments table ensured.');
        } catch (e) { /* already exists */ }
    } catch (err) {
        console.error('❌ [DB INIT ERROR] Table initialization failed:', err.message);
    }
};

module.exports = initDb;
