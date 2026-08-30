# Contexte — ia_life

## Objectif (immuable sauf décision explicite)
Créer un environnement Godot avec 2 personnages lowpoly pilotés chacun par un LLM, capables de se déplacer et de communiquer entre eux (loggé), afin d'étudier l'évolution de leurs comportements face aux modifications de l'environnement de jeu.

## Stack / contraintes techniques (stable, rarement modifié)
Godot 4.5 (GDScript), LLM local via Ollama (`gemma3:1b` en référence pour les campagnes ;
`gemma3:4b` disponible mais s'effondre sur ce prompt — voir décisions).

## État actuel (réécrit intégralement à chaque /close)
Le prototype est un laboratoire headless reproductible : configurations versionnées, logs JSONL,
résumés et campagnes. Les Phases 1 à 8 sont closes fonctionnellement : temps simulé déterministe,
traits comportementaux mesurés, interactions sociales avancées, Inspecteur générique, décideur
interchangeable automate/LLM, et vision générique (portée/angle/occlusion) qui absorbe la
perception sociale par code partagé.
Assistant vocal `com_telephone` : le pont n'est plus hébergé ici — migré vers le projet Roberto
le 2026-08-28. IA_Life est un projet raccordé (README léger + commande `/roberto`).
Axe suivant : apprentissage individuel (option 1B, `roadmap_apprentissage.md`). Phase 1 close
(`adaptive_decider.gd`, dispatch, engagement sur l'action). A révélé et corrigé deux bugs de
mécanique préexistants (seuil de recherche de nourriture, sortie d'objectif de cueillette) sur
tout le projet, revalidés sur six campagnes de référence. `llm_vs_automate_v1` reste à rejouer
(Ollama injoignable en fin de session). Phase 2 non démarrée, feu vert utilisateur en attente.

## Décisions structurantes (append only — 10 entrées max, 5 lignes max/entrée, archiver au-delà)
- 2026-08-25 : Phase 6 close — communication (partage inconditionnel de position mémorisée),
  coopération (partage de nourriture si faim critique de l'autre) et agressivité (répulsion
  imposée) implémentées, chacune validée par un scénario de simulation dédié — voir
  `_docs/decisions/2026-08-25_phase6-mecaniques-sociales-avancees.md`. Phase 7 débloquée.
- 2026-08-26 : Phase 7 — décideur LLM interchangeable (`scripts/llm_decider.gd`), backend
  Ollama local (`gemma3:1b`, `gemma3:4b` écarté après effondrement), repli automatique sur
  l'automate en cas d'erreur, campagne comparative validée — voir
  `_docs/decisions/2026-08-26_decideurs-interchangeables-llm.md`.
- 2026-08-26 : ROBERTO — cause racine du bug "injoignable" identifiée et corrigée (clé VAPID
  codée en dur désynchronisée du serveur, pas un cache navigateur) ; reconnexion WebSocket et
  notification push validées en conditions réelles. Convention `!<commande>` (commande à
  distance depuis le téléphone, git compris) créée et inlinée dans `CLAUDE.md` en plus du
  README — un simple renvoi au README s'est avéré insuffisant.
- 2026-08-26 : Phase 8 (vision et perception générique) ajoutée à la roadmap en [TODO] ; défaut
  `llm_model` du registre corrigé (`gemma3:4b` -> `gemma3:1b`, désaligné de la décision
  Phase 7).
- 2026-08-27 : Phase 8 (vision) close — primitive de perception, vision portée/angle/occlusion,
  `social_radius` absorbé comme cas particulier de la vision (code partagé, équivalence
  démontrée sur les scénarios sociaux Phase 6) — voir
  `_docs/decisions/2026-08-27_phase8-vision-perception.md`.
- 2026-08-27 : Points ouverts Phase 7 clos — prompt few-shot LLM jugé non nécessaire, coopération
  sociale validée statistiquement (5 seeds, jamais nulle).
- 2026-08-28 : Pont `com_telephone` migré vers le projet Roberto (hôte du serveur + template de
  référence unique). IA_Life devient un projet raccordé (README léger + `/roberto` surveillant
  `messages_ia_life.log` chez Roberto). Serveur/PWA retirés du dépôt IA_Life. Clôt l'action
  ouverte sur l'inclusion git de `ROBERTO/com_telephone`. Détail :
  `D:\ServOMorph\Roberto\roadmap_com_telephone_hub.md`.
- 2026-08-29 : axe d'évolution suivant retenu — apprentissage individuel (option 1B,
  « heuristiques apprises ») : le personnage apprend en une vie quelle action de recherche de
  nourriture marche selon sa situation de faim (table `(situation, action) → score`). 1A
  (évolution/sélection) et 1C (RL formel) écartées pour l'instant. Plan : `roadmap_apprentissage.md`.
- 2026-08-30 : Phase 1 de `roadmap_apprentissage.md` close (décideur adaptatif + engagement sur
  l'action) ; correction de deux bugs de mécanique préexistants (seuil de recherche de
  nourriture inversé, aucune sortie d'objectif de cueillette atteint) affectant automate et LLM
  mock, revalidée sur six campagnes de référence rejouées à seeds identiques — voir
  `_docs/decisions/2026-08-29_correction-seuil-recherche-nourriture.md` et
  `_docs/decisions/2026-08-29_engagement-decision-adaptatif.md`.
