// ─── Product detail page logic ────────────────────────────────────────────
import { POLES, formatPrice, buildProductCard, showToast } from './app.js';

let currentProduct = null;
let pendingToken   = null;

async function loadProduct() {
  const params    = new URLSearchParams(window.location.search);
  const productId = params.get('id');
  if (!productId) { window.location.href = 'boutique.html'; return; }

  try {
    const res  = await fetch(`api/products.php?id=${encodeURIComponent(productId)}`);
    const data = await res.json();
    if (!res.ok) { window.location.href = 'boutique.html'; return; }
    currentProduct = data;
    renderProduct(currentProduct);
    loadRelated(currentProduct.pole, productId);
  } catch {
    showToast('Erreur lors du chargement du produit.', 'error');
  }
}

function renderProduct(product) {
  document.getElementById('pdLoading').classList.add('hidden');
  document.getElementById('pdContent').classList.remove('hidden');

  document.getElementById('pageTitle').textContent = `${product.name} — XOHO`;
  document.querySelector('meta[name="description"]')?.setAttribute('content', product.short_desc || product.name);

  const pole = POLES[product.pole] || { label: product.pole };
  document.querySelector('#breadcrumbPole span').textContent = pole.label;
  document.querySelector('#breadcrumbName span').textContent = product.name;

  const info   = POLES[product.pole] || { label: product.pole, color: '#64748B', bg: '#F1F5F9' };
  const poleEl = document.getElementById('pdPoleTag');
  poleEl.textContent     = info.label;
  poleEl.style.background = info.bg;
  poleEl.style.color      = info.color;

  document.getElementById('pd-title').textContent    = product.name;
  document.getElementById('pdShortDesc').textContent = product.short_desc || '';
  document.getElementById('pdPrice').innerHTML       = `${formatPrice(product.price)} <small>FCFA</small>`;
  document.getElementById('stickyPrice').textContent = formatPrice(product.price);

  document.getElementById('buyModalProductName').textContent = product.name;
  document.getElementById('buyTotal').textContent = formatPrice(product.price);

  if (product.preview_url) {
    const img = document.getElementById('pdPreviewImg');
    if (img) img.src = product.preview_url;
  }

  const bullets  = (product.bullets || '').split('\n').filter(b => b.trim());
  const bulletsEl = document.getElementById('pdBullets');
  if (bulletsEl) {
    bulletsEl.innerHTML = bullets.map(b => `
      <li>
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
        ${b.trim()}
      </li>`).join('');
  }

  const fullDescEl = document.getElementById('pdFullDesc');
  if (fullDescEl) {
    fullDescEl.innerHTML = (product.full_desc || product.short_desc || '').replace(/\n/g, '<br>');
  }

  const fileInfoEl = document.getElementById('pdFileInfo');
  if (fileInfoEl) {
    const infos = [
      { label: 'Format',    value: product.format    || 'PDF'          },
      { label: 'Taille',    value: product.file_size || 'N/A'          },
      { label: 'Pôle',      value: info.label                          },
      { label: 'Livraison', value: 'Instantanée'                       },
    ];
    fileInfoEl.innerHTML = infos.map(i => `
      <div>
        <div style="font-size:.75rem;color:var(--muted);font-weight:600;text-transform:uppercase;letter-spacing:.06em;margin-bottom:.25rem">${i.label}</div>
        <div style="font-weight:600;color:var(--navy)">${i.value}</div>
      </div>`).join('');
  }

  const io = new IntersectionObserver((entries) => {
    entries.forEach(e => { if (e.isIntersecting) { e.target.classList.add('visible'); io.unobserve(e.target); } });
  }, { threshold: 0.1 });
  document.querySelectorAll('.reveal').forEach(el => io.observe(el));
}

async function loadRelated(pole, excludeId) {
  try {
    const res  = await fetch(`api/products.php?pole=${encodeURIComponent(pole)}`);
    const data = await res.json();
    if (!res.ok) return;
    const related = data.filter(p => String(p.id) !== String(excludeId)).slice(0, 3);
    if (related.length > 0) {
      document.getElementById('relatedSection')?.classList.remove('hidden');
      const relGrid = document.getElementById('relatedGrid');
      if (relGrid) relGrid.innerHTML = related.map(buildProductCard).join('');
    }
  } catch { /* non-critical */ }
}

