// ─── Product detail page logic ────────────────────────────────────────────
import { supabase, storageUrl } from './supabase-config.js'
import { POLES, formatPrice, buildProductCard, showToast } from './app.js'

let currentProduct = null
let pendingToken   = null

async function loadProduct() {
  const params    = new URLSearchParams(window.location.search)
  const productId = params.get('id')
  if (!productId) { window.location.href = 'boutique.html'; return }

  try {
    const { data, error } = await supabase
      .from('products')
      .select('*')
      .eq('id', productId)
      .eq('published', true)
      .single()

    if (error || !data) { window.location.href = 'boutique.html'; return }
    currentProduct = data
    renderProduct(data)
    loadRelated(data.pole, productId)
  } catch {
    showToast('Erreur lors du chargement du produit.', 'error')
  }
}

function renderProduct(product) {
  document.getElementById('pdLoading').classList.add('hidden')
  document.getElementById('pdContent').classList.remove('hidden')

  document.getElementById('pageTitle').textContent = `${product.name} — XOHO`
  document.querySelector('meta[name="description"]')?.setAttribute('content', product.short_desc || product.name)

  const pole = POLES[product.pole] || { label: product.pole }
  document.querySelector('#breadcrumbPole span').textContent = pole.label
  document.querySelector('#breadcrumbName span').textContent = product.name

  const info   = POLES[product.pole] || { label: product.pole, color: '#64748B', bg: '#F1F5F9' }
  const poleEl = document.getElementById('pdPoleTag')
  poleEl.textContent      = info.label
  poleEl.style.background = info.bg
  poleEl.style.color      = info.color

  document.getElementById('pd-title').textContent    = product.name
  document.getElementById('pdShortDesc').textContent = product.short_desc || ''
  document.getElementById('pdPrice').innerHTML       = `${formatPrice(product.price)} <small>FCFA</small>`
  document.getElementById('stickyPrice').textContent = formatPrice(product.price)
  document.getElementById('buyModalProductName').textContent = product.name
  document.getElementById('buyTotal').textContent = formatPrice(product.price)

  if (product.preview_url) {
    const img = document.getElementById('pdPreviewImg')
    if (img) img.src = storageUrl('previews', product.preview_url)
  }

  const bullets   = (product.bullets || '').split('\n').filter(b => b.trim())
  const bulletsEl = document.getElementById('pdBullets')
  if (bulletsEl) {
    bulletsEl.innerHTML = ''
    bullets.forEach(b => {
      const li  = document.createElement('li')
      const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
      svg.setAttribute('width', '18'); svg.setAttribute('height', '18')
      svg.setAttribute('viewBox', '0 0 24 24'); svg.setAttribute('fill', 'none')
      svg.setAttribute('stroke', 'currentColor'); svg.setAttribute('stroke-width', '2.5')
      const poly = document.createElementNS('http://www.w3.org/2000/svg', 'polyline')
      poly.setAttribute('points', '20 6 9 17 4 12')
      svg.appendChild(poly)
      li.appendChild(svg)
      li.appendChild(document.createTextNode(' ' + b.trim()))
      bulletsEl.appendChild(li)
    })
  }

  const fullDescEl = document.getElementById('pdFullDesc')
  if (fullDescEl) {
    fullDescEl.innerHTML = ''
    const text = product.full_desc || product.short_desc || ''
    text.split('\n').forEach((line, i) => {
      if (i > 0) fullDescEl.appendChild(document.createElement('br'))
      fullDescEl.appendChild(document.createTextNode(line))
    })
  }

  const fileInfoEl = document.getElementById('pdFileInfo')
  if (fileInfoEl) {
    const infos = [
      { label: 'Format',    value: product.format    || 'PDF'      },
      { label: 'Taille',    value: product.file_size || 'N/A'      },
      { label: 'Pôle',      value: info.label                      },
      { label: 'Livraison', value: 'Instantanée'                   },
    ]
    fileInfoEl.innerHTML = ''
    infos.forEach(({ label, value }) => {
      const wrap     = document.createElement('div')
      const labelDiv = document.createElement('div')
      labelDiv.style.cssText = 'font-size:.75rem;color:var(--muted);font-weight:600;text-transform:uppercase;letter-spacing:.06em;margin-bottom:.25rem'
      labelDiv.textContent = label
      const valueDiv = document.createElement('div')
      valueDiv.style.cssText = 'font-weight:600;color:var(--navy)'
      valueDiv.textContent = value
      wrap.appendChild(labelDiv)
      wrap.appendChild(valueDiv)
      fileInfoEl.appendChild(wrap)
    })
  }

  const io = new IntersectionObserver((entries) => {
    entries.forEach(e => { if (e.isIntersecting) { e.target.classList.add('visible'); io.unobserve(e.target) } })
  }, { threshold: 0.1 })
  document.querySelectorAll('.reveal').forEach(el => io.observe(el))
}

