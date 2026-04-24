const request = require('supertest');
const app = require('../app');
const db = require('../config/db');

async function loginAs(email, password) {
  const res = await request(app).post('/auth/login').send({ email, password });
  return res.body.token;
}

describe('Attendance API Endpoints', () => {
  let teacherToken;
  let studentToken;
  let adminToken;

  beforeAll(async () => {
    teacherToken = await loginAs('teacher@test.com', 'password123');
    studentToken = await loginAs('student@test.com', 'password123');
    adminToken = await loginAs('admin@test.com', 'password123');
  });

  afterAll(async () => {
    await db.end();
  });

  describe('POST /attendance', () => {
    it('should allow teacher to mark attendance', async () => {
      const res = await request(app)
        .post('/attendance')
        .set('Authorization', `Bearer ${teacherToken}`)
        .send({
          studentId: 'STU001',
          status: 'Present'
        });
      
      expect(res.statusCode).toEqual(201);
      expect(res.body.message).toContain('successfully');
    });

    it('should block student from marking attendance', async () => {
      const res = await request(app)
        .post('/attendance')
        .set('Authorization', `Bearer ${studentToken}`)
        .send({
          studentId: 'STU001',
          status: 'Present'
        });
      
      expect(res.statusCode).toEqual(403);
    });
  });

  describe('GET /attendance/:studentId', () => {
    it('should allow student to view their own attendance', async () => {
      // Assuming student@test.com corresponds to STU001 from seed
      const res = await request(app)
        .get('/attendance/STU001')
        .set('Authorization', `Bearer ${studentToken}`);
      
      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('attendance');
    });

    it('should block student from viewing others attendance', async () => {
      const res = await request(app)
        .get('/attendance/STU002')
        .set('Authorization', `Bearer ${studentToken}`);
      
      expect(res.statusCode).toEqual(403);
    });

    it('should allow teacher to view any student attendance', async () => {
      const res = await request(app)
        .get('/attendance/STU001')
        .set('Authorization', `Bearer ${teacherToken}`);
      
      expect(res.statusCode).toEqual(200);
    });
  });
});
