# PAWS (Toilet & Aire)

PAWS est une nouvelle application Flutter pour localiser et noter la propreté des sanitaires et aires d'autoroute avec un code couleur simple : Vert, Orange ou Rouge.

## Fonctionnalités

- Localisation des sanitaires et aires dans un rayon de 100 km autour de la position actuelle.
- Recherche OpenStreetMap via Overpass sur `amenity=toilets`, `shop=convenience`, `amenity=fuel` et `amenity=charging_station`.
- Filtres horizontaux `Tous`, `Toilettes`, `Boutiques` et `Recharge ⚡`, avec panneau coulissant de détail et distance exacte.
- Splash Screen animé avec formes bleues/vertes qui fusionnent en logo PAWS avant la carte.
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

Les lieux sont découverts depuis Overpass/OpenStreetMap. Les avis sont enregistrés dans Firestore sous `locations/{locationId}/ratings`, avec agrégation de `averageRating` et `ratingCount` sur le document `locations/{locationId}`.

## Déploiement Netlify

- Build command : `flutter build web --release`
- Publish directory : `build/web`
- Redirection SPA : `web/_redirects` contient `/* /index.html 200`.
