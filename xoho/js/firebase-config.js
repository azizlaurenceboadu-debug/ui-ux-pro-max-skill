// ─── Firebase Configuration ───────────────────────────────────────────────
// Replace the values below with your actual Firebase project credentials.
// Firebase Console → Project Settings → Your Apps → Web App → SDK snippet

import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.12.0/firebase-app.js';
import { getFirestore }  from 'https://www.gstatic.com/firebasejs/10.12.0/firebase-firestore.js';
import { getAuth }       from 'https://www.gstatic.com/firebasejs/10.12.0/firebase-auth.js';
import { getStorage }    from 'https://www.gstatic.com/firebasejs/10.12.0/firebase-storage.js';

const firebaseConfig = {
  apiKey:            "AIzaSyB-BaqpzVfTpDATkI1CxwDxQrQkN-LmoaA",
  authDomain:        "xoho-23.firebaseapp.com",
  projectId:         "xoho-23",
  storageBucket:     "xoho-23.firebasestorage.app",
  messagingSenderId: "480577900528",
  appId:             "1:480577900528:web:5086c2bfd28b7ccc42d735"
};

const app     = initializeApp(firebaseConfig);
const db      = getFirestore(app);
const auth    = getAuth(app);
const storage = getStorage(app);

export { app, db, auth, storage };
