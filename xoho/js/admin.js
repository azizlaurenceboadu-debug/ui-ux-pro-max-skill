// ─── Admin panel logic ────────────────────────────────────────────────────
import { supabase, storageUrl } from './supabase-config.js'
import { POLES, formatPrice, formatDate, showToast } from './app.js'

let deleteTargetId = null

// ── Auth ──────────────────────────────────────────────────────────────────
supabase.auth.onAuthStateChange((event, session) => {
  if (session?.user) {
    showDashboard(session.user)
  } else {
    document.getElementById('loginScreen').classList.remove('hidden')
    document.getElementById('dashboardScreen').classList.add('hidden')
  }
})

function showDashboard(user) {
  document.getElementById('loginScreen').classList.add('hidden')
  document.getElementById('dashboardScreen').classList.remove('hidden')
  document.getElementById('adminUserEmail').textContent = user.email || ''
  document.getElementById('adminAvatar').textContent = (user.email || 'A').charAt(0).toUpperCase()
  loadDashboard()
}

// ── Login ─────────────────────────────────────────────────────────────────
document.getElementById('loginForm').addEventListener('submit', async (e) => {
  e.preventDefault()
  const emailEl    = document.getElementById('loginEmail')
  const pwdEl      = document.getElementById('loginPassword')
  const globalErr  = document.getElementById('loginGlobalErr')
  const btn        = document.getElementById('loginBtn')
  let valid = true

  if (!emailEl.value.trim() || !/\S+@\S+\.\S+/.test(emailEl.value)) {
    document.getElementById('loginEmailErr').classList.add('show'); emailEl.classList.add('error'); valid = false
  } else { document.getElementById('loginEmailErr').classList.remove('show'); emailEl.classList.remove('error') }
  if (!pwdEl.value) {
    document.getElementById('loginPwdErr').classList.add('show'); pwdEl.classList.add('error'); valid = false
  } else { document.getElementById('loginPwdErr').classList.remove('show'); pwdEl.classList.remove('error') }
  if (!valid) return

  btn.classList.add('loading'); btn.innerHTML = `<div class="spinner-full"></div> Connexion…`; btn.disabled = true
  globalErr.classList.remove('show')

  const { data, error } = await supabase.auth.signInWithPassword({
    email:    emailEl.value.trim(),
    password: pwdEl.value,
  })

  if (error) {
    globalErr.textContent = error.message.includes('Invalid') ? 'Email ou mot de passe incorrect.' : error.message
    globalErr.classList.add('show')
    btn.classList.remove('loading'); btn.innerHTML = 'Se connecter'; btn.disabled = false
  }
  // onAuthStateChange handles the rest
})

// ── Logout ────────────────────────────────────────────────────────────────
document.getElementById('logoutBtn').addEventListener('click', () => supabase.auth.signOut())

// ── Dashboard ─────────────────────────────────────────────────────────────
async function loadDashboard() {
  try {
    const [{ count: productCount }, { data: orders }] = await Promise.all([
      supabase.from('products').select('*', { count: 'exact', head: true }).eq('published', true),
      supabase.from('orders').select('*').order('created_at', { ascending: false }),
    ])

    const allOrders  = orders || []
    const completed  = allOrders.filter(o => ['completed','accessed'].includes(o.status))
    const revenue    = completed.reduce((s, o) => s + (o.amount || 0), 0)
    const successRate = allOrders.length ? Math.round((completed.length / allOrders.length) * 100) : 0
    const pending     = allOrders.filter(o => o.status === 'pending')

    document.getElementById('statProducts').textContent = productCount || 0
    document.getElementById('statOrders').textContent   = allOrders.length
    document.getElementById('statRevenue').textContent  = formatPrice(revenue)
    document.getElementById('statSuccess').textContent  = successRate + '%'

    const badge = document.getElementById('pendingBadge')
    if (pending.length > 0) { badge.textContent = pending.length; badge.style.display = 'inline' }

    renderRecentOrders(allOrders.slice(0, 10))
  } catch (err) { console.error('loadDashboard:', err) }
}

function renderRecentOrders(orders) {
  const tbody = document.getElementById('recentOrdersBody')
  if (!orders.length) {
    tbody.innerHTML = `<tr><td colspan="5" style="text-align:center;padding:2rem;color:var(--muted)">Aucune commande pour le moment.</td></tr>`
    return
  }
  tbody.innerHTML = orders.map(o => `
    <tr>
      <td><strong>${o.buyer_name || '—'}</strong><br/><small style="color:var(--muted)">${o.buyer_email || ''}</small></td>
      <td>${o.product_name || '—'}</td>
      <td style="font-weight:700">${formatPrice(o.amount || 0)}</td>
      <td>${statusBadge(o.status)}</td>
      <td style="color:var(--muted)">${formatDate(o.created_at)}</td>
    </tr>`).join('')
}

