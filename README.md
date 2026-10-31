# AlloService — Frontend (Flutter)

Marketplace de services **Fiverr × Uber × WhatsApp** pour le Cameroun :
_« Trouve un prestataire proche, regarde son profil, parle-lui directement, fais affaire sans friction. »_

## Stack

- **Flutter 3.44** / Dart 3.12
- **Riverpod 2.x** (generator) — state management MVVM
- **go_router** — navigation (shell + bottom nav)
- **google_fonts** (Inter), **cached_network_image**, **shimmer**
- Design system **plat** : couleur primaire `#1482F7`, aucun gradient/glassmorphism

## Architecture (feature-first + Clean Architecture)

```
lib/
├─ core/
│  ├─ router/        # go_router (app_router, app_routes)
│  └─ theme/         # couleurs, typographie, spacing, thème clair/sombre
├─ features/
│  ├─ auth/          # splash, login, register, sélection de rôle
│  ├─ home/          # accueil : recherche, catégories, prestataires proches
│  ├─ search/        # recherche live
│  ├─ providers/     # modèle prestataire, liste triée/filtrée, écran détail
│  ├─ chat/          # liste conversations + chat temps réel (cœur produit)
│  ├─ profile/       # profil utilisateur + stats prestataire
│  ├─ settings/      # paramètres, switch de rôle, déconnexion
│  └─ shell/         # coquille avec bottom navigation
├─ shared/
│  └─ widgets/       # AppButton, AppTextField, RatingStars, SectionHeader
└─ main.dart
```

Chaque feature suit `domain/` (modèles), `data/` (sources — mockées pour l'instant),
`application/` (contrôleurs Riverpod), `presentation/` (screens + widgets).

## Périmètre actuel (MVP, données mockées)

- ✅ Auth : splash, connexion (téléphone), inscription + choix de rôle
- ✅ Accueil : catégories, tri (proximité/note/prix), filtres distance (1/5/10/20 km)
- ✅ Recherche live sur nom / métier / ville / catégorie
- ✅ Détail prestataire : bio, portfolio, avis, placeholder carte, bouton **Contacter**
- ✅ Chat : liste des conversations + messagerie (envoi de message)
- ✅ Profil + paramètres + bascule de rôle client ↔ prestataire

> Toutes les données viennent de `*/data/mock_*.dart`. À remplacer par les
> appels à l'API Spring Boot (auth JWT/OTP, WebSocket chat, géoloc).

## Commandes

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # génère les *.g.dart Riverpod
flutter run
```

Après toute modification d'un contrôleur `@riverpod`, relancer `build_runner`.

## Prochaines étapes

- [ ] Géolocalisation réelle (geolocator + google_maps_flutter)
- [ ] Intégration API Spring Boot + WebSocket chat
- [ ] Auth JWT + OTP SMS + biométrie
- [ ] Envoi de médias (images/vocaux) dans le chat
- [ ] Paiement (phase 2) : MTN MoMo, Orange Money, Flutterwave, PayDunya
