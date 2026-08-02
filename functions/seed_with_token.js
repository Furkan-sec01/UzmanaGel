/**
 * seed_with_token.js — Firebase CLI token ile kimlik doğrulayan seed scripti
 */

const admin = require("firebase-admin");
const { execSync } = require("child_process");

// Firebase CLI'dan geçici token al
function getFirebaseToken() {
  try {
    // Firebase CLI'nın sakladığı credentials'ı kullan
    const result = execSync(
      "npx firebase-tools@latest login:list --json 2>/dev/null",
      { encoding: "utf8", timeout: 15000 }
    );
    return null; // Token tabanlı auth yerine credential.applicationDefault() kullanacağız
  } catch (e) {
    return null;
  }
}

// Firestore REST API kullanarak veri ekle
async function addDocumentViaREST(projectId, collection, docId, data, token) {
  const { default: fetch } = await import("node-fetch");
  const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/${collection}/${docId}`;
  
  const fields = {};
  for (const [key, value] of Object.entries(data)) {
    fields[key] = toFirestoreValue(value);
  }

  const response = await fetch(url, {
    method: "PATCH",
    headers: {
      "Authorization": `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ fields }),
  });

  if (!response.ok) {
    const err = await response.text();
    throw new Error(`REST API hatası: ${response.status} – ${err}`);
  }
  return response.json();
}

function toFirestoreValue(value) {
  if (value === null || value === undefined) return { nullValue: null };
  if (typeof value === "boolean") return { booleanValue: value };
  if (typeof value === "number") {
    if (Number.isInteger(value)) return { integerValue: String(value) };
    return { doubleValue: value };
  }
  if (typeof value === "string") return { stringValue: value };
  if (value instanceof Date) {
    return { timestampValue: value.toISOString() };
  }
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map(toFirestoreValue) } };
  }
  if (typeof value === "object") {
    const fields = {};
    for (const [k, v] of Object.entries(value)) {
      fields[k] = toFirestoreValue(v);
    }
    return { mapValue: { fields } };
  }
  return { stringValue: String(value) };
}

async function main() {
  // Önce CLI token al
  console.log("🔑 Firebase CLI token alınıyor...");
  let token;
  try {
    token = execSync(
      "node -e \"const t = require('./node_modules/firebase-tools/lib/auth'); t.getAccessToken().then(r => process.stdout.write(r.access_token || r))\""
    , { encoding: "utf8", cwd: __dirname, timeout: 10000 });
  } catch(e) {
    // Farklı yol dene
    try {
      const credPath = require("os").homedir() + "/.config/configstore/firebase-tools.json";
      const creds = JSON.parse(require("fs").readFileSync(credPath, "utf8"));
      const tokens = creds.tokens;
      if (tokens && tokens.access_token) {
        token = tokens.access_token;
      }
    } catch(e2) {}
  }
  
  if (!token) {
    console.log("⚠️  Token bulunamadı, alternatif yöntem deneniyor...");
  }
  
  console.log("Token:", token ? token.substring(0, 20) + "..." : "YOK");
}

main().catch(console.error);
