const request = require('supertest');
const app = require('../app');
const db = require('../config/db');

async function loginAs(email, password) {
  const res = await request(app).post('/auth/login').send({ email, password });
  return res.body.token;
}

describe('Teacher API Endpoints', () => {
  let teacherToken;
  let adminToken;
  let studentToken;

  beforeAll(async () => {
    teacherToken = await loginAs('teacher@test.com', 'password123');
    adminToken = await loginAs('admin@test.com', 'password123');
    studentToken = await loginAs('student@test.com', 'password123');
  });

  afterAll(async () => {
    await db.end();
  });

  describe('GET /teacher/dashboard', () => {
    it('should return 200 and dashboard data for a teacher', async () => {
      const res = await request(app)
        .get('/teacher/dashboard')
        .set('Authorization', `Bearer ${teacherToken}`);

      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('totalStudents');
      expect(res.body).toHaveProperty('avgAttendance');
      expect(res.body).toHaveProperty('riskStudents');
    });

    it('should return 200 for an admin', async () => {
      const res = await request(app)
        .get('/teacher/dashboard')
        .set('Authorization', `Bearer ${adminToken}`);
      expect(res.statusCode).toEqual(200);
    });

    it('should return 403 for a student', async () => {
      const res = await request(app)
        .get('/teacher/dashboard')
        .set('Authorization', `Bearer ${studentToken}`);
      expect(res.statusCode).toEqual(403);
    });
  });

  describe('GET /teacher/profile', () => {
    it('should return the teacher profile', async () => {
      const res = await request(app)
        .get('/teacher/profile')
        .set('Authorization', `Bearer ${teacherToken}`);

      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('name', 'Rajesh Kumar');
      expect(res.body).toHaveProperty('email', 'teacher@test.com');
    });
  });

  describe('GET /teacher/schedule', () => {
    it('should return the schedule', async () => {
      const res = await request(app)
        .get('/teacher/schedule')
        .set('Authorization', `Bearer ${teacherToken}`);

      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('schedule');
      expect(Array.isArray(res.body.schedule)).toBe(true);
    });
  });
});
