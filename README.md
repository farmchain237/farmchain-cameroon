# FarmChain Cameroun — MVP v0.5.0

## Structure
```
/backend   NestJS + Prisma + PostgreSQL/PostGIS API
/mobile    Flutter app (iOS/Android)
/web       Next.js 14 web app (SSR listings) — scaffold to be filled in next pass
/infra     docker-compose, mosquitto config
/.github   CI workflows (iOS TestFlight)
```

## What's implemented in this pass
- Full Prisma schema: users, farms, listings, bids/buy-requests, orders, payments,
  chat channels, accountability videos, security devices/events, employees/shifts,
  daily reports.
- **Auth**: phone OTP (Africa's Talking, with a dev-mode console fallback) → JWT.
- **Listings**: create + geo/filter search (PostGIS `ST_DWithin`/`ST_Distance`).
- **Orders/Escrow**: create order → MTN MoMo or Orange Money `requestToPay` →
  webhook marks `ESCROWED` → transporter confirms GPS delivery → funds auto-release
  (disbursement API call itself is a `TODO` — needs your MoMo Disbursements product
  credentials, which are separate from Collections).
- **Chat**: Stream Chat token issuance + auto-created channels per listing and
  per region+crop group.
- **Accountability videos**: presigned S3 upload flow, 60s cap enforced server-side.
- **Security**: device registry with encrypted RTSP URLs, MQTT motion/status
  listener, Flutter live view via `flutter_vlc_player`, QR-code device onboarding.
- **Employees**: PIN-based clock-in/out with GPS capture.
- **Reports**: nightly cron (`23:59 Africa/Douala`) generating per-company
  `DailyReport`. PDF/Excel export and WhatsApp/email delivery are stubbed —
  `TODO` in `reports.controller.ts`.
- **Mobile**: offline-first shell (Hive cache + retry queue), FR/EN toggle,
  phone OTP flow, listings browse/filter, listing detail, chat, video recording,
  security tab, employee clock-in.
- **CI**: GitHub Actions workflow building Flutter iOS and pushing to TestFlight
  via Fastlane + match + App Store Connect API key.

## What's realistically NOT done yet (be aware before promising "7 days")
- USSD (`*126#`) listing creation — needs an Africa's Talking USSD session
  handler; the listings API is shaped to support it, but the session/state
  machine controller isn't written.
- Web app (`/web`) is an empty scaffold — Next.js SSR listings pages need
  building.
- Reverse-bidding acceptance flow (farmer accepts a bid → creates order) — the
  `Bid`/`BuyRequest` models exist, the accept-bid endpoint doesn't yet.
- PDF/Excel report export + WhatsApp/email delivery.
- Lambda thumbnail generation for videos (S3 trigger) — not written.
- USSD, disbursement payouts, and the RTSP "test connection" button all need
  real credentials/hardware to finish and test properly.
- No automated tests yet.

## To run locally
```bash
cd infra/docker
docker compose up -d          # Postgres+PostGIS, Redis, Mosquitto

cd ../../backend
cp .env.example .env          # fill in secrets
npm install
npx prisma migrate dev --name init
npm run start:dev

cd ../mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1 \
            --dart-define=STREAM_API_KEY=your_key
```

## Before I can continue with exact wiring, I need from you
1. **Stream Chat API key + secret**
2. **MTN MoMo**: Collections subscription key, API user, API key (and separately,
   Disbursements product credentials once you have them — different sandbox app)
3. **Orange Money**: client ID/secret, merchant key
4. **Apple Team ID** + an App Store Connect API key (`.p8`, Key ID, Issuer ID) for
   the TestFlight pipeline, plus a `match` git repo URL for cert/profile storage
5. **Africa's Talking** (or Twilio) API key/username for OTP SMS
6. **AWS**: access key/secret for the `af-south-1` S3 bucket + CloudFront domain
7. Confirmation on the 1% platform fee and whether it's deducted from the farmer's
   payout or added on top of the buyer's price (schema currently assumes the former)

Once I have those, I'll wire real values into `.env`, write the reverse-bidding
accept-bid endpoint, the web app's listing pages, and the USSD session handler.
