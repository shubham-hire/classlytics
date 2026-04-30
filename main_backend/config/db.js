const { Pool } = require('pg');

// ─── PostgreSQL Connection Pool ────────────────────────────────────────────────
const pool = new Pool({
  host:     process.env.DB_HOST     || 'localhost',
  user:     process.env.DB_USER     || 'postgres',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME     || 'classlytics_db',
  port:     parseInt(process.env.DB_PORT || '5432'),
  ssl: process.env.DB_SSL === 'false'
    ? false
    : { rejectUnauthorized: false }, // Required for Render's managed Postgres
});

// ─── MySQL → PostgreSQL compatibility shim ────────────────────────────────────
// Converts MySQL ? placeholders → PostgreSQL $1 $2 … and normalises results
// so all existing controllers keep working with no changes.

function toPostgresParams(sql, params = []) {
  let i = 0;
  const pgSql = sql.replace(/\?/g, () => `$${++i}`);
  return [pgSql, params];
}

// Wraps a pg result so controllers can destructure as [rows] like mysql2
function wrapResult(pgResult) {
  const rows = pgResult.rows;
  // MySQL's execute returns [rows, fields]. We mimic that tuple.
  // insertId is surfaced from RETURNING clauses if present.
  const meta = {
    affectedRows: pgResult.rowCount,
    insertId: rows.length > 0 && rows[0].id !== undefined ? rows[0].id : null,
  };
  return [rows, meta];
}

// ─── Public API ───────────────────────────────────────────────────────────────

/** Drop-in for mysql2 pool.execute(sql, params) */
async function execute(sql, params = []) {
  const [pgSql, pgParams] = toPostgresParams(sql, params);
  const result = await pool.query(pgSql, pgParams);
  return wrapResult(result);
}

/** Drop-in for mysql2 pool.query(sql, params) */
async function query(sql, params = []) {
  return execute(sql, params);
}

/** Returns a transaction-capable client that mimics mysql2's connection API */
async function getConnection() {
  const client = await pool.connect();

  return {
    // Allow controllers to call connection.execute() like mysql2
    execute: async (sql, params = []) => {
      const [pgSql, pgParams] = toPostgresParams(sql, params);
      const result = await client.query(pgSql, pgParams);
      return wrapResult(result);
    },
    query: async (sql, params = []) => {
      const [pgSql, pgParams] = toPostgresParams(sql, params);
      const result = await client.query(pgSql, pgParams);
      return wrapResult(result);
    },
    beginTransaction: () => client.query('BEGIN'),
    commit:           () => client.query('COMMIT'),
    rollback:         () => client.query('ROLLBACK'),
    release:          () => client.release(),
    // Expose raw pg client for advanced use
    _client: client,
  };
}

module.exports = { execute, query, getConnection, pool };
