const request = require('supertest');
const app = require('../app');
const db = require('../config/db');

describe('Auth API Endpoints', () => {
  afterAll(async () => {
    await db.end();
  });

  describe('POST /auth/login', () => {
    it('should login successfully as a teacher and return a token', async () => {
      const res = await request(app)
        .post('/auth/login')
        .send({ email: 'teacher@test.com', password: 'password123' });

      expect(res.statusCode).toEqual(200);
      expect(res.body.message).toEqual('Login successful');
      expect(res.body).toHaveProperty('token');
      expect(typeof res.body.token).toBe('string');
      expect(res.body.user).toHaveProperty('role', 'Teacher');
    });

    it('should login successfully as a student and return a token', async () => {
      const res = await request(app)
        .post('/auth/login')
        .send({ email: 'student@test.com', password: 'password123' });

      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('token');
      expect(res.body.user).toHaveProperty('role', 'Student');
      // Password must NOT be in the response
      expect(res.body.user.password).toBeUndefined();
    });

    it('should return 401 for invalid credentials', async () => {
      const res = await request(app)
        .post('/auth/login')
        .send({ email: 'teacher@test.com', password: 'wrongpassword' });

      expect(res.statusCode).toEqual(401);
      expect(res.body).toHaveProperty('error', 'Invalid credentials');
    });

    it('should return 400 for missing fields', async () => {
      const res = await request(app)
        .post('/auth/login')
        .send({ email: 'teacher@test.com' });

      expect(res.statusCode).toEqual(400);
    });
  });

  describe('GET /auth/me', () => {
    it('should return current user info with a valid token', async () => {
      // First login to get a token
      const loginRes = await request(app)
        .post('/auth/login')
        .send({ email: 'teacher@test.com', password: 'password123' });
      
      const token = loginRes.body.token;

      const meRes = await request(app)
        .get('/auth/me')
        .set('Authorization', `Bearer ${token}`);

      expect(meRes.statusCode).toEqual(200);
      expect(meRes.body.user).toHaveProperty('email', 'teacher@test.com');
      expect(meRes.body.user).toHaveProperty('role', 'Teacher');
    });

    it('should return 401 with no token on /auth/me', async () => {
      const res = await request(app).get('/auth/me');
      expect(res.statusCode).toEqual(401);
    });

    it('should return 403 with an invalid token', async () => {
      const res = await request(app)
        .get('/auth/me')
        .set('Authorization', 'Bearer this.is.a.fake.token');
      expect(res.statusCode).toEqual(403);
    });
  });
});
