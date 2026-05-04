# Xoho – Architecture & Documentation Technique

## Vision Produit

Xoho est la première plateforme logistique collaborative du Bénin. Elle connecte les expéditeurs de colis avec des livreurs professionnels ou des particuliers en déplacement, pour des trajets urbains (Cotonou) et interurbains (Cotonou–Parakou).

**Tagline :** *Connecter les besoins et les envois*

---

## Stack Technique

| Couche | Technologie | Justification |
|--------|-------------|---------------|
| Mobile | Flutter 3.x | Performance native Android/iOS, une seule codebase |
| État | Riverpod 2.x | Type-safe, testable, scalable |
| Navigation | GoRouter | Deep links, navigation déclarative |
| Backend | Firebase (Auth, Firestore, Functions, Storage, FCM) | Temps réel, serverless, scalable |
| Maps | Google Maps Flutter | Précision, compatibilité GeoFirestore |
| Paiement | MTN MoMo API + Moov Money API | Standards locaux Bénin |
| QR Code | qr_flutter (génération) + mobile_scanner (scan) | Standard industrie |

---

## Architecture Clean (Feature-First)

```
lib/
├── main.dart                          # Point d'entrée
├── app.dart                           # MaterialApp.router
├── core/
│   ├── constants/
│   │   └── app_constants.dart         # Constantes (prix, villes, etc.)
│   ├── theme/
│   │   ├── app_colors.dart            # Système de couleurs complet
│   │   ├── app_text_styles.dart       # Typographie Nunito
│   │   └── app_theme.dart             # ThemeData dark
│   └── widgets/
│       ├── glass_card.dart            # Glassmorphism réutilisable
│       ├── xoho_button.dart           # Bouton animé avec haptics
│       └── gradient_background.dart  # Fond dégradé + glows
├── models/
│   ├── user_model.dart                # Utilisateur + KYC + rôles
│   ├── shipment_model.dart            # Colis + statuts + localisation
│   └── driver_model.dart             # Livreur + trajets planifiés
├── providers/
│   ├── auth_provider.dart             # Authentification Firebase
│   ├── shipment_provider.dart         # CRUD colis + séquestre
│   ├── driver_provider.dart           # Livreurs + temps réel
│   └── wallet_provider.dart           # Portefeuille + transactions
├── navigation/
│   └── app_router.dart               # Routes + redirections auth
└── features/
    ├── auth/
    │   └── presentation/screens/
    │       ├── splash_screen.dart     # Animation logo
    │       ├── onboarding_screen.dart # 4 slides paginées
    │       ├── login_screen.dart      # OTP phone (Firebase)
    │       └── kyc_screen.dart        # CIP + selfie (3 étapes)
    ├── home/
    │   └── presentation/
    │       ├── screens/home_screen.dart          # Carte + nav + bannière
    │       └── widgets/
    │           ├── map_widget.dart               # Google Maps dark style
    │           └── driver_bottom_sheet.dart      # Fiche livreur + unlock
    ├── sender/
    │   └── presentation/screens/
    │       ├── create_shipment_screen.dart       # 3 étapes: adresses/colis/prix
    │       └── tracking_screen.dart              # Carte + timeline + rating
    ├── driver/
    │   └── presentation/screens/
    │       ├── driver_home_screen.dart            # Toggle online + colis dispo
    │       └── register_trip_screen.dart          # Enregistrer trajet interurbain
    ├── wallet/
    │   └── presentation/screens/
    │       └── wallet_screen.dart                 # Solde + recharge MoMo/Moov
    ├── qr/
    │   └── presentation/screens/
    │       └── qr_screen.dart                    # QR code animé + instructions
    └── profile/
        └── presentation/screens/
            └── profile_screen.dart               # Profil + KYC + settings
```

---

## Business Model

### Flux de Revenus

1. **Micro-paiement de mise en relation : 100 F CFA**
   - L'expéditeur paie 100 F pour débloquer le contact du livreur
   - Implémenté via Cloud Functions (sécurisé côté serveur)

