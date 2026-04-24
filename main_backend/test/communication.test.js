const request = require('supertest');
const app = require('../app');
const db = require('../config/db');

async function loginAs(email, password) {
  const res = await request(app).post('/auth/login').send({ email, password });
  return res.body.token;
}

describe('Communication API Endpoints', () => {
  let teacherToken;
  let studentToken;

  beforeAll(async () => {
    teacherToken = await loginAs('teacher@test.com', 'password123');
    studentToken = await loginAs('student@test.com', 'password123');
  });

  afterAll(async () => {
    await db.end();
  });

  describe('POST /communication/announcements', () => {
    it('should allow teacher to send announcements', async () => {
      const res = await request(app)
        .post('/communication/announcements')
        .set('Authorization', `Bearer ${teacherToken}`)
        .send({
          classId: 'cls-10a',
          title: 'Class Update',
          body: 'Please check your portal.'
        });
      expect(res.statusCode).toEqual(201);
    });

    it('should block student from sending announcements', async () => {
      const res = await request(app)
        .post('/communication/announcements')
        .set('Authorization', `Bearer ${studentToken}`)
        .send({
          classId: 'cls-10a',
          title: 'Hack',
          body: 'Hack'
        });
      expect(res.statusCode).toEqual(403);
    });
  });

  describe('GET /communication/messages/:userId', () => {
    it('should allow user to view their own messages', async () => {
      const res = await request(app)
        .get('/communication/messages/uid-student-001')
        .set('Authorization', `Bearer ${studentToken}`);
      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('messages');
    });

    it('should block user from viewing others messages', async () => {
      const res = await request(app)
        .get('/communication/messages/uid-teacher-001')
        .set('Authorization', `Bearer ${studentToken}`);
      expect(res.statusCode).toEqual(403);
    });
  });
});
