const request = require('supertest');
const app = require('../app');
const db = require('../config/db');

async function loginAs(email, password) {
  const res = await request(app).post('/auth/login').send({ email, password });
  return res.body.token;
}

describe('Parent API Endpoints', () => {
  let parentToken;
  let teacherToken;

  beforeAll(async () => {
    process.env.NVIDIA_API_KEY = 'your_nvidia_api_key_here';
    parentToken = await loginAs('parent@test.com', 'password123');
    teacherToken = await loginAs('teacher@test.com', 'password123');
  });

  afterAll(async () => {
    await db.end();
  });

  describe('GET /parent/child-info/:userId', () => {
    it('should allow parent to view their child info', async () => {
      const res = await request(app)
        .get('/parent/child-info/uid-parent-001')
        .set('Authorization', `Bearer ${parentToken}`);
      
      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('childName');
      expect(res.body.childId).toEqual('STU001');
    });

    it('should allow teacher to view any child info', async () => {
      const res = await request(app)
        .get('/parent/child-info/uid-parent-001')
        .set('Authorization', `Bearer ${teacherToken}`);
      
      expect(res.statusCode).toEqual(200);
    });
  });

  describe('GET /parent/weekly-summary/:studentId', () => {
    it('should allow parent to view their own child summary', async () => {
      const res = await request(app)
        .get('/parent/weekly-summary/STU001')
        .set('Authorization', `Bearer ${parentToken}`);
      
      if (res.statusCode !== 200) console.error('FAIL REASON:', res.body);
      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('summary');
    });

    it('should block parent from viewing others child summary', async () => {
      const res = await request(app)
        .get('/parent/weekly-summary/STU002')
        .set('Authorization', `Bearer ${parentToken}`);
      
      expect(res.statusCode).toEqual(403);
    });
  });

  describe('POST /parent/leave-request', () => {
    it('should allow parent to submit leave request for their child', async () => {
      const res = await request(app)
        .post('/parent/leave-request')
        .set('Authorization', `Bearer ${parentToken}`)
        .send({
          studentId: 'STU001',
          startDate: '2026-05-01',
          endDate: '2026-05-03',
          reason: 'Family wedding'
        });
      
      expect(res.statusCode).toEqual(201);
    });

    it('should block parent from submitting leave for others child', async () => {
      const res = await request(app)
        .post('/parent/leave-request')
        .set('Authorization', `Bearer ${parentToken}`)
        .send({
          studentId: 'STU002',
          startDate: '2026-05-01',
          endDate: '2026-05-03',
          reason: 'Unauthorized'
        });
      
      expect(res.statusCode).toEqual(403);
    });
  });
});
