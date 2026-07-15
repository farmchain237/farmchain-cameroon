generator client {
  provider        = "prisma-client-js"
  previewFeatures = ["postgresqlExtensions"]
}

datasource db {
  provider   = "postgresql"
  url        = env("DATABASE_URL")
  extensions = [postgis]
}

// ─────────────────────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────────────────────

enum Role {
  FARMER
  BUYER
  TRANSPORTER
  AGRONOMIST
  CONSUMER
  EMPLOYEE
  ADMIN
}

enum Locale {
  fr_CM
  en
}

enum CropType {
  CACAO
  CAFE
  PLANTAIN
  MAIS
  TOMATE
  MANIOC
}

enum Region {
  LITTORAL
  CENTRE
  OUEST
  SUD_OUEST
  NORD_OUEST
  ADAMAOUA
  EST
  EXTREME_NORD
  NORD
  SUD
}

enum Grade {
  A
  B
}

enum ListingStatus {
  ACTIVE
  RESERVED
  SOLD
  EXPIRED
  CANCELLED
}

enum BidStatus {
  PENDING
  ACCEPTED
  REJECTED
  WITHDRAWN
}

enum OrderStatus {
  CREATED
  PAYMENT_PENDING
  ESCROWED
  IN_TRANSIT
  DELIVERED
  RELEASED
  DISPUTED
  REFUNDED
  CANCELLED
}

enum PaymentProvider {
  MTN_MOMO
  ORANGE_MONEY
}

enum PaymentStatus {
  INITIATED
  PENDING
  SUCCESS
  FAILED
  REFUNDED
}

enum VideoType {
  FARM_VISIT
  PICKUP
  DELIVERY
  QUALITY_CHECK
  HARVEST
}

enum DeviceType {
  CAMERA
  MOTION
  DOOR
}

enum SecurityEventType {
  MOTION_DETECTED
  CAMERA_OFFLINE
  CAMERA_ONLINE
  DOOR_OPENED
}

enum ChatChannelType {
  LISTING
  REGION_CROP
  DIRECT
}

// ─────────────────────────────────────────────────────────
// CORE IDENTITY
// ─────────────────────────────────────────────────────────

model User {
  id            String   @id @default(cuid())
  phone         String   @unique // E.164, e.g. +2376XXXXXXXX
  cniNumber     String? // optional Cameroon national ID
  fullName      String
  role          Role
  locale        Locale   @default(fr_CM)
  avatarUrl     String?
  isVerified    Boolean  @default(false)
  streamUserId  String?  @unique // Stream Chat user id (mirrors User.id normally)
  fcmTokens     String[] // device push tokens
  createdAt     DateTime @default(now())
  updatedAt     DateTime @updatedAt

  farms             Farm[]
  listings          Listing[]
  bids              Bid[]
  buyerOrders       Order[]        @relation("BuyerOrders")
  transporterOrders Order[]        @relation("TransporterOrders")
  videos            AccountabilityVideo[]
  employee          Employee?
  chatMessages      ChatMessage[]
  securityDevices   SecurityDevice[]

  @@index([role])
  @@map("users")
}

model Company {
  id        String   @id @default(cuid())
  name      String
  region    Region
  createdAt DateTime @default(now())

  employees    Employee[]
  dailyReports DailyReport[]

  @@map("companies")
}

model Farm {
  id       String @id @default(cuid())
  ownerId  String
  owner    User   @relation(fields: [ownerId], references: [id])
  name     String
  region   Region
  // PostGIS point, set via raw SQL migration: location geography(Point, 4326)
  location Unsupported("geography(Point, 4326)")?
  address  String?

  listings        Listing[]
  securityDevices SecurityDevice[]

  @@index([ownerId])
  @@map("farms")
}

// ─────────────────────────────────────────────────────────
// MARKETPLACE
// ─────────────────────────────────────────────────────────

model Listing {
  id          String        @id @default(cuid())
  farmerId    String
  farmer      User          @relation(fields: [farmerId], references: [id])
  farmId      String?
  farm        Farm?         @relation(fields: [farmId], references: [id])
  cropType    CropType
  region      Region
  qtyKg       Decimal       @db.Decimal(10, 2)
  grade       Grade
  pricePerKg  Decimal       @db.Decimal(10, 2) // XAF
  harvestDate DateTime
  photos      String[] // S3 keys
  location    Unsupported("geography(Point, 4326)")?
  status      ListingStatus @default(ACTIVE)
  createdAt   DateTime      @default(now())
  updatedAt   DateTime      @updatedAt

  bids     Bid[]
  orders   Order[]
  videos   AccountabilityVideo[]
  chatChannel ChatChannel?

  @@index([cropType, region, status])
  @@map("listings")
}

// Reverse bidding: buyer posts a request, farmers bid against it
model BuyRequest {
  id          String   @id @default(cuid())
  buyerId     String
  cropType    CropType
  region      Region
  qtyKg       Decimal  @db.Decimal(10, 2)
  maxPricePerKg Decimal @db.Decimal(10, 2)
  neededBy    DateTime
  status      BidStatus @default(PENDING)
  createdAt   DateTime @default(now())

  bids Bid[]

  @@map("buy_requests")
}

model Bid {
  id            String     @id @default(cuid())
  buyRequestId  String
  buyRequest    BuyRequest @relation(fields: [buyRequestId], references: [id])
  farmerId      String
  farmer        User       @relation(fields: [farmerId], references: [id])
  listingId     String?
  listing       Listing?   @relation(fields: [listingId], references: [id])
  offeredPrice  Decimal    @db.Decimal(10, 2)
  status        BidStatus  @default(PENDING)
  createdAt     DateTime   @default(now())

  @@index([buyRequestId])
  @@map("bids")
}

