const request = require('supertest');
const app = require('../app');
const db = require('../config/db');

// ── Helper: login and extract token ──────────────────────────
async function loginAs(email, password) {
  const res = await request(app).post('/auth/login').send({ email, password });
  return res.body.token;
}

describe('Admin API Endpoints (JWT Protected)', () => {
  let adminToken;
  let teacherToken;

  beforeAll(async () => {
    // Log in as Admin (admin@test.com) and Teacher (teacher@test.com) to get tokens
    adminToken = await loginAs('admin@test.com', 'password123');
    teacherToken = await loginAs('teacher@test.com', 'password123');
  });

  afterAll(async () => {
    await db.end();
  });

  describe('GET /api/admin/stats', () => {
    it('should return 200 and stats for an admin', async () => {
      const res = await request(app)
        .get('/api/admin/stats')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('totalUsers');
      expect(res.body).toHaveProperty('byRole');
      expect(res.body).toHaveProperty('activeUsers');
    });

    it('should return 403 for a teacher accessing admin route', async () => {
      const res = await request(app)
        .get('/api/admin/stats')
        .set('Authorization', `Bearer ${teacherToken}`);

      expect(res.statusCode).toEqual(403);
      expect(res.body.error).toMatch(/forbidden/i);
    });

    it('should return 401 with no token', async () => {
      const res = await request(app).get('/api/admin/stats');
      expect(res.statusCode).toEqual(401);
    });
  });

  describe('GET /api/admin/visual-analytics', () => {
    it('should return 200 and visual data for an admin', async () => {
      const res = await request(app)
        .get('/api/admin/visual-analytics')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('feeTrends');
      expect(res.body).toHaveProperty('attendanceDaily');
      expect(res.body).toHaveProperty('subjectPerformance');
      expect(res.body).toHaveProperty('roleDistribution');
    });
  });
});