// ── Products table ────────────────────────────────────────────────────────
async function loadProductsTable(poleFilter = 'all') {
  const tbody = document.getElementById('productsTableBody')
  tbody.innerHTML = `<tr><td colspan="6" style="text-align:center;padding:2rem;color:var(--muted)">Chargement…</td></tr>`

  let query = supabase.from('products').select('*').order('created_at', { ascending: false })
  if (poleFilter !== 'all') query = query.eq('pole', poleFilter)

  const { data: products, error } = await query
  if (error) { tbody.innerHTML = `<tr><td colspan="6" style="text-align:center;padding:2rem;color:#DC2626">Erreur de chargement.</td></tr>`; return }

  if (!products?.length) {
    tbody.innerHTML = `<tr><td colspan="6" style="text-align:center;padding:2rem;color:var(--muted)">Aucun produit trouvé.</td></tr>`
    return
  }

  tbody.innerHTML = products.map(p => {
    const pole = POLES[p.pole] || { label: p.pole, color: '#64748B', bg: '#F1F5F9' }
    return `
      <tr>
        <td><strong style="color:var(--navy)">${p.name}</strong></td>
        <td><span class="status-pill" style="background:${pole.bg};color:${pole.color}">${pole.label}</span></td>
        <td style="font-weight:700">${formatPrice(p.price)}</td>
        <td style="text-align:center">${p.top_sell ? '⭐' : '—'}</td>
        <td>${p.published ? '<span class="status-pill status-success">Publié</span>' : '<span class="status-pill status-pending">Brouillon</span>'}</td>
        <td>
          <div style="display:flex;gap:.375rem">
            <button class="btn btn-ghost btn-sm" onclick="editProduct('${p.id}')" style="padding:.375rem .75rem">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
            </button>
            <button class="btn btn-sm" onclick="confirmDelete('${p.id}','${p.name.replace(/'/g,"\\'")}') " style="padding:.375rem .75rem;color:#DC2626;background:#FEF2F2;border-radius:var(--r-sm)">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a1 1 0 011-1h4a1 1 0 011 1v2"/></svg>
            </button>
            <a href="produit.html?id=${p.id}" class="btn btn-ghost btn-sm" target="_blank" style="padding:.375rem .75rem">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M18 13v6a2 2 0 01-2 2H5a2 2 0 01-2-2V8a2 2 0 012-2h6"/><polyline points="15 3 21 3 21 9"/><line x1="10" y1="14" x2="21" y2="3"/></svg>
            </a>
          </div>
        </td>
      </tr>`
  }).join('')
}

// ── Orders table ──────────────────────────────────────────────────────────
async function loadOrdersTable(statusFilter = 'all') {
  const tbody = document.getElementById('ordersTableBody')
  tbody.innerHTML = `<tr><td colspan="8" style="text-align:center;padding:2rem;color:var(--muted)">Chargement…</td></tr>`

  let query = supabase.from('orders').select('*').order('created_at', { ascending: false })
  if (statusFilter !== 'all') query = query.eq('status', statusFilter)

  const { data: orders } = await query
  if (!orders?.length) {
    tbody.innerHTML = `<tr><td colspan="8" style="text-align:center;padding:2rem;color:var(--muted)">Aucune commande.</td></tr>`
    return
  }

  tbody.innerHTML = orders.map(o => `
    <tr>
      <td style="font-family:monospace;font-size:.75rem;color:var(--muted)">${o.id.substring(0,8)}…</td>
      <td><strong>${o.buyer_name || '—'}</strong><br/><small style="color:var(--muted)">${o.buyer_email || ''}</small></td>
      <td>${o.buyer_phone || '—'}</td>
      <td style="max-width:160px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${o.product_name || '—'}</td>
      <td style="font-weight:700">${formatPrice(o.amount || 0)}</td>
      <td>${statusBadge(o.status)}</td>
      <td style="color:var(--muted);white-space:nowrap">${formatDate(o.created_at)}</td>
      <td>
        <button class="btn btn-ghost btn-sm" onclick="viewOrderDetail('${o.id}')" style="padding:.375rem .75rem">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
        </button>
      </td>
    </tr>`).join('')
}

