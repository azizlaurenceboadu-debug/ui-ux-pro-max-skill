// ─── Supabase Configuration ───────────────────────────────────────────────
// Supabase Dashboard → Project Settings → API
// ⚠️ Remplacez les deux valeurs ci-dessous avec vos vraies credentials

import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm'

const SUPABASE_URL      = 'https://VOTRE_PROJECT_ID.supabase.co'
const SUPABASE_ANON_KEY = 'VOTRE_CLE_ANON_PUBLIQUE'

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)

// Helper: URL publique d'un fichier Storage
export function storageUrl(bucket, path) {
  if (!path) return ''
  if (path.startsWith('http')) return path
  return `${SUPABASE_URL}/storage/v1/object/public/${bucket}/${path}`
}
