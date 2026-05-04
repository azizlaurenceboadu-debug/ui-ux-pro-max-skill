// ─── Success / Download page logic ───────────────────────────────────────
import { db } from './firebase-config.js';
import {
  doc, getDoc, updateDoc, serverTimestamp
} from 'https://www.gstatic.com/firebasejs/10.12.0/firebase-firestore.js';

async function init() {
  const params  = new URLSearchParams(window.location.search);
  const orderId = params.get('orderId');
  const status  = params.get('status'); // 'test' for sandbox

  const loadEl   = document.getElementById('loadingState');
  const successEl = document.getElementById('successState');
  const errorEl  = document.getElementById('errorState');

  if (!orderId) {
    show(errorEl, loadEl);
    document.getElementById('errorMsg').textContent = 'Commande introuvable. Veuillez contacter le support.';
    return;
  }

  try {
    // Fetch order from Firestore
    const orderSnap = await getDoc(doc(db, 'orders', orderId));

    if (!orderSnap.exists()) {
      show(errorEl, loadEl);
      document.getElementById('errorMsg').textContent = "Commande introuvable. Si vous avez payé, contactez-nous via WhatsApp.";
      return;
    }

    const order = orderSnap.data();

    // Accept 'completed' or 'test' (sandbox testing)
    const isPaid = order.status === 'completed' || status === 'test';

    if (!isPaid) {
      show(errorEl, loadEl);
      document.getElementById('errorMsg').textContent = "Votre paiement n'a pas encore été confirmé. Veuillez attendre ou contacter le support.";
      return;
    }

    // Mark order as accessed if not already
    if (order.status !== 'accessed') {
      await updateDoc(doc(db, 'orders', orderId), {
        status: 'accessed',
        accessedAt: serverTimestamp(),
      });
    }

    // Show success
    show(successEl, loadEl);

    // Populate UI
    document.getElementById('productNameDisplay').textContent = order.productName || '—';
    document.getElementById('emailDisplay').textContent       = order.buyerEmail  || '—';

    // Download button
    const dlBtn = document.getElementById('downloadBtn');
    if (order.downloadUrl) {
      dlBtn.href = order.downloadUrl;
      dlBtn.setAttribute('download', '');
    } else {
      dlBtn.style.display = 'none';
      document.getElementById('successMsg').textContent =
        'Votre document vous a été envoyé par Email. Vérifiez votre boîte de réception.';
    }

    // WhatsApp share
    const msg = encodeURIComponent(`J'ai acheté "${order.productName}" sur XOHO pour seulement ${order.amount} FCFA ! 🎉 Découvre leurs documents pros → https://xoho.bj`);
    document.getElementById('waShareBtn').href = `https://wa.me/?text=${msg}`;

  } catch (err) {
    console.error('succes.js error:', err);
    show(errorEl, loadEl);
    document.getElementById('errorMsg').textContent = "Une erreur est survenue. Veuillez contacter le support WhatsApp.";
  }
}

function show(target, loading) {
  loading.classList.add('hidden');
  target.classList.remove('hidden');
}

document.addEventListener('DOMContentLoaded', init);