// ── Product form ──────────────────────────────────────────────────────────
document.getElementById('productForm').addEventListener('submit', async (e) => {
  e.preventDefault()

  const fields = {
    name:      document.getElementById('pName'),
    pole:      document.getElementById('pPole'),
    price:     document.getElementById('pPrice'),
    shortDesc: document.getElementById('pShortDesc'),
    bullets:   document.getElementById('pBullets'),
    filePath:  document.getElementById('pFileUrl'),
  }
  let valid = true
  ;[
    { el: fields.name,      errId: 'pNameErr',      ok: () => fields.name.value.trim().length > 1 },
    { el: fields.pole,      errId: 'pPoleErr',      ok: () => fields.pole.value !== '' },
    { el: fields.price,     errId: 'pPriceErr',     ok: () => Number(fields.price.value) >= 50 },
    { el: fields.shortDesc, errId: 'pShortDescErr', ok: () => fields.shortDesc.value.trim().length > 5 },
    { el: fields.bullets,   errId: 'pBulletsErr',   ok: () => fields.bullets.value.trim().length > 0 },
    { el: fields.filePath,  errId: 'pFileUrlErr',   ok: () => fields.filePath.value.trim().length > 0 },
  ].forEach(({ el, errId, ok }) => {
    const errEl = document.getElementById(errId)
    if (!ok()) { el.classList.add('error'); errEl?.classList.add('show'); valid = false }
    else        { el.classList.remove('error'); errEl?.classList.remove('show') }
  })
  if (!valid) return

  const btn = document.getElementById('productSubmitBtn')
  btn.classList.add('loading'); btn.disabled = true
  document.getElementById('productSubmitText').textContent = 'Sauvegarde…'

  const payload = {
    name:        fields.name.value.trim(),
    pole:        fields.pole.value,
    price:       Number(fields.price.value),
    short_desc:  fields.shortDesc.value.trim(),
    full_desc:   document.getElementById('pFullDesc').value.trim(),
    bullets:     fields.bullets.value.trim(),
    format:      document.getElementById('pFormat').value,
    file_size:   document.getElementById('pFileSize').value.trim(),
    file_path:   fields.filePath.value.trim(),
    preview_url: document.getElementById('pPreviewUrl').value.trim(),
    published:   document.getElementById('togglePublished').classList.contains('on'),
    top_sell:    document.getElementById('toggleTopSell').classList.contains('on'),
    featured:    document.getElementById('toggleFeatured').classList.contains('on'),
  }

  try {
    const editId = document.getElementById('editProductId').value
    let error

    if (editId) {
      ;({ error } = await supabase.from('products').update(payload).eq('id', editId))
    } else {
      ;({ error } = await supabase.from('products').insert(payload))
    }

    if (error) throw new Error(error.message)
    showToast(editId ? 'Produit mis à jour !' : 'Produit publié !', 'success')
    resetForm(); showSection('products'); loadProductsTable()
  } catch (err) {
    showToast('Erreur : ' + err.message, 'error')
  } finally {
    btn.classList.remove('loading'); btn.disabled = false
    document.getElementById('productSubmitText').textContent = 'Publier le produit'
  }
})

function resetForm() {
  document.getElementById('productForm').reset()
  document.getElementById('editProductId').value = ''
  document.getElementById('productFormTitle').textContent  = 'Ajouter un produit'
  document.getElementById('productSubmitText').textContent = 'Publier le produit'
  document.getElementById('togglePublished').classList.add('on')
  document.getElementById('togglePublished').setAttribute('aria-checked', 'true')
  ;['toggleTopSell','toggleFeatured'].forEach(id => {
    document.getElementById(id).classList.remove('on')
    document.getElementById(id).setAttribute('aria-checked', 'false')
  })
}

window.editProduct = async (id) => {
  const { data: p, error } = await supabase.from('products').select('*').eq('id', id).single()
  if (error || !p) { showToast('Produit introuvable.', 'error'); return }

  document.getElementById('editProductId').value   = p.id
  document.getElementById('pName').value           = p.name || ''
  document.getElementById('pPole').value           = p.pole || ''
  document.getElementById('pPrice').value          = p.price || ''
  document.getElementById('pShortDesc').value      = p.short_desc || ''
  document.getElementById('pFullDesc').value       = p.full_desc || ''
  document.getElementById('pBullets').value        = p.bullets || ''
  document.getElementById('pFormat').value         = p.format || 'PDF'
  document.getElementById('pFileSize').value       = p.file_size || ''
  document.getElementById('pFileUrl').value        = p.file_path || ''
  document.getElementById('pPreviewUrl').value     = p.preview_url || ''
  document.getElementById('pShortDescCount').textContent = `${(p.short_desc||'').length} / 120 caractères`

  const setToggle = (id, val) => {
    const el = document.getElementById(id)
    el.classList.toggle('on', !!val); el.setAttribute('aria-checked', String(!!val))
  }
  setToggle('togglePublished', p.published)
  setToggle('toggleTopSell',   p.top_sell)
  setToggle('toggleFeatured',  p.featured)

  document.getElementById('productFormTitle').textContent  = 'Modifier le produit'
  document.getElementById('productSubmitText').textContent = 'Enregistrer les modifications'
  showSection('add-product')
}

