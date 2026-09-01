# Contexte — ia_life

## Objectif (immuable sauf décision explicite)
Créer un environnement Godot avec 2 personnages lowpoly pilotés chacun par un LLM, capables de se déplacer et de communiquer entre eux (loggé), afin d'étudier l'évolution de leurs comportements face aux modifications de l'environnement de jeu.

## Stack / contraintes techniques (stable, rarement modifié)
Godot 4.5 (GDScript), LLM local via Ollama (`gemma3:1b` en référence pour les campagnes ;
`gemma3:4b` disponible mais s'effondre sur ce prompt — voir décisions).

## État actuel (réécrit intégralement à chaque /close)
Laboratoire headless reproductible (configs versionnées, logs JSONL, campagnes parallélisées).
Phases 1 à 8 closes ; assistant vocal migré vers Roberto (2026-08-28). **Axe apprentissage
individuel suspendu (2026-09-01, branche « Échec »)** : `roadmap_apprentissage_v2.md` Phases 0-3
closes, mais après refonte du signal (récompense événementielle + amorçage TD), espace d'action
S3 ×5 et enrichissement + re-gel de l'environnement (`apprentissage_env_ref_v2.json`), le décideur
adaptatif reste à égalité statistique avec la sélection aléatoire au seed apparié (M1 v2). Code
Phases 2-3 conservé (gates (a)/(b) passés, tests verts) ; M2-M5 et Phase 6 non engagées.

## Décisions structurantes (append only — 10 entrées max, 5 lignes max/entrée, archiver au-delà)
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
- 2026-08-30 : `roadmap_apprentissage.md` close côté code (Phases 2-4). Phase 2 : récompense sur
  la fenêtre d'engagement + MAJ en ligne + pénalité terminale + logs. Phase 3 : gate recalibré
  (bras de contrôle `exploration_epsilon` 1,0, même seed) franchi sur un seed. Phase 4 (balayage
  `learning_rate` × `exploration_epsilon`, 2 seeds) : l'avantage 1B ne généralise pas,
  `learning_rate` sans effet mesurable — discrétisation probablement trop grossière pour
  apprendre en une vie. Bifurcation d'axe à trancher (affiner 1B, ou 1A/1C). Voir
  `_docs/decisions/2026-08-30_apprentissage-intra-vie-faim.md`. `llm_vs_automate_v1` rejoué
  post-correction : pas de régression avec le vrai LLM.
- 2026-08-30 : bifurcation de l'axe apprentissage tranchée — approche par étapes plutôt que
  « affiner la discrétisation » seul ou bascule 1C immédiate. `roadmap_apprentissage_v2.md` créée
  (diagnostic en 5 défauts structurels, 7 phases gatées sur métrique de résultat, benchmark
  avant/après à 6 bras figés). `roadmap_apprentissage.md` close ; `roadmap_roberto_multiprojet.md`
  et `roadmap_experimentation.md` archivées dans `_docs/archives/`.
- 2026-09-01 : Phases 0-1 de `roadmap_apprentissage_v2.md` closes. Phase 0 : parallélisme
  reproductible de `run_campaign.py` (`--jobs/--retries`, bras nommés `arms`), bras gelé
  `adaptatif_v1`. Phase 1 : décideur `politique_fixe`, environnement de référence gelé
  (`vision` 15 / `hunger` 0,7 / `ronce` 30), gate franchi à n=12 (`pf_er_rm` 0,83 vs `pf_er_er`
  0,17 ; bit apprenable = décision S2), mesure M0 prise. `pf_rv_rm` ≡ `automate` ; `aleatoire`
  meilleur bras M0 (0,92). Voir `_docs/decisions/2026-08-31_calibrage-environnement-oracle.md`.
- 2026-09-01 : Phases 2-3 closes + **axe apprentissage suspendu** (branche « Échec »). Phase 2 :
  récompense événementielle + amorçage TD (γ 0,9), franchit le plateau sans-apprentissage
  (`adaptatif_v1` 0,50 < `aleatoire` 0,58) — mécanisme conservé. Phase 3 : espace d'action S3
  ×5 + `souvenir_ancien` ; gates (a)/(b) passés (le second sur env v2 enrichi). Environnement
  re-gelé en v2 (`eat_hunger_threshold` 90, `hunger` 0,9), rupture M0 v1 assumée. M1 v2 :
  `adaptatif_courant` (0,67) ne se sépare pas de `aleatoire` (0,58) ni de `adaptatif_v1` au
  seed apparié → suspension, M2-M5 et Phase 6 non engagées. Voir
  `_docs/decisions/2026-09-01_phase3-bifurcation-suspension-axe-apprentissage.md`.
