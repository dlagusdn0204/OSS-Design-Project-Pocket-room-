// RoomController — 방 관련 HTTP 요청/응답을 다룹니다.
// ⚠️ ownerId 는 항상 req.userId(토큰에서 온 값)에서 꺼냅니다.
//    요청 본문으로 받지 않습니다 → 남의 방을 조회·생성하는 것을 원천 차단.

const roomService = require('../services/room_service');

function handleError(res, err) {
  const status = err.status || 500;
  if (status === 500) {
    console.error('[room] 예기치 못한 오류:', err);
  }
  res.status(status).json({ ok: false, error: err.message });
}

// GET /rooms  → 200 { ok, rooms: [ Room ] }
async function list(req, res) {
  try {
    const rooms = await roomService.listRooms(req.userId);
    res.json({ ok: true, rooms });
  } catch (err) {
    handleError(res, err);
  }
}

// POST /rooms  — { name } → 201 { ok, room(+빈 카드 3종) }
async function create(req, res) {
  try {
    const { name } = req.body || {};
    const room = await roomService.addRoom(req.userId, name);
    res.status(201).json({ ok: true, room });
  } catch (err) {
    handleError(res, err);
  }
}

module.exports = { list, create };
