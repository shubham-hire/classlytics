const request = require('supertest');
const app = require('../app');
const db = require('../config/db');

async function loginAs(email, password) {
  const res = await request(app).post('/auth/login').send({ email, password });
  return res.body.token;
}

describe('Student Management API', () => {
  let teacherToken;
  let studentToken;

  beforeAll(async () => {
    teacherToken = await loginAs('teacher@test.com', 'password123');
    studentToken = await loginAs('student@test.com', 'password123');
  });

  afterAll(async () => {
    await db.end();
  });

  describe('GET /class/registered', () => {
    it('should allow teachers to view all students', async () => {
      const res = await request(app)
        .get('/class/registered')
        .set('Authorization', `Bearer ${teacherToken}`);
      
      expect(res.statusCode).toEqual(200);
      expect(Array.isArray(res.body)).toBe(true);
    });

    it('should block students from viewing the global list', async () => {
      const res = await request(app)
        .get('/class/registered')
        .set('Authorization', `Bearer ${studentToken}`);
      
      expect(res.statusCode).toEqual(403);
    });
  });

  describe('POST /class/add', () => {
    it('should create a new student when called by teacher', async () => {
      const uniqueEmail = `newstudent_${Date.now()}@test.com`;
      const res = await request(app)
        .post('/class/add')
        .set('Authorization', `Bearer ${teacherToken}`)
        .send({
          name: 'Integration Test Student',
          email: uniqueEmail,
          dept: 'Science',
          currentYear: '1st Year'
        });

      expect(res.statusCode).toEqual(201);
      expect(res.body).toHaveProperty('studentId');
    });

    it('should return 400 for missing fields', async () => {
      const res = await request(app)
        .post('/class/add')
        .set('Authorization', `Bearer ${teacherToken}`)
        .send({ name: 'Incomplete' });

      expect(res.statusCode).toEqual(400);
    });
  });

  describe('GET /class/student/:id', () => {
    it('should return 404 for non-existent student', async () => {
      const res = await request(app)
        .get('/class/student/NONEXISTENT')
        .set('Authorization', `Bearer ${teacherToken}`);
      
      expect(res.statusCode).toEqual(404);
    });
  });
});
