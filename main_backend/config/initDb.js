const { pool } = require('./db');

const initDb = async () => {
  const client = await pool.connect();
  try {
    console.log('⏳ [DB INIT] Initializing PostgreSQL tables…');
    await client.query('BEGIN');

    // ─── Extensions ───────────────────────────────────────────────────────────
    await client.query('CREATE EXTENSION IF NOT EXISTS "pgcrypto"');

    // ─── global_sequences ─────────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS global_sequences (
        name       VARCHAR(50) PRIMARY KEY,
        last_value INT DEFAULT 0
      )
    `);
    await client.query(`
      INSERT INTO global_sequences (name, last_value) VALUES ('student', 0), ('teacher', 0)
      ON CONFLICT (name) DO NOTHING
    `);

    // ─── departments ──────────────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS departments (
        id         SERIAL PRIMARY KEY,
        name       VARCHAR(100) UNIQUE NOT NULL,
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    `);

    // ─── users ────────────────────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id            VARCHAR(50) PRIMARY KEY,
        name          VARCHAR(100) NOT NULL,
        email         VARCHAR(100) UNIQUE NOT NULL,
        password      VARCHAR(255) NOT NULL,
        role          VARCHAR(50) NOT NULL CHECK (role IN ('ADMIN','Admin','Teacher','Student','Parent','DEPARTMENT_ADMIN')),
        phone         VARCHAR(20),
        address       TEXT,
        country       VARCHAR(100),
        state         VARCHAR(100),
        district      VARCHAR(100),
        city          VARCHAR(100),
        dept          VARCHAR(50),
        department_id INT REFERENCES departments(id) ON DELETE SET NULL,
        is_active     BOOLEAN DEFAULT TRUE,
        created_at    TIMESTAMPTZ DEFAULT NOW()
      )
    `);

    // ─── teachers ─────────────────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS teachers (
        id                  VARCHAR(50) PRIMARY KEY,
        user_id             VARCHAR(50) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        employee_id         VARCHAR(50) UNIQUE NOT NULL,
        department          VARCHAR(100),
        designation         VARCHAR(50) NOT NULL,
        joining_date        DATE,
        employment_type     VARCHAR(20) DEFAULT 'Full-time' CHECK (employment_type IN ('Full-time','Part-time','Contract')),
        qualification       VARCHAR(255),
        specialization      VARCHAR(255),
        experience_years    INT DEFAULT 0,
        previous_school     VARCHAR(255),
        gender              VARCHAR(10) CHECK (gender IN ('Male','Female','Other')),
        dob                 DATE,
        profile_img         VARCHAR(255),
        subjects            TEXT,
        classes             TEXT,
        salary_structure_id VARCHAR(50),
        bank_account_no     VARCHAR(50),
        bank_ifsc           VARCHAR(20),
        emergency_contact   VARCHAR(20),
        created_at          TIMESTAMPTZ DEFAULT NOW()
      )
    `);

    // ─── classes ──────────────────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS classes (
        id            VARCHAR(50) PRIMARY KEY,
        name          VARCHAR(50) NOT NULL,
        section       VARCHAR(10) NOT NULL,
        teacher_id    VARCHAR(50) REFERENCES users(id) ON DELETE SET NULL,
        department_id INT REFERENCES departments(id) ON DELETE SET NULL
      )
    `);

    // ─── divisions ────────────────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS divisions (
        id            SERIAL PRIMARY KEY,
        class_id      VARCHAR(50) NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
        division_name VARCHAR(10) NOT NULL,
        created_at    TIMESTAMPTZ DEFAULT NOW()
      )
    `);

    // ─── students ─────────────────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS students (
        id           VARCHAR(50) PRIMARY KEY,
        user_id      VARCHAR(50) REFERENCES users(id) ON DELETE CASCADE,
        roll_no      INT,
        dept         VARCHAR(50) NOT NULL,
        current_year VARCHAR(20) NOT NULL,
        dob          DATE,
        parent_id    VARCHAR(50),
        profile_img  VARCHAR(255),
        division_id  INT REFERENCES divisions(id) ON DELETE SET NULL,
        category     VARCHAR(10) DEFAULT 'OPEN' CHECK (category IN ('OPEN','SC_ST','EWS')),
        created_at   TIMESTAMPTZ DEFAULT NOW()
      )
    `);

    // ─── timetable ────────────────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS timetable (
        id          SERIAL PRIMARY KEY,
        class_id    VARCHAR(50) NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
        division_id INT REFERENCES divisions(id) ON DELETE SET NULL,
        subject     VARCHAR(100) NOT NULL,
        teacher_id  VARCHAR(50) REFERENCES users(id) ON DELETE SET NULL,
        day_of_week VARCHAR(20) NOT NULL,
        start_time  TIME NOT NULL,
        end_time    TIME NOT NULL,
        created_at  TIMESTAMPTZ DEFAULT NOW()
      )
    `);

    // ─── parents ──────────────────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS parents (
        id         VARCHAR(50) PRIMARY KEY,
        user_id    VARCHAR(50) REFERENCES users(id) ON DELETE CASCADE,
        name       VARCHAR(255),
        relation   VARCHAR(100),
        phone      VARCHAR(50),
        email      VARCHAR(255) UNIQUE,
        password   VARCHAR(255),
        child_id   VARCHAR(50) REFERENCES students(id) ON DELETE SET NULL,
        occupation VARCHAR(100),
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    `);

    // Add FK from students.parent_id -> parents.id (after parents table exists)
    await client.query(`
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM pg_constraint WHERE conname = 'fk_student_parent'
        ) THEN
          ALTER TABLE students
            ADD CONSTRAINT fk_student_parent FOREIGN KEY (parent_id) REFERENCES parents(id) ON DELETE SET NULL;
        END IF;
      END $$
    `);

    // ─── class_enrollments ────────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS class_enrollments (
        class_id    VARCHAR(50) REFERENCES classes(id) ON DELETE CASCADE,
        student_id  VARCHAR(50) REFERENCES students(id) ON DELETE CASCADE,
        roll_no     INT,
        enrolled_at TIMESTAMPTZ DEFAULT NOW(),
        PRIMARY KEY (class_id, student_id)
      )
    `);

    // ─── attendance ───────────────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS attendance (
        id         SERIAL PRIMARY KEY,
        student_id VARCHAR(50) REFERENCES students(id) ON DELETE CASCADE,
        date       DATE NOT NULL,
        status     VARCHAR(10) NOT NULL CHECK (status IN ('Present','Absent','Late'))
      )
    `);

    // ─── leave_requests ───────────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS leave_requests (
        id         SERIAL PRIMARY KEY,
        student_id VARCHAR(50) NOT NULL REFERENCES students(id) ON DELETE CASCADE,
        parent_id  VARCHAR(50) REFERENCES users(id) ON DELETE SET NULL,
        start_date DATE NOT NULL,
        end_date   DATE NOT NULL,
        reason     TEXT NOT NULL,
        status     VARCHAR(20) DEFAULT 'Pending' CHECK (status IN ('Pending','Approved','Rejected')),
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    `);

    // ─── marks ────────────────────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS marks (
        id         SERIAL PRIMARY KEY,
        student_id VARCHAR(50) REFERENCES students(id) ON DELETE CASCADE,
        subject    VARCHAR(50) NOT NULL,
        score      FLOAT NOT NULL,
        max_score  FLOAT NOT NULL,
        type       VARCHAR(20) NOT NULL CHECK (type IN ('Quiz','Midterm','Final','Assignment')),
        date       DATE NOT NULL
      )
    `);

    // ─── assignments ──────────────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS assignments (
        id          VARCHAR(50) PRIMARY KEY,
        class_id    VARCHAR(50) REFERENCES classes(id) ON DELETE CASCADE,
        teacher_id  VARCHAR(50) REFERENCES users(id) ON DELETE SET NULL,
        title       VARCHAR(255) NOT NULL,
        description TEXT,
        media_url   VARCHAR(500) DEFAULT NULL,
        media_type  VARCHAR(10) DEFAULT 'none' CHECK (media_type IN ('image','pdf','none')),
        deadline    TIMESTAMPTZ NOT NULL,
        created_at  TIMESTAMPTZ DEFAULT NOW()
      )
    `);

    // ─── submissions ──────────────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS submissions (
        id            VARCHAR(50) PRIMARY KEY,
        assignment_id VARCHAR(50) REFERENCES assignments(id) ON DELETE CASCADE,
        student_id    VARCHAR(50) REFERENCES students(id) ON DELETE CASCADE,
        note          TEXT,
        submitted_at  TIMESTAMPTZ DEFAULT NOW(),
        score_awarded FLOAT DEFAULT NULL
      )
    `);

    // ─── quizzes ──────────────────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS quizzes (
        id               VARCHAR(50) PRIMARY KEY,
        class_id         VARCHAR(50) REFERENCES classes(id) ON DELETE CASCADE,
        teacher_id       VARCHAR(50) REFERENCES users(id) ON DELETE SET NULL,
        title            VARCHAR(255) NOT NULL,
        description      TEXT,
        duration_minutes INT NOT NULL DEFAULT 30,
        created_at       TIMESTAMPTZ DEFAULT NOW()
      )
    `);

    // ─── quiz_questions ───────────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS quiz_questions (
        id             VARCHAR(50) PRIMARY KEY,
        quiz_id        VARCHAR(50) NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
        question       TEXT NOT NULL,
        option_a       VARCHAR(500) NOT NULL,
        option_b       VARCHAR(500) NOT NULL,
        option_c       VARCHAR(500) NOT NULL,
        option_d       VARCHAR(500) NOT NULL,
        correct_option VARCHAR(1) NOT NULL CHECK (correct_option IN ('A','B','C','D')),
        marks          INT NOT NULL DEFAULT 1
      )
    `);

    // ─── quiz_submissions ─────────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS quiz_submissions (
        id                 VARCHAR(50) PRIMARY KEY,
        quiz_id            VARCHAR(50) NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
        student_id         VARCHAR(50) NOT NULL REFERENCES students(id) ON DELETE CASCADE,
        score              INT NOT NULL DEFAULT 0,
        total_marks        INT NOT NULL DEFAULT 0,
        time_taken_seconds INT DEFAULT NULL,
        answers            JSONB DEFAULT NULL,
        submitted_at       TIMESTAMPTZ DEFAULT NOW(),
        UNIQUE (quiz_id, student_id)
      )
    `);

    // ─── behavior_logs ────────────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS behavior_logs (
        id         SERIAL PRIMARY KEY,
        student_id VARCHAR(50) REFERENCES students(id) ON DELETE CASCADE,
        type       VARCHAR(10) NOT NULL CHECK (type IN ('Positive','Negative')),
        remark     TEXT,
        date       TIMESTAMPTZ DEFAULT NOW()
      )
    `);

    // ─── messages ─────────────────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS messages (
        id          SERIAL PRIMARY KEY,
        sender_id   VARCHAR(50) REFERENCES users(id) ON DELETE CASCADE,
        receiver_id VARCHAR(50) REFERENCES users(id) ON DELETE CASCADE,
        body        TEXT NOT NULL,
        timestamp   TIMESTAMPTZ DEFAULT NOW(),
        is_read     BOOLEAN DEFAULT FALSE
      )
    `);

    // ─── announcements ────────────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS announcements (
        id         SERIAL PRIMARY KEY,
        class_id   VARCHAR(50) REFERENCES classes(id) ON DELETE CASCADE,
        title      VARCHAR(255) NOT NULL,
        body       TEXT NOT NULL,
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    `);

    // ─── fees (legacy flat table) ─────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS fees (
        id          SERIAL PRIMARY KEY,
        student_id  VARCHAR(50) NOT NULL REFERENCES students(id) ON DELETE CASCADE,
        total_fee   NUMERIC(10,2) NOT NULL DEFAULT 50000.00,
        paid_amount NUMERIC(10,2) NOT NULL DEFAULT 0.00,
        due_date    DATE,
        semester    VARCHAR(20) DEFAULT 'Sem 1',
        created_at  TIMESTAMPTZ DEFAULT NOW()
      )
    `);

    // ─── fee_structures ───────────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS fee_structures (
        id                SERIAL PRIMARY KEY,
        class_id          VARCHAR(50) NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
        academic_year     VARCHAR(20) NOT NULL,
        title             VARCHAR(255) NOT NULL,
        tuition_fee       NUMERIC(10,2) NOT NULL DEFAULT 0.00,
        exam_fee          NUMERIC(10,2) NOT NULL DEFAULT 0.00,
        transport_fee     NUMERIC(10,2) NOT NULL DEFAULT 0.00,
        library_fee       NUMERIC(10,2) NOT NULL DEFAULT 0.00,
        sports_fee        NUMERIC(10,2) NOT NULL DEFAULT 0.00,
        miscellaneous_fee NUMERIC(10,2) NOT NULL DEFAULT 0.00,
        due_date          DATE,
        created_at        TIMESTAMPTZ DEFAULT NOW(),
        updated_at        TIMESTAMPTZ DEFAULT NOW(),
        UNIQUE (class_id, academic_year)
      )
    `);

    // ─── student_fee_assignments ──────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS student_fee_assignments (
        id               SERIAL PRIMARY KEY,
        student_id       VARCHAR(50) NOT NULL REFERENCES students(id) ON DELETE CASCADE,
        fee_structure_id INT NOT NULL REFERENCES fee_structures(id) ON DELETE CASCADE,
        total_amount     NUMERIC(10,2) NOT NULL DEFAULT 0.00,
        paid_amount      NUMERIC(10,2) NOT NULL DEFAULT 0.00,
        status           VARCHAR(10) DEFAULT 'Pending' CHECK (status IN ('Pending','Partial','Paid','Overdue')),
        due_date         DATE,
        assigned_at      TIMESTAMPTZ DEFAULT NOW(),
        updated_at       TIMESTAMPTZ DEFAULT NOW(),
        UNIQUE (student_id, fee_structure_id)
      )
    `);

    // ─── fee_payments ─────────────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS fee_payments (
        id            SERIAL PRIMARY KEY,
        assignment_id INT NOT NULL REFERENCES student_fee_assignments(id) ON DELETE CASCADE,
        student_id    VARCHAR(50) NOT NULL REFERENCES students(id) ON DELETE CASCADE,
        amount        NUMERIC(10,2) NOT NULL,
        payment_mode  VARCHAR(20) DEFAULT 'Cash' CHECK (payment_mode IN ('Cash','Online','Cheque','DD','Simulated')),
        reference_no  VARCHAR(100),
        note          TEXT,
        paid_at       TIMESTAMPTZ DEFAULT NOW()
      )
    `);

    // ─── category_fee_structures ──────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS category_fee_structures (
        id            SERIAL PRIMARY KEY,
        department_id INT REFERENCES departments(id),
        year          VARCHAR(20),
        category      VARCHAR(10) CHECK (category IN ('OPEN','SC_ST','EWS')),
        amount        NUMERIC(10,2),
        created_at    TIMESTAMPTZ DEFAULT NOW(),
        UNIQUE (department_id, year, category)
      )
    `);

    // ─── student_category_fees ────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS student_category_fees (
        id               SERIAL PRIMARY KEY,
        student_id       VARCHAR(50) NOT NULL REFERENCES students(id) ON DELETE CASCADE,
        fee_structure_id INT REFERENCES category_fee_structures(id) ON DELETE RESTRICT,
        total_amount     NUMERIC(10,2),
        paid_amount      NUMERIC(10,2) DEFAULT 0.00,
        status           VARCHAR(10) DEFAULT 'PENDING' CHECK (status IN ('PENDING','PARTIAL','PAID')),
        UNIQUE (student_id, fee_structure_id)
      )
    `);

    // ─── payments (Razorpay) ──────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS payments (
        id                  SERIAL PRIMARY KEY,
        parent_id           VARCHAR(50),
        student_id          VARCHAR(50),
        amount              NUMERIC(10,2),
        status              VARCHAR(10) DEFAULT 'PENDING' CHECK (status IN ('PENDING','SUCCESS','FAILED')),
        razorpay_order_id   VARCHAR(255),
        razorpay_payment_id VARCHAR(255),
        created_at          TIMESTAMPTZ DEFAULT NOW()
      )
    `);

    await client.query('COMMIT');
    console.log('✅ [DB INIT] All PostgreSQL tables initialized successfully.');

    // ─── Auto-seed default department ─────────────────────────────────────────
    const { rows } = await pool.query('SELECT COUNT(*) AS count FROM departments');
    if (parseInt(rows[0].count) === 0) {
      await pool.query("INSERT INTO departments (name) VALUES ('General Engineering') ON CONFLICT DO NOTHING");
      console.log('🌱 [DB SEED] Created default department: General Engineering');
    }

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ [DB INIT ERROR] Table initialization failed:', err.message);
    throw err;
  } finally {
    client.release();
  }
};

module.exports = initDb;
