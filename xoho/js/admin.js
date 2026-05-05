// ─── Admin panel logic ────────────────────────────────────────────────────
import { POLES, formatPrice, formatDate, showToast } from './app.js';

let deleteTargetId = null;

// ── Auth check ────────────────────────────────────────────────────────────
async function checkAuth() {
  const res  = await fetch('api/auth.php?action=check');
  const data = await res.json();
  return data;
}

async function initAdmin() {
  const auth = await checkAuth();
  if (auth.loggedIn) {
    showDashboard(auth);
  } else {
    document.getElementById('loginScreen').classList.remove('hidden');
    document.getElementById('dashboardScreen').classList.add('hidden');
  }
}

function showDashboard(auth) {
  document.getElementById('loginScreen').classList.add('hidden');
  document.getElementById('dashboardScreen').classList.remove('hidden');
  document.getElementById('adminUserEmail').textContent = auth.email || '';
  const initial = (auth.name || auth.email || 'A').charAt(0).toUpperCase();
  document.getElementById('adminAvatar').textContent = initial;
  loadDashboard();
}

// ── Login form ────────────────────────────────────────────────────────────
document.getElementById('loginForm').addEventListener('submit', async (e) => {
  e.preventDefault();
  const emailEl = document.getElementById('loginEmail');
  const pwdEl   = document.getElementById('loginPassword');
  const globalErr = document.getElementById('loginGlobalErr');
  const btn     = document.getElementById('loginBtn');
  let valid = true;

  if (!emailEl.value.trim() || !/\S+@\S+\.\S+/.test(emailEl.value)) {
    document.getElementById('loginEmailErr').classList.add('show'); emailEl.classList.add('error'); valid = false;
  } else { document.getElementById('loginEmailErr').classList.remove('show'); emailEl.classList.remove('error'); }
  if (!pwdEl.value) {
    document.getElementById('loginPwdErr').classList.add('show'); pwdEl.classList.add('error'); valid = false;
  } else { document.getElementById('loginPwdErr').classList.remove('show'); pwdEl.classList.remove('error'); }
  if (!valid) return;

  btn.classList.add('loading'); btn.innerHTML = `<div class="spinner-full"></div> Connexion…`; btn.disabled = true;
  globalErr.classList.remove('show');

  try {
    const res  = await fetch('api/auth.php?action=login', {
      method:  'POST',
      headers: { 'Content-Type': 'application/json' },
      body:    JSON.stringify({ email: emailEl.value.trim(), password: pwdEl.value }),
    });
    const data = await res.json();
    if (!res.ok) {
      globalErr.textContent = data.error || 'Identifiants incorrects.';
      globalErr.classList.add('show');
    } else {
      showDashboard(data);
    }
  } catch {
    globalErr.textContent = 'Erreur réseau. Veuillez réessayer.';
    globalErr.classList.add('show');
  } finally {
    btn.classList.remove('loading'); btn.innerHTML = 'Se connecter'; btn.disabled = false;
  }
});

// ── Logout ────────────────────────────────────────────────────────────────
document.getElementById('logoutBtn').addEventListener('click', async () => {
  await fetch('api/auth.php?action=logout', { method: 'POST' });
  document.getElementById('loginScreen').classList.remove('hidden');
  document.getElementById('dashboardScreen').classList.add('hidden');
});

// ── Dashboard stats ───────────────────────────────────────────────────────
async function loadDashboard() {
  try {
    const [pRes, oRes] = await Promise.all([
      fetch('api/products.php?all=1'),
      fetch('api/orders.php?all=1'),
    ]);
    const products = await pRes.json();
    const orders   = await oRes.json();

    const published  = products.filter(p => p.published).length;
    const completed  = orders.filter(o => o.status === 'completed' || o.status === 'accessed');
    const revenue    = completed.reduce((s, o) => s + (o.amount || 0), 0);
    const successRate = orders.length ? Math.round((completed.length / orders.length) * 100) : 0;
    const pending    = orders.filter(o => o.status === 'pending');

    document.getElementById('statProducts').textContent = published;
    document.getElementById('statOrders').textContent   = orders.length;
    document.getElementById('statRevenue').textContent  = formatPrice(revenue);
    document.getElementById('statSuccess').textContent  = successRate + '%';

    const badge = document.getElementById('pendingBadge');
    if (pending.length > 0) { badge.textContent = pending.length; badge.style.display = 'inline'; }

    renderRecentOrders(orders.slice(0, 10));
  } catch (err) { console.error('loadDashboard error:', err); }
}