2. **Commission Livraison Sécurisée : 10%**
   - Fonds en séquestre pendant la livraison
   - Libérés au scan QR de confirmation
   - Commission prélevée automatiquement

3. **Assurance Xoho**
   - Basic : +200 F → remboursement jusqu'à 25 000 F
   - Premium : +500 F → remboursement jusqu'à 100 000 F

---

## Système de Sécurité

### KYC (Know Your Customer)
```
1. Scan CIP béninoise (recto/verso)
2. Selfie de vérification (liveness check)
3. Validation manuelle ou IA (Cloud Vision API)
4. Badge "Vérifié" sur le profil
```

### Système QR Code
```
xoho://delivery/{shipmentId}/{qrCode}

Flux :
[Expéditeur génère QR] 
  → [Livreur scanne au départ = status: picked_up]
  → [Livreur scanne à l'arrivée = status: delivered]
  → [Paiement libéré automatiquement]
```

### Escrow (Séquestre)
```
Cloud Function : onShipmentAccepted
  → Débite l'expéditeur (MTN MoMo / Moov)
  → Met en séquestre dans Xoho Wallet

Cloud Function : onQrScanDelivery
  → Valide la livraison
  → Crédit livreur (prix - commission 10%)
  → Confirmation expéditeur
```

---

## Intégration Firebase

```
firebase/
├── firestore/
│   ├── users/{userId}         # Profil + KYC
│   ├── shipments/{id}         # Colis + statuts temps réel
│   ├── drivers/{id}           # Localisation GeoFirestore
│   └── trips/{id}             # Trajets planifiés
├── functions/
│   ├── unlockContact.ts       # Débit 100F + révèle contact
│   ├── createEscrow.ts        # Séquestre paiement
│   ├── releasePayment.ts      # Libération au scan QR
│   └── sendSmsNotification.ts # SMS via Twilio/AfricasTalking
├── storage/
│   └── kyc/{userId}/          # Photos CIP + selfie
└── messaging/
    └── notifications          # Push notifications FCM
```

---

## Gestion Hors-Ligne

```dart
// Stratégie offline-first
1. Firestore persistence activée
2. SharedPreferences pour cache local
3. ConnectivityPlus pour détecter la connexion
4. Queue des actions hors-ligne (sync au retour)
5. Indicateur visuel "Hors ligne – Mode limité"
```

---

## Optimisations Bénin

- **SMS Fallback** : Si push notification échoue → SMS via Africa's Talking
- **Données légères** : Images compressées côté client avant upload
- **Cache agressif** : Firestore offline mode activé par défaut
- **Support 2G** : Requêtes minimales, pagination (20 items)
- **Multilingue** : Français (par défaut) → Fon/Yoruba (roadmap)

---

## Roadmap

### v1.0 (MVP)
- [x] Authentification OTP
- [x] Carte interactive avec livreurs
- [x] Création d'annonce (3 étapes)
- [x] Système de déblocage de contact (100F)
- [x] QR Code génération
- [x] Portefeuille MTN MoMo + Moov Money
- [x] Enregistrement de trajets interurbains
- [x] Profil + KYC

### v1.1
- [ ] Tracking temps réel GeoFirestore
- [ ] Scan QR camera (mobile_scanner)
- [ ] Notifications push/SMS
- [ ] Système d'enchères

### v2.0
- [ ] Notes vocales (description colis)
- [ ] Assurance Xoho active
- [ ] Dashboard analytics livreur
- [ ] Support multilingue audio

---

## Configuration Requise

```bash
# Flutter
flutter 3.19+
dart 3.3+

# Firebase
firebase_core: ^2.30.1
google-services.json (Android)
GoogleService-Info.plist (iOS)

# Google Maps
GOOGLE_MAPS_API_KEY=your_api_key_here
```

---

*Xoho – La référence logistique au Bénin* 🇧🇯
