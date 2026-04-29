const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/departmentAdminController');
const { verifyToken, checkRole } = require('../middleware/auth');

// All routes require authentication
router.use(verifyToken);
// ADMIN can also access dept-admin routes for management
router.use(checkRole('DEPARTMENT_ADMIN', 'ADMIN'));

// ─── Profile ───────────────────────────────────────────────────────────────
router.get('/profile', ctrl.getProfile);

// ─── Department Stats Dashboard ───────────────────────────────────────────
router.get('/department-stats', ctrl.getDepartmentStats);

// ─── Department ───────────────────────────────────────────────────────────
router.post('/department', ctrl.createDepartment);
router.get('/department', ctrl.getDepartments);

// ─── Teachers (for dropdowns) ─────────────────────────────────────────────
router.get('/teachers', ctrl.getTeachersByDepartment);

// ─── Students by Year (for class creation) ────────────────────────────────
router.get('/students-by-year', ctrl.getStudentsByDepartmentYear);

// ─── Classes ──────────────────────────────────────────────────────────────
router.post('/class', ctrl.createClass);
router.post('/create-class', ctrl.createClassEnhanced);
router.get('/department/:id/classes', ctrl.getClassesByDepartment);

// ─── Roll Numbers ─────────────────────────────────────────────────────────
router.post('/assign-roll-numbers', ctrl.assignRollNumbers);

// ─── Divisions ────────────────────────────────────────────────────────────
router.post('/division', ctrl.createDivision);
router.get('/class/:id/divisions', ctrl.getDivisionsByClass);

// ─── Students ─────────────────────────────────────────────────────────────
router.post('/student', ctrl.addStudent);
router.get('/division/:id/students', ctrl.getStudentsByDivision);

// ─── Timetable ────────────────────────────────────────────────────────────
router.post('/timetable', ctrl.createTimetableEntry);
router.get('/timetable/:classId/:divisionId', ctrl.getTimetable);
router.delete('/timetable/:id', ctrl.deleteTimetableEntry);

module.exports = router;

