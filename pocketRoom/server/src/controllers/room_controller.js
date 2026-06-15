
const roomService = require('../services/room_service');

function handleError(res, err) {
  const status = err.status || 500;
  if (status === 500) {
    console.error('[room] 예기치 못한 오류:', err);
  }
  res.status(status).json({ ok: false, error: err.message });
}

async function list(req, res) {
  try {
    const rooms = await roomService.listRooms(req.userId);
    res.json({ ok: true, rooms });
  } catch (err) {
    handleError(res, err);
  }
}

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
