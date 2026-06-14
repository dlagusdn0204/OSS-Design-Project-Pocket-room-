// Auth 라우터 — /auth/* 경로를 컨트롤러 핸들러에 연결합니다.
// app.js 에서 app.use('/auth', authRouter) 로 등록됩니다.
// 이 엔드포인트들은 모두 "로그인 전" 단계라 인증 미들웨어가 없습니다.

const express = require('express');
const authController = require('../controllers/auth_controller');

const router = express.Router();

router.post('/signup', authController.signup); // 회원가입
router.post('/login', authController.login); // 로그인 → 토큰 한 쌍
router.post('/refresh', authController.refresh); // access 재발급

module.exports = router;
