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

        // Split schema into individual queries
        const queries = schema
            .split(';')
            .map(q => q.trim())
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
            { table: 'students', col: 'dob', type: 'DATE' },
            { table: 'students', col: 'current_year', type: 'VARCHAR(20)' },
            { table: 'students', col: 'dept', type: 'VARCHAR(50)' },
        ];

        // Ensure class_enrollments has roll_no column
        try {
            await db.execute('ALTER TABLE class_enrollments ADD COLUMN roll_no INT');
            console.log('📡 [DB MIGRATION] Added column roll_no to class_enrollments');
        } catch (e) { /* already exists */ }

        for (const c of columnsToEnsure) {
            try {
                await db.execute(`ALTER TABLE ${c.table} ADD COLUMN ${c.col} ${c.type}`);
                console.log(`📡 [DB MIGRATION] Added column ${c.col} to ${c.table}`);
            } catch (e) {
                // Column likely already exists
            }
        }
    } catch (err) {
        console.error('❌ [DB INIT ERROR] Table initialization failed:', err.message);
    }
};

module.exports = initDb;
