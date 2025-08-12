import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

async function applyAggregates(serviceId: string, deltaCount: number, deltaSum: number) {
  const serviceRef = db.collection('services').doc(serviceId);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(serviceRef);
    if (!snap.exists) return;

    const data = snap.data() || {};
    const nextCount = Math.max(0, (data.reviewCount || 0) + deltaCount);
    const nextSum = Math.max(0, (data.sumRatings || 0) + deltaSum);
    const nextRating = nextCount > 0 ? nextSum / nextCount : 0;

    tx.update(serviceRef, {
      reviewCount: nextCount,
      sumRatings: nextSum,
      rating: nextRating,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
}

export const onReviewCreate = functions.firestore
  .document('services/{serviceId}/reviews/{reviewId}')
  .onCreate(async (snap, context) => {
    const { serviceId } = context.params as { serviceId: string };
    const rating = (snap.data()?.rating ?? 0) as number;
    await applyAggregates(serviceId, 1, rating);
  });

export const onReviewUpdate = functions.firestore
  .document('services/{serviceId}/reviews/{reviewId}')
  .onUpdate(async (change, context) => {
    const { serviceId } = context.params as { serviceId: string };
    const before = (change.before.data()?.rating ?? 0) as number;
    const after = (change.after.data()?.rating ?? 0) as number;
    const delta = after - before;
    if (delta !== 0) {
      await applyAggregates(serviceId, 0, delta);
    }
  });

export const onReviewDelete = functions.firestore
  .document('services/{serviceId}/reviews/{reviewId}')
  .onDelete(async (snap, context) => {
    const { serviceId } = context.params as { serviceId: string };
    const rating = (snap.data()?.rating ?? 0) as number;
    await applyAggregates(serviceId, -1, -rating);
  });


