
const { badRequest } = require('../utils/http_error');

const SUCCESS_CODE = '0000';

function parseSamplePayload(payload) {
  if (!payload || typeof payload !== 'object') {
    throw badRequest('OPM 응답(payload)이 올바른 JSON 객체가 아닙니다');
  }

  const code = payload.response_code;
  if (code && code !== SUCCESS_CODE) {
    const msg = payload.response_message || `OPM 오류 코드 ${code}`;
    throw badRequest(`OPM 오류 응답: ${msg}`);
  }

  const bills = Array.isArray(payload.bills) ? payload.bills : [];

  return bills.map((bill, idx) => {
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

// eslint-disable-next-line no-unused-vars
function fetchBills(customerNo) {
  throw new Error('실 OPM 연동(fetchBills)은 서비스 등록 승인 후 구현 예정입니다');
}

module.exports = { parseSamplePayload, fetchBills, SUCCESS_CODE };
