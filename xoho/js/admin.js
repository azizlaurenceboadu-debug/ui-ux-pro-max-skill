// ─── Admin panel logic ────────────────────────────────────────────────────
import { db, auth } from './firebase-config.js';
import {
  signInWithEmailAndPassword, signOut, onAuthStateChanged
} from 'https://www.gstatic.com/firebasejs/10.12.0/firebase-auth.js';
import {
  collection, getDocs, addDoc, updateDoc, deleteDoc,
  doc, query, orderBy, where, serverTimestamp, getCountFromServer
} from 'https://www.gstatic.com/firebasejs/10.12.0/firebase-firestore.js';
import { POLES, formatPrice, formatDate, showToast } from './app.js';

let deleteTargetId = null;

// ── Auth ─────────────────────────────────────────────────────────────────
onAuthStateChanged(auth, (user) => {
  if (user) {
    document.getElementById('loginScreen').classList.add('hidden');
    document.getElementById('dashboardScreen').classList.remove('hidden');
    document.getElementById('adminUserEmail').textContent = user.email;
    const initial = user.email.charAt(0).toUpperCase();
    document.getElementById('adminAvatar').textContent = initial;
    loadDashboard();
  } else {
    document.getElementById('loginScreen').classList.remove('hidden');
    document.getElementById('dashboardScreen').classList.add('hidden');
  }
});

// Login form
document.getElementById('loginForm').addEventListener('submit', async (e) => {
  e.preventDefault();
  const email    = document.getElementById('loginEmail');
  const password = document.getElementById('loginPassword');
  const globalErr = document.getElementById('loginGlobalErr');
  const btn      = document.getElementById('loginBtn');
  let valid = true;

  if (!email.value.trim() || !/\S+@\S+\.\S+/.test(email.value)) {
    document.getElementById('loginEmailErr').classList.add('show');
    email.classList.add('error');
    valid = false;
  } else {
    document.getElementById('loginEmailErr').classList.remove('show');
    email.classList.remove('error');
  }
  if (!password.value) {
    document.getElementById('loginPwdErr').classList.add('show');
    password.classList.add('error');
    valid = false;
  } else {
    document.getElementById('loginPwdErr').classList.remove('show');
    password.classList.remove('error');
  }
  if (!valid) return;

  btn.classList.add('loading');
  btn.innerHTML = `<div class="spinner-full"></div> Connexion…`;
  btn.disabled = true;
  globalErr.classList.remove('show');

  try {
    await signInWithEmailAndPassword(auth, email.value.trim(), password.value);
  } catch (err) {
    const msgs = {
      'auth/invalid-credential': 'Email ou mot de passe incorrect.',
      'auth/too-many-requests':  'Trop de tentatives. Réessayez plus tard.',
    };
    globalErr.textContent = msgs[err.code] || 'Erreur de connexion. Réessayez.';
    globalErr.classList.add('show');
    btn.classList.remove('loading');
    btn.innerHTML = 'Se connecter';
    btn.disabled = false;
  }
});

// Logout
document.getElementById('logoutBtn').addEventListener('click', async () => {
  await signOut(auth);
});

// ── Dashboard ─────────────────────────────────────────────────────────────
async function loadDashboard() {
  try {
    // Stats
    const [productsSnap, ordersSnap] = await Promise.all([
      getCountFromServer(query(collection(db, 'products'), where('published', '==', true))),
      getDocs(query(collection(db, 'orders'), orderBy('createdAt', 'desc'))),
    ]);

    const orders  = ordersSnap.docs.map(d => ({ id: d.id, ...d.data() }));
    const completed = orders.filter(o => o.status === 'completed' || o.status === 'accessed');
    const revenue   = completed.reduce((sum, o) => sum + (o.amount || 0), 0);
    const successRate = orders.length ? Math.round((completed.length / orders.length) * 100) : 0;
    const pendingOrders = orders.filter(o => o.status === 'pending');

    document.getElementById('statProducts').textContent = productsSnap.data().count;
    document.getElementById('statOrders').textContent   = orders.length;
    document.getElementById('statRevenue').textContent  = formatPrice(revenue);
    document.getElementById('statSuccess').textContent  = successRate + '%';

    // Pending badge
    const badge = document.getElementById('pendingBadge');
    if (pendingOrders.length > 0) {
      badge.textContent = pendingOrders.length;
      badge.style.display = 'inline';
    }

    // Recent orders (last 10)
    renderRecentOrders(orders.slice(0, 10));
  } catch (err) {
    console.error('loadDashboard error:', err);
  }
}

