# Captures avant / après — refonte mobile Ouvra

Captures prises sur Flutter web (Chrome headless, 390 × 844, densité 2), branché sur
le backend local et les comptes de démo (`aurelien.tabi@demo.cm`, `paul.kamdem@demo.cm`).

- `avant/` : l'app telle qu'elle était (bleu royal, dégradés, emojis, bandeau « -20 % »).
  Le thème sombre y apparaît car l'ancienne app suivait le système.
- `apres/` : parcours client en thème clair, barre d'onglets flottante.
- `apres/prestataire/` : espace prestataire (Paul Kamdem).
- `apres/sombre/` : quelques écrans en thème sombre.
- `apres/petit-ecran/` : 360 × 640, format des Android d'entrée de gamme.

Les photos venant de `randomuser.me` et de `/uploads` ne s'affichent pas sur le web
(CanvasKit exige des en-têtes CORS) : on voit les initiales ou un fond neutre.
Sur Android et iOS elles s'affichent normalement.

| Écran | Avant | Après |
| --- | --- | --- |
| Splash animé (nouveau) | — | `apres/00a-splash-assemblage.png` → `00b-…voyant`, `00c-…ondes`, `00d-…final` |
| Onboarding | `avant/01-onboarding.png` | `apres/01-onboarding.png`, `01b-…`, `01c-…` |
| Connexion | `avant/02-login.png` | `apres/02-login.png` |
| Inscription | `avant/03-register.png` | `apres/03-register.png` |
| Mot de passe oublié | `avant/04-forgot-password.png` | `apres/04-forgot-password.png` |
| Accueil client | `avant/05-home.png`, `06-…` | `apres/05-home.png`, `06-…` |
| Recherche | `avant/07-search.png` | `apres/07-search.png` |
| Carte | `avant/08-map.png` | `apres/08-map.png` |
| Profil prestataire | `avant/09-provider.png`, `10-…` | `apres/09-provider.png`, `10-…` |
| Messages | `avant/11-chats.png` | `apres/11-chats.png` |
| Conversation | `avant/12-chat.png` | `apres/12-chat.png` |
| Profil | `avant/13-profile.png` | `apres/13-profile.png` |
| Réglages | `avant/14-settings.png` | `apres/14-settings.png` |
| Devenir prestataire | `avant/15-become-provider.png` | `apres/15-become-provider.png` |
| Métiers | `avant/16-categories.png` | `apres/16-categories.png` |
| Réserver (nouveau) | — | `apres/17-booking-form.png` |
| Réservations (nouveau) | — | `apres/18-bookings.png` |
| Réservation à payer (nouveau) | — | `apres/19-booking-to-pay.png` |
| Paiement Mobile Money (nouveau) | — | `apres/20-payment-sheet.png` |
| Séquestre et code de fin (nouveau) | — | `apres/21-booking-escrow-code.png` |
| Notifications (nouveau) | — | `apres/22-notifications.png` |
| Emplacement du fil de demandes | — | `apres/23-request-placeholder.png` |
