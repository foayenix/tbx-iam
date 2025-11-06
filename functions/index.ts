import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

/**
 * Submit score and update leaderboards
 */
export const submitScore = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const uid = context.auth.uid;
  const { delta, solved, timeMs, today } = data;

  try {
    const userRef = db.collection('users').doc(uid);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User not found');
    }

    const userData = userDoc.data()!;
    const newScore = (userData.todayScore || 0) + delta;
    const newBestScore = Math.max(userData.bestScoreAllTime || 0, newScore);

    // Update user
    await userRef.update({
      todayScore: newScore,
      todaySolvedCount: admin.firestore.FieldValue.increment(solved),
      bestScoreAllTime: newBestScore,
      lastPlayedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Update daily leaderboard
    const dailyKey = today || new Date().toISOString().substring(0, 10).replace(/-/g, '');
    const dailyLeaderboardRef = db
      .collection('leaderboards')
      .doc(`daily_${dailyKey}`)
      .collection('scores')
      .doc(uid);

    await dailyLeaderboardRef.set({
      displayName: userData.handle || 'Player',
      score: newScore,
      solved: userData.todaySolvedCount + solved,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    // Update global leaderboard if new best
    if (newBestScore > (userData.bestScoreAllTime || 0)) {
      const globalLeaderboardRef = db
        .collection('leaderboards')
        .doc('global')
        .collection('scores')
        .doc(uid);

      await globalLeaderboardRef.set({
        displayName: userData.handle || 'Player',
        score: newBestScore,
        solved: userData.todaySolvedCount + solved,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    }

    return { success: true, newScore, newBestScore };
  } catch (error) {
    console.error('Error submitting score:', error);
    throw new functions.https.HttpsError('internal', 'Failed to submit score');
  }
});

/**
 * Grant reward (coins, skips, etc.)
 */
export const grantReward = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const uid = context.auth.uid;
  const { type, amount } = data;

  try {
    const userRef = db.collection('users').doc(uid);

    switch (type) {
      case 'coins':
        await userRef.update({
          coins: admin.firestore.FieldValue.increment(amount || 1),
        });
        break;

      case 'skip':
        // Already handled client-side, just validate
        break;

      default:
        throw new functions.https.HttpsError('invalid-argument', 'Invalid reward type');
    }

    return { success: true };
  } catch (error) {
    console.error('Error granting reward:', error);
    throw new functions.https.HttpsError('internal', 'Failed to grant reward');
  }
});

/**
 * Submit riddle for moderation
 */
export const submitRiddle = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const uid = context.auth.uid;
  const { text, answer, category, hint } = data;

  try {
    // Server-side validation
    if (!text || !text.toLowerCase().startsWith('i am')) {
      throw new functions.https.HttpsError('invalid-argument', 'Riddle must start with "I am"');
    }

    // Canonicalize
    const canonText = canonicalize(text);
    const canonAnswer = canonicalize(answer);

    // Generate hashes
    const sha256 = require('crypto').createHash('sha256').update(canonText).digest('hex');
    const simhash64 = simpleSimHash(canonText);

    // Check for duplicates
    const existingRiddle = await db
      .collection('riddles')
      .where('hashes.sha256', '==', sha256)
      .limit(1)
      .get();

    if (!existingRiddle.empty) {
      throw new functions.https.HttpsError('already-exists', 'This riddle already exists');
    }

    // Create riddle
    const riddleRef = await db.collection('riddles').add({
      text,
      canonText,
      answer,
      canonAnswer,
      aliases: [],
      category,
      hint: hint || null,
      difficulty: 'medium',
      status: 'pending',
      createdBy: uid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      stats: {
        plays: 0,
        correctFirstTry: 0,
        skips: 0,
        reports: 0,
        avgSolveMs: 0,
      },
      hashes: {
        sha256,
        simhash64,
      },
    });

    return { success: true, riddleId: riddleRef.id };
  } catch (error) {
    console.error('Error submitting riddle:', error);
    throw new functions.https.HttpsError('internal', 'Failed to submit riddle');
  }
});

