const request = require('supertest');
const app = require('../app');
const db = require('../config/db');

async function loginAs(email, password) {
  const res = await request(app).post('/auth/login').send({ email, password });
  return res.body.token;
}

describe('Fees API Endpoints', () => {
  let adminToken;
  let teacherToken;
  let studentToken;

  beforeAll(async () => {
    adminToken = await loginAs('admin@test.com', 'password123');
    teacherToken = await loginAs('teacher@test.com', 'password123');
    studentToken = await loginAs('student@test.com', 'password123');
  });

  afterAll(async () => {
    await db.end();
  });

  describe('GET /api/fees/structure', () => {
    it('should allow Admin to view fee structures', async () => {
      const res = await request(app)
        .get('/api/fees/structure')
        .set('Authorization', `Bearer ${adminToken}`);
      expect(res.statusCode).toEqual(200);
      expect(Array.isArray(res.body)).toBeTruthy();
    });

    it('should block Student from viewing fee structures', async () => {
      const res = await request(app)
        .get('/api/fees/structure')
        .set('Authorization', `Bearer ${studentToken}`);
      expect(res.statusCode).toEqual(403);
    });
  });

  describe('GET /api/fees/:studentId', () => {
    it('should allow student to view their own fee status', async () => {
      const res = await request(app)
        .get('/api/fees/STU001')
        .set('Authorization', `Bearer ${studentToken}`);
      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('studentId', 'STU001');
    });

    it('should block student from viewing others fee status', async () => {
      const res = await request(app)
        .get('/api/fees/STU002')
        .set('Authorization', `Bearer ${studentToken}`);
      expect(res.statusCode).toEqual(403);
    });
  });

  describe('POST /api/fees/structure', () => {
    it('should block Teacher from creating fee structure', async () => {
      const res = await request(app)
        .post('/api/fees/structure')
        .set('Authorization', `Bearer ${teacherToken}`)
        .send({
          class_id: 'cls-10a',
          academic_year: '2026-27',
          title: 'Unauthorized Structure'
        });
      expect(res.statusCode).toEqual(403);
    });
  });
});
