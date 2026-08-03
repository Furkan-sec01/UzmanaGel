import { after, before, beforeEach, test } from "node:test";
import { readFileSync } from "node:fs";

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";

import {
  Timestamp,
  doc,
  serverTimestamp,
  setDoc,
  writeBatch,
} from "firebase/firestore";

const projectId = "demo-uzmanagel";

const providerId = "provider-1";
const serviceId = "service-1";
const dateKey = "20260804";
const timeString = "09:00";
const timeKey = "0900";

let testEnvironment;

before(async () => {
  testEnvironment = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: readFileSync(
        new URL("../firestore.rules", import.meta.url),
        "utf8"
      ),
    },
  });
});

beforeEach(async () => {
  await testEnvironment.clearFirestore();

  await testEnvironment.withSecurityRulesDisabled(async (context) => {
    const firestore = context.firestore();

    await setDoc(doc(firestore, "services", serviceId), {
      providerId,
      isActive: true,
      isAvailable: true,
    });

    await setDoc(doc(firestore, "service_providers", providerId), {
      isAvailable: true,
    });
  });
});

after(async () => {
  await testEnvironment.cleanup();
});

function reservationData({
  reservationId,
  customerId,
}) {
  return {
    reservationId,
    serviceId,
    serviceTitle: "Test Service",
    servicePrice: 500,
    serviceDuration: 60,
    providerId,
    providerName: "Test Provider",
    customerId,
    customerName: "Test Customer",
    reservationDate: Timestamp.fromDate(
      new Date("2026-08-04T09:00:00+03:00")
    ),
    dateKey,
    timeString,
    timeKey,
    addressText: "Test Address",
    note: "",
    status: "pending",
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  };
}

function slotData(reservationId) {
  return {
    providerId,
    dateKey,
    timeString,
    status: "pending",
    reservationId,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  };
}

function createReservationAndSlot({
  firestore,
  reservationId,
  customerId,
}) {
  const batch = writeBatch(firestore);

  const reservationReference = doc(
    firestore,
    "reservations",
    reservationId
  );

  const slotReference = doc(
    firestore,
    "provider_booked_slots",
    providerId,
    "dates",
    dateKey,
    "times",
    timeKey
  );

  batch.set(
    reservationReference,
    reservationData({
      reservationId,
      customerId,
    })
  );

  batch.set(slotReference, slotData(reservationId));

  return batch.commit();
}

test("customer can create own reservation and slot atomically", async () => {
  const customerId = "customer-1";

  const firestore = testEnvironment
    .authenticatedContext(customerId)
    .firestore();

  await assertSucceeds(
    createReservationAndSlot({
      firestore,
      reservationId: "reservation-1",
      customerId,
    })
  );
});

test("customer cannot create reservation for another user", async () => {
  const firestore = testEnvironment
    .authenticatedContext("customer-1")
    .firestore();

  await assertFails(
    createReservationAndSlot({
      firestore,
      reservationId: "reservation-2",
      customerId: "customer-2",
    })
  );
});

test("reservation cannot be created without matching slot", async () => {
  const customerId = "customer-1";

  const firestore = testEnvironment
    .authenticatedContext(customerId)
    .firestore();

  const reservationId = "reservation-3";

  await assertFails(
    setDoc(
      doc(firestore, "reservations", reservationId),
      reservationData({
        reservationId,
        customerId,
      })
    )
  );
});

async function seedPendingReservationAndSlot({
  reservationId,
  customerId,
}) {
  await testEnvironment.withSecurityRulesDisabled(async (context) => {
    const firestore = context.firestore();
    const timestamp = Timestamp.now();
    const batch = writeBatch(firestore);

    batch.set(
      doc(firestore, "reservations", reservationId),
      {
        ...reservationData({
          reservationId,
          customerId,
        }),
        createdAt: timestamp,
        updatedAt: timestamp,
      }
    );

    batch.set(
      doc(
        firestore,
        "provider_booked_slots",
        providerId,
        "dates",
        dateKey,
        "times",
        timeKey
      ),
      {
        ...slotData(reservationId),
        createdAt: timestamp,
        updatedAt: timestamp,
      }
    );

    await batch.commit();
  });
}

test("second reservation cannot use an occupied slot", async () => {
  await seedPendingReservationAndSlot({
    reservationId: "existing-reservation",
    customerId: "customer-1",
  });

  const firestore = testEnvironment
    .authenticatedContext("customer-2")
    .firestore();

  await assertFails(
    createReservationAndSlot({
      firestore,
      reservationId: "second-reservation",
      customerId: "customer-2",
    })
  );
});

test("unrelated user cannot change reservation status", async () => {
  const reservationId = "protected-reservation";

  await seedPendingReservationAndSlot({
    reservationId,
    customerId: "customer-1",
  });

  const firestore = testEnvironment
    .authenticatedContext("customer-2")
    .firestore();

  const batch = writeBatch(firestore);

  batch.update(
    doc(firestore, "reservations", reservationId),
    {
      status: "cancelled",
      updatedAt: serverTimestamp(),
    }
  );

  await assertFails(batch.commit());
});

