# Signals — ia_life (MAJ 2026-08-25)

## Actions ouvertes

- [P2|ouvert] Décider si Phase 7 (LLM) démarre maintenant que la Phase 6 est close.
  fait quand: décision actée et documentée dans roadmap_experimentation.md (statut Phase 7).
  réf: roadmap_experimentation.md (Phase 7)
- [P2|ouvert] Décider si une campagne multi-seeds est nécessaire pour valider statistiquement
  la coopération (fonctionne mais observée seulement en configuration généreuse à ce stade).
  fait quand: campagne lancée et documentée, ou décision explicite de considérer la validation
  fonctionnelle actuelle suffisante.
  réf: experiments/social_cooperation_smoke_v1.json, tools/aggregate_results.py (mean_food_shared)

## Contexte chaud

- Phase 6 (roadmap_experimentation.md) close ce jour : communication (partage inconditionnel
  de position mémorisée), coopération (partage de nourriture si faim critique de l'autre) et
  agressivité (répulsion imposée) implémentées et validées par smoke tests dédiés — voir
  `_docs/decisions/2026-08-25_phase6-mecaniques-sociales-avancees.md`. Phase 7 (LLM) débloquée.
- Écart connu : `scripts/check_kit.py` est absent (contrôle d'intégrité de l'étape 10 de
  `/close` non exécutable) — reconfirmé le 2026-08-25 (troisième fois).
- `_docs/Analyse du projet/` (dossier vide daté 2026-08-17) reste non tracké, origine non
  éclaircie : ne pas committer.
- `.tmp_gdrl_smoke/`, `.tmp_native_rl_smoke/`, `.rl_godot_pid` : résidus des bridges RL tiers
  abandonnés (GDRL, godot-native-rl) ; non trackés, à nettoyer manuellement si souhaité.
- `ROBERTO/com_telephone/` reste entièrement non tracké git (node_modules, `.env` avec
  secrets, voix, logs) — ne pas `git add` ce dossier en bloc. Cette session : système de choix
  rapide par boutons ajouté (`server.js`, `mobile/index.html`, `mobile/app.js`), règle durable
  documentée dans `README.md` (utiliser ces boutons pour toute décision quand le bridge est
  actif) ; correction d'un bug réel — la demande de permission de notification push n'était
  déclenchée que par le bouton micro, jamais par l'envoi de texte, donc jamais activée pour un
  usage texte-only. Les 3 process (node/stt/tts) et le Monitor sur `messages.log` restent actifs
  en fin de session (task_id `be3rcakkm` dans `ROBERTO/com_telephone/_commands/monitor.lock`),
  à revalider en début de session suivante.

## Dernière session (2026-08-25)

# Session du 2026-08-25

## Décisions prises
- Phase 6 close : communication (partage inconditionnel de position mémorisée), coopération
  (partage de nourriture si faim critique) et agressivité (répulsion imposée) implémentées.
- ROBERTO : système de choix rapide par boutons, à utiliser systématiquement pour toute
  décision quand le bridge téléphone est actif.

## Livrables produits ou modifiés
- `scripts/variable_registry.gd`, `scripts/character.gd` : 3 nouvelles mécaniques sociales.
- `scripts/main.gd`, `tools/aggregate_results.py` : nouvelles métriques exportées/agrégées.
- `experiments/social_communication_smoke_v1.json`, `social_cooperation_smoke_v1.json`,
  `social_aggression_smoke_v1.json` : scénarios de validation.
- ROBERTO (hors git) : boutons de choix rapide, correction de l'abonnement aux notifications
  push, documenté dans `README.md`.
- `roadmap_experimentation.md` : Phase 6 marquée [FAIT], Phase 7 débloquée.
- `_docs/decisions/` : nouvelle entrée (mécaniques sociales avancées).

## Hypothèses validées / invalidées
- VALIDE : communication et agressivité se déclenchent de façon fiable et rapide en simulation.
- VALIDE avec réserve : coopération fonctionne mais nécessite une configuration généreuse
  (beaucoup de ronciers, rayon large, longue durée) pour être observée — pas de preuve
  statistique multi-seeds à ce stade.
- INVALIDE puis corrigée : les notifications push ROBERTO ne s'abonnaient jamais en usage
  texte -> demande de permission déplacée sur l'envoi de message et le chargement de la page.

## Prochaine étape exacte
Décider si Phase 7 (LLM) démarre maintenant, et si une campagne multi-seeds est nécessaire
pour valider statistiquement la coopération avant de la considérer stable.

## Question bloquante pour la session suivante
Aucune.

<!-- Écrasé intégralement par /close. Synthèse < 25 lignes. -->