window.confirmDelete = (id, name) => {
  deleteTargetId = id
  document.getElementById('deleteMsg').textContent = `Supprimer "${name}" ? Cette action est irréversible.`
  document.getElementById('deleteOverlay').classList.add('open')
}

document.getElementById('confirmDeleteBtn').addEventListener('click', async () => {
  if (!deleteTargetId) return
  const { error } = await supabase.from('products').delete().eq('id', deleteTargetId)
  if (error) { showToast('Erreur : ' + error.message, 'error'); return }
  window.closeDeleteModal?.()
  showToast('Produit supprimé.', 'success')
  loadProductsTable(); loadDashboard(); deleteTargetId = null
})

window.viewOrderDetail = async (id) => {
  const { data: o, error } = await supabase.from('orders').select('*').eq('id', id).single()
  if (error || !o) return

  document.getElementById('orderDetailBody').innerHTML = `
    <div style="display:grid;gap:.875rem">
      ${detailRow('ID Commande', o.id.substring(0,8) + '…')}
      ${detailRow('Client', o.buyer_name || '—')}
      ${detailRow('Email', o.buyer_email || '—')}
      ${detailRow('Téléphone', o.buyer_phone || '—')}
      ${detailRow('Produit', o.product_name || '—')}
      ${detailRow('Montant', formatPrice(o.amount || 0))}
      ${detailRow('Statut', statusBadge(o.status))}
      ${detailRow('Date', formatDate(o.created_at))}
      ${o.kkiapay_txid ? detailRow('Transaction Kkiapay', o.kkiapay_txid) : ''}
    </div>`
  document.getElementById('orderDetailOverlay').classList.add('open')
}

function detailRow(label, value) {
  return `<div style="display:flex;justify-content:space-between;align-items:center;padding:.625rem 0;border-bottom:1px solid var(--border)"><span style="font-size:.85rem;color:var(--muted);font-weight:600">${label}</span><span style="font-size:.875rem;color:var(--text);font-weight:500">${value}</span></div>`
}

// ── Navigation ────────────────────────────────────────────────────────────
document.querySelectorAll('.nav-item[data-section]').forEach(item => {
  item.addEventListener('click', (e) => {
    e.preventDefault()
    const section = item.dataset.section
    showSection(section)
    if (section === 'products')  loadProductsTable()
    if (section === 'orders')    loadOrdersTable()
    if (section === 'dashboard') loadDashboard()
  })
})

document.getElementById('orderStatusFilter')?.addEventListener('change', function() {
  loadOrdersTable(this.value)
})

document.querySelectorAll('[data-filter-pole]').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('[data-filter-pole]').forEach(b => b.classList.remove('active'))
    btn.classList.add('active')
    loadProductsTable(btn.dataset.filterPole)
  })
})

function statusBadge(status) {
  const map = {
    completed: `<span class="status-pill status-success">Complété</span>`,
    accessed:  `<span class="status-pill status-success">Téléchargé</span>`,
    pending:   `<span class="status-pill status-pending">En attente</span>`,
    failed:    `<span class="status-pill status-failed">Échoué</span>`,
  }
  return map[status] || `<span class="status-pill">${status || '—'}</span>`
}

// ── Upload fichiers vers Supabase Storage ─────────────────────────────────
async function uploadToStorage(file, bucket) {
  const ext  = file.name.split('.').pop()
  const path = `${crypto.randomUUID()}.${ext}`
  const { error } = await supabase.storage.from(bucket).upload(path, file, { upsert: false })
  if (error) throw new Error(error.message)
  return path
}

document.getElementById('pFileInput')?.addEventListener('change', async function() {
  const file     = this.files?.[0]
  const statusEl = document.getElementById('pFileStatus')
  if (!file) return
  statusEl.textContent = 'Envoi en cours…'
  try {
    const path = await uploadToStorage(file, 'products')
    document.getElementById('pFileUrl').value = path
    statusEl.textContent = `✅ ${(file.size / 1024 / 1024).toFixed(2)} Mo`
  } catch (err) {
    statusEl.textContent = '❌ ' + err.message
    showToast('Erreur upload : ' + err.message, 'error')
  }
})

document.getElementById('pPreviewInput')?.addEventListener('change', async function() {
  const file     = this.files?.[0]
  const statusEl = document.getElementById('pPreviewStatus')
  if (!file) return
  statusEl.textContent = 'Envoi en cours…'
  try {
    const path = await uploadToStorage(file, 'previews')
    document.getElementById('pPreviewUrl').value = path
    statusEl.textContent = '✅ Image uploadée'
  } catch (err) {
    statusEl.textContent = '❌ ' + err.message
    showToast('Erreur upload : ' + err.message, 'error')
  }
})
