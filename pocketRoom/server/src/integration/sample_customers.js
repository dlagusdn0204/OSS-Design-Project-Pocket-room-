
const { badRequest } = require('../utils/http_error');

const ELECTRICITY_FIXED = [
  15600, 16800, 14700, 12000, 18000, 25000,
  31000, 34000, 25000, 16500, 16000, 21000,
];
const GAS_FIXED = [
  56000, 53000, 36500, 16000, 13200, 19800,
  9000, 8000, 12000, 24000, 42000, 58000,
];

function elecUsageKwh(amountWon) {
  return Math.max(1, Math.round((amountWon - 1600) / 130));
}
function gasUsageM3(amountWon) {
  return Math.max(1, Math.round((amountWon - 1000) / 850));
}

function buildSampleBills({ type, customerNo, year }) {
  const key = String(customerNo ?? '').trim();
  if (!key) {
    throw badRequest('고객번호(customerNo)가 필요합니다');
  }
  const y = Number.isInteger(Number(year)) ? Number(year) : new Date().getFullYear();

  const table =
    type === 'electricity'
      ? ELECTRICITY_FIXED
      : type === 'cityGas'
        ? GAS_FIXED
        : null;
  if (!table) {
    throw badRequest(`알 수 없는 카드 종류: ${type}`);
  }

  const upTo = Math.min(12, new Date().getMonth() + 1);
  const bills = [];
  for (let m = 1; m <= upTo; m += 1) {
    const amountWon = table[m - 1];
    if (type === 'electricity') {
      bills.push({
        year: y,
        month: m,
        amountWon,
        usageKwh: elecUsageKwh(amountWon),
        usageM3: null,
      });
    } else {
      bills.push({
        year: y,
        month: m,
        amountWon,
        usageKwh: null,
        usageM3: gasUsageM3(amountWon),
      });
    }
  }
  return bills;
}

module.exports = { ELECTRICITY_FIXED, GAS_FIXED, buildSampleBills };