model Order {
  id             String      @id @default(cuid())
  listingId      String
  listing        Listing     @relation(fields: [listingId], references: [id])
  buyerId        String
  buyer          User        @relation("BuyerOrders", fields: [buyerId], references: [id])
  transporterId  String?
  transporter    User?       @relation("TransporterOrders", fields: [transporterId], references: [id])
  qtyKg          Decimal     @db.Decimal(10, 2)
  totalPriceXaf  Decimal     @db.Decimal(12, 2)
  feeXaf         Decimal     @db.Decimal(12, 2) @default(0) // 1% platform fee
  status         OrderStatus @default(CREATED)
  deliveryGps    Unsupported("geography(Point, 4326)")?
  deliveredAt    DateTime?
  releasedAt     DateTime?
  createdAt      DateTime    @default(now())
  updatedAt      DateTime    @updatedAt

  payments Payment[]
  videos   AccountabilityVideo[]

  @@index([status])
  @@map("orders")
}

model Payment {
  id          String          @id @default(cuid())
  orderId     String
  order       Order           @relation(fields: [orderId], references: [id])
  provider    PaymentProvider
  providerRef String? // MoMo/Orange transaction id
  amountXaf   Decimal         @db.Decimal(12, 2)
  status      PaymentStatus   @default(INITIATED)
  isEscrow    Boolean         @default(true)
  releasedAt  DateTime?
  createdAt   DateTime        @default(now())
  updatedAt   DateTime        @updatedAt

  @@index([orderId])
  @@map("payments")
}

// ─────────────────────────────────────────────────────────
// CHAT
// ─────────────────────────────────────────────────────────

model ChatChannel {
  id           String          @id @default(cuid())
  streamChannelId String       @unique
  type         ChatChannelType
  listingId    String?         @unique
  listing      Listing?        @relation(fields: [listingId], references: [id])
  regionCropKey String? // e.g. "MAIS_CENTRE"
  createdAt    DateTime        @default(now())

  messages ChatMessage[]

  @@map("chat_channels")
}

model ChatMessage {
  id            String      @id @default(cuid())
  channelId     String
  channel       ChatChannel @relation(fields: [channelId], references: [id])
  senderId      String
  sender        User        @relation(fields: [senderId], references: [id])
  streamMessageId String    @unique
  createdAt     DateTime    @default(now())

  @@index([channelId])
  @@map("chat_messages")
}

// ─────────────────────────────────────────────────────────
// ACCOUNTABILITY VIDEOS
// ─────────────────────────────────────────────────────────

model AccountabilityVideo {
  id         String    @id @default(cuid())
  userId     String
  user       User      @relation(fields: [userId], references: [id])
  listingId  String?
  listing    Listing?  @relation(fields: [listingId], references: [id])
  orderId    String?
  order      Order?    @relation(fields: [orderId], references: [id])
  type       VideoType
  s3Key      String
  thumbnailUrl String?
  durationSec Int      @db.SmallInt // max 60
  location   Unsupported("geography(Point, 4326)")?
  recordedAt DateTime
  createdAt  DateTime  @default(now())

  @@index([listingId])
  @@index([orderId])
  @@map("accountability_videos")
}

// ─────────────────────────────────────────────────────────
// SECURITY
// ─────────────────────────────────────────────────────────

model SecurityDevice {
  id            String     @id @default(cuid())
  ownerId       String
  owner         User       @relation(fields: [ownerId], references: [id])
  farmId        String
  farm          Farm       @relation(fields: [farmId], references: [id])
  type          DeviceType
  name          String
  rtspUrlEnc    String? // encrypted at rest (KMS/envelope encryption in app layer)
  mqttTopic     String? // e.g. farmchain/security/{deviceId}/motion
  isOnline      Boolean    @default(false)
  lastSeenAt    DateTime?
  createdAt     DateTime   @default(now())

  events SecurityEvent[]

  @@index([farmId])
  @@map("security_devices")
}

model SecurityEvent {
  id           String            @id @default(cuid())
  deviceId     String
  device       SecurityDevice    @relation(fields: [deviceId], references: [id])
  type         SecurityEventType
  snapshotUrl  String?
  metadata     Json?
  createdAt    DateTime          @default(now())

  @@index([deviceId, createdAt])
  @@map("security_events")
}

// ─────────────────────────────────────────────────────────
// EMPLOYEES / SHIFTS / REPORTS
// ─────────────────────────────────────────────────────────

model Employee {
  id         String   @id @default(cuid())
  userId     String   @unique
  user       User     @relation(fields: [userId], references: [id])
  companyId  String
  company    Company  @relation(fields: [companyId], references: [id])
  role       String
  pinCodeHash String // hashed, never store raw PIN
  createdAt  DateTime @default(now())

  shifts Shift[]

  @@map("employees")
}

model Shift {
  id            String    @id @default(cuid())
  employeeId    String
  employee      Employee  @relation(fields: [employeeId], references: [id])
  clockIn       DateTime
  clockOut      DateTime?
  clockInGps    Unsupported("geography(Point, 4326)")?
  clockOutGps   Unsupported("geography(Point, 4326)")?

  @@index([employeeId, clockIn])
  @@map("shifts")
}

model DailyReport {
  id              String   @id @default(cuid())
  companyId       String
  company         Company  @relation(fields: [companyId], references: [id])
  reportDate      DateTime @db.Date
  ordersCount     Int
  revenueXaf      Decimal  @db.Decimal(14, 2)
  momoFeesXaf     Decimal  @db.Decimal(14, 2)
  netXaf          Decimal  @db.Decimal(14, 2)
  topCrop         CropType?
  activeEmployees Int
  createdAt       DateTime @default(now())

  @@unique([companyId, reportDate])
  @@map("daily_reports")
}
