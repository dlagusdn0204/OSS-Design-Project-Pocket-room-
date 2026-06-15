
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS users (
  id            TEXT        PRIMARY KEY,
  password_hash TEXT        NOT NULL,
  email         TEXT        NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS rooms (
  id         TEXT        PRIMARY KEY DEFAULT gen_random_uuid()::text,
  owner_id   TEXT        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name       TEXT        NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_rooms_owner ON rooms(owner_id);

CREATE TABLE IF NOT EXISTS cards (
  id         TEXT        PRIMARY KEY DEFAULT gen_random_uuid()::text,
  room_id    TEXT        NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  type       TEXT        NOT NULL CHECK (type IN ('contract', 'electricity', 'cityGas')),
  data       JSONB       NOT NULL DEFAULT '{}'::jsonb,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (room_id, type)
);
CREATE INDEX IF NOT EXISTS idx_cards_room ON cards(room_id);

CREATE TABLE IF NOT EXISTS bill_records (
  id          TEXT        PRIMARY KEY DEFAULT gen_random_uuid()::text,
  card_id     TEXT        NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
  year        INTEGER     NOT NULL,
  month       INTEGER     NOT NULL CHECK (month BETWEEN 1 AND 12),
  amount_won  INTEGER     NOT NULL,
  usage_kwh   NUMERIC,
  usage_m3    NUMERIC,
  fetched_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (card_id, year, month)
);
CREATE INDEX IF NOT EXISTS idx_bill_records_card ON bill_records(card_id);
