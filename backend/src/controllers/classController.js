const classService = require('../services/classService');
const { asyncHandler, apiResponse, ApiError } = require('../utils/helpers');

const createClass = asyncHandler(async (req, res) => {
  const { name, subject } = req.body;
  if (!name || !subject) {
    throw new ApiError(400, 'Class name and subject are required');
  }

  const result = await classService.createClass(req.user.id, { name, subject });
  apiResponse(res, 201, result, 'Class created successfully');
});

const getTeacherClasses = asyncHandler(async (req, res) => {
  const classes = await classService.getTeacherClasses(req.user.id);
  apiResponse(res, 200, classes);
});

const getClassDetail = asyncHandler(async (req, res) => {
  const classData = await classService.getClassDetail(req.params.id, req.user.id);
  apiResponse(res, 200, classData);
});

const getClassStudents = asyncHandler(async (req, res) => {
  const students = await classService.getClassStudents(req.params.id);
  apiResponse(res, 200, students);
});

const joinClass = asyncHandler(async (req, res) => {
  const { code } = req.body;
  if (!code) throw new ApiError(400, 'Class code is required');

  const result = await classService.joinClass(req.user.id, code.toUpperCase());
  apiResponse(res, 200, result, 'Successfully joined class');
});

const getStudentClasses = asyncHandler(async (req, res) => {
  const classes = await classService.getStudentClasses(req.user.id);
  apiResponse(res, 200, classes);
});

module.exports = {
  createClass,
  getTeacherClasses,
  getClassDetail,
  getClassStudents,
  joinClass,
  getStudentClasses,
};
