
const roomRepository = require('../repositories/room_repository');
const cardRepository = require('../repositories/card_repository');
const sampleCustomers = require('../integration/sample_customers');
const { badRequest, notFound } = require('../utils/http_error');

async function assertOwnedRoom(roomId, ownerId) {
  const room = await roomRepository.findById(roomId);
  if (!room || room.owner_id !== ownerId) {
    throw notFound('방을 찾을 수 없습니다');
  }
  return room;
}

async function getCards(ownerId, roomId) {
  await assertOwnedRoom(roomId, ownerId);
  const cards = await cardRepository.findByRoom(roomId);

  const result = [];
  for (const card of cards) {
    if (card.type === 'electricity' || card.type === 'cityGas') {
      const history = await cardRepository.getBillRecords(card.id);
      result.push({ ...card, history });
    } else {
      result.push(card);
    }
  }
  return result;
}

async function saveContract(ownerId, roomId, data) {
  await assertOwnedRoom(roomId, ownerId);
  const body = data || {};

  const dueDay = body.paymentDueDay;
  if (dueDay != null && (!Number.isInteger(Number(dueDay)) || dueDay < 1 || dueDay > 31)) {
    throw badRequest('paymentDueDay 는 1~31 사이의 값이어야 합니다');
  }

  const safe = {
    rentWon: body.rentWon ?? null,
    accountNumber: body.accountNumber ?? null,
    address: body.address ?? null,
    paymentDueDay: dueDay ?? null,
  };
  return cardRepository.upsertCard(roomId, 'contract', safe);
}

async function refreshElectricity(ownerId, roomId, { customerNo, year }) {
  await assertOwnedRoom(roomId, ownerId);

  const cards = await cardRepository.findByRoom(roomId);
  const elec = cards.find((c) => c.type === 'electricity');
  if (!elec) {
    throw notFound('전기 카드를 찾을 수 없습니다');
  }

  const records = sampleCustomers.buildSampleBills({
    type: 'electricity',
    customerNo,
    year,
  });

  await cardRepository.clearBillRecords(elec.id);

  const saved = [];
  for (const r of records) {
    const row = await cardRepository.insertBillRecord({
      cardId: elec.id,
      year: r.year,
      month: r.month,
      amountWon: r.amountWon,
      usageKwh: r.usageKwh,
      usageM3: r.usageM3,
    });
    saved.push(row);
  }

  const updatedData = {
    ...(elec.data || {}),
    isLinked: true,
    customerNo: String(customerNo).trim(),
  };
  const card = await cardRepository.upsertCard(roomId, 'electricity', updatedData);

  const history = await cardRepository.getBillRecords(elec.id);
  return { card, saved, history };
}

async function refreshCityGas(ownerId, roomId, { customerNo, year, company }) {
  await assertOwnedRoom(roomId, ownerId);

  const cards = await cardRepository.findByRoom(roomId);
  const gas = cards.find((c) => c.type === 'cityGas');
  if (!gas) {
    throw notFound('도시가스 카드를 찾을 수 없습니다');
  }

  const records = sampleCustomers.buildSampleBills({
    type: 'cityGas',
    customerNo,
    year,
  });

  await cardRepository.clearBillRecords(gas.id);

  const saved = [];
  for (const r of records) {
    const row = await cardRepository.insertBillRecord({
      cardId: gas.id,
      year: r.year,
      month: r.month,
      amountWon: r.amountWon,
      usageKwh: r.usageKwh,
      usageM3: r.usageM3,
    });
    saved.push(row);
  }

  const updatedData = {
    ...(gas.data || {}),
    isLinked: true,
    customerNo: String(customerNo).trim(),
  };
  if (company != null && String(company).trim() !== '') {
    updatedData.company = String(company).trim();
  }
  const card = await cardRepository.upsertCard(roomId, 'cityGas', updatedData);

  const history = await cardRepository.getBillRecords(gas.id);
  return { card, saved, history };
}

module.exports = { getCards, saveContract, refreshElectricity, refreshCityGas };