test("customer can cancel reservation and slot atomically", async () => {
  const reservationId = "cancelled-reservation";
  const customerId = "customer-1";

  await seedPendingReservationAndSlot({
    reservationId,
    customerId,
  });

  const firestore = testEnvironment
    .authenticatedContext(customerId)
    .firestore();

  const batch = writeBatch(firestore);

  batch.update(
    doc(firestore, "reservations", reservationId),
    {
      status: "cancelled",
      updatedAt: serverTimestamp(),
    }
  );

  batch.update(
    doc(
      firestore,
      "provider_booked_slots",
      providerId,
      "dates",
      dateKey,
      "times",
      timeKey
    ),
    {
      status: "cancelled",
      updatedAt: serverTimestamp(),
    }
  );

  await assertSucceeds(batch.commit());
});

test("customer cannot cancel reservation without updating slot", async () => {
  const reservationId = "reservation-only-cancellation";
  const customerId = "customer-1";

  await seedPendingReservationAndSlot({
    reservationId,
    customerId,
  });

  const firestore = testEnvironment
    .authenticatedContext(customerId)
    .firestore();

  const batch = writeBatch(firestore);

  batch.update(
    doc(firestore, "reservations", reservationId),
    {
      status: "cancelled",
      updatedAt: serverTimestamp(),
    }
  );

  await assertFails(batch.commit());
});

test("provider can accept reservation and slot atomically", async () => {
  const reservationId = "accepted-reservation";

  await seedPendingReservationAndSlot({
    reservationId,
    customerId: "customer-1",
  });

  const firestore = testEnvironment
    .authenticatedContext(providerId)
    .firestore();

  const batch = writeBatch(firestore);

  batch.update(
    doc(firestore, "reservations", reservationId),
    {
      status: "accepted",
      updatedAt: serverTimestamp(),
    }
  );

  batch.update(
    doc(
      firestore,
      "provider_booked_slots",
      providerId,
      "dates",
      dateKey,
      "times",
      timeKey
    ),
    {
      status: "accepted",
      updatedAt: serverTimestamp(),
    }
  );

  await assertSucceeds(batch.commit());
});

test("provider cannot accept reservation without updating slot", async () => {
  const reservationId = "reservation-only-acceptance";

  await seedPendingReservationAndSlot({
    reservationId,
    customerId: "customer-1",
  });

  const firestore = testEnvironment
    .authenticatedContext(providerId)
    .firestore();

  await assertFails(
    setDoc(
      doc(firestore, "reservations", reservationId),
      {
        status: "accepted",
        updatedAt: serverTimestamp(),
      },
      {
        merge: true,
      }
    )
  );
});


test("provider can reject reservation and slot atomically", async () => {
  const reservationId = "rejected-reservation";

  await seedPendingReservationAndSlot({
    reservationId,
    customerId: "customer-1",
  });

  const firestore = testEnvironment
    .authenticatedContext(providerId)
    .firestore();

  const batch = writeBatch(firestore);

  batch.update(
    doc(firestore, "reservations", reservationId),
    {
      status: "rejected",
      rejectionReason: "Provider is unavailable.",
      updatedAt: serverTimestamp(),
    }
  );

  batch.update(
    doc(
      firestore,
      "provider_booked_slots",
      providerId,
      "dates",
      dateKey,
      "times",
      timeKey
    ),
    {
      status: "rejected",
      updatedAt: serverTimestamp(),
    }
  );

  await assertSucceeds(batch.commit());
});

test("provider cannot reject reservation without updating slot", async () => {
  const reservationId = "reservation-only-rejection";

  await seedPendingReservationAndSlot({
    reservationId,
    customerId: "customer-1",
  });

  const firestore = testEnvironment
    .authenticatedContext(providerId)
    .firestore();

  await assertFails(
    setDoc(
      doc(firestore, "reservations", reservationId),
      {
        status: "rejected",
        rejectionReason: "Provider is unavailable.",
        updatedAt: serverTimestamp(),
      },
      {
        merge: true,
      }
    )
  );
});

async function seedReservationAndSlotWithStatus({
  reservationId,
  customerId,
  status,
}) {
  await testEnvironment.withSecurityRulesDisabled(async (context) => {
    const firestore = context.firestore();
    const timestamp = Timestamp.now();
    const batch = writeBatch(firestore);

    batch.set(
      doc(firestore, "reservations", reservationId),
      {
        ...reservationData({
          reservationId,
          customerId,
        }),
        status,
        createdAt: timestamp,
        updatedAt: timestamp,
      }
    );

    batch.set(
      doc(
        firestore,
        "provider_booked_slots",
        providerId,
        "dates",
        dateKey,
        "times",
        timeKey
      ),
      {
        ...slotData(reservationId),
        status,
        createdAt: timestamp,
        updatedAt: timestamp,
      }
    );

    await batch.commit();
  });
}

