# 🖥️ Pocket Room Server

Pocket Room 앱의 백엔드 서버입니다. **Node.js + Express + PostgreSQL + JWT** 로 구성됩니다.

> 클라이언트(Flutter 앱)는 `../pocket_room/` 에 있습니다.
> 설계 근거: `../docs/Design_[22212047_임현우].md` (2.8~2.10, 3.6~3.7, 6장) / 작업 분할: `../docs/BACKEND_GUIDE.md`

---

## 1. 로컬 실행

```bash
cd pocket_room_server
npm install                # 최초 1회 (의존성 설치)

# .env 준비 (아래 2장 참고) — .env.example 을 복사해 값 채우기
cp .env.example .env       # 그 후 에디터로 실제 값 입력

npm run db:init            # DB 에 테이블 4종 생성/갱신 (idempotent, 여러 번 실행 OK)
npm run dev                # 개발 모드(파일 저장 시 자동 재시작)
# 또는
npm start                  # 일반 실행
```

확인:

```bash
curl http://localhost:3000/health        # → {"ok":true}
curl http://localhost:3000/health/db     # → {"ok":true,"db":true}
```

---

## 2. 환경변수 (`.env`)

`.env.example` 을 복사해 `.env` 를 만들고 아래 값을 채웁니다.
**`.env` 는 `.gitignore` 에 등록돼 있어 공유되지 않습니다. 실제 비밀값을 코드/문서/대화에 남기지 마세요.**

| 키 | 설명 |
| :-- | :-- |
| `DATABASE_URL` | Render PostgreSQL 의 **External Database URL**. 형식 `postgresql://user:pass@host:port/db` |
| `JWT_ACCESS_SECRET` | access 토큰 서명용 비밀키 (길고 무작위한 문자열) |
| `JWT_REFRESH_SECRET` | refresh 토큰 서명용 비밀키 (access 와 **다른** 값) |
| `JWT_ACCESS_EXPIRES` | (선택) access 만료. 기본 `15m` |
| `JWT_REFRESH_EXPIRES` | (선택) refresh 만료. 기본 `14d` |
| `PORT` | (선택) 로컬 포트. 기본 `3000`. Render 는 자동 주입하므로 배포 시 무시됨 |

JWT 시크릿 생성 예시:

```bash
node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
```

> ⏳ Render 무료 PostgreSQL(`PocketRoom`, Singapore, PG18)은 생성 30일 후(~2026-07-08) 만료됩니다.
> 만료 시 새 DB 를 만들고 `DATABASE_URL` 만 교체한 뒤 `npm run db:init` 를 다시 실행하세요(스키마는 `src/db/schema.sql` 로 보존).

---

## 3. API 엔드포인트

| 메서드 | 경로 | 인증 | 설명 |
| :-- | :-- | :--: | :-- |
| GET | `/health` | ✕ | 서버 생존 확인 |
| GET | `/health/db` | ✕ | DB 연결 확인 |
| POST | `/auth/signup` | ✕ | 회원가입 `{ id, password, email }` → 201 |
| POST | `/auth/login` | ✕ | 로그인 `{ id, password }` → `{ accessToken, refreshToken }` |
| POST | `/auth/refresh` | ✕ | 재발급 `{ refreshToken }` → `{ accessToken }` |
| GET | `/rooms` | ✓ | 내 방 목록 |
| POST | `/rooms` | ✓ | 방 생성 `{ name }` (빈 카드 3종 자동 생성) |
| GET | `/rooms/:id/cards` | ✓ | 방의 카드 3종 + 전기/가스 요금 이력 |
| PUT | `/rooms/:id/cards/contract` | ✓ | 계약 카드 저장 `{ rentWon, accountNumber, address, paymentDueDay }` |
| POST | `/rooms/:id/cards/electricity/refresh` | ✓ | 전기요금 갱신 — **예시 OPM 응답(JSON)** 을 body 로 받아 파싱·누적 |

