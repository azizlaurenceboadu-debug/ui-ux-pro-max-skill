// ─── Catalog page logic ───────────────────────────────────────────────────
import { buildProductCard, showToast } from './app.js';

let allProducts  = [];
let currentPole  = 'all';
let currentSort  = 'default';
let searchQuery  = '';

async function loadProducts() {
  const grid = document.getElementById('productsGrid');
  if (!grid) return;

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
    const res  = await fetch('api/products.php');
    const data = await res.json();
    if (!res.ok) throw new Error(data.error || 'Erreur');
    allProducts = data;

    const params  = new URLSearchParams(window.location.search);
    const urlPole = params.get('pole');
    if (urlPole && urlPole !== 'all') {
      currentPole = urlPole;
      const btn = document.querySelector(`[data-pole="${urlPole}"]`);
      if (btn) {
        document.querySelectorAll('.filter-pill').forEach(b => {
          b.classList.remove('active'); b.setAttribute('aria-pressed', 'false');
        });
        btn.classList.add('active'); btn.setAttribute('aria-pressed', 'true');
      }
    }
    renderProducts();
  } catch {
    grid.innerHTML = `<div style="text-align:center;padding:3rem;color:var(--muted);grid-column:1/-1">
      <p>Impossible de charger le catalogue. Veuillez réessayer.</p>
      <button onclick="location.reload()" class="btn btn-outline btn-sm" style="margin-top:1rem">Réessayer</button>
    </div>`;
  }
}

function getFilteredProducts() {
  let products = [...allProducts];
  if (currentPole !== 'all') products = products.filter(p => p.pole === currentPole);
  if (searchQuery.trim()) {
    const q = searchQuery.toLowerCase();
    products = products.filter(p =>
      p.name.toLowerCase().includes(q) ||
      (p.short_desc || '').toLowerCase().includes(q) ||
      (p.pole || '').toLowerCase().includes(q)
    );
  }
  if (currentSort === 'price-asc')  products.sort((a, b) => a.price - b.price);
  if (currentSort === 'price-desc') products.sort((a, b) => b.price - a.price);
  if (currentSort === 'newest')     products.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
  return products;
}

function renderProducts() {
  const grid  = document.getElementById('productsGrid');
  const empty = document.getElementById('emptyState');
  const count = document.getElementById('resultsCount');
  if (!grid) return;

  const products = getFilteredProducts();

  if (products.length === 0) {
    grid.innerHTML = ''; grid.setAttribute('aria-busy', 'false');
    empty?.classList.remove('hidden');
    if (count) count.textContent = 'Aucun résultat';
    return;
  }

  empty?.classList.add('hidden');
  if (count) count.textContent = `${products.length} document${products.length > 1 ? 's' : ''}`;
  grid.setAttribute('aria-busy', 'false');
  grid.innerHTML = products.map(buildProductCard).join('');

  const io = new IntersectionObserver((entries) => {
    entries.forEach(e => { if (e.isIntersecting) { e.target.classList.add('visible'); io.unobserve(e.target); } });
  }, { threshold: 0.08 });
  grid.querySelectorAll('.product-card').forEach((c, i) => {
    c.classList.add('reveal'); c.style.transitionDelay = `${i * 0.05}s`; io.observe(c);
  });
}

document.addEventListener('DOMContentLoaded', () => {
  loadProducts();

  document.querySelectorAll('.filter-pill[data-pole]').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.filter-pill[data-pole]').forEach(b => {
        b.classList.remove('active'); b.setAttribute('aria-pressed', 'false');
      });
      btn.classList.add('active'); btn.setAttribute('aria-pressed', 'true');
      currentPole = btn.dataset.pole;
      renderProducts();
    });
  });

  const sortSelect = document.getElementById('sortSelect');
  if (sortSelect) sortSelect.addEventListener('change', () => { currentSort = sortSelect.value; renderProducts(); });

  const searchInput = document.getElementById('searchInput');
  if (searchInput) {
    let timer;
    searchInput.addEventListener('input', () => {
      clearTimeout(timer);
      timer = setTimeout(() => { searchQuery = searchInput.value; renderProducts(); }, 300);
    });
  }
});
