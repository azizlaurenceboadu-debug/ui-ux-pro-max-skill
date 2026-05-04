// ─── Shared utilities used across all pages ───────────────────────────────
import { db } from './firebase-config.js';
import {
  collection, getDocs, query, where, orderBy, limit
} from 'https://www.gstatic.com/firebasejs/10.12.0/firebase-firestore.js';

// ── Toast notifications ──────────────────────────────────────────────────
export function showToast(message, type = 'info', duration = 4000) {
  const stack = document.getElementById('toastStack');
  if (!stack) return;

  const icons = {
    success: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#10B981" stroke-width="2.5" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>`,
    error:   `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#DC2626" stroke-width="2.5" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>`,
    info:    `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#1A2B6B" stroke-width="2.5" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>`,
  };

  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  toast.setAttribute('role', 'status');
  toast.innerHTML = `${icons[type] || icons.info}<span>${message}</span>`;
  stack.appendChild(toast);

  setTimeout(() => {
    toast.classList.add('hiding');
    toast.addEventListener('animationend', () => toast.remove(), { once: true });
  }, duration);
}

// ── Product helpers ───────────────────────────────────────────────────────
export const POLES = {
  administratif: { label: 'Pôle Administratif', color: '#4F46E5', bg: '#EEF2FF', tagClass: 'tag-admin' },
  academique:    { label: 'Pôle Académique',    color: '#16A34A', bg: '#F0FDF4', tagClass: 'tag-academic' },
  citoyen:       { label: 'Pôle Citoyen',       color: '#EA580C', bg: '#FFF7ED', tagClass: 'tag-citizen' },
  business:      { label: 'Pôle Business',      color: '#D97706', bg: '#FFFBEB', tagClass: 'tag-business' },
  'vie-pratique': { label: 'Vie Pratique',      color: '#0284C7', bg: '#F0F9FF', tagClass: 'tag-practical' },
};

export function formatPrice(amount) {
  return new Intl.NumberFormat('fr-FR').format(amount) + ' FCFA';
}

export function formatDate(ts) {
  if (!ts) return '—';
  const d = ts.toDate ? ts.toDate() : new Date(ts);
  return d.toLocaleDateString('fr-FR', { day: '2-digit', month: 'short', year: 'numeric' });
}

// ── Build product card HTML ───────────────────────────────────────────────
export function buildProductCard(product) {
  const pole = POLES[product.pole] || { label: product.pole, color: '#64748B', bg: '#F1F5F9', tagClass: '' };
  const docIcon = `<svg class="product-thumb-icon" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,.22)" stroke-width="1.2" aria-hidden="true"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>`;

  return `
    <a href="produit.html?id=${product.id}" class="product-card" aria-label="${product.name} — ${formatPrice(product.price)}">
      <div class="product-card-thumb">
        ${product.topSell ? '<span class="product-top-badge" aria-label="Top vente">⭐ Top vente</span>' : ''}
        ${docIcon}
        <span class="product-price-badge" aria-hidden="true">${formatPrice(product.price)}</span>
      </div>
      <div class="product-card-body">
        <span class="pole-tag ${pole.tagClass}" style="background:${pole.bg};color:${pole.color}">${pole.label}</span>
        <h3 class="product-title">${product.name}</h3>
        <p class="product-desc">${product.shortDesc || ''}</p>
        <div class="product-footer">
          <div class="product-price">${formatPrice(product.price)} <small>FCFA</small></div>
          <button class="product-cta" aria-label="Acheter ${product.name}">Acheter</button>
        </div>
      </div>
    </a>`;
}

// ── Load top selling products (used on homepage) ──────────────────────────
export async function loadTopSales(containerId, maxItems = 3) {
  const container = document.getElementById(containerId);
  if (!container) return;

  try {
    const q = query(
      collection(db, 'products'),
      where('published', '==', true),
      where('topSell', '==', true),
      orderBy('createdAt', 'desc'),
      limit(maxItems)
    );
    const snap = await getDocs(q);
    const products = snap.docs.map(d => ({ id: d.id, ...d.data() }));

    if (products.length === 0) {
      // Fallback: show any 3 published products
      const fallbackQ = query(
        collection(db, 'products'),
        where('published', '==', true),
        orderBy('createdAt', 'desc'),
        limit(maxItems)
      );
      const fallbackSnap = await getDocs(fallbackQ);
      products.push(...fallbackSnap.docs.map(d => ({ id: d.id, ...d.data() })));
    }

    container.innerHTML = products.map(buildProductCard).join('');

    // Re-observe for scroll animation
    const io = new IntersectionObserver((entries) => {
      entries.forEach(e => { if (e.isIntersecting) { e.target.classList.add('visible'); io.unobserve(e.target); } });
    }, { threshold: 0.1 });
    container.querySelectorAll('.product-card').forEach(c => {
      c.classList.add('reveal');
      io.observe(c);
    });
  } catch (err) {
    console.error('loadTopSales error:', err);
    container.innerHTML = `<div style="text-align:center;padding:2rem;color:var(--muted);grid-column:1/-1">Impossible de charger les produits.</div>`;
  }
}

// ── Init shared page behaviours ───────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  // Load top sales on homepage
  if (document.getElementById('topSalesGrid')) {
    loadTopSales('topSalesGrid', 3);
  }
});