인증이 필요한 요청은 헤더에 `Authorization: Bearer <accessToken>` 를 넣습니다.
방 관련 엔드포인트는 토큰의 사용자가 소유한 방만 접근 가능합니다(아니면 404).

### 전기요금 갱신 body 예시 (예시 OPM 응답)

형식 정의: `../docs/MOCK_DESIGN.md` 3.1 절.

```json
{
  "customer_no": "1234567890",
  "customer_name": "임현우",
  "contract_type": "주택용(저압)",
  "ami_installed": true,
  "bills": [
    { "year": 2026, "month": 6, "usage_kwh": 245.5, "amount_won": 32500 }
  ],
  "response_code": "0000",
  "response_message": "정상 응답"
}
```

> 🔒 한전 OPM **실연동은 보류**(FAQ Q8 제약). 서버 `src/integration/opm_client.js` 의
> `parseSamplePayload` 가 위 예시 응답을 `BillRecord` 로 변환합니다.
> 실서비스 시 `fetchBills`(현재 `// TODO`)만 채우면 상위 계층은 그대로 동작합니다.

---

## 4. 폴더 구조

```
pocket_room_server/
├── package.json
├── .env.example            # 키 이름만 (실제 .env 는 직접 생성)
├── .gitignore              # node_modules, .env 제외
├── README.md               # (이 파일)
└── src/
    ├── index.js            # 진입점 (.env 로드 + listen)
    ├── app.js              # Express 앱 (미들웨어 + 라우트 + 공통 에러 핸들러)
    ├── db/
    │   ├── pool.js         # PostgreSQL 풀 (Render SSL 자동)
    │   ├── schema.sql      # 4테이블 스키마
    │   └── init_schema.js  # npm run db:init
    ├── repositories/       # DB 입출고(SQL)만 — user/room/card
    ├── services/           # 비즈니스 로직 — token/auth/room/bill
    ├── integration/        # 외부 연동 — opm_client (예시 응답 파싱)
    ├── controllers/        # HTTP 요청/응답 — auth/room/bill
    ├── routes/             # 경로 ↔ 컨트롤러 — auth/room/bill
    ├── middleware/         # auth (Bearer 토큰 검증)
    └── utils/              # http_error
```

계층 흐름: **Routes → Controller → Service → (Integration / Repository) → PostgreSQL**

---

## 5. 배포 (Render 무료 웹 서비스)

> ⚠️ 이 프로젝트는 **Git 사용이 금지**돼 있습니다(CLAUDE.md 규칙). Render 의 기본 배포 방식은
> GitHub 연동(Git)이므로, 배포는 **사용자(임현우)** 가 직접 진행합니다. 아래는 안내 메모입니다.

**선택지**

1. **GitHub 연동 배포** (가장 쉬움, Git 필요)
   - 별도로 GitHub 저장소를 만들고 `pocket_room_server/` 를 올린 뒤 Render 의
     "New + → Web Service" 에서 그 저장소를 연결.
   - Build Command: `npm install` / Start Command: `npm start`
   - Root Directory: `pocket_room_server` (모노레포라면 지정)
2. **Render CLI** (`render` CLI) 또는 Docker 이미지 배포 — Git 없이도 가능.
3. **Render Blueprint** — 저장소 루트에 `render.yaml`(이 폴더에 동봉)을 두고 Blueprint 로 생성.

**환경변수**: Render 대시보드의 서비스 → Environment 에 `JWT_ACCESS_SECRET`,
`JWT_REFRESH_SECRET`, `DATABASE_URL`(Render 내부 DB 라면 Internal URL 사용 가능)을 등록.
**`PORT` 는 Render 가 자동 주입**하므로 따로 넣지 않아도 됩니다.

**배포 후 확인**

```bash
curl https://<your-service>.onrender.com/health      # → {"ok":true}
```

> 무료 웹 서비스는 유휴 시 잠듭니다(spin-down). 시연 직전 `/health` 를 한 번 호출해 깨워두세요.
