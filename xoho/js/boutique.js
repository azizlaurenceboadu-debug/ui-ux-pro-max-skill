// ─── Catalog page logic ───────────────────────────────────────────────────
import { db } from './firebase-config.js';
import {
  collection, getDocs, query, where, orderBy
} from 'https://www.gstatic.com/firebasejs/10.12.0/firebase-firestore.js';
import { buildProductCard, formatPrice, showToast } from './app.js';

let allProducts = [];
let currentPole = 'all';
let currentSort = 'default';
let searchQuery = '';

// ── Load all published products ───────────────────────────────────────────
async function loadProducts() {
  const grid = document.getElementById('productsGrid');
  if (!grid) return;

  // Show skeletons
  grid.innerHTML = Array(6).fill(0).map(() => `
    <div class="product-card" style="pointer-events:none" aria-busy="true">
      <div class="skeleton" style="height:160px;border-radius:0"></div>
      <div class="product-card-body" style="gap:.75rem;display:flex;flex-direction:column">
        <div class="skeleton" style="height:20px;width:60%"></div>
        <div class="skeleton" style="height:16px;width:100%"></div>
        <div class="skeleton" style="height:16px;width:80%"></div>
        <div class="skeleton" style="height:40px;margin-top:.5rem"></div>
      </div>
    </div>`).join('');

  try {
    const q = query(
      collection(db, 'products'),
      where('published', '==', true),
      orderBy('createdAt', 'desc')
    );
    const snap = await getDocs(q);
    allProducts = snap.docs.map(d => ({ id: d.id, ...d.data() }));

    // Check URL params for pre-selected pole
    const params = new URLSearchParams(window.location.search);
    const urlPole = params.get('pole');
    if (urlPole && urlPole !== 'all') {
      currentPole = urlPole;
      const btn = document.querySelector(`[data-pole="${urlPole}"]`);
      if (btn) {
        document.querySelectorAll('.filter-pill').forEach(b => {
          b.classList.remove('active');
          b.setAttribute('aria-pressed', 'false');
        });
        btn.classList.add('active');
        btn.setAttribute('aria-pressed', 'true');
      }
    }

    renderProducts();
  } catch (err) {
    console.error('loadProducts error:', err);
    grid.innerHTML = `<div style="text-align:center;padding:3rem;color:var(--muted);grid-column:1/-1">
      <p>Impossible de charger le catalogue. Veuillez réessayer.</p>
      <button onclick="location.reload()" class="btn btn-outline btn-sm" style="margin-top:1rem">Réessayer</button>
    </div>`;
  }
}

// ── Filter + sort + search ────────────────────────────────────────────────
function getFilteredProducts() {
  let products = [...allProducts];

  // Pole filter
  if (currentPole !== 'all') {
    products = products.filter(p => p.pole === currentPole);
  }

  // Search
  if (searchQuery.trim()) {
    const q = searchQuery.toLowerCase();
    products = products.filter(p =>
      p.name.toLowerCase().includes(q) ||
      (p.shortDesc || '').toLowerCase().includes(q) ||
      (p.pole || '').toLowerCase().includes(q)
    );
  }

  // Sort
  if (currentSort === 'price-asc')  products.sort((a, b) => a.price - b.price);
  if (currentSort === 'price-desc') products.sort((a, b) => b.price - a.price);
  if (currentSort === 'newest')     products.sort((a, b) => (b.createdAt?.seconds || 0) - (a.createdAt?.seconds || 0));

  return products;
}

// ── Render products grid ──────────────────────────────────────────────────
function renderProducts() {
  const grid   = document.getElementById('productsGrid');
  const empty  = document.getElementById('emptyState');
  const count  = document.getElementById('resultsCount');
  if (!grid) return;

  const products = getFilteredProducts();

  if (products.length === 0) {
    grid.innerHTML = '';
    grid.setAttribute('aria-busy', 'false');
    empty.classList.remove('hidden');
    count.textContent = 'Aucun résultat';
    return;
  }

  empty.classList.add('hidden');
  count.textContent = `${products.length} document${products.length > 1 ? 's' : ''}`;
  grid.setAttribute('aria-busy', 'false');
  grid.innerHTML = products.map(buildProductCard).join('');

  // Scroll reveal
  const io = new IntersectionObserver((entries) => {
    entries.forEach(e => { if (e.isIntersecting) { e.target.classList.add('visible'); io.unobserve(e.target); } });
  }, { threshold: 0.08 });
  grid.querySelectorAll('.product-card').forEach((c, i) => {
    c.classList.add('reveal');
    c.style.transitionDelay = `${i * 0.05}s`;
    io.observe(c);
  });
}

// ── Event listeners ───────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  loadProducts();

  // Filter pills
  document.querySelectorAll('.filter-pill[data-pole]').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.filter-pill[data-pole]').forEach(b => {
        b.classList.remove('active');
        b.setAttribute('aria-pressed', 'false');
      });
      btn.classList.add('active');
      btn.setAttribute('aria-pressed', 'true');
      currentPole = btn.dataset.pole;
      renderProducts();
    });
  });

  // Sort
  const sortSelect = document.getElementById('sortSelect');
  if (sortSelect) {
    sortSelect.addEventListener('change', () => {
      currentSort = sortSelect.value;
      renderProducts();
    });
  }

  // Search
  const searchInput = document.getElementById('searchInput');
  if (searchInput) {
    let debounceTimer;
    searchInput.addEventListener('input', () => {
      clearTimeout(debounceTimer);
      debounceTimer = setTimeout(() => {
        searchQuery = searchInput.value;
        renderProducts();
      }, 300);
    });
  }

  // Admin product filter pills in admin panel
  document.querySelectorAll('[data-filter-pole]').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('[data-filter-pole]').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
    });
  });
});