async function handleBuySubmit(e) {
  e.preventDefault();
  if (!currentProduct) return;

  const nameEl  = document.getElementById('buyName');
  const phoneEl = document.getElementById('buyPhone');
  const emailEl = document.getElementById('buyEmail');
  let valid = true;

  [
    { el: nameEl,  errId: 'buyNameErr',  ok: () => nameEl.value.trim().length > 1 },
    { el: phoneEl, errId: 'buyPhoneErr', ok: () => /^[0-9]{8,}$/.test(phoneEl.value.replace(/\s/g, '')) },
    { el: emailEl, errId: 'buyEmailErr', ok: () => !emailEl.value || /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(emailEl.value.trim()) },
  ].forEach(({ el, errId, ok }) => {
    const errEl = document.getElementById(errId);
    if (!ok()) { el.classList.add('error'); errEl?.classList.add('show'); valid = false; }
    else        { el.classList.remove('error'); errEl?.classList.remove('show'); }
  });

  if (!valid) return;

  const btn = document.getElementById('buySubmitBtn');
  btn.disabled  = true;
  btn.innerHTML = `<div class="spinner-full"></div> Traitement en cours…`;

  try {
    // Create pending order in PHP backend
    const res  = await fetch('api/orders.php', {
      method:  'POST',
      headers: { 'Content-Type': 'application/json' },
      body:    JSON.stringify({
        productId:  currentProduct.id,
        buyerName:  nameEl.value.trim(),
        buyerPhone: phoneEl.value.trim(),
        buyerEmail: emailEl.value.trim().toLowerCase(),
      }),
    });
    const order = await res.json();
    if (!res.ok) throw new Error(order.error || 'Erreur création commande');

    pendingToken = order.token;

    // Launch Kkiapay widget
    if (typeof openKkiapayWidget === 'function') {
      openKkiapayWidget({
        amount:   currentProduct.price,
        api_key:  'VOTRE_CLE_PUBLIQUE_KKIAPAY',  // ⚠️ Replace with your Kkiapay public key
        sandbox:  true,                            // Set to false in production
        phone:    phoneEl.value.trim(),
        name:     nameEl.value.trim(),
        email:    emailEl.value.trim(),
        data:     JSON.stringify({ token: order.token }),
        callback: `${window.location.origin}/succes.html?token=${order.token}`,
      });
    } else {
      // Kkiapay not loaded — dev/test redirect
      window.location.href = `succes.html?token=${order.token}&status=test`;
    }
  } catch (err) {
    showToast(err.message || 'Une erreur est survenue.', 'error');
  } finally {
    btn.disabled  = false;
    btn.innerHTML = `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M5 12h14M12 5l7 7-7 7"/></svg> Payer maintenant`;
  }
}

// Kkiapay payment success callback
window.addEventListener('message', async (e) => {
  if (e.data?.event === 'kkiapay.payment.success' && pendingToken) {
    const txid = e.data?.data?.transactionId || '';
    try {
      await fetch(`api/orders.php?action=confirm`, {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({ token: pendingToken, transactionId: txid }),
      });
    } catch { /* ignore — succes.php handles status */ }
    window.location.href = `succes.html?token=${pendingToken}`;
  }
});

document.addEventListener('DOMContentLoaded', () => {
  loadProduct();

  document.getElementById('buyForm')?.addEventListener('submit', handleBuySubmit);

  const backBtn = document.getElementById('backBtn');
  if (backBtn) { backBtn.style.display = 'inline-flex'; backBtn.addEventListener('click', () => history.back()); }

  document.querySelectorAll('.form-input').forEach(input => {
    input.addEventListener('input', () => {
      input.classList.remove('error');
      document.getElementById(input.id + 'Err')?.classList.remove('show');
    });
  });
});
