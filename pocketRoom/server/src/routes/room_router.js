// Room 라우터 — /rooms 경로를 컨트롤러에 연결합니다.
// app.js 에서 app.use('/rooms', roomRouter) 로 등록됩니다.
// 🔒 두 엔드포인트 모두 requireAuth 미들웨어를 거칩니다(로그인 필수).
//    미들웨어가 토큰을 검증해 req.userId 를 채운 뒤에야 컨트롤러가 실행됩니다.

const express = require('express');
const { requireAuth } = require('../middleware/auth');
const roomController = require('../controllers/room_controller');

const router = express.Router();

router.get('/', requireAuth, roomController.list); // 내 방 목록
router.post('/', requireAuth, roomController.create); // 방 생성(+빈 카드 3종)

module.exports = router;