async function updateReservationAndSlot({
  firestore,
  reservationId,
  status,
  extraReservationData = {},
}) {
  const batch = writeBatch(firestore);

  batch.update(
    doc(firestore, "reservations", reservationId),
    {
      status,
      updatedAt: serverTimestamp(),
      ...extraReservationData,
    }
  );

  batch.update(
    doc(
      firestore,
      "provider_booked_slots",
      providerId,
      "dates",
      dateKey,
      "times",
      timeKey
    ),
    {
      status,
      updatedAt: serverTimestamp(),
    }
  );

  return batch.commit();
}

test("provider can start reservation and slot atomically", async () => {
  const reservationId = "in-progress-reservation";

  await seedReservationAndSlotWithStatus({
    reservationId,
    customerId: "customer-1",
    status: "accepted",
  });

  const firestore = testEnvironment
    .authenticatedContext(providerId)
    .firestore();

  await assertSucceeds(
    updateReservationAndSlot({
      firestore,
      reservationId,
      status: "inProgress",
      extraReservationData: {
        startedAt: serverTimestamp(),
      },
    })
  );
});

test("provider cannot start reservation without updating slot", async () => {
  const reservationId = "reservation-only-in-progress";

  await seedReservationAndSlotWithStatus({
    reservationId,
    customerId: "customer-1",
    status: "accepted",
  });

  const firestore = testEnvironment
    .authenticatedContext(providerId)
    .firestore();

  await assertFails(
    setDoc(
      doc(firestore, "reservations", reservationId),
      {
        status: "inProgress",
        startedAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      },
      {
        merge: true,
      }
    )
  );
});

test("provider can mark no show and update slot atomically", async () => {
  const reservationId = "no-show-reservation";

  await seedReservationAndSlotWithStatus({
    reservationId,
    customerId: "customer-1",
    status: "accepted",
  });

  const firestore = testEnvironment
    .authenticatedContext(providerId)
    .firestore();

  await assertSucceeds(
    updateReservationAndSlot({
      firestore,
      reservationId,
      status: "noShow",
      extraReservationData: {
        noShowAt: serverTimestamp(),
      },
    })
  );
});

test("provider cannot mark no show without updating slot", async () => {
  const reservationId = "reservation-only-no-show";

  await seedReservationAndSlotWithStatus({
    reservationId,
    customerId: "customer-1",
    status: "accepted",
  });

  const firestore = testEnvironment
    .authenticatedContext(providerId)
    .firestore();

  await assertFails(
    setDoc(
      doc(firestore, "reservations", reservationId),
      {
        status: "noShow",
        noShowAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      },
      {
        merge: true,
      }
    )
  );
});

test("provider can complete reservation and slot atomically", async () => {
  const reservationId = "completed-reservation";

  await seedReservationAndSlotWithStatus({
    reservationId,
    customerId: "customer-1",
    status: "inProgress",
  });

  const firestore = testEnvironment
    .authenticatedContext(providerId)
    .firestore();

  await assertSucceeds(
    updateReservationAndSlot({
      firestore,
      reservationId,
      status: "completed",
      extraReservationData: {
        completedAt: serverTimestamp(),
      },
    })
  );
});

test("provider cannot complete reservation without updating slot", async () => {
  const reservationId = "reservation-only-completed";

  await seedReservationAndSlotWithStatus({
    reservationId,
    customerId: "customer-1",
    status: "inProgress",
  });

  const firestore = testEnvironment
    .authenticatedContext(providerId)
    .firestore();

  await assertFails(
    setDoc(
      doc(firestore, "reservations", reservationId),
      {
        status: "completed",
        completedAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      },
      {
        merge: true,
      }
    )
  );
});

async function seedLegacyReservation({
  reservationId,
  customerId,
  includePartialSlotData = false,
}) {
  await testEnvironment.withSecurityRulesDisabled(async (context) => {
    const firestore = context.firestore();
    const timestamp = Timestamp.now();

    const data = {
      ...reservationData({
        reservationId,
        customerId,
      }),
      createdAt: timestamp,
      updatedAt: timestamp,
    };

    delete data.dateKey;
    delete data.timeString;
    delete data.timeKey;

    if (includePartialSlotData) {
      data.dateKey = dateKey;
    }

    await setDoc(
      doc(firestore, "reservations", reservationId),
      data
    );
  });
}

test("legacy reservation without slot keys can be cancelled", async () => {
  const reservationId = "legacy-reservation";
  const customerId = "customer-1";

  await seedLegacyReservation({
    reservationId,
    customerId,
  });

  const firestore = testEnvironment
    .authenticatedContext(customerId)
    .firestore();

  await assertSucceeds(
    setDoc(
      doc(firestore, "reservations", reservationId),
      {
        status: "cancelled",
        updatedAt: serverTimestamp(),
      },
      {
        merge: true,
      }
    )
  );
});

test("partial slot metadata cannot bypass slot synchronization", async () => {
  const reservationId = "partial-slot-reservation";
  const customerId = "customer-1";

  await seedLegacyReservation({
    reservationId,
    customerId,
    includePartialSlotData: true,
  });

  const firestore = testEnvironment
    .authenticatedContext(customerId)
    .firestore();

  await assertFails(
    setDoc(
      doc(firestore, "reservations", reservationId),
      {
        status: "cancelled",
        updatedAt: serverTimestamp(),
      },
      {
        merge: true,
      }
    )
  );
});
