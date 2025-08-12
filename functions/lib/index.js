"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.onReviewDelete = exports.onReviewUpdate = exports.onReviewCreate = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
admin.initializeApp();
const db = admin.firestore();
async function applyAggregates(serviceId, deltaCount, deltaSum) {
    const serviceRef = db.collection('services').doc(serviceId);
    await db.runTransaction(async (tx) => {
        const snap = await tx.get(serviceRef);
        if (!snap.exists)
            return;
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
exports.onReviewCreate = functions.firestore
    .document('services/{serviceId}/reviews/{reviewId}')
    .onCreate(async (snap, context) => {
    const { serviceId } = context.params;
    const rating = (snap.data()?.rating ?? 0);
    await applyAggregates(serviceId, 1, rating);
});
exports.onReviewUpdate = functions.firestore
    .document('services/{serviceId}/reviews/{reviewId}')
    .onUpdate(async (change, context) => {
    const { serviceId } = context.params;
    const before = (change.before.data()?.rating ?? 0);
    const after = (change.after.data()?.rating ?? 0);
    const delta = after - before;
    if (delta !== 0) {
        await applyAggregates(serviceId, 0, delta);
    }
});
exports.onReviewDelete = functions.firestore
    .document('services/{serviceId}/reviews/{reviewId}')
    .onDelete(async (snap, context) => {
    const { serviceId } = context.params;
    const rating = (snap.data()?.rating ?? 0);
    await applyAggregates(serviceId, -1, -rating);
});
//# sourceMappingURL=index.js.map