/**
 * Moderate riddle (approve/reject)
 */
export const moderateRiddle = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  // Check admin role
  const userDoc = await db.collection('users').doc(context.auth.uid).get();
  const isAdmin = userDoc.data()?.roles?.isAdmin || false;

  if (!isAdmin) {
    throw new functions.https.HttpsError('permission-denied', 'Admin access required');
  }

  const { riddleId, action, reason } = data;

  try {
    const riddleRef = db.collection('riddles').doc(riddleId);
    const riddleDoc = await riddleRef.get();

    if (!riddleDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Riddle not found');
    }

    const riddleData = riddleDoc.data()!;

    if (action === 'approve') {
      await riddleRef.update({
        status: 'live',
      });

      // Reward creator
      const creatorRef = db.collection('users').doc(riddleData.createdBy);
      await creatorRef.update({
        coins: admin.firestore.FieldValue.increment(25), // UGC reward
      });

      return { success: true, action: 'approved' };
    } else if (action === 'reject') {
      await riddleRef.update({
        status: 'rejected',
        rejectionReason: reason || 'Does not meet quality standards',
      });

      return { success: true, action: 'rejected' };
    } else {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid action');
    }
  } catch (error) {
    console.error('Error moderating riddle:', error);
    throw new functions.https.HttpsError('internal', 'Failed to moderate riddle');
  }
});

/**
 * Handle referral
 */
export const handleReferral = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const inviteeUid = context.auth.uid;
  const { inviterUid } = data;

  if (!inviterUid) {
    throw new functions.https.HttpsError('invalid-argument', 'Inviter UID required');
  }

  try {
    // Check if already processed
    const existingReferral = await db
      .collection('referrals')
      .where('inviterUid', '==', inviterUid)
      .where('inviteeUid', '==', inviteeUid)
      .limit(1)
      .get();

    if (!existingReferral.empty) {
      return { success: false, message: 'Referral already processed' };
    }

    // Create referral record
    await db.collection('referrals').add({
      inviterUid,
      inviteeUid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      rewarded: true,
    });

    // Reward both users
    const batch = db.batch();

    const inviterRef = db.collection('users').doc(inviterUid);
    batch.update(inviterRef, {
      coins: admin.firestore.FieldValue.increment(2),
      'referral.referredCount': admin.firestore.FieldValue.increment(1),
    });

    const inviteeRef = db.collection('users').doc(inviteeUid);
    batch.update(inviteeRef, {
      coins: admin.firestore.FieldValue.increment(2),
      'referral.inviterUid': inviterUid,
    });

    await batch.commit();

    return { success: true };
  } catch (error) {
    console.error('Error handling referral:', error);
    throw new functions.https.HttpsError('internal', 'Failed to handle referral');
  }
});

/**
 * Daily reset (scheduled function)
 */
export const dailyReset = functions.pubsub
  .schedule('0 0 * * *')
  .timeZone('UTC')
  .onRun(async (context) => {
    console.log('Running daily reset...');

    try {
      // Reset daily counters for all users
      const usersSnapshot = await db.collection('users').get();
      const batch = db.batch();

      usersSnapshot.docs.forEach((doc) => {
        batch.update(doc.ref, {
          dailySkipsUsed: 0,
          adSkipsUsedToday: 0,
          todayScore: 0,
          todaySolvedCount: 0,
        });
      });

      await batch.commit();
      console.log(`Reset daily counters for ${usersSnapshot.size} users`);

      return null;
    } catch (error) {
      console.error('Error in daily reset:', error);
      throw error;
    }
  });

// Helper functions
function canonicalize(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^\w\s]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

function simpleSimHash(text: string): number {
  let hash = 0;
  for (let i = 0; i < text.length; i++) {
    hash = ((hash << 5) - hash) + text.charCodeAt(i);
    hash |= 0; // Convert to 32-bit integer
  }
  return hash;
}
