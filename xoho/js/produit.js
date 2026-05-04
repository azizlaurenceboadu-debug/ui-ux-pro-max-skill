// ─── Product detail page logic ────────────────────────────────────────────
import { db } from './firebase-config.js';
import {
  doc, getDoc, collection, query, where, getDocs, limit, addDoc, serverTimestamp
} from 'https://www.gstatic.com/firebasejs/10.12.0/firebase-firestore.js';
import { POLES, formatPrice, buildProductCard, showToast } from './app.js';

let currentProduct = null;

// ── Load product from Firestore ───────────────────────────────────────────
async function loadProduct() {
  const params = new URLSearchParams(window.location.search);
  const productId = params.get('id');

  if (!productId) {
    window.location.href = 'boutique.html';
    return;
  }

  try {
    const snap = await getDoc(doc(db, 'products', productId));
    if (!snap.exists() || !snap.data().published) {
      window.location.href = 'boutique.html';
      return;
    }
    currentProduct = { id: snap.id, ...snap.data() };
    renderProduct(currentProduct);
    loadRelated(currentProduct.pole, productId);
  } catch (err) {
    console.error('loadProduct error:', err);
    showToast('Erreur lors du chargement du produit.', 'error');
  }
}

// ── Render product on page ────────────────────────────────────────────────
function renderProduct(product) {
  // Hide loading, show content
  document.getElementById('pdLoading').classList.add('hidden');
  document.getElementById('pdContent').classList.remove('hidden');

  // Update <title>
  document.getElementById('pageTitle').textContent = `${product.name} — XOHO`;
  document.querySelector('meta[name="description"]').setAttribute('content', product.shortDesc || product.name);

  // Breadcrumb
  const pole = POLES[product.pole] || { label: product.pole };
  document.querySelector('#breadcrumbPole span').textContent = pole.label;
  document.querySelector('#breadcrumbName span').textContent = product.name;

  // Hero content
  const poleEl = document.getElementById('pdPoleTag');
  const info   = POLES[product.pole] || { label: product.pole, color: '#64748B', bg: '#F1F5F9' };
  poleEl.textContent = info.label;
  poleEl.style.background = info.bg;
  poleEl.style.color      = info.color;

  document.getElementById('pd-title').textContent     = product.name;
  document.getElementById('pdShortDesc').textContent  = product.shortDesc || '';
  document.getElementById('pdPrice').innerHTML        = `${formatPrice(product.price)} <small>FCFA</small>`;
  document.getElementById('stickyPrice').textContent  = formatPrice(product.price);

  // Buy modal
  document.getElementById('buyModalProductName').textContent = product.name;
  document.getElementById('buyTotal').textContent = formatPrice(product.price);

  // Bullets
  const bullets = (product.bullets || '').split('\n').filter(b => b.trim());
  const bulletsEl = document.getElementById('pdBullets');
  if (bulletsEl) {
    bulletsEl.innerHTML = bullets.map(b => `
      <li>
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
        ${b.trim()}
      </li>`).join('');
  }

  // Full description
  const fullDescEl = document.getElementById('pdFullDesc');
  if (fullDescEl && product.fullDesc) {
    fullDescEl.innerHTML = product.fullDesc.replace(/\n/g, '<br/>');
  } else if (fullDescEl) {
    fullDescEl.textContent = product.shortDesc || '';
  }

  // File info
  const fileInfoEl = document.getElementById('pdFileInfo');
  if (fileInfoEl) {
    const infos = [
      { label: 'Format', value: product.format || 'PDF' },
      { label: 'Taille', value: product.fileSize || 'N/A' },
      { label: 'Pôle', value: info.label },
      { label: 'Livraison', value: 'Instantanée' },
    ];
    fileInfoEl.innerHTML = infos.map(i => `
      <div>
        <div style="font-size:.75rem;color:var(--muted);font-weight:600;text-transform:uppercase;letter-spacing:.06em;margin-bottom:.25rem">${i.label}</div>
        <div style="font-weight:600;color:var(--navy)">${i.value}</div>
      </div>`).join('');
  }

  // Scroll reveal
  const io = new IntersectionObserver((entries) => {
    entries.forEach(e => { if (e.isIntersecting) { e.target.classList.add('visible'); io.unobserve(e.target); } });
  }, { threshold: 0.1 });
  document.querySelectorAll('.reveal').forEach(el => io.observe(el));
}

