// Bill 라우터 — 방 하위의 카드/요금 경로(/rooms/:id/cards*)를 컨트롤러에 연결합니다.
// app.js 에서 app.use('/rooms', billRouter) 로 (roomRouter 와 함께) 등록됩니다.
//   - roomRouter 는 GET/POST '/' (방 목록·생성)만 처리
//   - billRouter 는 '/:id/cards...' (카드 조회·계약 저장·전기 갱신)만 처리
//   → 경로가 겹치지 않아 두 라우터를 같은 '/rooms' 에 올려도 충돌하지 않습니다.
// 🔒 세 엔드포인트 모두 requireAuth(로그인 필수). 방 소유권은 service 가 추가 확인.

const express = require('express');
const { requireAuth } = require('../middleware/auth');
const billController = require('../controllers/bill_controller');

const router = express.Router();

router.get('/:id/cards', requireAuth, billController.getCards); // 카드 3종(+이력) 조회
router.put('/:id/cards/contract', requireAuth, billController.saveContract); // 계약 카드 저장
router.post(
  '/:id/cards/electricity/refresh',
  requireAuth,
  billController.refreshElectricity
); // 전기요금 갱신(예시 OPM 응답 파싱)

module.exports = router;
