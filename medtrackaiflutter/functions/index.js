const functions = require('firebase-functions/v2');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { setGlobalOptions } = require('firebase-functions/v2');
const axios = require('axios');
const admin = require('firebase-admin');

admin.initializeApp();

setGlobalOptions({ region: 'us-central1' });

// ── Scan Medicine via Claude Vision ──────────────────────────────────
exports.scanMedicine = onCall({ secrets: ['ANTHROPIC_API_KEY'] }, async (request) => {
    const { imageBase64, mediaType, hint } = request.data;

    if (!imageBase64) throw new HttpsError('invalid-argument', 'imageBase64 is required');
    if (!request.auth) throw new HttpsError('unauthenticated', 'Must be authenticated');

    const apiKey = process.env.ANTHROPIC_API_KEY;
    if (!apiKey) {
        console.error('CRITICAL: ANTHROPIC_API_KEY secret is not set in Firebase.');
        throw new HttpsError('failed-precondition', 'AI Service not configured (API key missing)');
    }

    console.log(`Scan Request: size=${imageBase64.length} bytes, type=${mediaType}, hint=${hint}`);
    const systemPrompt = `You are a professional medical assistant and pharmacist expert in global medicine identification. 
Your task is to analyze images of medicine packaging, blister packs, or pill bottles. 
The user categorized this as a "${hint || 'medicine'}".
CRITICAL: Always try your absolute best to identify the medicine. Even if the image is blurry, if you can read a few letters or recognize a logo/color scheme, provide your best estimate.
NEVER set "identified": false unless the image is clearly NOT a medicine (e.g., a person, an animal, or a random object). 
If you see ANY text, search your database for matching pharmaceuticals.`;

    try {
        const response = await axios.post(
            'https://api.anthropic.com/v1/messages',
            {
                model: 'claude-3-5-sonnet-20241022',
                max_tokens: 1024,
                system: systemPrompt,
                messages: [{
                    role: 'user',
                    content: [
                        {
                            type: 'image',
                            source: { type: 'base64', media_type: mediaType || 'image/jpeg', data: imageBase64 },
                        },
                        {
                            type: 'text',
                            text: `Identify this medicine. Return ONLY JSON.
{
  "identified": true,
  "name": "...",
  "brand": "...",
  "dose": "...",
  "form": "tablet|liquid|spray|...",
  "isLiquid": true/false,
  "category": "...",
  "description": "...",
  "howToTake": "...",
  "pillCount": 30,
  "packSize": 30,
  "refillAlert": 7,
  "volumeAmount": 0,
  "confidence": "high|medium|low"
}`
                        }
                    ]
                }]
            },
            {
                headers: {
                    'x-api-key': apiKey,
                    'anthropic-version': '2023-06-01',
                    'content-type': 'application/json',
                },
                timeout: 45000,
            }
        );

        const text = response.data.content[0].text.trim();
        console.log('RAW AI Response:', text);

        let result;
        try {
            const jsonMatch = text.match(/\{[\s\S]*\}/);
            result = JSON.parse(jsonMatch ? jsonMatch[0] : text);
        } catch (parseErr) {
            console.warn('JSON Parse failed, using fallback regex extraction');
            // Fallback: Try to extract at least some fields if JSON is messy
            result = {
                identified: text.toLowerCase().includes('name') || text.length > 20,
                name: (text.match(/"name":\s*"([^"]+)"/) || [null, 'Unknown Medicine'])[1],
                description: 'AI response was malformed, but something was found.',
                confidence: 'low'
            };
        }

        // Force identified to true if we have a name that isn't empty
        if (result.name && result.name !== 'Unknown Medicine' && result.name.length > 2) {
            result.identified = true;
        }

        return result;
    } catch (err) {
        console.error('Scan Error:', err.response?.data || err.message);
        throw new HttpsError('internal', `Scan failed: ${err.message}`);
    }
});

exports.helloWorld = onCall({ secrets: ['ANTHROPIC_API_KEY'] }, async (request) => {
    const apiKey = process.env.ANTHROPIC_API_KEY;
    return {
        message: "Cloud Functions are connected!",
        secretConfigured: !!apiKey,
        region: 'us-central1'
    };
});

// ── Get Health Insight via Claude ────────────────────────────────────
exports.getHealthInsight = onCall({ secrets: ['ANTHROPIC_API_KEY'] }, async (request) => {
    const { meds, streak } = request.data;
    if (!request.auth) throw new HttpsError('unauthenticated', 'Must be authenticated');

    const apiKey = process.env.ANTHROPIC_API_KEY;
    const medList = (meds || []).join(', ');

    try {
        const response = await axios.post(
            'https://api.anthropic.com/v1/messages',
            {
                model: 'claude-3-5-sonnet-20241022',
                max_tokens: 200,
                messages: [{
                    role: 'user',
                    content: `Give a short, friendly 1-sentence health tip for someone taking: ${medList}. Streak: ${streak} days. Be specific, positive and practical. No lists.`
                }]
            },
            {
                headers: {
                    'x-api-key': apiKey,
                    'anthropic-version': '2023-06-01',
                    'content-type': 'application/json',
                },
                timeout: 15000,
            }
        );
        return { insight: response.data.content[0].text };
    } catch (err) {
        // Return a fallback
        let insight = '💊 Remember: taking medicines at the same time each day builds a powerful habit.';
        if (streak >= 7) insight = `🔥 ${streak} day streak! Consistency is the foundation of good health.`;
        else if (streak >= 3) insight = `💪 ${streak} days strong! Keep the momentum going.`;
        return { insight };
    }
});

// ── Send Missed Dose Push Notification ───────────────────────────────
exports.sendMissedDoseAlert = onCall(async (request) => {
    // Requires authentication
    if (!request.auth) throw new HttpsError('unauthenticated', 'Must be authenticated');

    const { targetUserId, title, body, data } = request.data;
    if (!targetUserId || !title || !body) {
        throw new HttpsError('invalid-argument', 'targetUserId, title, and body are required');
    }

    try {
        // Fetch the target user's document to get their FCM token
        const userDoc = await admin.firestore().collection('users').doc(targetUserId).get();
        if (!userDoc.exists) {
            console.log(`User ${targetUserId} not found.`);
            return { success: false, error: 'User not found' };
        }

        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;

        if (!fcmToken) {
            console.log(`User ${targetUserId} has no FCM token.`);
            return { success: false, error: 'User has no FCM token' };
        }

        const message = {
            notification: {
                title: title,
                body: body,
            },
            data: data || {},
            token: fcmToken,
        };

        const response = await admin.messaging().send(message);
        console.log('Successfully sent message:', response);
        return { success: true, messageId: response };

    } catch (error) {
        console.error('Error sending message:', error);
        throw new HttpsError('internal', `Failed to send notification: ${error.message}`);
    }
});