// ── Load related products ─────────────────────────────────────────────────
async function loadRelated(pole, excludeId) {
  try {
    const q = query(
      collection(db, 'products'),
      where('published', '==', true),
      where('pole', '==', pole),
      limit(4)
    );
    const snap = await getDocs(q);
    const related = snap.docs
      .map(d => ({ id: d.id, ...d.data() }))
      .filter(p => p.id !== excludeId)
      .slice(0, 3);

    if (related.length > 0) {
      document.getElementById('relatedSection').classList.remove('hidden');
      document.getElementById('relatedGrid').innerHTML = related.map(buildProductCard).join('');
    }
  } catch (err) {
    console.error('loadRelated error:', err);
  }
}

// ── Handle buy form submit (Kkiapay integration) ──────────────────────────
async function handleBuySubmit(e) {
  e.preventDefault();
  if (!currentProduct) return;

  const name  = document.getElementById('buyName');
  const phone = document.getElementById('buyPhone');
  const email = document.getElementById('buyEmail');
  let valid = true;

  // Validate
  [
    { el: name,  err: 'buyNameErr',  check: () => name.value.trim().length > 1 },
    { el: phone, err: 'buyPhoneErr', check: () => /^[0-9]{8,}$/.test(phone.value.replace(/\s/g, '')) },
    { el: email, err: 'buyEmailErr', check: () => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.value.trim()) },
  ].forEach(({ el, err, check }) => {
    const errEl = document.getElementById(err);
    if (!check()) {
      el.classList.add('error');
      errEl.classList.add('show');
      valid = false;
    } else {
      el.classList.remove('error');
      errEl.classList.remove('show');
    }
  });

  if (!valid) return;

  const btn = document.getElementById('buySubmitBtn');
  btn.classList.add('loading');
  btn.innerHTML = `<div class="spinner-full"></div> Traitement en cours…`;
  btn.disabled = true;

  try {
    // Create a pending order in Firestore first
    const orderRef = await addDoc(collection(db, 'orders'), {
      productId:   currentProduct.id,
      productName: currentProduct.name,
      amount:      currentProduct.price,
      buyerName:   name.value.trim(),
      buyerPhone:  phone.value.trim(),
      buyerEmail:  email.value.trim().toLowerCase(),
      status:      'pending',
      createdAt:   serverTimestamp(),
      downloadUrl: currentProduct.fileUrl || '',
    });

    // Launch Kkiapay payment widget
    // Ensure Kkiapay SDK script is loaded (add to HTML if not present)
    if (typeof openKkiapayWidget === 'function') {
      openKkiapayWidget({
        amount:    currentProduct.price,
        api_key:   'VOTRE_CLE_PUBLIQUE_KKIAPAY',   // Replace with your Kkiapay public key
        sandbox:   true,                             // Set to false in production
        phone:     phone.value.trim(),
        name:      name.value.trim(),
        email:     email.value.trim(),
        data:      orderId(orderRef.id),
        callback:  window.location.origin + '/xoho/succes.html?orderId=' + orderRef.id,
      });
    } else {
      // Kkiapay SDK not loaded — redirect to success with orderId for testing
      window.location.href = `succes.html?orderId=${orderRef.id}&status=test`;
    }

    btn.classList.remove('loading');
    btn.innerHTML = `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M5 12h14M12 5l7 7-7 7"/></svg> Payer maintenant`;
    btn.disabled = false;
  } catch (err) {
    console.error('Buy error:', err);
    btn.classList.remove('loading');
    btn.innerHTML = `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M5 12h14M12 5l7 7-7 7"/></svg> Payer maintenant`;
    btn.disabled = false;
    showToast('Une erreur est survenue. Veuillez réessayer.', 'error');
  }
}

function orderId(id) {
  return JSON.stringify({ orderId: id });
}

// ── Kkiapay success callback ──────────────────────────────────────────────
// Called by Kkiapay widget after successful payment
window.addEventListener('message', (e) => {
  if (e.data && e.data.event === 'kkiapay.payment.success') {
    const params = new URLSearchParams(window.location.search);
    const productId = params.get('id');
    // orderId should be in e.data.data
    window.location.href = `succes.html?orderId=${e.data.data}&productId=${productId}`;
  }
});

// ── Init ──────────────────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  loadProduct();

  const buyForm = document.getElementById('buyForm');
  if (buyForm) buyForm.addEventListener('submit', handleBuySubmit);

  // Show back button
  const backBtn = document.getElementById('backBtn');
  if (backBtn) {
    backBtn.style.display = 'inline-flex';
    backBtn.addEventListener('click', () => history.back());
  }

  // Clear error on input
  document.querySelectorAll('.form-input').forEach(input => {
    input.addEventListener('input', () => {
      input.classList.remove('error');
      const errId = input.id + 'Err';
      const errEl = document.getElementById(errId.replace('buy', 'buy'));
      if (errEl) errEl.classList.remove('show');
    });
  });
});
