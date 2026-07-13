import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();

export const acceptHelpRequest = onCall(async (request) => {
  const auth = request.auth;
  const requestId = request.data.requestId as string;

  if (!auth) {
    throw new HttpsError("unauthenticated", "Giriş yapmalısınız.");
  }

  if (!requestId) {
    throw new HttpsError("invalid-argument", "requestId zorunludur.");
  }

  const providerId = auth.uid;
  const helpRequestRef = db.collection("helpRequests").doc(requestId);
  const providerRef = db.collection("users").doc(providerId);

  await db.runTransaction(async (transaction) => {
    const helpRequestSnap = await transaction.get(helpRequestRef);

    if (!helpRequestSnap.exists) {
      throw new HttpsError("not-found", "Talep bulunamadı.");
    }

    const helpRequestData = helpRequestSnap.data();

    if (!helpRequestData) {
      throw new HttpsError("not-found", "Talep verisi bulunamadı.");
    }

    if (helpRequestData.providerId !== providerId) {
      throw new HttpsError("permission-denied", "Bu talep size ait değil.");
    }

    if (helpRequestData.status !== "pending") {
      throw new HttpsError("failed-precondition", "Talep zaten cevaplanmış.");
    }

    const providerSnap = await transaction.get(providerRef);

    if (!providerSnap.exists) {
      throw new HttpsError("not-found", "Usta profili bulunamadı.");
    }

    const providerData = providerSnap.data();

    if (!providerData) {
      throw new HttpsError("not-found", "Usta verisi bulunamadı.");
    }

    const balance = Number(providerData.balance ?? 0);
    const priceToAccept = Number(helpRequestData.priceToAccept ?? 50);

    if (balance < priceToAccept) {
      throw new HttpsError("failed-precondition", "Yetersiz bakiye.");
    }

    transaction.update(providerRef, {
      balance: balance - priceToAccept,
    });

    transaction.update(helpRequestRef, {
      status: "accepted",
      respondedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return {
    success: true,
    message: "Talep kabul edildi, bakiye düşüldü.",
  };
});

export const rejectHelpRequest = onCall(async (request) => {
  const auth = request.auth;
  const requestId = request.data.requestId as string;

  if (!auth) {
    throw new HttpsError("unauthenticated", "Giriş yapmalısınız.");
  }

  if (!requestId) {
    throw new HttpsError("invalid-argument", "requestId zorunludur.");
  }

  const providerId = auth.uid;
  const helpRequestRef = db.collection("helpRequests").doc(requestId);

  const helpRequestSnap = await helpRequestRef.get();

  if (!helpRequestSnap.exists) {
    throw new HttpsError("not-found", "Talep bulunamadı.");
  }

  const helpRequestData = helpRequestSnap.data();

  if (!helpRequestData) {
    throw new HttpsError("not-found", "Talep verisi bulunamadı.");
  }

  if (helpRequestData.providerId !== providerId) {
    throw new HttpsError("permission-denied", "Bu talep size ait değil.");
  }

  if (helpRequestData.status !== "pending") {
    throw new HttpsError("failed-precondition", "Talep zaten cevaplanmış.");
  }

  await helpRequestRef.update({
    status: "rejected",
    respondedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    success: true,
    message: "Talep reddedildi.",
  };
});
