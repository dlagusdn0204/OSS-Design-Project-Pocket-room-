// OpmClient — 한전 OPM(Open P-Meter) 연동을 담당하는 통합(Integration) 계층.
// ───────────────────────────────────────────────────────────────
// ⚠️ 실연동(fetchBills)은 FAQ Q8 제약(학부 프로젝트는 서비스 승인 대상 아님)으로 보류.
//    대신 parseSamplePayload 가 "한전에서 받은 예시 OPM 응답(JSON)"을 우리 BillRecord
//    형태로 변환합니다. 실서비스 때는 fetchBills 안에서 실제 HTTP 호출로 받은 응답을
//    이 parseSamplePayload 에 그대로 흘려보내면 위 계층(Service/Controller)은 불변입니다.
//
// 예시 OPM 응답 형식은 docs/MOCK_DESIGN.md 3.1 절에 정의돼 있습니다.

const { badRequest } = require('../utils/http_error');

// OPM 응답 코드 → 정상은 '0000'. 그 외는 에러.
const SUCCESS_CODE = '0000';

// 예시 OPM 응답(JSON) → 우리 BillRecord 후보 배열로 변환.
//   입력(payload) 모양(MOCK_DESIGN 3.1):
//     {
//       customer_no, customer_name, address, contract_type, ami_installed,
//       bills: [ { year, month, usage_kwh, amount_won, issue_date, due_date, paid } ],
//       fetched_at, response_code, response_message
//     }
//   반환: [ { year, month, amountWon, usageKwh, usageM3:null } ]
//        (DB 저장은 card_repository.insertBillRecord 가 담당 → 여기선 형식 변환만)
//   에러: 형식이 잘못됐거나 response_code 가 0000 이 아니면 400 으로 던집니다.
function parseSamplePayload(payload) {
  if (!payload || typeof payload !== 'object') {
    throw badRequest('OPM 응답(payload)이 올바른 JSON 객체가 아닙니다');
  }

  // 응답 코드가 있고 정상('0000')이 아니면 한전 측 에러로 간주.
  const code = payload.response_code;
  if (code && code !== SUCCESS_CODE) {
    const msg = payload.response_message || `OPM 오류 코드 ${code}`;
    throw badRequest(`OPM 오류 응답: ${msg}`);
  }

  const bills = Array.isArray(payload.bills) ? payload.bills : [];

  return bills.map((bill, idx) => {
    // 필수 필드 검증 — 하나라도 빠지면 어떤 항목인지 알려주고 400.
    if (bill == null || typeof bill !== 'object') {
      throw badRequest(`bills[${idx}] 항목이 객체가 아닙니다`);
    }
    const year = Number(bill.year);
    const month = Number(bill.month);
    const amountWon = Number(bill.amount_won);
    if (!Number.isInteger(year) || !Number.isInteger(month)) {
      throw badRequest(`bills[${idx}] 의 year/month 가 올바르지 않습니다`);
    }
    if (month < 1 || month > 12) {
      throw badRequest(`bills[${idx}] 의 month 는 1~12 여야 합니다`);
    }
    if (!Number.isFinite(amountWon)) {
      throw badRequest(`bills[${idx}] 의 amount_won 이 올바르지 않습니다`);
    }
    // usage_kwh 는 선택(없으면 null). 전기 카드이므로 usage_m3 는 항상 null.
    const usageKwh =
      bill.usage_kwh == null || bill.usage_kwh === ''
        ? null
        : Number(bill.usage_kwh);
    if (usageKwh != null && !Number.isFinite(usageKwh)) {
      throw badRequest(`bills[${idx}] 의 usage_kwh 가 올바르지 않습니다`);
    }

    return {
      year,
      month,
      amountWon: Math.trunc(amountWon),
      usageKwh,
      usageM3: null,
    };
  });
}

// 실서비스용 자리 — OPM 서비스 등록 승인 후 실제 Open API 를 호출해 응답을 받고,
// 위 parseSamplePayload 로 변환하면 됩니다. 지금은 호출되면 명시적으로 막습니다.
// eslint-disable-next-line no-unused-vars
function fetchBills(customerNo) {
  // TODO: 실서비스 — OPM Open API 실 호출(서비스 등록 승인 후). FAQ Q8 제약으로 현재 보류.
  throw new Error('실 OPM 연동(fetchBills)은 서비스 등록 승인 후 구현 예정입니다');
}

module.exports = { parseSamplePayload, fetchBills, SUCCESS_CODE };
