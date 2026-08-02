/**
 * clean_seed.js — veritabanındaki seed (mock) verilerini temizler.
 * Kullanım: node clean_seed.js
 */

const fs = require("fs");
const https = require("https");

const PROJECT_ID = "uzmanagel-cad0b";
const BASE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

function getStoredToken() {
  const credPath = "/Users/baran/.config/configstore/firebase-tools.json";
  const creds = JSON.parse(fs.readFileSync(credPath, "utf8"));
  const tokens = creds.tokens;
  if (tokens && tokens.access_token) {
    return tokens.access_token;
  }
  throw new Error("Token bulunamadı. Lütfen 'firebase login' ile tekrar giriş yapın.");
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
          resolve(data ? JSON.parse(data) : {});
        }
      });
    });

    req.on("error", reject);
    if (bodyStr) req.write(bodyStr);
    req.end();
  });
}

async function listDocuments(collection, token) {
  const url = `${BASE_URL}/${collection}?pageSize=300`;
  try {
    const res = await httpsRequest(url, "GET", null, token);
    return res.documents || [];
  } catch (e) {
    console.error(`  ⚠️ ${collection} listelenirken hata:`, e.message);
    return [];
  }
}

async function deleteDocument(docPath, token) {
  const url = `https://firestore.googleapis.com/v1/${docPath}`;
  await httpsRequest(url, "DELETE", null, token);
}

function isSeedReservation(doc) {
  const fields = doc.fields || {};
  const customerId = fields.customerId?.stringValue || "";
  const note = fields.note?.stringValue || "";
  const addressText = fields.addressText?.stringValue || "";

  if (customerId.startsWith("seed_customer_") || customerId.startsWith("seed_pending_")) {
    return true;
  }
  if (note.toLowerCase().includes("seed verisi") || note.toLowerCase().includes("yaklaşan rezervasyon")) {
    return true;
  }
  if (addressText.includes("Kadıköy, İstanbul") && addressText.includes("Test Adresi")) {
    return true;
  }
  if (addressText.includes("Beşiktaş, İstanbul") && addressText.includes("Bekleyen Test")) {
    return true;
  }
  return false;
}

function isSeedReview(doc) {
  const fields = doc.fields || {};
  const customerId = fields.customerId?.stringValue || "";
  const comment = fields.comment?.stringValue || "";

  if (customerId.startsWith("seed_customer_") || customerId.startsWith("seed_pending_")) {
    return true;
  }
  const reviewTexts = [
    "Çok profesyonel ve işini iyi yapıyor. Kesinlikle tavsiye ederim.",
    "Zamanında geldi, temiz çalıştı. Memnun kaldım.",
    "Hızlı ve kaliteli hizmet. Teşekkürler!",
    "Fiyat/performans açısından mükemmel.",
    "Her şey yolundaydı, tekrar tercih edeceğim.",
    "İyi iş çıkardı, sabırlı ve dikkatli.",
    "Gayet başarılı, sorunsuz bir deneyimdi.",
    "Harika hizmet, çok beğendim!",
  ];
  if (reviewTexts.includes(comment)) {
    return true;
  }
  return false;
}

async function main() {
  console.log("🔑 Firebase CLI token alınıyor...\n");
  const token = getStoredToken();

  console.log("🔍 Rezervasyonlar kontrol ediliyor...");
  const reservations = await listDocuments("reservations", token);
  let deletedResCount = 0;

  for (const doc of reservations) {
    if (isSeedReservation(doc)) {
      const docPath = doc.name;
      const parts = docPath.split("/");
      const docId = parts[parts.length - 1];
      console.log(`  🗑️ Siliniyor (reservation): ${docId}`);
      await deleteDocument(docPath, token);
      deletedResCount++;
    }
  }
  console.log(`✅ ${deletedResCount} seed rezervasyon silindi.\n`);

  console.log("🔍 Yorumlar (reviews) kontrol ediliyor...");
  const reviews = await listDocuments("reviews", token);
  let deletedReviewCount = 0;

  for (const doc of reviews) {
    if (isSeedReview(doc)) {
      const docPath = doc.name;
      const parts = docPath.split("/");
      const docId = parts[parts.length - 1];
      console.log(`  🗑️ Siliniyor (review): ${docId}`);
      await deleteDocument(docPath, token);
      deletedReviewCount++;
    }
  }
  console.log(`✅ ${deletedReviewCount} seed yorum silindi.\n`);

  console.log("🎉 Seed verileri başarıyla temizlendi!");
}

main().catch((err) => {
  console.error("❌ Hata:", err.message || err);
  process.exit(1);
});