function renderRecentOrders(orders) {
  const tbody = document.getElementById('recentOrdersBody');
  if (!orders.length) {
    tbody.innerHTML = `<tr><td colspan="5" style="text-align:center;padding:2rem;color:var(--muted)">Aucune commande pour le moment.</td></tr>`;
    return;
  }
  tbody.innerHTML = orders.map(o => `
    <tr>
      <td><strong>${o.buyer_name || '—'}</strong><br/><small style="color:var(--muted)">${o.buyer_email || ''}</small></td>
      <td>${o.product_name || '—'}</td>
      <td style="font-weight:700">${formatPrice(o.amount || 0)}</td>
      <td>${statusBadge(o.status)}</td>
      <td style="color:var(--muted)">${formatDate(o.created_at)}</td>
    </tr>`).join('');
}

// ── Products table ────────────────────────────────────────────────────────
async function loadProductsTable(poleFilter = 'all') {
  const tbody = document.getElementById('productsTableBody');
  tbody.innerHTML = `<tr><td colspan="6" style="text-align:center;padding:2rem;color:var(--muted)">Chargement…</td></tr>`;
  try {
    const url = poleFilter !== 'all'
      ? `api/products.php?all=1&pole=${encodeURIComponent(poleFilter)}`
      : 'api/products.php?all=1';
    const res      = await fetch(url);
    const products = await res.json();
    if (!res.ok) throw new Error(products.error);

    if (!products.length) {
      tbody.innerHTML = `<tr><td colspan="6" style="text-align:center;padding:2rem;color:var(--muted)">Aucun produit trouvé.</td></tr>`;
      return;
    }
    tbody.innerHTML = products.map(p => {
      const pole = POLES[p.pole] || { label: p.pole, color: '#64748B', bg: '#F1F5F9' };
      return `
        <tr>
          <td><strong style="color:var(--navy)">${p.name}</strong></td>
          <td><span class="status-pill" style="background:${pole.bg};color:${pole.color}">${pole.label}</span></td>
          <td style="font-weight:700">${formatPrice(p.price)}</td>
          <td style="text-align:center">${p.top_sell ? '⭐' : '—'}</td>
          <td>${p.published ? '<span class="status-pill status-success">Publié</span>' : '<span class="status-pill status-pending">Brouillon</span>'}</td>
          <td>
            <div style="display:flex;gap:.375rem">
              <button class="btn btn-ghost btn-sm" onclick="editProduct(${p.id})" style="padding:.375rem .75rem">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
              </button>
              <button class="btn btn-sm" onclick="confirmDelete(${p.id},'${p.name.replace(/'/g,"\\'")}') " style="padding:.375rem .75rem;color:#DC2626;background:#FEF2F2;border-radius:var(--r-sm)">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a1 1 0 011-1h4a1 1 0 011 1v2"/></svg>
              </button>
              <a href="produit.html?id=${p.id}" class="btn btn-ghost btn-sm" target="_blank" style="padding:.375rem .75rem">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M18 13v6a2 2 0 01-2 2H5a2 2 0 01-2-2V8a2 2 0 012-2h6"/><polyline points="15 3 21 3 21 9"/><line x1="10" y1="14" x2="21" y2="3"/></svg>
              </a>
            </div>
          </td>
        </tr>`;
    }).join('');
  } catch (err) {
    tbody.innerHTML = `<tr><td colspan="6" style="text-align:center;padding:2rem;color:#DC2626">Erreur: ${err.message}</td></tr>`;
  }
}

