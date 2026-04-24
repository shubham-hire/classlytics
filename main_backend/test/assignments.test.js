const request = require('supertest');
const app = require('../app');
const db = require('../config/db');

async function loginAs(email, password) {
  const res = await request(app).post('/auth/login').send({ email, password });
  return res.body.token;
}

describe('Assignments API Endpoints', () => {
  let teacherToken;
  let studentToken;

  beforeAll(async () => {
    teacherToken = await loginAs('teacher@test.com', 'password123');
    studentToken = await loginAs('student@test.com', 'password123');
  });

  afterAll(async () => {
    await db.end();
  });

  describe('POST /assignments', () => {
    it('should allow teacher to create an assignment', async () => {
      const res = await request(app)
        .post('/assignments')
        .set('Authorization', `Bearer ${teacherToken}`)
        .send({
          classId: 'cls-10a',
          title: 'Unit Test Assignment',
          deadline: '2026-12-31'
        });
      expect(res.statusCode).toEqual(201);
      expect(res.body.assignment).toHaveProperty('title', 'Unit Test Assignment');
    });

    it('should block student from creating an assignment', async () => {
      const res = await request(app)
        .post('/assignments')
        .set('Authorization', `Bearer ${studentToken}`)
        .send({
          classId: 'cls-10a',
          title: 'Hack Assignment',
          deadline: '2026-12-31'
        });
      expect(res.statusCode).toEqual(403);
    });
  });

  describe('GET /assignments/student/:studentId', () => {
    it('should allow student to view their own assignments', async () => {
      const res = await request(app)
        .get('/assignments/student/STU001')
        .set('Authorization', `Bearer ${studentToken}`);
      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('assignments');
    });

    it('should block student from viewing others assignments', async () => {
      const res = await request(app)
        .get('/assignments/student/STU002')
        .set('Authorization', `Bearer ${studentToken}`);
      expect(res.statusCode).toEqual(403);
    });
  });
});
