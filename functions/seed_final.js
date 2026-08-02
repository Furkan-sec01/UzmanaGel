/**
 * seed_final.js — Firebase CLI'da saklanan OAuth token ile
 * Firestore REST API üzerinden test verisi ekler.
 *
 * Kullanım: node seed_final.js
 */

const fs = require("fs");
const https = require("https");
const { execSync } = require("child_process");

const PROJECT_ID = "uzmanagel-cad0b";
const BASE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

// ─── Token al ────────────────────────────────────────────────────────────────

function getStoredToken() {
  const credPath = "/Users/baran/.config/configstore/firebase-tools.json";
  const creds = JSON.parse(fs.readFileSync(credPath, "utf8"));
  const tokens = creds.tokens;
  if (tokens && tokens.access_token) {
    return tokens.access_token;
  }
  throw new Error("Token bulunamadı. Lütfen 'firebase login' ile tekrar giriş yapın.");
}

async function refreshTokenIfNeeded(token) {
  // Mevcut token'ı test et
  try {
    await firestoreGet("users", "test_probe_nonexistent", token);
    return token;
  } catch (e) {
    if (e.message && e.message.includes("401")) {
      throw new Error("Token süresi dolmuş. Lütfen 'firebase login' ile tekrar giriş yapın.");
    }
    return token; // 404 = token geçerli, doküman sadece yok
  }
}

// ─── Firestore REST API ───────────────────────────────────────────────────────

function toFirestoreValue(value) {
  if (value === null || value === undefined) return { nullValue: null };
  if (typeof value === "boolean") return { booleanValue: value };
  if (typeof value === "number") {
    if (Number.isInteger(value) && Math.abs(value) < 1e15)
      return { integerValue: String(value) };
    return { doubleValue: value };
  }
  if (typeof value === "string") return { stringValue: value };
  if (value instanceof Date) return { timestampValue: value.toISOString() };
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map(toFirestoreValue) } };
  }
  if (typeof value === "object") {
    const fields = {};
    for (const [k, v] of Object.entries(value)) {
      if (v !== undefined) fields[k] = toFirestoreValue(v);
    }
    return { mapValue: { fields } };
  }
  return { stringValue: String(value) };
}

function makeFields(data) {
  const fields = {};
  for (const [k, v] of Object.entries(data)) {
    if (v !== undefined) fields[k] = toFirestoreValue(v);
  }
  return fields;
}

function httpsRequest(url, method, body, token) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const bodyStr = body ? JSON.stringify(body) : null;

    const options = {
      hostname: urlObj.hostname,
      path: urlObj.pathname + urlObj.search,
      method,
      headers: {
        "Authorization": `Bearer ${token}`,
        "Content-Type": "application/json",
        ...(bodyStr ? { "Content-Length": Buffer.byteLength(bodyStr) } : {}),
      },
    };

    const req = https.request(options, (res) => {
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => {
        if (res.statusCode >= 400) {
          reject(new Error(`HTTP ${res.statusCode}: ${data.substring(0, 200)}`));
        } else {
          resolve(JSON.parse(data));
        }
      });
    });

    req.on("error", reject);
    if (bodyStr) req.write(bodyStr);
    req.end();
  });
}

async function firestoreSet(collection, docId, data, token) {
  const url = `${BASE_URL}/${collection}/${docId}`;
  return httpsRequest(url, "PATCH", { fields: makeFields(data) }, token);
}

async function firestoreGet(collection, docId, token) {
  const url = `${BASE_URL}/${collection}/${docId}`;
  return httpsRequest(url, "GET", null, token);
}

