import {onCall, HttpsError} from "firebase-functions/v2/https";
import {
  onDocumentCreated,
  onDocumentDeleted,
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

/**
 * Sends a push notification to a user.
 *
 * @param {string} userId Target user ID.
 * @param {string} title Notification title.
 * @param {string} body Notification body.
 * @param {Record<string, string>} data Notification data.
 * @return {Promise<void>} Completes after sending or skipping.
 */
async function sendUserPushNotification(
  userId: string,
  title: string,
  body: string,
  data: Record<string, string>
): Promise<void> {
  const userSnapshot = await db
    .collection("users")
    .doc(userId)
    .get();

  const fcmToken = userSnapshot.data()?.fcmToken;

  if (typeof fcmToken !== "string" || !fcmToken.trim()) {
    console.log("Kullanıcının FCM tokenı bulunamadı:", userId);
    return;
  }

  const notificationId = await admin.messaging().send({
    token: fcmToken,
    notification: {
      title: title,
      body: body,
    },
    data: data,
    apns: {
      payload: {
        aps: {
          sound: "default",
        },
      },
    },
  });

  console.log(
    "Kullanıcı bildirimi gönderildi:",
    userId,
    notificationId
  );
}


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

    case "inProgress": {
      receiverId = customerId;
      title = "Hizmet başlatıldı";
      body =
        `${displayServiceTitle} hizmetiniz uzman tarafından ` +
        "başlatıldı.";
      break;
    }

    case "completed": {
      receiverId = customerId;
      title = "Hizmet tamamlandı";
      body =
        `${displayServiceTitle} hizmetiniz tamamlandı.`;
      break;
    }

    case "noShow": {
      receiverId = customerId;
      title = "Rezervasyon güncellendi";
      body =
        `${displayServiceTitle} rezervasyonunuz, müşteri ` +
        "gelmedi olarak işaretlendi.";
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


export const syncReviewStatistics = onDocumentCreated(
  {
    document: "reviews/{reviewId}",
    region: "europe-west1",
  },
  async (event) => {
    const reviewData = event.data?.data();

    if (!reviewData) {
      console.log("Yorum verisi bulunamadı.");
      return;
    }

    const providerId =
      typeof reviewData.providerId === "string" ?
        reviewData.providerId.trim() :
        "";

    const bookingId =
      typeof reviewData.bookingId === "string" ?
        reviewData.bookingId.trim() :
        "";

    const reservationId =
      bookingId ||
      (
        typeof reviewData.reservationId === "string" ?
          reviewData.reservationId.trim() :
          ""
      );

    const rating = Number(reviewData.rating);

    if (
      !providerId ||
      !Number.isFinite(rating) ||
      rating < 1 ||
      rating > 5
    ) {
      console.log("Yorum istatistiği alanları geçersiz.");
      return;
    }

    const reviewsSnapshot = await db
      .collection("reviews")
      .where("providerId", "==", providerId)
      .get();

    let totalRating = 0;
    let reviewCount = 0;

    reviewsSnapshot.docs.forEach((document) => {
      const value = Number(document.data().rating);

      if (Number.isFinite(value) && value >= 1 && value <= 5) {
        totalRating += value;
        reviewCount += 1;
      }
    });

    const averageRating =
      reviewCount > 0 ?
        Math.round((totalRating / reviewCount) * 10) / 10 :
        0;

    const servicesSnapshot = await db
      .collection("services")
      .where("providerId", "==", providerId)
      .get();

    const batch = db.batch();

    const providerRef = db
      .collection("service_providers")
      .doc(providerId);

    batch.update(providerRef, {
      rating: averageRating,
      reviewCount: reviewCount,
    });

    servicesSnapshot.docs.forEach((document) => {
      batch.update(document.ref, {
        rating: averageRating,
        reviewCount: reviewCount,
      });
    });

    if (reservationId) {
      const reservationRef = db
        .collection("reservations")
        .doc(reservationId);

      batch.update(reservationRef, {
        isRated: true,
        rating: rating,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    console.log(
      "Yorum istatistikleri güncellendi:",
      event.params.reviewId
    );
  }
);

export const sendProviderResponseNotification = onDocumentUpdated(
  {
    document: "reviews/{reviewId}",
    region: "europe-west1",
  },
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (!beforeData || !afterData) {
      console.log("Yorum güncelleme verisi bulunamadı.");
      return;
    }

    const beforeResponse =
      typeof beforeData.providerResponse === "string" ?
        beforeData.providerResponse.trim() :
        "";

    const afterResponse =
      typeof afterData.providerResponse === "string" ?
        afterData.providerResponse.trim() :
        "";

    // Send only for the first provider response.
    if (beforeResponse || !afterResponse) {
      return;
    }

    const customerId =
      typeof afterData.customerId === "string" ?
        afterData.customerId.trim() :
        "";

    const providerId =
      typeof afterData.providerId === "string" ?
        afterData.providerId.trim() :
        "";

    const reviewId =
      String(event.params.reviewId ?? "").trim();

    if (!customerId || !providerId || !reviewId) {
      console.log("Yorum bildirimi alanları eksik.");
      return;
    }

    const customerSnapshot = await db
      .collection("users")
      .doc(customerId)
      .get();

    const fcmToken = customerSnapshot.data()?.fcmToken;

    if (typeof fcmToken !== "string" || !fcmToken.trim()) {
      console.log("Müşterinin FCM tokenı bulunamadı.");
      return;
    }

    const notificationId = await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: "Uzman yorumunuza yanıt verdi",
        body:
          "Değerlendirmenize verilen yanıtı " +
          "görüntüleyebilirsiniz.",
      },
      data: {
        type: "review",
        reviewId: reviewId,
        providerId: providerId,
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
      "Yorum yanıtı bildirimi gönderildi:",
      notificationId
    );
  }
);

// MARK: - Admin Review Moderation

/**
 * Recalculates review statistics for a provider.
 * @param {string} providerId The provider ID.
 * @return {Promise<void>} Resolves after the update.
 */
async function recalculateProviderReviewStatistics(
  providerId: string
): Promise<void> {
  const reviewsSnapshot = await db
    .collection("reviews")
    .where("providerId", "==", providerId)
    .get();

  let totalRating = 0;
  let reviewCount = 0;

  reviewsSnapshot.docs.forEach((document) => {
    const rating = Number(document.data().rating);

    if (
      Number.isFinite(rating) &&
      rating >= 1 &&
      rating <= 5
    ) {
      totalRating += rating;
      reviewCount += 1;
    }
  });

  const averageRating =
    reviewCount > 0 ?
      Math.round((totalRating / reviewCount) * 10) / 10 :
      0;

  const servicesSnapshot = await db
    .collection("services")
    .where("providerId", "==", providerId)
    .get();

  const batch = db.batch();

  const providerRef = db
    .collection("service_providers")
    .doc(providerId);

  batch.set(
    providerRef,
    {
      rating: averageRating,
      reviewCount: reviewCount,
    },
    {merge: true}
  );

  servicesSnapshot.docs.forEach((document) => {
    batch.update(document.ref, {
      rating: averageRating,
      reviewCount: reviewCount,
    });
  });

  await batch.commit();
}

export const syncReviewStatisticsOnDelete = onDocumentDeleted(
  {
    document: "reviews/{reviewId}",
    region: "europe-west1",
  },
  async (event) => {
    const reviewData = event.data?.data();

    if (!reviewData) {
      console.log("Silinen yorum verisi bulunamadı.");
      return;
    }

    const providerId =
      typeof reviewData.providerId === "string" ?
        reviewData.providerId.trim() :
        "";

    if (!providerId) {
      console.log("Silinen yorumun uzman bilgisi bulunamadı.");
      return;
    }

    await recalculateProviderReviewStatistics(providerId);

    console.log(
      "Yorum silme sonrası istatistikler güncellendi:",
      providerId
    );
  }
);

export const moderateReviewReport = onCall(
  {
    region: "europe-west1",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Bu işlem için giriş yapmalısınız."
      );
    }

    if (request.auth.token.admin !== true) {
      throw new HttpsError(
        "permission-denied",
        "Bu işlem yalnızca yöneticiler tarafından yapılabilir."
      );
    }

    const adminUid = request.auth.uid;

    const rawReportId = request.data?.reportId;
    const rawAction = request.data?.action;
    const rawResolutionNote = request.data?.resolutionNote;

    const reportId =
      typeof rawReportId === "string" ?
        rawReportId.trim() :
        "";

    const action =
      typeof rawAction === "string" ?
        rawAction.trim() :
        "";

    const resolutionNote =
      typeof rawResolutionNote === "string" ?
        rawResolutionNote.trim() :
        "";

    if (!reportId) {
      throw new HttpsError(
        "invalid-argument",
        "Rapor kimliği bulunamadı."
      );
    }

    if (
      action !== "dismiss" &&
      action !== "remove" &&
      action !== "flag"
    ) {
      throw new HttpsError(
        "invalid-argument",
        "Geçersiz moderasyon işlemi."
      );
    }

    if (resolutionNote.length > 500) {
      throw new HttpsError(
        "invalid-argument",
        "Açıklama en fazla 500 karakter olabilir."
      );
    }

    const reportRef = db
      .collection("review_reports")
      .doc(reportId);

    await db.runTransaction(async (transaction) => {
      const reportSnapshot = await transaction.get(reportRef);

      if (!reportSnapshot.exists) {
        throw new HttpsError(
          "not-found",
          "İncelenecek rapor bulunamadı."
        );
      }

      const reportData = reportSnapshot.data();

      if (!reportData) {
        throw new HttpsError(
          "not-found",
          "Rapor verisi bulunamadı."
        );
      }

      const reportStatus =
        typeof reportData.status === "string" ?
          reportData.status :
          "";

      const canProcessReport =
        action === "flag" ?
          reportStatus === "pending" :
          reportStatus === "pending" ||
            reportStatus === "flagged";

      if (!canProcessReport) {
        throw new HttpsError(
          "failed-precondition",
          "Bu rapor mevcut işlem için uygun durumda değil."
        );
      }

      const reviewId =
        typeof reportData.reviewId === "string" ?
          reportData.reviewId.trim() :
          "";

      const providerId =
        typeof reportData.providerId === "string" ?
          reportData.providerId.trim() :
          "";

      if (!reviewId || !providerId) {
        throw new HttpsError(
          "failed-precondition",
          "Raporun yorum veya uzman bilgisi eksik."
        );
      }

      const resolvedFields = {
        resolvedAt:
          admin.firestore.FieldValue.serverTimestamp(),
        resolvedBy: adminUid,
        resolutionNote: resolutionNote,
      };

      const reviewRef = db
        .collection("reviews")
        .doc(reviewId);

      const relatedReportsQuery = db
        .collection("review_reports")
        .where("reviewId", "==", reviewId);

      if (action === "flag") {
        const flaggedReviewSnapshot =
          await transaction.get(reviewRef);

        if (!flaggedReviewSnapshot.exists) {
          throw new HttpsError(
            "not-found",
            "İncelemeye alınacak yorum bulunamadı."
          );
        }

        const flaggedReviewData =
          flaggedReviewSnapshot.data();

        if (
          !flaggedReviewData ||
          flaggedReviewData.providerId !== providerId
        ) {
          throw new HttpsError(
            "failed-precondition",
            "Rapor ve yorum bilgileri eşleşmiyor."
          );
        }

        transaction.update(reportRef, {
          status: "flagged",
          flaggedAt:
            admin.firestore.FieldValue.serverTimestamp(),
          flaggedBy: adminUid,
          flagNote: resolutionNote,
        });

        transaction.update(reviewRef, {
          isReported: true,
          moderationStatus: "flagged",
          updatedAt:
            admin.firestore.FieldValue.serverTimestamp(),
        });

        return;
      }

      if (action === "dismiss") {
        const [
          dismissedReviewSnapshot,
          dismissedReportsSnapshot,
        ] = await Promise.all([
          transaction.get(reviewRef),
          transaction.get(relatedReportsQuery),
        ]);

        if (!dismissedReviewSnapshot.exists) {
          throw new HttpsError(
            "not-found",
            "Raporlanan yorum bulunamadı."
          );
        }

        const dismissedReviewData =
          dismissedReviewSnapshot.data();

        if (
          !dismissedReviewData ||
          dismissedReviewData.providerId !== providerId
        ) {
          throw new HttpsError(
            "failed-precondition",
            "Rapor ve yorum bilgileri eşleşmiyor."
          );
        }

        const otherReports =
          dismissedReportsSnapshot.docs.filter((document) => {
            return document.id !== reportId;
          });

        const hasOtherOpenReport =
          otherReports.some((document) => {
            const status = document.data().status;

            return status === "pending" ||
              status === "flagged";
          });

        const hasOtherFlaggedReport =
          otherReports.some((document) => {
            return document.data().status === "flagged";
          });

        const dismissedArchiveRef = db
          .collection("review_report_archive")
          .doc();

        transaction.set(dismissedArchiveRef, {
          ...reportData,
          originalReportId: reportId,
          status: "dismissed",
          ...resolvedFields,
          archivedAt:
            admin.firestore.FieldValue.serverTimestamp(),
        });

        transaction.delete(reportRef);

        transaction.update(reviewRef, {
          isReported: hasOtherOpenReport,
          moderationStatus: hasOtherFlaggedReport ?
            "flagged" :
            admin.firestore.FieldValue.delete(),
          updatedAt:
            admin.firestore.FieldValue.serverTimestamp(),
        });

        return;
      }

      const [
        reviewSnapshot,
        relatedReportsSnapshot,
      ] = await Promise.all([
        transaction.get(reviewRef),
        transaction.get(relatedReportsQuery),
      ]);

      if (!reviewSnapshot.exists) {
        throw new HttpsError(
          "not-found",
          "Kaldırılacak yorum bulunamadı."
        );
      }

      const reviewData = reviewSnapshot.data();

      if (!reviewData) {
        throw new HttpsError(
          "not-found",
          "Yorum verisi bulunamadı."
        );
      }

      if (reviewData.providerId !== providerId) {
        throw new HttpsError(
          "failed-precondition",
          "Rapor ve yorum uzman bilgileri eşleşmiyor."
        );
      }

      const openReportIds = relatedReportsSnapshot.docs
        .filter((document) => {
          const status = document.data().status;

          return status === "pending" ||
            status === "flagged";
        })
        .map((document) => {
          return document.id;
        });

      const reporterIds =
        relatedReportsSnapshot.docs.reduce<string[]>(
          (result, document) => {
            const status = document.data().status;
            const rawReporterId =
              document.data().reporterId;

            const reporterId =
              typeof rawReporterId === "string" ?
                rawReporterId.trim() :
                "";

            const isOpen =
              status === "pending" ||
              status === "flagged";

            if (
              isOpen &&
              reporterId &&
              !result.includes(reporterId)
            ) {
              result.push(reporterId);
            }

            return result;
          },
          []
        );

      const archiveRef = db
        .collection("review_moderation_archive")
        .doc(reviewId);

      transaction.set(archiveRef, {
        ...reviewData,
        originalReviewId: reviewId,
        moderationAction: "removed",
        moderationReportId: reportId,
        relatedReportIds: openReportIds,
        reporterIds: reporterIds,
        removedAt:
          admin.firestore.FieldValue.serverTimestamp(),
        removedBy: adminUid,
        resolutionNote: resolutionNote,
      });

      relatedReportsSnapshot.docs.forEach((document) => {
        const status = document.data().status;

        if (status !== "pending" && status !== "flagged") {
          return;
        }

        transaction.update(document.ref, {
          status: "removed",
          ...resolvedFields,
        });
      });

      transaction.delete(reviewRef);
    });

    return {
      success: true,
      reportId: reportId,
      action: action,
    };
  }
);

export const sendDismissedReviewReportNotification =
  onDocumentCreated(
    {
      document: "review_report_archive/{archiveId}",
      region: "europe-west1",
    },
    async (event) => {
      const archiveData = event.data?.data();

      if (!archiveData || archiveData.status !== "dismissed") {
        return;
      }

      const reporterId =
        typeof archiveData.reporterId === "string" ?
          archiveData.reporterId.trim() :
          "";

      const reviewId =
        typeof archiveData.reviewId === "string" ?
          archiveData.reviewId.trim() :
          "";

      if (!reporterId) {
        console.log("Rapor sahibi bulunamadı.");
        return;
      }

      await sendUserPushNotification(
        reporterId,
        "Yorum bildiriminiz incelendi",
        "Bildiriminiz değerlendirildi. Yorum yayında kalmaya devam ediyor.",
        {
          type: "reviewModeration",
          action: "dismissed",
          reviewId: reviewId,
        }
      );
    }
  );


export const sendRemovedReviewNotification =
  onDocumentCreated(
    {
      document: "review_moderation_archive/{reviewId}",
      region: "europe-west1",
    },
    async (event) => {
      const archiveData = event.data?.data();

      if (
        !archiveData ||
        archiveData.moderationAction !== "removed"
      ) {
        return;
      }

      const reviewId =
        String(event.params.reviewId ?? "").trim();

      const customerId =
        typeof archiveData.customerId === "string" ?
          archiveData.customerId.trim() :
          "";

      const reporterIds: string[] = [];
      const rawReporterIds = archiveData.reporterIds;

      if (Array.isArray(rawReporterIds)) {
        rawReporterIds.forEach((value) => {
          if (typeof value !== "string") {
            return;
          }

          const reporterId = value.trim();

          if (
            reporterId &&
            !reporterIds.includes(reporterId)
          ) {
            reporterIds.push(reporterId);
          }
        });
      }

      const notificationJobs = reporterIds.map(
        async (reporterId) => {
          await sendUserPushNotification(
            reporterId,
            "Bildirilen yorum kaldırıldı",
            "Bildiriminiz sonucunda yorum yayından kaldırıldı.",
            {
              type: "reviewModeration",
              action: "removed",
              reviewId: reviewId,
            }
          );
        }
      );

      if (
        customerId &&
        !reporterIds.includes(customerId)
      ) {
        notificationJobs.push(
          sendUserPushNotification(
            customerId,
            "Yorumunuz kaldırıldı",
            "Yorumunuz moderasyon kuralları nedeniyle yayından kaldırıldı.",
            {
              type: "reviewModeration",
              action: "removed",
              reviewId: reviewId,
            }
          )
        );
      }

      await Promise.all(notificationJobs);
    }
  );

// MARK: - Admin Provider Application Moderation

export const moderateProviderApplication = onCall(
  {
    region: "europe-west1",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Bu işlem için giriş yapmalısınız."
      );
    }

    if (request.auth.token.admin !== true) {
      throw new HttpsError(
        "permission-denied",
        "Bu işlem yalnızca yöneticiler tarafından yapılabilir."
      );
    }

    const rawProviderId = request.data?.providerId;
    const rawAction = request.data?.action;
    const rawAdminNote = request.data?.adminNote;

    const providerId =
      typeof rawProviderId === "string" ?
        rawProviderId.trim() :
        "";

    const action =
      typeof rawAction === "string" ?
        rawAction.trim() :
        "";

    const adminNote =
      typeof rawAdminNote === "string" ?
        rawAdminNote.trim() :
        "";

    if (!providerId) {
      throw new HttpsError(
        "invalid-argument",
        "Uzman kimliği bulunamadı."
      );
    }

    if (
      action !== "approve" &&
      action !== "reject" &&
      action !== "requestDocuments"
    ) {
      throw new HttpsError(
        "invalid-argument",
        "Geçersiz başvuru işlemi."
      );
    }

    if (adminNote.length > 500) {
      throw new HttpsError(
        "invalid-argument",
        "Admin açıklaması en fazla 500 karakter olabilir."
      );
    }

    if (
      (action === "reject" || action === "requestDocuments") &&
      !adminNote
    ) {
      throw new HttpsError(
        "invalid-argument",
        "Bu işlem için admin açıklaması zorunludur."
      );
    }

    const adminUid = request.auth.uid;
    const providerRef = db
      .collection("service_providers")
      .doc(providerId);

    const historyRef = db
      .collection("provider_application_history")
      .doc();

    let nextStatus = "";
    let isActive = false;
    let notificationTitle = "";
    let notificationBody = "";

    switch (action) {
    case "approve":
      nextStatus = "approved";
      isActive = true;
      notificationTitle = "Uzman başvurunuz onaylandı";
      notificationBody =
        "Başvurunuz onaylandı. Uzman hesabınızı kullanabilirsiniz.";
      break;

    case "reject":
      nextStatus = "rejected";
      notificationTitle = "Uzman başvurunuz reddedildi";
      notificationBody = adminNote;
      break;

    case "requestDocuments":
      nextStatus = "documentsRequired";
      notificationTitle = "Eksik belge bildirimi";
      notificationBody = adminNote;
      break;

    default:
      throw new HttpsError(
        "invalid-argument",
        "Geçersiz başvuru işlemi."
      );
    }

    await db.runTransaction(async (transaction) => {
      const providerSnapshot = await transaction.get(providerRef);

      if (!providerSnapshot.exists) {
        throw new HttpsError(
          "not-found",
          "Uzman başvurusu bulunamadı."
        );
      }

      const providerData = providerSnapshot.data();

      if (!providerData) {
        throw new HttpsError(
          "not-found",
          "Uzman başvuru verisi bulunamadı."
        );
      }

      const rawCurrentStatus = providerData.status;
      const currentStatus =
        typeof rawCurrentStatus === "string" ?
          rawCurrentStatus.trim().toLowerCase() :
          "";

      if (currentStatus !== "pending") {
        throw new HttpsError(
          "failed-precondition",
          "Yalnızca bekleyen başvurular işleme alınabilir."
        );
      }

      const serverTime =
        admin.firestore.FieldValue.serverTimestamp();

      transaction.update(providerRef, {
        status: nextStatus,
        verificationStatus: nextStatus,
        isActive: isActive,
        adminNote: adminNote,
        applicationDecision: action,
        reviewedAt: serverTime,
        reviewedBy: adminUid,
        updatedAt: serverTime,
      });

      transaction.set(historyRef, {
        historyId: historyRef.id,
        providerId: providerId,
        action: action,
        previousStatus: currentStatus,
        status: nextStatus,
        adminNote: adminNote,
        reviewedAt: serverTime,
        reviewedBy: adminUid,
      });
    });

    const notificationData = {
      type: "providerApplication",
      action: action,
      providerId: providerId,
      status: nextStatus,
    };

    try {
      const notificationRef = db
        .collection("notifications")
        .doc();

      await notificationRef.set({
        notificationId: notificationRef.id,
        userId: providerId,
        title: notificationTitle,
        body: notificationBody,
        type: "providerApplication",
        data: notificationData,
        isRead: false,
        createdAt:
          admin.firestore.FieldValue.serverTimestamp(),
        actionUrl: "providerApplication",
      });
    } catch (error) {
      console.error(
        "Başvuru uygulama bildirimi kaydedilemedi:",
        error
      );
    }

    try {
      await sendUserPushNotification(
        providerId,
        notificationTitle,
        notificationBody,
        notificationData
      );
    } catch (error) {
      console.error(
        "Başvuru push bildirimi gönderilemedi:",
        error
      );
    }

    return {
      success: true,
      providerId: providerId,
      action: action,
      status: nextStatus,
    };
  }
);
