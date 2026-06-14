// RoomService — 방 목록 조회와 방 생성을 담당합니다.
// 방을 만들 때 빈 카드 3종(contract / electricity / cityGas)을 함께 생성합니다.
// (클라이언트 RoomProvider.addRoom 이 빈 카드 3종을 자동 생성하던 동작을 서버로 옮긴 것)
// Design 3.2(Add Room)·2.8 기준.

const roomRepository = require('../repositories/room_repository');
const cardRepository = require('../repositories/card_repository');
const { badRequest } = require('../utils/http_error');

// 방 생성 시 함께 만들 빈 카드 3종의 기본 data(JSONB).
//   - contract: 아직 입력 전이라 빈 객체. (#7 에서 PUT 으로 채움)
//   - electricity / cityGas: 외부 연동 전이므로 isLinked=false.
const EMPTY_CARDS = [
  { type: 'contract', data: {} },
  { type: 'electricity', data: { isLinked: false } },
  { type: 'cityGas', data: { isLinked: false } },
];

// 한 사용자의 방 목록(오래된 순).
//   ownerId 는 토큰에서 온 값(컨트롤러가 req.userId 로 전달).
async function listRooms(ownerId) {
  return roomRepository.findByOwner(ownerId);
}

// 방 1개 생성 + 빈 카드 3종 생성.
//   입력: ownerId(토큰에서), name(요청 본문)
//   반환: { ...room, cards: [3종] }
async function addRoom(ownerId, name) {
  if (!name || !name.trim()) {
    throw badRequest('방 이름(name)은 필수입니다');
  }
  const room = await roomRepository.insert(ownerId, name.trim());

  // 빈 카드 3종을 순서대로 생성. (upsertCard 는 room_id+type 기준이라 중복 걱정 없음)
  const cards = [];
  for (const { type, data } of EMPTY_CARDS) {
    const card = await cardRepository.upsertCard(room.id, type, data);
    cards.push(card);
  }

  return { ...room, cards };
}

module.exports = { listRooms, addRoom };
