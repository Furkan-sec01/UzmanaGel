/**
 * seed.js — UzmanaGel test verisi ekleme scripti
 * Kullanım: node seed.js
 *
 * Bu script:
 * 1. Firebase'deki tüm "expert" rolündeki kullanıcıları listeler
 * 2. Seçilen provider için tamamlanan rezervasyon verileri ekler
 * 3. Finans ve İstatistik ekranlarının gerçek veriyle çalışmasını sağlar
 */

const admin = require("firebase-admin");

// Firebase Admin'i Application Default Credentials ile başlat
admin.initializeApp({
  projectId: "uzmanagel-cad0b",
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();

// ─── Yardımcı ────────────────────────────────────────────────────────────────

function randomDate(daysAgo) {
  const d = new Date();
  d.setDate(d.getDate() - daysAgo);
  d.setHours(Math.floor(Math.random() * 8) + 9); // 09-16 arası
  d.setMinutes(0, 0, 0);
  return d;
}

function randomId() {
  return db.collection("_").doc().id;
}

// ─── Seed veri tanımları ──────────────────────────────────────────────────────

const SERVICES = [
  { title: "Kombi Bakımı ve Onarımı", category: "Tesisatçı", price: 850 },
  { title: "Elektrik Pano Kontrolü", category: "Elektrikçi", price: 650 },
  { title: "Boya – Tek Oda", category: "Boyacı", price: 1200 },
  { title: "Klima Montajı", category: "Klima Teknisyeni", price: 950 },
  { title: "Çatı Tadilatı", category: "Çatıcı", price: 2500 },
  { title: "Fayans ve Seramik", category: "Karocu", price: 1800 },
];

const CUSTOMER_NAMES = [
  "Ahmet Yılmaz", "Zeynep Kaya", "Murat Demir", "Elif Çelik",
  "Burak Şahin", "Selin Arslan", "Oğuz Aydın", "Merve Doğan",
];

const STATUSES = {
  completed: "completed",
  accepted: "accepted",
  pending: "pending",
};

// ─── Seed fonksiyonu ──────────────────────────────────────────────────────────

async function seedForProvider(providerId, providerName) {
  console.log(`\n🌱 Seed başlıyor: ${providerName} (${providerId})`);

  const batch = db.batch();
  const createdIds = [];

  // ─── 1. Servis dokümanı oluştur (eğer yoksa)
  let serviceId;
  const existingServices = await db.collection("services")
    .where("providerId", "==", providerId)
    .limit(1)
    .get();

  if (!existingServices.empty) {
    serviceId = existingServices.docs[0].id;
    console.log(`  ✅ Mevcut servis kullanılıyor: ${serviceId}`);
  } else {
    serviceId = db.collection("services").doc().id;
    const svc = SERVICES[0];
    batch.set(db.collection("services").doc(serviceId), {
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
      reviewCount: 12,
      isCertified: true,
      acceptsCreditCard: false,
      experienceYears: 5,
      description: "Profesyonel ve güvenilir hizmet.",
      image: "",
      city: "İstanbul",
    });
    console.log(`  🆕 Servis oluşturuldu: ${serviceId}`);
  }

  // ─── 2. service_providers dokümanı (eğer yoksa)
  const spRef = db.collection("service_providers").doc(providerId);
  const spSnap = await spRef.get();
  if (!spSnap.exists) {
    batch.set(spRef, {
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
    });
    console.log("  🆕 service_providers dokümanı oluşturuldu.");
  }

  await batch.commit();

  // ─── 3. Tamamlanan rezervasyonlar (son 90 gün)
  const completedReservations = [
    // Geçen ay
    { daysAgo: 3,  price: 850,  svcIndex: 0 },
    { daysAgo: 7,  price: 1200, svcIndex: 2 },
    { daysAgo: 12, price: 650,  svcIndex: 1 },
    { daysAgo: 18, price: 950,  svcIndex: 3 },
    { daysAgo: 22, price: 1800, svcIndex: 5 },
    { daysAgo: 28, price: 850,  svcIndex: 0 },
    // İki ay önce
    { daysAgo: 35, price: 2500, svcIndex: 4 },
    { daysAgo: 42, price: 950,  svcIndex: 3 },
    { daysAgo: 48, price: 650,  svcIndex: 1 },
    { daysAgo: 55, price: 1200, svcIndex: 2 },
    { daysAgo: 61, price: 850,  svcIndex: 0 },
    // Üç ay önce
    { daysAgo: 68, price: 1800, svcIndex: 5 },
    { daysAgo: 75, price: 950,  svcIndex: 3 },
    { daysAgo: 82, price: 1200, svcIndex: 2 },
    { daysAgo: 88, price: 850,  svcIndex: 0 },
  ];

  const batch2 = db.batch();

  for (let i = 0; i < completedReservations.length; i++) {
    const item = completedReservations[i];
    const svc = SERVICES[item.svcIndex];
    const resDate = randomDate(item.daysAgo);
    const resId = randomId();
    const customerId = `seed_customer_${i % CUSTOMER_NAMES.length}`;
    const customerName = CUSTOMER_NAMES[i % CUSTOMER_NAMES.length];

    const reservationData = {
      reservationId: resId,
      serviceId,
      serviceTitle: svc.title,
      servicePrice: item.price,
      serviceDuration: "60 dakika",
      providerId,
      providerName,
      customerId,
      customerName,
      reservationDate: admin.firestore.Timestamp.fromDate(resDate),
      addressText: `Kadıköy, İstanbul - ${i + 1}. Test Adresi`,
      note: "Seed verisi – test amaçlı.",
      status: STATUSES.completed,
      rejectionReason: "",
      isRated: i < 8,
      rating: i < 8 ? (4 + (i % 2) * 0.5) : null,
      createdAt: admin.firestore.Timestamp.fromDate(resDate),
      updatedAt: admin.firestore.Timestamp.fromDate(new Date()),
      completedAt: admin.firestore.Timestamp.fromDate(new Date()),
    };

    batch2.set(db.collection("reservations").doc(resId), reservationData);
    createdIds.push(resId);
  }

  // ─── 4. Bekleyen/aktif rezervasyon (bugün/yarın)
  const pendingStatuses = [STATUSES.accepted, STATUSES.pending];
  for (let i = 0; i < 2; i++) {
    const svc = SERVICES[i];
    const resDate = randomDate(-(i + 1)); // yarın/öbür gün
    const resId = randomId();

    batch2.set(db.collection("reservations").doc(resId), {
      reservationId: resId,
      serviceId,
      serviceTitle: svc.title,
      servicePrice: svc.price,
      serviceDuration: "60 dakika",
      providerId,
      providerName,
      customerId: `seed_customer_pending_${i}`,
      customerName: CUSTOMER_NAMES[i + 2],
      reservationDate: admin.firestore.Timestamp.fromDate(resDate),
      addressText: `Beşiktaş, İstanbul - Bekleyen Test`,
      note: "Yaklaşan rezervasyon – seed verisi.",
      status: pendingStatuses[i],
      rejectionReason: "",
      isRated: false,
      createdAt: admin.firestore.Timestamp.fromDate(new Date()),
      updatedAt: admin.firestore.Timestamp.fromDate(new Date()),
    });
    createdIds.push(resId);
  }

  await batch2.commit();
  console.log(`  ✅ ${completedReservations.length} tamamlanan + 2 bekleyen rezervasyon eklendi.`);

  // ─── 5. Review'lar
  const reviewBatch = db.batch();
  const ratingTexts = [
    "Çok profesyonel ve işini iyi yapıyor. Kesinlikle tavsiye ederim.",
    "Zamanında geldi, temiz çalıştı. Memnun kaldım.",
    "Hızlı ve kaliteli hizmet. Teşekkürler!",
    "Fiyat/performans açısından mükemmel.",
    "Her şey yolundaydı, tekrar tercih edeceğim.",
    "İyi iş çıkardı, sabırlı ve dikkatli.",
    "Gayet başarılı, sorunsuz bir deneyimdi.",
    "Harika hizmet, çok beğendim!",
  ];

  for (let i = 0; i < 8; i++) {
    const reviewId = randomId();
    const rating = 4 + (i % 2) * 0.5;
    const createdDate = randomDate(3 + i * 5);

    reviewBatch.set(db.collection("reviews").doc(reviewId), {
      reviewId,
      bookingId: createdIds[i],
      reservationId: createdIds[i],
      serviceId,
      serviceTitle: SERVICES[i % SERVICES.length].title,
      customerId: `seed_customer_${i % CUSTOMER_NAMES.length}`,
      customerName: CUSTOMER_NAMES[i % CUSTOMER_NAMES.length],
      providerId,
      rating,
      comment: ratingTexts[i],
      categoryRatings: { quality: rating, punctuality: 5.0, communication: 4.5 },
      photos: [],
      isReported: false,
      isVerifiedBooking: true,
      helpfulCount: i,
      helpfulUsers: [],
      createdAt: admin.firestore.Timestamp.fromDate(createdDate),
      updatedAt: admin.firestore.Timestamp.fromDate(createdDate),
    });
  }

  await reviewBatch.commit();
  console.log("  ✅ 8 review eklendi.");

  // ─── 6. Toplam kazanç özetle
  const total = completedReservations.reduce((sum, r) => sum + r.price, 0);
  console.log(`\n  💰 Toplam eklenen kazanç: ₺${total.toLocaleString("tr-TR")}`);
  console.log("  📊 İstatistik ve Finans ekranlarını şimdi test edebilirsin!\n");
}

// ─── Ana akış ─────────────────────────────────────────────────────────────────

async function main() {
  console.log("🔍 Firebase'deki uzman hesapları aranıyor...\n");

  // Tüm approved expert kullanıcıları bul
  const providersSnap = await db.collection("service_providers")
    .where("status", "in", ["Approved", "approved", "Draft", "Pending"])
    .limit(10)
    .get();

  let providers = [];

  if (!providersSnap.empty) {
    for (const doc of providersSnap.docs) {
      const data = doc.data();
      providers.push({
        uid: doc.id,
        name: data.businessName || data.displayName || "İsimsiz Uzman",
      });
    }
  }

  // Hiç bulunamazsa users koleksiyonuna bak
  if (providers.length === 0) {
    const usersSnap = await db.collection("users")
      .where("role", "==", "expert")
      .limit(10)
      .get();

    for (const doc of usersSnap.docs) {
      const data = doc.data();
      providers.push({
        uid: doc.id,
        name: data.displayName || data.email || "Uzman",
      });
    }
  }

  if (providers.length === 0) {
    console.log("❌ Hiç uzman hesabı bulunamadı.");
    console.log("   Lütfen önce uygulamadan uzman olarak kaydolun.");
    process.exit(1);
  }

  console.log(`✅ ${providers.length} uzman bulundu:\n`);
  providers.forEach((p, i) => {
    console.log(`  [${i + 1}] ${p.name} — UID: ${p.uid}`);
  });

  // Hepsi için seed et
  for (const provider of providers) {
    await seedForProvider(provider.uid, provider.name);
  }

  console.log("\n🎉 Seed tamamlandı! Uygulamayı yeniden başlatarak test edebilirsin.");
  process.exit(0);
}

main().catch((err) => {
  console.error("❌ Hata:", err.message || err);
  process.exit(1);
});
