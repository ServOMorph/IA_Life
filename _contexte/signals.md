# Signals — ia_life   (MAJ 2026-08-17)

## Actions ouvertes
- [P1|ouvert] Retester en jeu (`python run.py`) l'ensemble des mécaniques ajoutées cette
  session : cueillette/consommation de mûres, capacité à se nourrir, modale "Données du
  jeu", mémoire spatiale des ronciers, collision physique des ronces — puis
  valider/invalider les décisions archivées correspondantes.
  fait quand: l'utilisateur confirme le comportement observé en jeu
  réf: `_docs/decisions/2026-08-17_ronces-mures-donnees-jeu.md`,
  `_docs/decisions/2026-08-17_experimentation-headless.md`, `scripts/ronce.gd`,
  `scripts/character.gd`, `scripts/ui_manager.gd`, `scripts/game_config.gd`,
  `scripts/main.gd`

## Dernière session (2026-08-17)
<!-- Écrasé intégralement par /close. Synthèse < 25 lignes. -->
# Session du 2026-08-17

## Décisions prises
- Cueillette de mûres (ronces), consommation auto, modale "Données du jeu" (proposé)
- Mode headless + skills `analyse-partie`/`experimentation-headless` (proposé)
- Mémoire spatiale des ronciers par personnage, capacité 0-10 (proposé)
- Collision physique ajoutée aux ronces, en plus de l'Area3D de détection (proposé)
- Plafond de vitesse headless x80 documenté ; correction collision de nommage des logs

## Livrables produits ou modifiés
- scripts/game_config.gd, ronce.gd, game_logger.gd : créés
- scripts/character.gd, main.gd, ui_manager.gd, free_camera.gd : modifiés
- run_headless.py : créé
- .claude/skills/analyse-partie/, experimentation-headless/ : créés
- _docs/decisions/*.md : mis à jour (2 décisions enrichies d'amendements)

## Hypothèses validées / invalidées
- VALIDE (empirique headless) : la vitesse de jeu n'altère pas l'issue une fois les
  mécaniques indexées sur `time_scale`
- VALIDE (empirique headless, 8 runs x50) : mémoire + collision physique des ronces
  n'introduisent pas de régression sur cueillette/survie
- EN ATTENTE : aucune validation manuelle en jeu (`python run.py`) reçue cette session ->
  les décisions restent au statut "proposé"

## Prochaine étape exacte
Retester manuellement en jeu (`python run.py`) l'ensemble des mécaniques ronces/mémoire,
puis valider/invalider les décisions dans `_docs/decisions/`.

## Question bloquante pour la session suivante
Aucune