// ── Orders table ──────────────────────────────────────────────────────────
async function loadOrdersTable(statusFilter = 'all') {
  const tbody = document.getElementById('ordersTableBody');
  tbody.innerHTML = `<tr><td colspan="8" style="text-align:center;padding:2rem;color:var(--muted)">Chargement…</td></tr>`;
  try {
    const url = statusFilter !== 'all'
      ? `api/orders.php?all=1&status=${encodeURIComponent(statusFilter)}`
      : 'api/orders.php?all=1';
    const res    = await fetch(url);
    const orders = await res.json();
    if (!res.ok) throw new Error(orders.error);

    if (!orders.length) {
      tbody.innerHTML = `<tr><td colspan="8" style="text-align:center;padding:2rem;color:var(--muted)">Aucune commande.</td></tr>`;
      return;
    }
    tbody.innerHTML = orders.map(o => `
      <tr>
        <td style="font-family:monospace;font-size:.75rem;color:var(--muted)">#${o.id}</td>
        <td><strong>${o.buyer_name || '—'}</strong><br/><small style="color:var(--muted)">${o.buyer_email || ''}</small></td>
        <td>${o.buyer_phone || '—'}</td>
        <td style="max-width:160px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${o.product_name || '—'}</td>
        <td style="font-weight:700">${formatPrice(o.amount || 0)}</td>
        <td>${statusBadge(o.status)}</td>
        <td style="color:var(--muted);white-space:nowrap">${formatDate(o.created_at)}</td>
        <td>
          <button class="btn btn-ghost btn-sm" onclick="viewOrderDetail(${o.id})" style="padding:.375rem .75rem">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
          </button>
        </td>
      </tr>`).join('');
  } catch (err) { console.error('loadOrdersTable error:', err); }
}

