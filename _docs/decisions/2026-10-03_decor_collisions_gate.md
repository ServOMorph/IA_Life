# Décors bloquants — gate de Phase 5 atteint

Date : 2026-10-03. Décision : activer `decor_collisions` par défaut pour les nouvelles configurations. Une valeur déjà enregistrée par l'utilisateur reste prioritaire.

Le protocole de `experiments/decor_collisions_contrat_v1.md` a été appliqué aux graines 26103101 à 26103106, avec 4 agents par carte, `game_speed = 1.0`, une durée maximale de 1 200 s simulées et la configuration de `experiments/llm_survie_v1.json`. Les deux bras d'un même décideur ne diffèrent que par `decor_collisions`. L'automate a été parallélisé ; `llm_survie` a tourné à `--jobs 1` avec Ollama `gemma3:1b` en temps réel.

| Graine | Automate sans / avec (s) | LLM sans / avec (s) |
| --- | ---: | ---: |
| 26103101 | 551,19 / 535,97 | 254,66 / 264,64 |
| 26103102 | 564,73 / 568,52 | 266,92 / 263,44 |
| 26103103 | 561,90 / 553,56 | 274,22 / 276,58 |
| 26103104 | 531,93 / 557,09 | 276,36 / 270,88 |
| 26103105 | 569,10 / 557,75 | 278,89 / 297,48 |
| 26103106 | 490,17 / 562,06 | 276,04 / 267,78 |
| Moyenne | 544,84 / 555,82 | 271,18 / 273,46 |

## Gates

- Automate : ratio de vie 102,02 % (seuil 90 %) ; 109 contacts de tronc, 50 contournements, aucun échec, immobilisation maximale mesurée pendant un détour de 0,10 s (seuil 3 s). Le contrôle de connectivité à pas de 0,5 m, avec obstacles élargis au rayon de l'agent et à la demi-diagonale de la maille, trouve les 24 ronciers atteignables sur chacune des six cartes depuis au moins un départ.
- `llm_survie` : ratio de vie 100,84 % (seuil 80 %) ; 0 repli sur 1 417 tours (seuil 5 %) ; 32 contournements, aucun échec et aucun contact de tronc. Les blocages d'action restent présents avec et sans arbres bloquants : respectivement 9 contre 8 pour `aller_vers`, 96 contre 77 pour `explorer`. L'audit spatial des neuf blocages de cible donne une marge minimale estimée de 2,98 m jusqu'à la surface d'un tronc, après correction du décalage des échantillons de position à 2,5 m/s. Aucun de ces blocages n'est directement imputable à un tronc. Cela ne démontre pas l'absence de tout effet indirect des arbres sur les autres blocages.

Les critères contractuels sont atteints sur ce lot. `scripts/variable_registry.gd` fixe désormais la valeur par défaut à `true`. Les deux états restent sélectionnables et les campagnes historiques explicitement configurées restent inchangées.

## Traçabilité et limites

Les configurations, journaux et résumés complets sont dans `results/_decor_collisions_v1_automate/` et `results/_decor_collisions_v1_llm_realtime/`. Les calculs sont reproduits par `tools/analyze_decor_collisions.py` et les rapports JSON de ces dossiers. `tools/audit_decor_target_blocks.py` rapproche les positions journalisées des troncs générés sur ces graines. Les contrôles ciblés couvrent l'interrupteur, le placement, l'accessibilité et le contournement des deux décideurs.

Un premier essai LLM avec `--fixed-fps 60` a été exclu : les requêtes Godot expiraient (`result = 13`) et provoquaient des replis artificiels. Ses sorties dans `results/_decor_collisions_v1_llm/` ne font pas partie de ce gate. La campagne retenue est celle en temps réel.

La conclusion porte sur six cartes, un seul modèle LLM et une carte sans repousse ; elle n'est pas un test statistique ni une garantie pour tous les décors futurs. Les blocages d'action LLM hors détour restent à diagnostiquer séparément, mais ne changent pas la décision contractuelle relative aux troncs.

La suite globale `tools/manual_checks.tscn` échoue encore sur cinq assertions « Phase 8 vision » (mémorisation, découvertes et détections). Ces mêmes cinq échecs étaient présents avant l'activation par défaut ; les contrôles ciblés du décor passent.

## Reproduction

Exécuter les campagnes dans des dossiers de sortie vierges. L'automate peut utiliser le mode headless accéléré à pas de 60 Hz ; le LLM doit rester en temps réel pour préserver ses délais HTTP.

```powershell
$env:IA_LIFE_HEADLESS_FIXED_FPS = '60'
python tools/run_campaign.py experiments/campaigns/decor_collisions_v1_automate.json --jobs 4 --output-dir results/_decor_collisions_v1_automate_replay
Remove-Item Env:IA_LIFE_HEADLESS_FIXED_FPS -ErrorAction SilentlyContinue
python tools/run_campaign.py experiments/campaigns/decor_collisions_v1_llm.json --jobs 1 --output-dir results/_decor_collisions_v1_llm_replay
python tools/analyze_decor_collisions.py automate --directory results/_decor_collisions_v1_automate_replay
python tools/analyze_decor_collisions.py llm --directory results/_decor_collisions_v1_llm_replay
```
