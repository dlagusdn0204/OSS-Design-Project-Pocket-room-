-- Pocket Room 서버 DB 스키마 (PostgreSQL)
-- ───────────────────────────────────────────────────────────────
-- Design v2.x 6장(구현 요구) + 클라이언트 도메인 모델 기준.
-- 이 파일 하나로 전체 테이블을 재생성할 수 있게 작성 (DB 만료 후 재구축 대비).
--
-- 적용 방법: `npm run db:init` (src/db/init_schema.js 가 이 파일을 실행)
-- IF NOT EXISTS 를 사용하므로 여러 번 실행해도 안전(idempotent)합니다.

-- UUID 생성 함수(gen_random_uuid)를 쓰기 위한 확장. PG13+ 기본 포함.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1) 사용자 ─ 클라이언트 User 모델과 대응
--    id 는 사용자가 정한 아이디(문자열)를 그대로 PK 로 사용 (앱과 동일).
CREATE TABLE IF NOT EXISTS users (
  id            TEXT        PRIMARY KEY,
  password_hash TEXT        NOT NULL,           -- bcrypt 해시만 저장 (평문 금지)
  email         TEXT        NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2) 방(거주지) ─ 한 사용자가 여러 방 보유 (1:N)
CREATE TABLE IF NOT EXISTS rooms (
  id         TEXT        PRIMARY KEY DEFAULT gen_random_uuid()::text,
  owner_id   TEXT        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name       TEXT        NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_rooms_owner ON rooms(owner_id);

-- 3) 카드 ─ 방마다 contract / electricity / cityGas 각 1장씩
--    카드별로 들어가는 필드가 제각각이라 가변 부분은 JSONB(data)로 단순화.
--      contract    → { rentWon, accountNumber, address, paymentDueDay }
--      electricity → { customerNo, isLinked }
--      cityGas     → { company, isLinked }
CREATE TABLE IF NOT EXISTS cards (
  id         TEXT        PRIMARY KEY DEFAULT gen_random_uuid()::text,
  room_id    TEXT        NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  type       TEXT        NOT NULL CHECK (type IN ('contract', 'electricity', 'cityGas')),
  data       JSONB       NOT NULL DEFAULT '{}'::jsonb,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  -- 방 하나당 같은 종류 카드는 하나만 → upsert 의 기준 키
  UNIQUE (room_id, type)
);
CREATE INDEX IF NOT EXISTS idx_cards_room ON cards(room_id);

-- 4) 월별 요금 이력 ─ 전기/가스 카드의 추이 그래프용
--    클라이언트 BillRecord(year, month, amountWon, usageKwh, usageM3, fetchedAt)와 대응.
CREATE TABLE IF NOT EXISTS bill_records (
  id          TEXT        PRIMARY KEY DEFAULT gen_random_uuid()::text,
  card_id     TEXT        NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
  year        INTEGER     NOT NULL,
  month       INTEGER     NOT NULL CHECK (month BETWEEN 1 AND 12),
  amount_won  INTEGER     NOT NULL,
  usage_kwh   NUMERIC,                          -- 전기 사용량 (가스는 NULL)
  usage_m3    NUMERIC,                          -- 가스 사용량 (전기는 NULL)
  fetched_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  -- 같은 카드의 같은 연·월은 1건만 → 재갱신 시 덮어쓰기(upsert) 기준
  UNIQUE (card_id, year, month)
);
CREATE INDEX IF NOT EXISTS idx_bill_records_card ON bill_records(card_id);
