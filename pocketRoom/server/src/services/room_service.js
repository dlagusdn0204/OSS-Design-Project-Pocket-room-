
const roomRepository = require('../repositories/room_repository');
const cardRepository = require('../repositories/card_repository');
const { badRequest } = require('../utils/http_error');

const EMPTY_CARDS = [
  { type: 'contract', data: {} },
  { type: 'electricity', data: { isLinked: false } },
  { type: 'cityGas', data: { isLinked: false } },
];

async function listRooms(ownerId) {
  return roomRepository.findByOwner(ownerId);
}

async function addRoom(ownerId, name) {
  if (!name || !name.trim()) {
    throw badRequest('방 이름(name)은 필수입니다');
  }
  const room = await roomRepository.insert(ownerId, name.trim());

  const cards = [];
  for (const { type, data } of EMPTY_CARDS) {
    const card = await cardRepository.upsertCard(room.id, type, data);
    cards.push(card);
  }

  return { ...room, cards };
}

module.exports = { listRooms, addRoom };