function renderRecentOrders(orders) {
  const tbody = document.getElementById('recentOrdersBody');
  if (!orders.length) {
    tbody.innerHTML = `<tr><td colspan="5" style="text-align:center;padding:2rem;color:var(--muted)">Aucune commande pour le moment.</td></tr>`;
    return;
  }
  tbody.innerHTML = orders.map(o => `
    <tr>
      <td><strong>${o.buyerName || '—'}</strong><br/><small style="color:var(--muted)">${o.buyerEmail || ''}</small></td>
      <td>${o.productName || '—'}</td>
      <td style="font-weight:700">${formatPrice(o.amount || 0)}</td>
      <td>${statusBadge(o.status)}</td>
      <td style="color:var(--muted)">${formatDate(o.createdAt)}</td>
    </tr>`).join('');
}

// ── Products table ────────────────────────────────────────────────────────
async function loadProductsTable(poleFilter = 'all') {
  const tbody = document.getElementById('productsTableBody');
  tbody.innerHTML = `<tr><td colspan="6" style="text-align:center;padding:2rem;color:var(--muted)">Chargement…</td></tr>`;
  try {
    let q = query(collection(db, 'products'), orderBy('createdAt', 'desc'));
    const snap = await getDocs(q);
    let products = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    if (poleFilter !== 'all') products = products.filter(p => p.pole === poleFilter);

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
          <td style="text-align:center">${p.topSell ? '⭐' : '—'}</td>
          <td>${p.published ? '<span class="status-pill status-success">Publié</span>' : '<span class="status-pill status-pending">Brouillon</span>'}</td>
          <td>
            <div style="display:flex;gap:.375rem">
              <button class="btn btn-ghost btn-sm" onclick="editProduct('${p.id}')" aria-label="Modifier ${p.name}" style="padding:.375rem .75rem">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
              </button>
              <button class="btn btn-sm" onclick="confirmDelete('${p.id}','${p.name.replace(/'/g,"\\'")}') " aria-label="Supprimer ${p.name}" style="padding:.375rem .75rem;color:#DC2626;background:#FEF2F2;border-radius:var(--r-sm)">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a1 1 0 011-1h4a1 1 0 011 1v2"/></svg>
              </button>
              <a href="produit.html?id=${p.id}" class="btn btn-ghost btn-sm" target="_blank" rel="noopener noreferrer" aria-label="Voir ${p.name}" style="padding:.375rem .75rem">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M18 13v6a2 2 0 01-2 2H5a2 2 0 01-2-2V8a2 2 0 012-2h6"/><polyline points="15 3 21 3 21 9"/><line x1="10" y1="14" x2="21" y2="3"/></svg>
              </a>
            </div>
          </td>
        </tr>`;
    }).join('');
  } catch (err) {
    console.error('loadProductsTable error:', err);
    tbody.innerHTML = `<tr><td colspan="6" style="text-align:center;padding:2rem;color:#DC2626">Erreur de chargement.</td></tr>`;
  }
}

// ── Orders table ──────────────────────────────────────────────────────────
async function loadOrdersTable(statusFilter = 'all') {
  const tbody = document.getElementById('ordersTableBody');
  tbody.innerHTML = `<tr><td colspan="8" style="text-align:center;padding:2rem;color:var(--muted)">Chargement…</td></tr>`;
  try {
    const snap = await getDocs(query(collection(db, 'orders'), orderBy('createdAt', 'desc')));
    let orders = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    if (statusFilter !== 'all') orders = orders.filter(o => o.status === statusFilter);

    if (!orders.length) {
      tbody.innerHTML = `<tr><td colspan="8" style="text-align:center;padding:2rem;color:var(--muted)">Aucune commande.</td></tr>`;
      return;
    }
    tbody.innerHTML = orders.map(o => `
      <tr>
        <td style="font-family:monospace;font-size:.75rem;color:var(--muted)">${o.id.substring(0,8)}…</td>
        <td><strong>${o.buyerName || '—'}</strong><br/><small style="color:var(--muted)">${o.buyerEmail || ''}</small></td>
        <td>${o.buyerPhone || '—'}</td>
        <td style="max-width:160px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap" title="${o.productName || ''}">${o.productName || '—'}</td>
        <td style="font-weight:700">${formatPrice(o.amount || 0)}</td>
        <td>${statusBadge(o.status)}</td>
        <td style="color:var(--muted);white-space:nowrap">${formatDate(o.createdAt)}</td>
        <td>
          <button class="btn btn-ghost btn-sm" onclick="viewOrderDetail('${o.id}')" style="padding:.375rem .75rem" aria-label="Voir détails commande">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
          </button>
        </td>
      </tr>`).join('');
  } catch (err) {
    console.error('loadOrdersTable error:', err);
  }
}

// ── Product form: save ────────────────────────────────────────────────────
document.getElementById('productForm').addEventListener('submit', async (e) => {
  e.preventDefault();

  const name      = document.getElementById('pName');
  const pole      = document.getElementById('pPole');
  const price     = document.getElementById('pPrice');
  const shortDesc = document.getElementById('pShortDesc');
  const bullets   = document.getElementById('pBullets');
  const fileUrl   = document.getElementById('pFileUrl');
  let valid = true;

  const checks = [
    { el: name,      err: 'pNameErr',      check: () => name.value.trim().length > 1 },
    { el: pole,      err: 'pPoleErr',      check: () => pole.value !== '' },
    { el: price,     err: 'pPriceErr',     check: () => Number(price.value) >= 50 },
    { el: shortDesc, err: 'pShortDescErr', check: () => shortDesc.value.trim().length > 5 },
    { el: bullets,   err: 'pBulletsErr',   check: () => bullets.value.trim().length > 0 },
    { el: fileUrl,   err: 'pFileUrlErr',   check: () => fileUrl.value.trim().startsWith('http') },
  ];
  checks.forEach(({ el, err, check }) => {
    const errEl = document.getElementById(err);
    if (!check()) { el.classList.add('error'); errEl.classList.add('show'); valid = false; }
    else          { el.classList.remove('error'); errEl.classList.remove('show'); }
  });
  if (!valid) return;

  const btn = document.getElementById('productSubmitBtn');
  btn.classList.add('loading');
  btn.disabled = true;
  document.getElementById('productSubmitText').textContent = 'Sauvegarde…';

  const data = {
    name:        name.value.trim(),
    pole:        pole.value,
    price:       Number(price.value),
    shortDesc:   shortDesc.value.trim(),
    fullDesc:    document.getElementById('pFullDesc').value.trim(),
    bullets:     bullets.value.trim(),
    format:      document.getElementById('pFormat').value,
    fileSize:    document.getElementById('pFileSize').value.trim(),
    fileUrl:     fileUrl.value.trim(),
    previewUrl:  document.getElementById('pPreviewUrl').value.trim(),
    published:   document.getElementById('togglePublished').classList.contains('on'),
    topSell:     document.getElementById('toggleTopSell').classList.contains('on'),
    featured:    document.getElementById('toggleFeatured').classList.contains('on'),
    updatedAt:   serverTimestamp(),
  };

  try {
    const editId = document.getElementById('editProductId').value;
    if (editId) {
      await updateDoc(doc(db, 'products', editId), data);
      showToast('Produit mis à jour avec succès !', 'success');
    } else {
      data.createdAt = serverTimestamp();
      await addDoc(collection(db, 'products'), data);
      showToast('Produit publié avec succès !', 'success');
    }
    resetForm();
    showSection('products');
    loadProductsTable();
  } catch (err) {
    console.error('save product error:', err);
    showToast('Erreur lors de la sauvegarde.', 'error');
  } finally {
    btn.classList.remove('loading');
    btn.disabled = false;
    document.getElementById('productSubmitText').textContent = 'Publier le produit';
  }
});

function resetForm() {
  document.getElementById('productForm').reset();
  document.getElementById('editProductId').value = '';
  document.getElementById('productFormTitle').textContent = 'Ajouter un produit';
  document.getElementById('productSubmitText').textContent = 'Publier le produit';
  // Reset toggles
  document.getElementById('togglePublished').classList.add('on');
  document.getElementById('togglePublished').setAttribute('aria-checked', 'true');
  ['toggleTopSell','toggleFeatured'].forEach(id => {
    document.getElementById(id).classList.remove('on');
    document.getElementById(id).setAttribute('aria-checked', 'false');
  });
}

// Edit product
window.editProduct = async (id) => {
  try {
    const snap = await getDocs(query(collection(db, 'products')));
    const product = snap.docs.find(d => d.id === id);
    if (!product) return;
    const p = product.data();

    document.getElementById('editProductId').value = id;
    document.getElementById('pName').value      = p.name || '';
    document.getElementById('pPole').value      = p.pole || '';
    document.getElementById('pPrice').value     = p.price || '';
    document.getElementById('pShortDesc').value = p.shortDesc || '';
    document.getElementById('pFullDesc').value  = p.fullDesc || '';
    document.getElementById('pBullets').value   = p.bullets || '';
    document.getElementById('pFormat').value    = p.format || 'PDF';
    document.getElementById('pFileSize').value  = p.fileSize || '';
    document.getElementById('pFileUrl').value   = p.fileUrl || '';
    document.getElementById('pPreviewUrl').value = p.previewUrl || '';

    const setToggle = (id, val) => {
      const el = document.getElementById(id);
      el.classList.toggle('on', !!val);
      el.setAttribute('aria-checked', !!val);
    };
    setToggle('togglePublished', p.published !== false);
    setToggle('toggleTopSell',  p.topSell);
    setToggle('toggleFeatured', p.featured);

    document.getElementById('productFormTitle').textContent    = 'Modifier le produit';
    document.getElementById('productSubmitText').textContent   = 'Enregistrer les modifications';
    document.getElementById('pShortDescCount').textContent     = `${(p.shortDesc||'').length} / 120 caractères`;

    showSection('add-product');
  } catch (err) {
    console.error('editProduct error:', err);
    showToast('Erreur lors du chargement du produit.', 'error');
  }
};

// Delete
window.confirmDelete = (id, name) => {
  deleteTargetId = id;
  document.getElementById('deleteMsg').textContent = `Supprimer "${name}" ? Cette action est irréversible.`;
  document.getElementById('deleteOverlay').classList.add('open');
};

document.getElementById('confirmDeleteBtn').addEventListener('click', async () => {
  if (!deleteTargetId) return;
  try {
    await deleteDoc(doc(db, 'products', deleteTargetId));
    window.closeDeleteModal();
    showToast('Produit supprimé.', 'success');
    loadProductsTable();
    loadDashboard();
    deleteTargetId = null;
  } catch (err) {
    console.error('delete error:', err);
    showToast('Erreur lors de la suppression.', 'error');
  }
});

// Order detail
window.viewOrderDetail = async (id) => {
  try {
    const snap = await getDocs(query(collection(db, 'orders')));
    const order = snap.docs.find(d => d.id === id)?.data();
    if (!order) return;

    document.getElementById('orderDetailBody').innerHTML = `
      <div style="display:grid;gap:.875rem">
        ${detailRow('ID Commande', id)}
        ${detailRow('Client', order.buyerName || '—')}
        ${detailRow('Email', order.buyerEmail || '—')}
        ${detailRow('Téléphone', order.buyerPhone || '—')}
        ${detailRow('Produit', order.productName || '—')}
        ${detailRow('Montant', formatPrice(order.amount || 0))}
        ${detailRow('Statut', statusBadge(order.status))}
        ${detailRow('Date', formatDate(order.createdAt))}
        ${order.downloadUrl ? detailRow('Lien téléchargement', `<a href="${order.downloadUrl}" target="_blank" rel="noopener noreferrer" style="color:var(--navy);text-decoration:underline">Voir le fichier</a>`) : ''}
      </div>`;
    document.getElementById('orderDetailOverlay').classList.add('open');
  } catch (err) {
    console.error('viewOrderDetail error:', err);
  }
};

function detailRow(label, value) {
  return `<div style="display:flex;justify-content:space-between;align-items:center;padding:.625rem 0;border-bottom:1px solid var(--border)"><span style="font-size:.85rem;color:var(--muted);font-weight:600">${label}</span><span style="font-size:.875rem;color:var(--text);font-weight:500">${value}</span></div>`;
}

// ── Navigation between sections ───────────────────────────────────────────
document.querySelectorAll('.nav-item[data-section]').forEach(item => {
  item.addEventListener('click', (e) => {
    e.preventDefault();
    const section = item.dataset.section;
    showSection(section);
    if (section === 'products') loadProductsTable();
    if (section === 'orders')   loadOrdersTable();
    if (section === 'dashboard') loadDashboard();
  });
});

// Order filter
document.getElementById('orderStatusFilter')?.addEventListener('change', function() {
  loadOrdersTable(this.value);
});

// Admin products pole filter
document.querySelectorAll('[data-filter-pole]').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('[data-filter-pole]').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    loadProductsTable(btn.dataset.filterPole);
  });
});

// ── Helpers ───────────────────────────────────────────────────────────────
function statusBadge(status) {
  const map = {
    completed: `<span class="status-pill status-success">Complété</span>`,
    accessed:  `<span class="status-pill status-success">Téléchargé</span>`,
    pending:   `<span class="status-pill status-pending">En attente</span>`,
    failed:    `<span class="status-pill status-failed">Échoué</span>`,
    test:      `<span class="status-pill status-info">Test</span>`,
  };
  return map[status] || `<span class="status-pill">${status || '—'}</span>`;
}
