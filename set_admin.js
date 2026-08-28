const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount)
});

async function setAdminClaim() {
  try {
    const uid = 'pCUZNBt9n9MKuadLar4G6qHSuw83'; // আপনার ফায়ারবেস UID

    await getAuth().setCustomUserClaims(uid, { admin: true });

    console.log(`সফলভাবে অ্যাডমিন পারমিশন দেওয়া হয়েছে ইউজারকে: ${uid}`);
    process.exit(0);
  } catch (error) {
    console.error('সমস্যা হয়েছে:', error);
    process.exit(1);
  }
}

setAdminClaim();