// ── Product form ──────────────────────────────────────────────────────────
document.getElementById('productForm').addEventListener('submit', async (e) => {
  e.preventDefault();
  const fields = {
    name:       document.getElementById('pName'),
    pole:       document.getElementById('pPole'),
    price:      document.getElementById('pPrice'),
    shortDesc:  document.getElementById('pShortDesc'),
    bullets:    document.getElementById('pBullets'),
    filePath:   document.getElementById('pFileUrl'),
  };
  let valid = true;
  const checks = [
    { el: fields.name,      err: 'pNameErr',      ok: () => fields.name.value.trim().length > 1 },
    { el: fields.pole,      err: 'pPoleErr',      ok: () => fields.pole.value !== '' },
    { el: fields.price,     err: 'pPriceErr',     ok: () => Number(fields.price.value) >= 50 },
    { el: fields.shortDesc, err: 'pShortDescErr', ok: () => fields.shortDesc.value.trim().length > 5 },
    { el: fields.bullets,   err: 'pBulletsErr',   ok: () => fields.bullets.value.trim().length > 0 },
    { el: fields.filePath,  err: 'pFileUrlErr',   ok: () => fields.filePath.value.trim().length > 0 },
  ];
  checks.forEach(({ el, err, ok }) => {
    const errEl = document.getElementById(err);
    if (!ok()) { el.classList.add('error'); errEl?.classList.add('show'); valid = false; }
    else        { el.classList.remove('error'); errEl?.classList.remove('show'); }
  });
  if (!valid) return;

  const btn = document.getElementById('productSubmitBtn');
  btn.classList.add('loading'); btn.disabled = true;
  document.getElementById('productSubmitText').textContent = 'Sauvegarde…';

  const payload = {
    name:       fields.name.value.trim(),
    pole:       fields.pole.value,
    price:      Number(fields.price.value),
    shortDesc:  fields.shortDesc.value.trim(),
    fullDesc:   document.getElementById('pFullDesc').value.trim(),
    bullets:    fields.bullets.value.trim(),
    format:     document.getElementById('pFormat').value,
    fileSize:   document.getElementById('pFileSize').value.trim(),
    filePath:   fields.filePath.value.trim(),
    previewUrl: document.getElementById('pPreviewUrl').value.trim(),
    published:  document.getElementById('togglePublished').classList.contains('on'),
    topSell:    document.getElementById('toggleTopSell').classList.contains('on'),
    featured:   document.getElementById('toggleFeatured').classList.contains('on'),
  };

  try {
    const editId = document.getElementById('editProductId').value;
    const url    = editId ? `api/products.php?id=${editId}` : 'api/products.php';
    const method = editId ? 'PUT' : 'POST';
    const res    = await fetch(url, {
      method, headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(payload),
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error || 'Erreur');
    showToast(editId ? 'Produit mis à jour !' : 'Produit publié !', 'success');
    resetForm(); showSection('products'); loadProductsTable();
  } catch (err) {
    showToast('Erreur : ' + err.message, 'error');
  } finally {
    btn.classList.remove('loading'); btn.disabled = false;
    document.getElementById('productSubmitText').textContent = 'Publier le produit';
  }
});

function resetForm() {
  document.getElementById('productForm').reset();
  document.getElementById('editProductId').value = '';
  document.getElementById('productFormTitle').textContent  = 'Ajouter un produit';
  document.getElementById('productSubmitText').textContent = 'Publier le produit';
  document.getElementById('togglePublished').classList.add('on');
  document.getElementById('togglePublished').setAttribute('aria-checked', 'true');
  ['toggleTopSell','toggleFeatured'].forEach(id => {
    document.getElementById(id).classList.remove('on');
    document.getElementById(id).setAttribute('aria-checked', 'false');
  });
}

window.editProduct = async (id) => {
  try {
    const res  = await fetch(`api/products.php?id=${id}&admin=1`);
    const p    = await res.json();
    if (!res.ok) throw new Error(p.error);

    document.getElementById('editProductId').value  = p.id;
    document.getElementById('pName').value          = p.name || '';
    document.getElementById('pPole').value          = p.pole || '';
    document.getElementById('pPrice').value         = p.price || '';
    document.getElementById('pShortDesc').value     = p.short_desc || '';
    document.getElementById('pFullDesc').value      = p.full_desc || '';
    document.getElementById('pBullets').value       = p.bullets || '';
    document.getElementById('pFormat').value        = p.format || 'PDF';
    document.getElementById('pFileSize').value      = p.file_size || '';
    document.getElementById('pFileUrl').value       = p.file_path || '';
    document.getElementById('pPreviewUrl').value    = p.preview_url || '';
    document.getElementById('pShortDescCount').textContent = `${(p.short_desc||'').length} / 120 caractères`;

    const setToggle = (id, val) => {
      const el = document.getElementById(id);
      el.classList.toggle('on', !!val); el.setAttribute('aria-checked', String(!!val));
    };
    setToggle('togglePublished', p.published);
    setToggle('toggleTopSell',  p.top_sell);
    setToggle('toggleFeatured', p.featured);

    document.getElementById('productFormTitle').textContent  = 'Modifier le produit';
    document.getElementById('productSubmitText').textContent = 'Enregistrer les modifications';
    showSection('add-product');
  } catch (err) { showToast('Erreur: ' + err.message, 'error'); }
};

window.confirmDelete = (id, name) => {
  deleteTargetId = id;
  document.getElementById('deleteMsg').textContent = `Supprimer "${name}" ? Cette action est irréversible.`;
  document.getElementById('deleteOverlay').classList.add('open');
};

document.getElementById('confirmDeleteBtn').addEventListener('click', async () => {
  if (!deleteTargetId) return;
  try {
    const res  = await fetch(`api/products.php?id=${deleteTargetId}`, { method: 'DELETE' });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error);
    window.closeDeleteModal?.();
    showToast('Produit supprimé.', 'success');
    loadProductsTable(); loadDashboard(); deleteTargetId = null;
  } catch (err) { showToast('Erreur: ' + err.message, 'error'); }
});

