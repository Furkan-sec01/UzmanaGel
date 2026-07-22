import {onCall, HttpsError} from "firebase-functions/v2/https";
import {
  onDocumentCreated,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
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

export const sendMessageNotification = onDocumentCreated(
  "conversations/{conversationId}/messages/{messageId}",
  async (event) => {
    const messageData = event.data?.data();

    if (!messageData) {
      console.log("Mesaj verisi bulunamadı.");
      return;
    }

    const rawReceiverId = messageData.receiverId;
    const receiverId =
      typeof rawReceiverId === "string" ?
        rawReceiverId.trim() :
        "";

    const conversationId =
      String(event.params.conversationId ?? "").trim();

    if (!receiverId || !conversationId) {
      console.log("Bildirim için gerekli alanlar eksik.");
      return;
    }

    const receiverSnapshot = await db
      .collection("users")
      .doc(receiverId)
      .get();

    const fcmToken = receiverSnapshot.data()?.fcmToken;

    if (typeof fcmToken !== "string" || !fcmToken.trim()) {
      console.log("Alıcı kullanıcının FCM tokenı bulunamadı.");
      return;
    }

    const messageId = await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: "Yeni mesaj",
        body: "Yeni bir mesajınız var.",
      },
      data: {
        type: "message",
        conversationId: conversationId,
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
          },
        },
      },
    });

    console.log("Mesaj bildirimi gönderildi:", messageId);
  }
);

export const sendReservationCreatedNotification = onDocumentCreated(
  "reservations/{reservationId}",
  async (event) => {
    const reservationData = event.data?.data();

    if (!reservationData) {
      console.log("Rezervasyon verisi bulunamadı.");
      return;
    }

    const rawProviderId = reservationData.providerId;
    const providerId =
      typeof rawProviderId === "string" ?
        rawProviderId.trim() :
        "";

    const reservationId =
      String(event.params.reservationId ?? "").trim();

    if (!providerId || !reservationId) {
      console.log("Rezervasyon bildirimi alanları eksik.");
      return;
    }

    const rawCustomerName = reservationData.customerName;
    const customerName =
      typeof rawCustomerName === "string" ?
        rawCustomerName.trim() :
        "";

    const rawServiceTitle = reservationData.serviceTitle;
    const serviceTitle =
      typeof rawServiceTitle === "string" ?
        rawServiceTitle.trim() :
        "";

    const displayCustomerName = customerName || "Bir müşteri";
    const displayServiceTitle = serviceTitle || "bir hizmet";

    const providerSnapshot = await db
      .collection("users")
      .doc(providerId)
      .get();

    const fcmToken = providerSnapshot.data()?.fcmToken;

    if (typeof fcmToken !== "string" || !fcmToken.trim()) {
      console.log("Uzmanın FCM tokenı bulunamadı.");
      return;
    }

    const notificationId = await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: "Yeni rezervasyon talebi",
        body:
          `${displayCustomerName}, ${displayServiceTitle} için ` +
          "rezervasyon oluşturdu.",
      },
      data: {
        type: "reservation",
        reservationId: reservationId,
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
          },
        },
      },
    });

    console.log(
      "Rezervasyon bildirimi gönderildi:",
      notificationId
    );
  }
);

export const sendReservationStatusNotification = onDocumentUpdated(
  "reservations/{reservationId}",
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (!beforeData || !afterData) {
      console.log("Rezervasyon güncelleme verisi bulunamadı.");
      return;
    }

    const rawOldStatus = beforeData.status;
    const oldStatus =
      typeof rawOldStatus === "string" ?
        rawOldStatus.trim() :
        "";

    const rawNewStatus = afterData.status;
    const newStatus =
      typeof rawNewStatus === "string" ?
        rawNewStatus.trim() :
        "";

    if (!newStatus || oldStatus === newStatus) {
      return;
    }

    const reservationId =
      String(event.params.reservationId ?? "").trim();

    const providerId =
      typeof afterData.providerId === "string" ?
        afterData.providerId.trim() :
        "";

    const customerId =
      typeof afterData.customerId === "string" ?
        afterData.customerId.trim() :
        "";

    const serviceTitle =
      typeof afterData.serviceTitle === "string" ?
        afterData.serviceTitle.trim() :
        "";

    const customerName =
      typeof afterData.customerName === "string" ?
        afterData.customerName.trim() :
        "";

    const displayServiceTitle =
      serviceTitle || "Hizmet";

    const displayCustomerName =
      customerName || "Müşteri";

    let receiverId = "";
    let title = "";
    let body = "";

    switch (newStatus) {
    case "accepted": {
      receiverId = customerId;
      title = "Rezervasyon onaylandı";
      body =
        `${displayServiceTitle} rezervasyonunuz ` +
        "uzman tarafından onaylandı.";
      break;
    }

    case "rejected": {
      receiverId = customerId;
      title = "Rezervasyon reddedildi";

      const rejectionReason =
        typeof afterData.rejectionReason === "string" ?
          afterData.rejectionReason.trim() :
          "";

      body = rejectionReason ?
        `Ret nedeni: ${rejectionReason}` :
        "Rezervasyon talebiniz uzman tarafından reddedildi.";
      break;
    }

    case "cancelled": {
      receiverId = providerId;
      title = "Rezervasyon iptal edildi";
      body =
        `${displayCustomerName}, ${displayServiceTitle} ` +
        "rezervasyonunu iptal etti.";
      break;
    }

    default:
      return;
    }

    if (!receiverId || !reservationId) {
      console.log("Durum bildirimi için gerekli alanlar eksik.");
      return;
    }

    const receiverSnapshot = await db
      .collection("users")
      .doc(receiverId)
      .get();

    const fcmToken = receiverSnapshot.data()?.fcmToken;

    if (typeof fcmToken !== "string" || !fcmToken.trim()) {
      console.log("Bildirim alıcısının FCM tokenı bulunamadı.");
      return;
    }

    const notificationId = await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: "reservation",
        reservationId: reservationId,
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
          },
        },
      },
    });

    console.log(
      "Rezervasyon durum bildirimi gönderildi:",
      newStatus,
      notificationId
    );
  }
);

