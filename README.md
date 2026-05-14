# PAWS (Toilet & Aire)

PAWS est une nouvelle application Flutter pour localiser et noter la propreté des sanitaires et aires d'autoroute avec un code couleur simple : Vert, Orange ou Rouge.

## Fonctionnalités

- Localisation des sanitaires et aires dans un rayon de 50 km autour de la position actuelle.
- Notes de propreté Vert / Orange / Rouge stockées dans Cloud Firestore.
- Photos de contribution prêtes à être stockées dans Firebase Storage.
- Architecture par `features/` avec une séparation claire entre carte et notation.
- Déploiement web Netlify compatible SPA.

## Structure

```text
lib/
  core/                  # Configuration Firebase
  features/
    map/                 # Recherche géolocalisée et affichage carte/liste
    rating/              # Modèle, persistance et UI de notation
web/
  _redirects             # Correction 404 Netlify
```

## Firebase

La configuration Firebase est injectée avec des variables `--dart-define` :

```bash
flutter build web --release \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_PROJECT_ID=... \
  --dart-define=FIREBASE_AUTH_DOMAIN=... \
  --dart-define=FIREBASE_STORAGE_BUCKET=...
```

Collection Firestore attendue : `locations`.

Champs principaux :

- `name` : nom de l'aire ou sanitaire.
- `type` : `Sanitaires`, `Aire d'autoroute`, etc.
- `latitude` / `longitude` : coordonnées numériques.
- `averageRating` : moyenne entre 1 et 3.
- `ratingCount` : nombre d'avis.
- `photoUrl` : URL optionnelle d'une image stockée.

## Déploiement Netlify

- Build command : `flutter build web --release`
- Publish directory : `build/web`
- Redirection SPA : `web/_redirects` contient `/* /index.html 200`.
