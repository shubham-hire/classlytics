const request = require('supertest');
const app = require('../app');
const db = require('../config/db');

async function loginAs(email, password) {
  const res = await request(app).post('/auth/login').send({ email, password });
  return res.body.token;
}

describe('Security / Role-Based Access Control', () => {
  let adminToken, teacherToken, studentToken, parentToken;

  beforeAll(async () => {
    adminToken = await loginAs('admin@test.com', 'password123');
    teacherToken = await loginAs('teacher@test.com', 'password123');
    studentToken = await loginAs('student@test.com', 'password123'); // STU001
    parentToken = await loginAs('parent@test.com', 'password123');   // Parent of STU001
  });

  afterAll(async () => {
    await db.end();
  });

  describe('Horizontal Privilege Escalation (Ownership Checks)', () => {
    it('should block Student A from viewing Student B marks', async () => {
      const res = await request(app)
        .get('/marks/STU002')
        .set('Authorization', `Bearer ${studentToken}`);
      
      expect(res.statusCode).toEqual(403);
      expect(res.body.error).toContain('Access denied');
    });

    it('should block Parent A from viewing Student B marks (unlinked)', async () => {
      const res = await request(app)
        .get('/marks/STU002')
        .set('Authorization', `Bearer ${parentToken}`);
      
      expect(res.statusCode).toEqual(403);
      expect(res.body.error).toContain('Access denied');
    });

    it('should allow Parent A to view Student A marks (linked)', async () => {
      const res = await request(app)
        .get('/marks/STU001')
        .set('Authorization', `Bearer ${parentToken}`);
      
      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('marks');
    });

    it('should block Student A from submitting leave for themselves (Parent only route)', async () => {
      const res = await request(app)
        .post('/parent/leave-request')
        .set('Authorization', `Bearer ${studentToken}`)
        .send({ studentId: 'STU001', startDate: '2026-06-01', endDate: '2026-06-02', reason: 'Self-submit' });
      
      expect(res.statusCode).toEqual(403);
    });
  });

  describe('Admin Route Protection', () => {
    it('should block teacher from accessing admin stats', async () => {
      const res = await request(app)
        .get('/api/admin/stats')
        .set('Authorization', `Bearer ${teacherToken}`);
      
      expect(res.statusCode).toEqual(403);
    });

    it('should block student from accessing admin stats', async () => {
      const res = await request(app)
        .get('/api/admin/stats')
        .set('Authorization', `Bearer ${studentToken}`);
      
      expect(res.statusCode).toEqual(403);
    });

    it('should allow admin to access admin stats', async () => {
      const res = await request(app)
        .get('/api/admin/stats')
        .set('Authorization', `Bearer ${adminToken}`);
      
      expect(res.statusCode).toEqual(200);
    });
  });

  describe('AI Route Protection', () => {
    it('should allow student to view their own AI insights', async () => {
      const res = await request(app)
        .get('/ai/STU001/insights')
        .set('Authorization', `Bearer ${studentToken}`);
      
      expect(res.statusCode).toEqual(200);
    });

    it('should block student from viewing others AI insights', async () => {
      const res = await request(app)
        .get('/ai/STU002/insights')
        .set('Authorization', `Bearer ${studentToken}`);
      
      expect(res.statusCode).toEqual(403);
    });

    it('should block teacher from admin strategic advice', async () => {
      const res = await request(app)
        .get('/ai/admin/strategic-advice')
        .set('Authorization', `Bearer ${teacherToken}`);
      
      expect(res.statusCode).toEqual(403);
    });

    it('should allow admin to access strategic advice', async () => {
      const res = await request(app)
        .get('/ai/admin/strategic-advice')
        .set('Authorization', `Bearer ${adminToken}`);
      
      expect(res.statusCode).toEqual(200);
    }, 15000);

    it('should block unauthenticated users from AI tools', async () => {
      const res = await request(app).get('/ai/STU001/insights');
      expect(res.statusCode).toEqual(401);
    });
  });
});
