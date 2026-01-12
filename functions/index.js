const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

/**
 * Cloud Function: onRewardAssigned
 * Triggered when a new reward is assigned to a user/team.
 * Sends push notification to all targeted users.
 */
exports.onRewardAssigned = onDocumentCreated('user_rewards/{rewardId}', async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
        console.log('No data associated with the event');
        return;
    }

    const reward = snapshot.data();
    const targetIds = reward.targetIds || [];

    if (targetIds.length === 0) {
        console.log('No target users for this reward.');
        return null;
    }

    const title = reward.title || 'Hediye Çeki';
    const amount = reward.amount || '';

    const db = getFirestore();

    // Fetch FCM tokens for each target user
    const tokensPromises = targetIds.map(async (userId) => {
        const userDoc = await db.collection('users').doc(userId).get();
        if (userDoc.exists) {
            return userDoc.data().fcmToken;
        }
        return null;
    });

    const tokens = (await Promise.all(tokensPromises)).filter(t => t);

    if (tokens.length === 0) {
        console.log('No FCM tokens found for target users.');
        return null;
    }

    const messaging = getMessaging();

    try {
        const response = await messaging.sendEachForMulticast({
            tokens: tokens,
            notification: {
                title: '🎁 Yeni Hediye Çeki!',
                body: `${title} - ${amount} seni bekliyor! Kazımak için uygulamayı aç.`,
            },
            data: {
                type: 'reward',
                rewardId: event.params.rewardId,
            },
        });
        console.log(`Successfully sent ${response.successCount} notifications.`);
        return response;
    } catch (error) {
        console.error('Error sending notifications:', error);
        return null;
    }
});