async function firestoreQuery(collection, field, op, value, token) {
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents:runQuery`;
  const body = {
    structuredQuery: {
      from: [{ collectionId: collection }],
      where: {
        fieldFilter: {
          field: { fieldPath: field },
          op: op === "==" ? "EQUAL" : "ARRAY_CONTAINS",
          value: toFirestoreValue(value),
        },
      },
      limit: 20,
    },
  };

  const results = await httpsRequest(url, "POST", body, token);
  return Array.isArray(results) ? results.filter((r) => r.document) : [];
}

function newId() {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  let id = "";
  for (let i = 0; i < 20; i++) id += chars[Math.floor(Math.random() * chars.length)];
  return id;
}

function randomDate(daysAgo) {
  const d = new Date();
  d.setDate(d.getDate() - Math.abs(daysAgo));
  d.setHours(9 + Math.floor(Math.random() * 8), 0, 0, 0);
  return d;
}

// ─── Seed fonksiyonu ──────────────────────────────────────────────────────────

const SERVICES_CATALOG = [
  { title: "Kombi Bakımı ve Onarımı",   category: "Tesisatçı",          price: 850  },
  { title: "Elektrik Pano Kontrolü",    category: "Elektrikçi",         price: 650  },
  { title: "Boya – Tek Oda",            category: "Boyacı",             price: 1200 },
  { title: "Klima Montajı",             category: "Klima Teknisyeni",   price: 950  },
  { title: "Çatı Tadilatı",             category: "Çatıcı",             price: 2500 },
  { title: "Fayans ve Seramik",         category: "Karocu",             price: 1800 },
];

const CUSTOMER_NAMES = [
  "Ahmet Yılmaz", "Zeynep Kaya", "Murat Demir", "Elif Çelik",
  "Burak Şahin", "Selin Arslan", "Oğuz Aydın", "Merve Doğan",
];

const REVIEW_TEXTS = [
  "Çok profesyonel ve işini iyi yapıyor. Kesinlikle tavsiye ederim.",
  "Zamanında geldi, temiz çalıştı. Memnun kaldım.",
  "Hızlı ve kaliteli hizmet. Teşekkürler!",
  "Fiyat/performans açısından mükemmel.",
  "Her şey yolundaydı, tekrar tercih edeceğim.",
  "İyi iş çıkardı, sabırlı ve dikkatli.",
  "Gayet başarılı, sorunsuz bir deneyimdi.",
  "Harika hizmet, çok beğendim!",
];

const COMPLETED_PLAN = [
  { daysAgo: 3,  svcIdx: 0 }, { daysAgo: 7,  svcIdx: 2 },
  { daysAgo: 12, svcIdx: 1 }, { daysAgo: 18, svcIdx: 3 },
  { daysAgo: 22, svcIdx: 5 }, { daysAgo: 28, svcIdx: 0 },
  { daysAgo: 35, svcIdx: 4 }, { daysAgo: 42, svcIdx: 3 },
  { daysAgo: 48, svcIdx: 1 }, { daysAgo: 55, svcIdx: 2 },
  { daysAgo: 61, svcIdx: 0 }, { daysAgo: 68, svcIdx: 5 },
  { daysAgo: 75, svcIdx: 3 }, { daysAgo: 82, svcIdx: 2 },
  { daysAgo: 88, svcIdx: 0 },
];

async function seedProvider(providerId, providerName, token) {
  console.log(`\n🌱 Seed başlıyor: ${providerName} (${providerId})`);

  // ─── 1. service_providers dokümanı
  try {
    await firestoreGet("service_providers", providerId, token);
    console.log("  ✅ service_providers dokümanı zaten var");
  } catch (e) {
    if (e.message.includes("404")) {
      await firestoreSet("service_providers", providerId, {
        providerId,
        businessName: providerName,
        city: "İstanbul",
        isActive: true,
        isAvailable: true,
        rating: 4.7,
        reviewCount: 0,
        experienceYears: 5,
        isCertified: true,
        acceptsCreditCard: false,
        description: "Uzman ve güvenilir hizmet sağlayıcı.",
        image: "",
      }, token);
      console.log("  🆕 service_providers oluşturuldu");
    }
  }

  // ─── 2. Servis dokümanı
  const existingSvc = await firestoreQuery("services", "providerId", "==", providerId, token);
  let serviceId;
  if (existingSvc.length > 0) {
    const parts = existingSvc[0].document.name.split("/");
    serviceId = parts[parts.length - 1];
    console.log(`  ✅ Mevcut servis: ${serviceId}`);
  } else {
    serviceId = newId();
    const svc = SERVICES_CATALOG[0];
    await firestoreSet("services", serviceId, {
      serviceId,
      title: svc.title,
      category: svc.category,
      price: svc.price,
      duration: "60 dakika",
      providerId,
      providerName,
      isActive: true,
      isAvailable: true,
      rating: 4.7,
      reviewCount: 8,
      isCertified: true,
      acceptsCreditCard: false,
      experienceYears: 5,
      description: "Profesyonel ve güvenilir hizmet.",
      image: "",
      city: "İstanbul",
    }, token);
    console.log(`  🆕 Servis oluşturuldu: ${serviceId}`);
  }

  // ─── 3. Tamamlanan rezervasyonlar
  const resIds = [];
  let totalEarnings = 0;

  for (let i = 0; i < COMPLETED_PLAN.length; i++) {
    const plan = COMPLETED_PLAN[i];
    const svc = SERVICES_CATALOG[plan.svcIdx];
    const resDate = randomDate(plan.daysAgo);
    const resId = newId();
    const customerName = CUSTOMER_NAMES[i % CUSTOMER_NAMES.length];

    await firestoreSet("reservations", resId, {
      reservationId: resId,
      serviceId,
      serviceTitle: svc.title,
      servicePrice: svc.price,
      serviceDuration: "60 dakika",
      providerId,
      providerName,
      customerId: `seed_customer_${i % 8}`,
      customerName,
      reservationDate: resDate,
      addressText: `Kadıköy, İstanbul – Test Adresi ${i + 1}`,
      note: "Seed verisi – test amaçlı.",
      status: "completed",
      rejectionReason: "",
      isRated: i < 8,
      createdAt: resDate,
      updatedAt: new Date(),
      completedAt: new Date(),
    }, token);

    resIds.push(resId);
    totalEarnings += svc.price;
    process.stdout.write(`\r  📝 Rezervasyon ${i + 1}/${COMPLETED_PLAN.length} eklendi...`);
  }
  console.log(`\n  ✅ ${COMPLETED_PLAN.length} tamamlanan rezervasyon eklendi`);

  // ─── 4. Bekleyen rezervasyon
  for (let i = 0; i < 2; i++) {
    const svc = SERVICES_CATALOG[i % 6];
    const future = new Date();
    future.setDate(future.getDate() + i + 1);
    future.setHours(10 + i, 0, 0, 0);
    const resId = newId();

    await firestoreSet("reservations", resId, {
      reservationId: resId,
      serviceId,
      serviceTitle: svc.title,
      servicePrice: svc.price,
      serviceDuration: "60 dakika",
      providerId,
      providerName,
      customerId: `seed_pending_${i}`,
      customerName: CUSTOMER_NAMES[i + 4],
      reservationDate: future,
      addressText: `Beşiktaş, İstanbul – Bekleyen Test`,
      note: "Yaklaşan rezervasyon.",
      status: i === 0 ? "accepted" : "pending",
      rejectionReason: "",
      isRated: false,
      createdAt: new Date(),
      updatedAt: new Date(),
    }, token);
  }
  console.log("  ✅ 2 bekleyen rezervasyon eklendi");

  // ─── 5. Yorumlar
  for (let i = 0; i < 8; i++) {
    const reviewId = newId();
    const rating = 4 + (i % 3) * 0.5;
    const createdDate = randomDate(3 + i * 5);

    await firestoreSet("reviews", reviewId, {
      reviewId,
      bookingId: resIds[i],
      reservationId: resIds[i],
      serviceId,
      serviceTitle: SERVICES_CATALOG[i % 6].title,
      customerId: `seed_customer_${i % 8}`,
      customerName: CUSTOMER_NAMES[i % 8],
      providerId,
      rating,
      comment: REVIEW_TEXTS[i],
      categoryRatings: { quality: rating, punctuality: 5.0, communication: 4.5 },
      photos: [],
      isReported: false,
      isVerifiedBooking: true,
      helpfulCount: i,
      helpfulUsers: [],
      createdAt: createdDate,
      updatedAt: createdDate,
    }, token);
  }
  console.log("  ✅ 8 yorum eklendi");

  // ─── 6. Özet
  console.log(`\n  💰 Toplam eklenen kazanç: ₺${totalEarnings.toLocaleString("tr-TR")}`);
  console.log("  📊 Finans ve İstatistik ekranlarını artık test edebilirsin!");
}

// ─── Ana akış ─────────────────────────────────────────────────────────────────

async function main() {
  console.log("🔑 Firebase CLI token okunuyor...\n");

  let token;
  try {
    token = getStoredToken();
    console.log("  ✅ Token bulundu\n");
  } catch (e) {
    console.error("  ❌", e.message);
    process.exit(1);
  }

  // Uzman hesaplarını bul (Firestore users koleksiyonu)
  console.log("🔍 Uzman hesapları aranıyor...\n");

  const expertResults = await firestoreQuery("users", "role", "==", "expert", token);
  let experts = expertResults.map((r) => {
    const parts = r.document.name.split("/");
    const uid = parts[parts.length - 1];
    const fields = r.document.fields || {};
    const displayName = fields.displayName?.stringValue || "İsimsiz Uzman";
    const email = fields.email?.stringValue || "";
    return { uid, displayName, email };
  });

  // service_providers'dan da bak
  if (experts.length === 0) {
    const spResults = await firestoreQuery("service_providers", "isActive", "==", true, token);
    experts = spResults.map((r) => {
      const parts = r.document.name.split("/");
      const uid = parts[parts.length - 1];
      const fields = r.document.fields || {};
      const name = fields.businessName?.stringValue || fields.displayName?.stringValue || "Uzman";
      return { uid, displayName: name, email: "" };
    });
  }

  if (experts.length === 0) {
    console.log("❌ Hiç uzman bulunamadı. Önce uygulamadan uzman olarak kaydolun.");
    process.exit(1);
  }

  console.log(`✅ ${experts.length} uzman bulundu:\n`);
  experts.forEach((e, i) => {
    console.log(`  [${i + 1}] ${e.displayName} (${e.email}) — UID: ${e.uid}`);
  });

  console.log("\n📦 Tüm uzman hesapları için seed başlatılıyor...\n");

  for (const expert of experts) {
    try {
      await seedProvider(expert.uid, expert.displayName, token);
    } catch (err) {
      console.error(`  ❌ ${expert.displayName} için hata: ${err.message}`);
    }
  }

  console.log("\n\n🎉 Seed tamamlandı! Uygulamayı yeniden başlatarak test edebilirsin.");
}

main().catch((err) => {
  console.error("❌ Beklenmedik hata:", err.message);
  process.exit(1);
});
