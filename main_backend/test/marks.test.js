const request = require('supertest');
const app = require('../app');
const db = require('../config/db');

async function loginAs(email, password) {
  const res = await request(app).post('/auth/login').send({ email, password });
  return res.body.token;
}

describe('Marks API Endpoints', () => {
  let teacherToken;
  let studentToken;

  beforeAll(async () => {
    teacherToken = await loginAs('teacher@test.com', 'password123');
    studentToken = await loginAs('student@test.com', 'password123');
  });

  afterAll(async () => {
    await db.end();
  });

  describe('POST /marks', () => {
    it('should allow teacher to add marks', async () => {
      const res = await request(app)
        .post('/marks')
        .set('Authorization', `Bearer ${teacherToken}`)
        .send({
          studentId: 'STU001',
          subject: 'Mathematics',
          score: 85,
          type: 'Midterm'
        });
      
      expect(res.statusCode).toEqual(201);
      expect(res.body.message).toContain('successfully');
    });

    it('should block student from adding marks', async () => {
      const res = await request(app)
        .post('/marks')
        .set('Authorization', `Bearer ${studentToken}`)
        .send({
          studentId: 'STU001',
          subject: 'Self-Grade',
          score: 100
        });
      
      expect(res.statusCode).toEqual(403);
    });
  });

  describe('GET /marks/:studentId', () => {
    it('should allow student to view their own marks', async () => {
      const res = await request(app)
        .get('/marks/STU001')
        .set('Authorization', `Bearer ${studentToken}`);
      
      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('marks');
      expect(res.body).toHaveProperty('average');
    });

    it('should block student from viewing others marks', async () => {
      const res = await request(app)
        .get('/marks/STU002')
        .set('Authorization', `Bearer ${studentToken}`);
      
      expect(res.statusCode).toEqual(403);
    });

    it('should allow teacher to view any student marks', async () => {
      const res = await request(app)
        .get('/marks/STU002')
        .set('Authorization', `Bearer ${teacherToken}`);
      
      expect(res.statusCode).toEqual(200);
    });
  });
});
