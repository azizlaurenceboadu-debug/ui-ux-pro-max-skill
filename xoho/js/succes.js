// ─── Success / Download page logic ───────────────────────────────────────
import { supabase } from './supabase-config.js'

async function init() {
  const params   = new URLSearchParams(window.location.search)
  const token    = params.get('token')

  const loadEl    = document.getElementById('loadingState')
  const successEl = document.getElementById('successState')
  const errorEl   = document.getElementById('errorState')

  if (!token) {
    show(errorEl, loadEl)
    document.getElementById('errorMsg').textContent = 'Lien invalide. Contactez le support.'
    return
  }

  try {
    const { data: order, error } = await supabase
      .from('orders')
      .select('*, products(file_path, format, file_size)')
      .eq('download_token', token)
      .single()

    if (error || !order) {
      show(errorEl, loadEl)
      document.getElementById('errorMsg').textContent =
        'Commande introuvable. Si vous avez payé, contactez-nous via WhatsApp.'
      return
    }

    const isPaid = ['completed', 'accessed'].includes(order.status)

    if (!isPaid) {
      show(errorEl, loadEl)
      document.getElementById('errorMsg').textContent =
        "Paiement non encore confirmé. Attendez quelques instants puis rechargez la page, ou contactez le support."
      return
    }

    // Marquer comme téléchargé
    if (order.status === 'completed') {
      await supabase
        .from('orders')
        .update({ status: 'accessed' })
        .eq('download_token', token)
    }

    show(successEl, loadEl)

    document.getElementById('productNameDisplay').textContent = order.product_name || '—'
    document.getElementById('emailDisplay').textContent       = order.buyer_email  || '—'

    // URL de téléchargement signée (expire dans 1 heure)
    const filePath = order.products?.file_path
    const dlBtn    = document.getElementById('downloadBtn')
    if (filePath) {
      const { data: signedData, error: signErr } = await supabase.storage
        .from('products')
        .createSignedUrl(filePath, 3600)
      if (!signErr && signedData?.signedUrl) {
        dlBtn.href = signedData.signedUrl
        dlBtn.setAttribute('download', '')
      } else {
        dlBtn.style.display = 'none'
      }
    } else {
      dlBtn.style.display = 'none'
      const msgEl = document.getElementById('successMsg')
      if (msgEl) msgEl.textContent = 'Votre document vous a été envoyé par email. Vérifiez votre boîte de réception.'
    }

    // Bouton partage WhatsApp
    const msg = encodeURIComponent(
      `J'ai acheté "${order.product_name}" sur XOHO pour seulement ${order.amount} FCFA ! 🎉 Découvrez leurs documents → https://xoho.bj`
    )
    const waBtn = document.getElementById('waShareBtn')
    if (waBtn) waBtn.href = `https://wa.me/?text=${msg}`

  } catch {
    show(errorEl, loadEl)
    document.getElementById('errorMsg').textContent =
      'Une erreur est survenue. Contactez le support WhatsApp.'
  }
}

function show(target, loading) {
  loading.classList.add('hidden')
  target.classList.remove('hidden')
}

document.addEventListener('DOMContentLoaded', init)