async function loadRelated(pole, excludeId) {
  try {
    const { data } = await supabase
      .from('products')
      .select('*')
      .eq('published', true)
      .eq('pole', pole)
      .neq('id', excludeId)
      .limit(3)

    if (data?.length) {
      document.getElementById('relatedSection')?.classList.remove('hidden')
      const grid = document.getElementById('relatedGrid')
      if (grid) grid.innerHTML = data.map(buildProductCard).join('')
    }
  } catch { /* non-critical */ }
}

async function handleBuySubmit(e) {
  e.preventDefault()
  if (!currentProduct) return

  const nameEl  = document.getElementById('buyName')
  const phoneEl = document.getElementById('buyPhone')
  const emailEl = document.getElementById('buyEmail')
  let valid = true

  ;[
    { el: nameEl,  errId: 'buyNameErr',  ok: () => nameEl.value.trim().length > 1 },
    { el: phoneEl, errId: 'buyPhoneErr', ok: () => /^[0-9]{8,}$/.test(phoneEl.value.replace(/\s/g, '')) },
    { el: emailEl, errId: 'buyEmailErr', ok: () => !emailEl.value || /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(emailEl.value.trim()) },
  ].forEach(({ el, errId, ok }) => {
    const errEl = document.getElementById(errId)
    if (!ok()) { el.classList.add('error'); errEl?.classList.add('show'); valid = false }
    else        { el.classList.remove('error'); errEl?.classList.remove('show') }
  })

  if (!valid) return

  const btn = document.getElementById('buySubmitBtn')
  btn.disabled  = true
  btn.innerHTML = `<div class="spinner-full"></div> Traitement en cours…`

  try {
    // Créer la commande dans Supabase
    const { data: order, error } = await supabase
      .from('orders')
      .insert({
        product_id:   currentProduct.id,
        product_name: currentProduct.name,
        amount:       currentProduct.price,
        buyer_name:   nameEl.value.trim(),
        buyer_phone:  phoneEl.value.trim(),
        buyer_email:  emailEl.value.trim().toLowerCase(),
        status:       'pending',
      })
      .select()
      .single()

    if (error) throw new Error(error.message)
    pendingToken = order.download_token

    // Ouvrir Kkiapay
    if (typeof openKkiapayWidget === 'function') {
      const isProduction = window.location.hostname !== 'localhost' &&
                           !window.location.hostname.startsWith('127.')
      openKkiapayWidget({
        amount:   currentProduct.price,
        api_key:  'VOTRE_CLE_PUBLIQUE_KKIAPAY', // ⚠️ Remplacez avec votre clé Kkiapay
        sandbox:  !isProduction,
        phone:    phoneEl.value.trim(),
        name:     nameEl.value.trim(),
        email:    emailEl.value.trim(),
        data:     JSON.stringify({ token: order.download_token }),
        callback: `${window.location.origin}/succes.html?token=${order.download_token}`,
      })
    } else {
      showToast('Le module de paiement n\'est pas chargé. Rechargez la page.', 'error')
    }
  } catch (err) {
    showToast(err.message || 'Une erreur est survenue.', 'error')
  } finally {
    btn.disabled  = false
    btn.innerHTML = `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M5 12h14M12 5l7 7-7 7"/></svg> Payer maintenant`
  }
}

// Callback Kkiapay après paiement réussi
const KKIAPAY_ORIGINS = ['https://cdn.kkiapay.me', 'https://api.kkiapay.me']
window.addEventListener('message', async (e) => {
  if (!KKIAPAY_ORIGINS.includes(e.origin)) return
  if (e.data?.event === 'kkiapay.payment.success' && pendingToken) {
    const txid = e.data?.data?.transactionId || ''
    try {
      await supabase
        .from('orders')
        .update({ status: 'completed', kkiapay_txid: txid })
        .eq('download_token', pendingToken)
    } catch { /* ignore — succes.js handle */ }
    window.location.href = `succes.html?token=${pendingToken}`
  }
})

document.addEventListener('DOMContentLoaded', () => {
  loadProduct()
  document.getElementById('buyForm')?.addEventListener('submit', handleBuySubmit)

  const backBtn = document.getElementById('backBtn')
  if (backBtn) { backBtn.style.display = 'inline-flex'; backBtn.addEventListener('click', () => history.back()) }

  document.querySelectorAll('.form-input').forEach(input => {
    input.addEventListener('input', () => {
      input.classList.remove('error')
      document.getElementById(input.id + 'Err')?.classList.remove('show')
    })
  })
})
