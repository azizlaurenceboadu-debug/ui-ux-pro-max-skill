# XOHO — Micro-Solutions Numériques

Plateforme e-commerce mobile-first pour la vente de documents professionnels au Bénin.

## Stack technique

- **Frontend** : HTML5, CSS3 (design system custom), JavaScript ES Modules
- **Backend** : Firebase (Firestore, Auth, Storage, Hosting)
- **Paiement** : Kkiapay (MoMo/Flooz)
- **Design** : Space Grotesk + Inter, Navy #1A2B6B, animations CSS

## Structure des fichiers

```
xoho/
├── index.html          → Landing page
├── boutique.html       → Catalogue avec filtres par pôle
├── produit.html        → Page produit individuelle (dynamique)
├── succes.html         → Page de téléchargement post-achat
├── admin.html          → Tableau de bord administrateur
├── assets/
│   ├── logo.svg        → Logo XOHO (remplacer par le vrai fichier)
│   └── logo-white.svg  → Version blanche du logo
├── css/
│   └── style.css       → Design system complet
├── js/
│   ├── firebase-config.js  → ⚠️ Configurer avec vos credentials
│   ├── app.js              → Utilitaires partagés
│   ├── boutique.js         → Logique catalogue
│   ├── produit.js          → Logique page produit + achat
│   ├── succes.js           → Logique page de téléchargement
│   └── admin.js            → Logique panneau admin
├── firebase.json       → Config Firebase Hosting
├── firestore.rules     → Règles de sécurité Firestore
└── storage.rules       → Règles de sécurité Storage
```

## Configuration (obligatoire)

### 1. Firebase

1. Créer un projet sur [Firebase Console](https://console.firebase.google.com)
2. Activer **Firestore**, **Authentication** (Email/Password), **Storage**, **Hosting**
3. Copier les credentials dans `js/firebase-config.js`
4. Créer un compte admin : Firebase Auth → Add User

### 2. Kkiapay

1. Créer un compte sur [kkiapay.me](https://kkiapay.me)
2. Récupérer votre clé publique
3. La remplacer dans `js/produit.js` à la ligne `api_key: 'VOTRE_CLE_PUBLIQUE_KKIAPAY'`
4. Ajouter le script Kkiapay dans `produit.html` :
   ```html
   <script src="https://cdn.kkiapay.me/k.js"></script>
   ```
5. Passer `sandbox: false` en production

### 3. WhatsApp

Remplacer `22900000000` par votre vrai numéro WhatsApp dans tous les fichiers HTML.

### 4. Logo

Remplacer `assets/logo.svg` et `assets/logo-white.svg` par votre vrai logo.

## Déploiement Firebase Hosting

```bash
npm install -g firebase-tools
firebase login
firebase init
firebase deploy
```

## Structure Firestore

### Collection `products`
```json
{
  "name": "Modèle de Facture OHADA",
  "pole": "business",
  "price": 500,
  "shortDesc": "Modèle professionnel conforme à la loi OHADA",
  "fullDesc": "Description complète...",
  "bullets": "Conforme OHADA\nPersonnalisable en 5 minutes\nFormats PDF + Excel",
  "format": "PDF + Excel",
  "fileSize": "1.2 Mo",
  "fileUrl": "https://firebasestorage.googleapis.com/...",
  "previewUrl": "https://...",
  "published": true,
  "topSell": true,
  "featured": false,
  "createdAt": "Timestamp"
}
```

### Collection `orders`
```json
{
  "productId": "abc123",
  "productName": "Modèle de Facture OHADA",
  "amount": 500,
  "buyerName": "Kofi Amoussou",
  "buyerEmail": "kofi@email.com",
  "buyerPhone": "97000000",
  "status": "pending|completed|accessed|failed",
  "downloadUrl": "https://...",
  "createdAt": "Timestamp"
}
```

## Les 5 pôles

| Pôle | Slug | Description |
|------|------|-------------|
| Administratif | `administratif` | Lettres, demandes officielles |
| Académique | `academique` | Fiches DCG, BTS, cours |
| Citoyen | `citoyen` | Guides IFU, e-services |
| Business | `business` | Factures, modèles Excel |
| Vie Pratique | `vie-pratique` | Budgets, plannings |
