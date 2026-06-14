// BillService — 방의 카드 조회, 계약 카드 저장, 전기요금 갱신(예시 OPM 응답 파싱)을 담당.
// Design 3.6(요금 수신, 서버 경유) 시퀀스 구현.
//
// 🔒 모든 작업은 먼저 "이 방이 정말 내 방인지"(소유권)를 확인합니다.
//    roomId 는 URL 로 들어오므로, 토큰의 ownerId 와 방의 owner_id 가 다르면 404 로 막아
//    남의 방 카드를 조회·수정하는 것을 차단합니다(존재 자체를 숨기려고 403 대신 404).

const roomRepository = require('../repositories/room_repository');
const cardRepository = require('../repositories/card_repository');
const opmClient = require('../integration/opm_client');
const { badRequest, notFound } = require('../utils/http_error');

// 방 소유권 확인. 내 방이 아니거나 없으면 404 를 던집니다.
//   반환: 방 행(이후 로직에서 재사용 가능).
async function assertOwnedRoom(roomId, ownerId) {
  const room = await roomRepository.findById(roomId);
  if (!room || room.owner_id !== ownerId) {
    throw notFound('방을 찾을 수 없습니다');
  }
  return room;
}

// 한 방의 카드 3종 + 전기/가스 카드의 요금 이력(추이 그래프용)을 함께 반환.
//   반환: [ { id, room_id, type, data, updated_at, history?: [BillRecord] } ]
//        contract 카드는 history 가 없습니다(요금 이력 대상이 아님).
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

// 계약 카드(contract) 저장 — 월세/계좌/주소/납부일.
//   입력(data): { rentWon, accountNumber, address, paymentDueDay } (모두 선택)
//   화이트리스트로 필요한 필드만 골라 저장(예상치 못한 키 유입 차단).
//   반환: 저장된 카드 행.
async function saveContract(ownerId, roomId, data) {
  await assertOwnedRoom(roomId, ownerId);
  const body = data || {};

  // 납부일은 1~31 범위만 허용(있을 때만 검사).
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

// 전기요금 갱신 — 예시 OPM 응답(JSON)을 파싱해 bill_records 에 누적 저장.
//   입력(samplePayload): docs/MOCK_DESIGN.md 3.1 형식의 OPM 응답.
//   흐름: 소유권 확인 → 전기 카드 찾기 → OpmClient 파싱 → 이력 upsert →
//        카드 data 갱신(isLinked=true, customerNo) → 최신 이력 반환.
//   반환: { card, saved: [방금 저장/덮어쓴 이력], history: [전체 이력] }
async function refreshElectricity(ownerId, roomId, samplePayload) {
  await assertOwnedRoom(roomId, ownerId);

  const cards = await cardRepository.findByRoom(roomId);
  const elec = cards.find((c) => c.type === 'electricity');
  if (!elec) {
    throw notFound('전기 카드를 찾을 수 없습니다');
  }

  // 예시 OPM 응답 → BillRecord 후보. 형식 오류/에러 코드면 여기서 400 이 던져집니다.
  const records = opmClient.parseSamplePayload(samplePayload);
  if (records.length === 0) {
    throw badRequest('OPM 응답에 청구 내역(bills)이 없습니다');
  }

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

  // 카드 상태 갱신: 연동됨 표시 + (응답에 있으면) 고객번호 저장.
  const updatedData = { ...(elec.data || {}), isLinked: true };
  if (samplePayload && samplePayload.customer_no) {
    updatedData.customerNo = samplePayload.customer_no;
  }
  const card = await cardRepository.upsertCard(roomId, 'electricity', updatedData);

  const history = await cardRepository.getBillRecords(elec.id);
  return { card, saved, history };
}

module.exports = { getCards, saveContract, refreshElectricity };