window.viewOrderDetail = async (id) => {
  try {
    const res   = await fetch(`api/orders.php?id=${id}`);
    const order = await res.json();
    if (!res.ok) throw new Error(order.error);

    document.getElementById('orderDetailBody').innerHTML = `
      <div style="display:grid;gap:.875rem">
        ${detailRow('N° Commande', '#' + order.id)}
        ${detailRow('Client', order.buyer_name || '—')}
        ${detailRow('Email', order.buyer_email || '—')}
        ${detailRow('Téléphone', order.buyer_phone || '—')}
        ${detailRow('Produit', order.product_name || '—')}
        ${detailRow('Montant', formatPrice(order.amount || 0))}
        ${detailRow('Statut', statusBadge(order.status))}
        ${detailRow('Date', formatDate(order.created_at))}
        ${order.kkiapay_txid ? detailRow('ID Transaction Kkiapay', order.kkiapay_txid) : ''}
        ${detailRow('Lien téléchargement', `<a href="api/download.php?token=${order.download_token}" target="_blank" style="color:var(--navy);text-decoration:underline">Télécharger</a>`)}
      </div>`;
    document.getElementById('orderDetailOverlay').classList.add('open');
  } catch (err) { console.error(err); }
};

function detailRow(label, value) {
  return `<div style="display:flex;justify-content:space-between;align-items:center;padding:.625rem 0;border-bottom:1px solid var(--border)"><span style="font-size:.85rem;color:var(--muted);font-weight:600">${label}</span><span style="font-size:.875rem;color:var(--text);font-weight:500">${value}</span></div>`;
}

// ── Navigation ────────────────────────────────────────────────────────────
document.querySelectorAll('.nav-item[data-section]').forEach(item => {
  item.addEventListener('click', (e) => {
    e.preventDefault();
    const section = item.dataset.section;
    showSection(section);
    if (section === 'products')  loadProductsTable();
    if (section === 'orders')    loadOrdersTable();
    if (section === 'dashboard') loadDashboard();
  });
});

document.getElementById('orderStatusFilter')?.addEventListener('change', function() {
  loadOrdersTable(this.value);
});

document.querySelectorAll('[data-filter-pole]').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('[data-filter-pole]').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    loadProductsTable(btn.dataset.filterPole);
  });
});

// ── Status badge ──────────────────────────────────────────────────────────
function statusBadge(status) {
  const map = {
    completed: `<span class="status-pill status-success">Complété</span>`,
    accessed:  `<span class="status-pill status-success">Téléchargé</span>`,
    pending:   `<span class="status-pill status-pending">En attente</span>`,
    failed:    `<span class="status-pill status-failed">Échoué</span>`,
  };
  return map[status] || `<span class="status-pill">${status || '—'}</span>`;
}

// ── File upload helpers ───────────────────────────────────────────────────
async function uploadFile(inputEl, type, statusElId) {
  const file = inputEl.files?.[0];
  if (!file) return null;
  const statusEl = document.getElementById(statusElId);
  if (statusEl) statusEl.textContent = 'Envoi en cours…';

  const form = new FormData();
  form.append('file', file);
  try {
    const res  = await fetch(`api/upload.php?type=${type}`, { method: 'POST', body: form });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error);
    if (statusEl) statusEl.textContent = `✅ ${data.size}`;
    return data.path;
  } catch (err) {
    if (statusEl) statusEl.textContent = '❌ ' + err.message;
    showToast('Erreur upload: ' + err.message, 'error');
    return null;
  }
}

// Wire up file input buttons
document.getElementById('pFileInput')?.addEventListener('change', async function() {
  const path = await uploadFile(this, 'product', 'pFileStatus');
  if (path) document.getElementById('pFileUrl').value = path;
});
document.getElementById('pPreviewInput')?.addEventListener('change', async function() {
  const path = await uploadFile(this, 'preview', 'pPreviewStatus');
  if (path) document.getElementById('pPreviewUrl').value = path;
});

// ── Init ──────────────────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', initAdmin);
