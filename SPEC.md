# Spec — Application de planification personnelle (v1)

## Objectif

Application web personnelle (PWA), à usage mono-utilisateur, pour planifier ses journées et
semaines : objectifs quotidiens/hebdomadaires avec un système de gamification simple, et un
endroit unique pour noter ses rendez-vous.

## Fonctionnalités v1

### 1. Objectifs (quotidiens et hebdomadaires)
- Créer un objectif ponctuel (aujourd'hui) ou récurrent (chaque jour / chaque semaine).
- Cocher un objectif comme accompli.
- Distinction visuelle objectifs du jour / objectifs de la semaine.
  **Mise à jour** : un objectif hebdomadaire peut désormais optionnellement être rattaché à
  un jour précis de la semaine (et à un horaire, comme un objectif quotidien) au lieu de
  rester affiché/cochable tous les jours de la semaine. Par défaut (rien renseigné), le
  comportement initial est conservé.

### 2. Gamification simple
- Points gagnés à chaque objectif coché.
- Suivi de streak (nombre de jours/semaines consécutifs avec au moins un objectif complété,
  ou avec tous les objectifs complétés — à trancher en phase de plan).
- Affichage du total de points et du streak courant sur la vue principale.
- Pas de niveaux, badges ou récompenses en v1 (prévu comme évolution future).
  **Mise à jour** : un système de niveaux simple (100 points par niveau, barre de progression)
  a finalement été ajouté lors de la refonte visuelle "Planner Moderne" importée depuis Claude
  Design — le design importé l'incluait explicitement, et l'utilisateur a validé cet écart
  au périmètre initial plutôt que de l'omettre. Toujours pas de badges/récompenses débloquables.
  **Mise à jour** : le barème de points inclut désormais un bonus quand une complétion fait
  progresser le streak courant (plafonné par un réglage `streak_bonus_cap`, désactivable à 0) —
  ce qui répond à la question ouverte "bonus pour un streak long ?" ci-dessous.
  **Mise à jour** : suite à l'import du design "Move the Spark", le système de niveaux passe
  à 7 paliers (Braise, Étincelle, Flammèche, Ardeur, Foyer, Brasier, Phare — "Flamme" du design
  original renommé "Ardeur" pour éviter la confusion avec le streak, lui aussi rebaptisé), et
  le vocabulaire "points"/"série" devient "étincelles"/"flamme" dans toute l'interface. Les
  badges/récompenses déblocables restent explicitement hors périmètre (voir plus bas) — non
  implémentés malgré leur présence dans ce même design.
  **Mise à jour** : suite à l'import d'une itération plus poussée du même design, une flamme
  animée (partagée via une seule partial `shared/flame_body`) illustre désormais la progression
  à quatre endroits : le cochage d'un objectif (petite salve d'étincelles), l'écran Focus
  (grossit avec la session en cours), le profil ("Ton foyer", taille liée au niveau), et l'écran
  de célébration de fin de journée (désormais plein écran, avec confettis). L'écran Focus gagne
  aussi une pause/reprise (nouvelle colonne `timer_paused_at` sur `goals`), revenant sur la
  décision précédente de ne pas l'implémenter. Les trophées/badges, à nouveau présents dans ce
  design plus récent, restent explicitement hors périmètre.

### 3. Rendez-vous (RDV)
- Créer un rdv avec titre, date, heure (et lieu/notes optionnels).
- Lister les rdv à venir.
- Un rdv peut être rattaché à un jour donné, visible dans la vue combinée.

### 4. Vue principale combinée
- Une vue jour (par défaut) et une vue semaine, affichant ensemble objectifs et rdv du/des
  jour(s) concernés — pas de sections séparées.

### 5. Notifications push
- Rappel push pour un rdv à venir (délai exact à définir en phase de plan, ex. 30 min avant).
- Rappel push pour les objectifs du jour non complétés (heure/fréquence à définir en phase de
  plan).
- Implémenté via Web Push (service worker + clés VAPID), compatible PWA installée sur Android.

### 6. Chronométrage des objectifs
- Chrono démarrer/arrêter directement sur un objectif existant (pas de nouvelle entité "tâche"
  séparée).
- Durée réelle enregistrée à chaque fois qu'un objectif chronométré est réalisé.
- Pas de saisie d'estimation manuelle en v1 : l'appli se contente de logger le temps réel.
- Pour les objectifs récurrents, affichage d'une moyenne des durées passées (ex. "en moyenne
  25 min"), pour aider à mieux planifier les prochaines occurrences.

### 7. Listes de courses
- Plusieurs listes nommées possibles (ex. "Courses hebdo", "Anniversaire"), créées, conservées
  et réutilisables comme modèles.
- Ajout/suppression d'articles dans une liste, articles cochables pendant les courses.
- Fonctionnalité utilitaire indépendante : pas de points ni de lien avec le streak/gamification.
- Affichée dans une section dédiée, séparée de la vue combinée jour/semaine (qui reste centrée
  sur objectifs + rdv).

## Hors périmètre v1 (évolutions futures possibles)

- Multi-utilisateur / authentification (aucun login prévu — accès direct, usage privé).
- Gamification avancée (niveaux, badges, récompenses déblocables).
- Synchronisation avec calendriers externes (Google Calendar, etc.).
- Application native (Hotwire Native) — on reste sur une PWA pour la v1.

## Contraintes techniques

- Backend : Ruby on Rails.
- Frontend : vues Rails classiques (ERB/Turbo), pas de framework JS séparé a priori.
- PWA : manifest.json, service worker, installable sur écran d'accueil Android.
- Notifications : Web Push API (VAPID), déclenchées côté serveur (nécessite un job
  planifié/scheduler pour les rappels).
- Hébergement : à définir en phase de plan (ex. Render ou Fly.io).
- Pas d'authentification (accès mono-utilisateur, URL non partagée).
  **Mise à jour** : ajout d'un Basic Auth (identifiant/mot de passe unique, partagé) devant
  toute l'application une fois hébergée publiquement — une protection de défense en
  profondeur en plus du secret de l'URL, pas un vrai système de comptes. Désactivé par défaut
  (aucun effet en local/tests tant que `BASIC_AUTH_USER`/`BASIC_AUTH_PASSWORD` ne sont pas
  définis).

## Questions ouvertes à trancher en phase de plan

- Barème exact des points (fixe par objectif ? bonus pour un streak long ?). **Tranché** :
  fixe par objectif (`points_per_goal`) + bonus optionnel plafonné quand le streak progresse
  (voir section 2 ci-dessus).
- Règle précise du streak (au moins un objectif fait, ou tous les objectifs faits, pour
  compter le jour/la semaine).
- Délai des rappels push pour les rdv et heure des rappels pour les objectifs du jour.
- Choix de l'hébergeur et mise en place du scheduler (rappels programmés).
- Comment identifier qu'un objectif est "récurrent" pour calculer sa moyenne de durée (même
  titre ? objectif template dupliqué chaque jour/semaine ?).
- Articles de liste de courses : simple texte libre, ou avec quantité/unité en plus du nom ?
- Nom de l'application. **Tranché** : "Move the Spark" (domaine `movethespark.com`) — en écho
  à "Étincelle", déjà le nom du premier palier de niveau dans la gamification. Renommage
  appliqué partout côté UI (titres de pages, manifest PWA, README). Le module Ruby interne
  (`config/application.rb`) et les identifiants techniques (image Docker, service Kamal)
  restent `planner` en minuscule — un renommage structurel séparé, plus risqué, non demandé.
