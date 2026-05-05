// ─── Success / Download page logic ───────────────────────────────────────

async function init() {
  const params    = new URLSearchParams(window.location.search);
  const token     = params.get('token');
  const testMode  = params.get('status') === 'test';

  const loadEl    = document.getElementById('loadingState');
  const successEl = document.getElementById('successState');
  const errorEl   = document.getElementById('errorState');

  if (!token) {
    show(errorEl, loadEl);
    document.getElementById('errorMsg').textContent = 'Commande introuvable. Contactez le support.';
    return;
  }

  // In test/sandbox mode, confirm the order before checking
  if (testMode) {
    try {
      await fetch(`api/orders.php?action=confirm`, {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({ token, transactionId: 'TEST_' + Date.now() }),
      });
    } catch { /* ignore */ }
  }

  try {
    const res   = await fetch(`api/orders.php?token=${encodeURIComponent(token)}`);
    const order = await res.json();

    if (!res.ok) {
      show(errorEl, loadEl);
      document.getElementById('errorMsg').textContent = order.error || "Commande introuvable. Si vous avez payé, contactez-nous via WhatsApp.";
      return;
    }

    const isPaid = ['completed', 'accessed'].includes(order.status) || testMode;

    if (!isPaid) {
      show(errorEl, loadEl);
      document.getElementById('errorMsg').textContent = "Votre paiement n'a pas encore été confirmé. Attendez quelques instants ou contactez le support.";
      return;
    }

    show(successEl, loadEl);

    document.getElementById('productNameDisplay').textContent = order.product_name || '—';
    document.getElementById('emailDisplay').textContent       = order.buyer_email  || '—';

    const dlBtn = document.getElementById('downloadBtn');
    if (order.download_url) {
      dlBtn.href = order.download_url;
    } else {
      dlBtn.style.display = 'none';
      const msgEl = document.getElementById('successMsg');
      if (msgEl) msgEl.textContent = 'Votre document vous a été envoyé par email. Vérifiez votre boîte de réception.';
    }

    const msg = encodeURIComponent(`J'ai acheté "${order.product_name}" sur XOHO pour seulement ${order.amount} FCFA ! 🎉 Découvrez leurs documents → https://xoho.bj`);
    const waBtn = document.getElementById('waShareBtn');
    if (waBtn) waBtn.href = `https://wa.me/?text=${msg}`;

  } catch {
    show(errorEl, loadEl);
    document.getElementById('errorMsg').textContent = "Une erreur est survenue. Contactez le support WhatsApp.";
  }
}

function show(target, loading) {
  loading.classList.add('hidden');
  target.classList.remove('hidden');
}

document.addEventListener('DOMContentLoaded', init);
