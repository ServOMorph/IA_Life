# Analyse et recherche pour un apprentissage fonctionnel

## Conclusion proposée

IA_Life dispose d'un simulateur instrumenté, de décideurs interchangeables et d'une mise à jour tabulaire par différence temporelle. Le point manquant est une démonstration complète : entraîner sur plusieurs épisodes, conserver ce qui a été appris, figer la politique, puis mesurer son avantage sur des situations inédites.

La recommandation est de retirer le danger du chemin critique de cette première démonstration. Commencer par la recherche de nourriture dans une petite scène Godot, conserver les acquis entre épisodes, puis augmenter progressivement la difficulté jusqu'au monde existant. Une politique compacte constitue le candidat principal ; un LLM local pourra utiliser les compétences obtenues ou apprendre par mémoire d'expérience dans une extension distincte.

Cette proposition révise une interprétation trop forte des résultats précédents. L'échec d'une famille de politiques fixes n'établit pas l'impossibilité d'apprendre. L'absence de séparation sur un petit échantillon n'établit pas non plus une équivalence statistique. Inversement, ajouter PPO ou un LLM ne garantit aucun succès : le contrat du simulateur et l'information fournie doivent d'abord être corrects.

Proposition datée du 10 septembre 2026, fondée sur le code du checkout `44121e2e`, les résultats archivés et les sources ci-dessous. Aucun nouvel entraînement ni test de compatibilité des bibliothèques externes n'a été exécuté. Les seuils et budgets proposés dans la roadmap sont des choix expérimentaux à préenregistrer, pas des résultats.

## 1. Ce que montre le projet

### Trois chemins à distinguer

| Chemin | Comportement lu dans le code | Conséquence |
| --- | --- | --- |
| Adaptatif GDScript | Sélection ε-greedy, récompense de cueillette, amorçage TD, table de scores | Apprentissage pendant une vie ; la conservation entre runs n'est pas raccordée dans le chemin inspecté |
| RL TCP | Actions directionnelles externes et observation numérique | Socle de communication, mais contrat d'entraînement incomplet |
| LLM Ollama | Requête asynchrone, réponse intention/direction, repli automate | Inférence ; aucun apprentissage des poids ni mémoire inter-épisodes dans ce décideur |

Sources : [décideur adaptatif](D:/ServOMorph/IA_Life/scripts/adaptive_decider.gd), [construction et pilotage des personnages](D:/ServOMorph/IA_Life/scripts/character.gd), [passerelle TCP](D:/ServOMorph/IA_Life/scripts/rl_bridge.gd), [boucle du monde](D:/ServOMorph/IA_Life/scripts/main.gd), [décideur Ollama](D:/ServOMorph/IA_Life/scripts/llm_decider.gd).

### Constats et limites d'interprétation

**D1 — La persistance arrive trop tard dans le plan.** `AdaptiveDecider._init()` appelle `reset_table()`. Le constructeur du personnage configure un nouveau décideur sans recharger une table. Le dump de fin de vie est une trace, pas une reprise d'entraînement. La Phase 4 de la [roadmap apprentissage actuelle](D:/ServOMorph/IA_Life/roadmap_apprentissage_v2.md) prévoit précisément cette persistance, mais elle est suspendue. Tester une accumulation d'expérience doit précéder une conclusion générale sur la capacité d'apprentissage.

**D2 — Les situations agrègent des contextes différents.** `classify()` distingue seulement ressource visible, souvenir disponible et inconnu. Distance à la cible, fraîcheur du souvenir, faim détaillée et blocage ne distinguent pas les cellules. Les directions influencent l'exécution des actions, mais pas les scores de choix. C'est un risque d'aliasing : une même cellule peut regrouper des actions utiles et nuisibles selon le contexte. Son rôle causal reste à mesurer par ablation.

**D3 — Le bras aléatoire n'est pas une ablation exacte du learner courant.** La [campagne M1 v2](D:/ServOMorph/IA_Life/experiments/campaigns/benchmark_apprentissage_m1_v2.json) utilise `adaptatif_v1` à ε = 1 pour `aleatoire`, tandis que `adaptatif_courant` utilise l'espace élargi. Le contraste mélange apprentissage et espace d'action. Ajouter une référence aléatoire sur les mêmes actions, masques et durées, ainsi qu'un candidat identique dont les mises à jour sont désactivées.

**D4 — Il manque une séparation explicite apprentissage/évaluation.** Le chemin adaptatif courant met à jour sa table pendant les décisions de faim. Mettre ε à zéro ne suffit pas à figer l'apprentissage : les mises à jour continuent. Il faut un mode d'évaluation sans modification des paramètres, distinct de l'exploration.

**D5 — Le reset RL n'est pas un reset du monde.** Dans `main.gd::_rl_reset`, la seed est réaffectée puis seul Rouge reçoit `reset_for_rl`. Cette fonction ne reconstruit ni ressources, ni terrain, ni autres personnages. Réaffecter le générateur aléatoire ne replace pas les objets déjà créés. Les épisodes successifs risquent donc d'hériter de ressources consommées et d'états des autres agents. Le [client actuel](D:/ServOMorph/IA_Life/rl/client_random.py) exécute un seul épisode puis ferme : il ne couvre pas ce cas.

**D6 — Le RL numérique ne reçoit pas la nourriture.** `_rl_observation()` contient dix composantes : faim, inventaire, position, vitesse et distances aux limites. Aucune cible alimentaire perçue ou mémorisée n'y figure. `_process_rl()` donne `0.005 × 0.25 − 0.001 = 0.00025` par pas hors mort, puis une pénalité à la mort. Il n'y a pas de crédit de cueillette dans cette branche. Une observation plus informative et un retour événementiel sont nécessaires avant d'interpréter un entraînement sur cette interface.

**D7 — Les actions et le temps demandent un contrat.** `set_rl_action()` expose sept directions : le nord-est et l'immobilité ne figurent pas dans la liste. C'est une asymétrie, pas une preuve que le déplacement est impossible. La cadence RL dépend de `_process`, alors que la physique des personnages dépend de `_physics_process`. Il faut compter les ticks physiques et tester une même trace d'actions avec différentes latences du client. La pause mérite aussi un test : le [roncier](D:/ServOMorph/IA_Life/scripts/ronce.gd) traite les contacts à chaque tick sans utiliser son delta ; mettre seulement `time_scale` à zéro n'est pas une preuve de gel de toutes les mutations.

**D8 — Les frontières de transition sont incomplètement spécifiées.** Dans l'adaptatif, la mort applique une pénalité fixe sans calculer le dernier delta de cueillette/temps ; la fin de run journalise la table sans fermer explicitement la transition restante. Le facteur γ est identique pour des engagements de durées différentes. Ces choix doivent être contractualisés et couverts par des cas de récompense suivie immédiatement d'une fin, d'interruption et de durée variable. Ils ne sont pas établis comme cause principale des résultats.

**D9 — Les tests unitaires ne prouvent pas une acquisition autonome.** Les [tests de crédit existants](D:/ServOMorph/IA_Life/tools/run_manual_checks.gd) contrôlent utilement les opérations : l'un initialise l'errance à une valeur négative pour maintenir l'approche ; l'autre précharge la valeur de l'état suivant. Ils vérifient le calcul local, mais pas qu'une politique neutre découvre et conserve un comportement gagnant dans Godot. Ajouter une preuve de bout en bout, sans précharger la réponse.

**D10 — Le LLM actuel a peu de contexte décisionnel.** Le prompt expose la faim et deux booléens concernant ressources visibles et souvenirs. Il n'expose pas les trajectoires précédentes, leurs résultats ou un inventaire de compétences acquises. La direction de nourriture est parfois résolue par le code à réception. Toute future comparaison doit séparer cette aide programmée de la décision du modèle. La latence réelle d'Ollama influe aussi sur l'exécution asynchrone ; un benchmark devra synchroniser ou rejouer les réponses.

**D11 — La mémoire existante n'est pas entièrement locale.** `_nearest_usable_memory()` lit le stock courant de l'objet roncier mémorisé, même si celui-ci n'est pas actuellement visible. Ce comportement peut être conservé pour les comparaisons historiques, mais une expérience de mémoire partiellement observable devra mémoriser la dernière information perçue. Sinon, elle fournit implicitement une information à distance.

### Résultats archivés relus et recalculés

Les summaries de la campagne M1 v2 ont été relus par le chargeur du [rapport de benchmark](D:/ServOMorph/IA_Life/tools/benchmark_report.py), sans lancer de simulation. Les agrégats reproduisent le [rapport archivé M1 v2](D:/ServOMorph/IA_Life/results/_benchmark_apprentissage_m1_v2/m1v2_report.json) :

| Bras | Survie, 12 épisodes historiques | Mûres mangées moyennes |
| --- | --- | --- |
| Adaptatif courant | 0,667 | 12,917 |
| Aléatoire historique | 0,583 | 12,417 |
| Adaptatif v1 | 0,500 | 11,833 |
| Automate | 0,083 | 5,833 |

Face à l'aléatoire, le recalcul donne quatre victoires, trois défaites et cinq égalités sur la survie. Cela justifie « avantage non démontré par cette expérience », pas « aucune politique apprenable n'existe ».

Le [rapport de calibration du contournement v2](D:/ServOMorph/IA_Life/results/_danger_zone_detour_v2/gate_report.json) indique un gate échoué, cinq accords sur douze contre l'aléatoire, et une survie d'évitement de 0,417. Cette expérience mesure des politiques fixes de danger. Elle ne mesure pas un modèle entraîné entre épisodes. Le [mécanisme de contournement](D:/ServOMorph/IA_Life/scripts/danger_detour.gd) et la [décision associée](D:/ServOMorph/IA_Life/_docs/decisions/2026-09-10_contournement-stateful.md) documentent une difficulté de navigation qui peut être traitée séparément.

### Problème de preuve statistique

La fonction `sign_test()` du rapport compte les signes mais ne calcule ni p-value ni intervalle. Pour neuf victoires et trois défaites sans égalité, le test binomial exact bilatéral donne `p = 0,14599609375` ; valeur recalculée pendant l'analyse. Le seuil « 9/12 » est un critère opérationnel possible, pas automatiquement une preuve à 5 %.

Le chargeur ignore les runs incomplets, et l'appariement indexe la référence par seed seule. Cela doit être durci avant d'ajouter plusieurs entraînements ou répétitions : une répétition ne doit pas écraser une autre. Il faut aussi distinguer la seed de la carte de celle de l'entraînement. Rejouer une même politique sur plusieurs cartes ne remplace pas plusieurs apprentissages indépendants. Ces exigences concordent avec les travaux sur l'incertitude et la puissance des expériences RL. [Sources 7–8]

## 2. Travaux et projets utiles

Les sources décrivent des solutions à des composantes du problème. Aucune n'a été exécutée sur IA_Life ; leur présence sur GitHub n'est pas une preuve de compatibilité avec ce projet.

| Source primaire | Apport concret pour IA_Life | Limite et décision proposée |
| --- | --- | --- |
| [Godot RL Agents](https://github.com/edbeeching/godot_rl_agents) et [tutoriel d'environnement](https://github.com/edbeeching/godot_rl_agents/blob/main/docs/CUSTOM_ENV.md) | Interface Godot/Python, observations/actions/récompenses, exemples de reset et capteurs | Candidat à comparer au bridge local sur une scène réduite ; le plugin ne réinitialise pas automatiquement toute la logique métier. Export ONNX annoncé expérimental, avec parcours .NET. [1] |
| [Stable-Baselines3](https://github.com/DLR-RM/stable-baselines3) | Entraînement PPO, sauvegarde de politique, outils d'évaluation | Choix par défaut pour une politique neuronale à observations structurées ; vérifier les versions conjointes avec Gymnasium et le bridge. [2] |
| [MiniGrid](https://github.com/Farama-Foundation/Minigrid) | Petites tâches distinctes de navigation et mémoire, API Gymnasium, complexité contrôlée | Inspiration de scénarios ; pas une migration du jeu. Le dépôt n'annonce pas de support Windows officiel. [3] |
| [Crafter](https://github.com/danijar/crafter) | Survie, collecte et mesure de compétences par accomplissements dans des mondes générés | Bon modèle d'évaluation par capacités ; sa complexité complète serait excessive pour la première preuve. [4] |
| [SB3-Contrib](https://github.com/Stable-Baselines-Team/stable-baselines3-contrib) et [Ni et al.](https://proceedings.mlr.press/v162/ni22a.html) | Politique récurrente pour information partielle ; masquage d'actions disponible dans un autre algorithme | Tester la récurrence seulement si une ablation démontre le besoin de mémoire. Ne pas supposer que RecurrentPPO et MaskablePPO se combinent directement. [5] |
| [imitation](https://github.com/HumanCompatibleAI/imitation) et [DAgger](https://proceedings.mlr.press/v15/ross11a.html) | Apprentissage depuis démonstrations ; correction sur les états réellement visités par l'apprenant | Repli borné si l'exploration manque de succès. L'expert doit être mesuré et ses appels comptabilisés. [6] |
| [rliable](https://github.com/google-research/rliable) | Intervalles, profils de performance, comparaison entre exécutions | Référence méthodologique ; dépôt archivé le 15 octobre 2025. Ne pas en faire une dépendance obligatoire sans validation. [7] |
| [Voyager](https://github.com/MineDojo/Voyager) | Curriculum, bibliothèque persistante de compétences et retour d'exécution | Apprentissage de compétences via requêtes LLM, sans affiner les poids dans l'approche présentée. Transfert à un petit modèle Ollama non établi. [9] |
| [Reflexion](https://github.com/noahshinn/reflexion) | Mémoire textuelle des retours d'expérience entre essais | Exemple d'adaptation sans entraînement des poids ; nécessite une comparaison avec mémoire désactivée. [10] |

### Réinitialisation, terminaisons et observation

Gymnasium distingue `terminated` et `truncated`. Une mort est terminale ; une coupure technique d'une tâche continue n'a pas le même traitement de bootstrap. Une tâche réellement définie à horizon fini doit rendre le temps restant observable et spécifier sa fin. La documentation ne remplace pas un test métier de reset, d'ordre des événements et d'observation finale. [11]

Le conseil de SB3 de partir d'une version simplifiée et de séparer l'évaluation de l'entraînement répond directement au projet. Cela suggère un curriculum alimentaire avant danger, avec comparaisons sur des épisodes frais. PPO est une référence pratique pour un environnement parallélisable ; ce choix reste une hypothèse d'ingénierie, pas une promesse de supériorité sur une table persistante. [2]

### Récompense utile sans détourner l'objectif

Préférer des événements observables : cueillette, consommation effective, mort et, plus tard, coût de danger. Tester les trajectoires qui exploiteraient la récompense sans atteindre le but : rester au contact, alterner deux cibles, accumuler sans consommer. Évaluer le résultat de jeu indépendamment de la récompense d'entraînement.

Si le retour terminal est trop rare, Ng, Harada et Russell étudient une mise en forme par potentiel : `F(s,s') = γΦ(s') − Φ(s)`, sous les hypothèses de leur cadre. Une simple prime à la proximité, un potentiel dont la cible change implicitement ou des fins mal traitées n'héritent pas automatiquement de cette garantie. N'ajouter ce mécanisme qu'avec ablation et état cohérent. [12]

### Place précise du LLM

Trois expériences différentes sont possibles : modifier les poids d'une politique ; conserver une mémoire externe qui améliore les décisions ; accumuler des compétences exécutables. Voyager et Reflexion documentent les deux dernières possibilités. Elles sont pertinentes pour l'objectif d'agents LLM, mais ne doivent pas être présentées comme une amélioration des poids. [9–10]

Le premier rôle proposé pour Ollama est de choisir un objectif parmi des compétences vérifiées et de conserver un bilan factuel des résultats. Les compétences exécutent les mouvements à cadence déterministe. L'expérience compare le même modèle avec et sans mémoire, à observations, outils et budget identiques. Un texte d'auto-évaluation positif ne constitue pas une récompense de référence.

L'affinage d'un LLM devient une branche possible une fois les trajectoires de démonstration validées. La documentation Ollama décrit l'import d'adaptateurs ou de poids produits par des outils d'entraînement externes. Il faut tester la chaîne modèle de base → affinage → export → inférence pour l'architecture exacte retenue ; la compatibilité de Gemma 3 ne peut pas être déduite de cette seule page. Aucun dimensionnement matériel sérieux n'est possible sans mesure locale de mémoire et de débit. [13]

## 3. Choix d'architecture recommandé

Conserver Godot comme source de vérité pour les contacts, ressources, faim et mort. Donner aux décideurs un contrat commun d'observations, d'actions et de temps. La micro-tâche T0 utilise des directions symétriques ; les niveaux alimentaires suivants privilégient des actions sémantiques bornées utilisant les primitives existantes, avec le même exécutant pour tous les bras. Si la primitive choisie se bloque, ce défaut relève de son test moteur avant d'être imputé au choix appris.

La première preuve utilisera une table persistante sur une micro-tâche avec états suffisants. Cette étape exploite le code existant et isole la valeur de l'expérience accumulée. Pour la scène riche, un petit réseau PPO via Gymnasium est le candidat par défaut si la table plafonne ; un historique court, puis une récurrence, seront comparés seulement si l'observation partielle le justifie.

Le bridge local et Godot RL Agents sont deux implémentations possibles du transport. Les comparer sur reset, ticks, headless, observation finale, isolation et maintenance, puis n'en garder qu'une pour l'entraînement neuf. La décision ne doit pas devenir une refonte préalable de tout le projet. Préserver les chemins historiques nécessaires aux régressions.

Les poids appris persistent entre épisodes ; les souvenirs de la carte, positions, stocks, compteurs et états récurrents repartent à zéro au reset. Pour une expérience d'adaptation en ligne, définir au contraire explicitement ce qui persiste et mesurer la performance avant/après adaptation à budget fixé. Cela répond à deux objectifs différents : savoir déjà agir et apprendre pendant une nouvelle vie.

## 4. Modification des roadmaps

La [roadmap danger](D:/ServOMorph/IA_Life/roadmap_environnement_apprenable_v3.md) subordonne toute reprise à la réussite de ses Phases 0–5. La proposition est de remplacer cette dépendance globale par un préalable plus étroit : une tâche alimentaire contrôlée doit être solvable et porter un signal d'action, puis un agent doit effectivement y apprendre.

La Phase 4 de persistance et la Phase 5 de protocole de la [roadmap apprentissage v2](D:/ServOMorph/IA_Life/roadmap_apprentissage_v2.md) remontent donc au début de la nouvelle séquence. L'approximation de fonction devient un candidat conditionnel à un diagnostic d'observation ou de capacité ; elle ne dépend plus de l'échec d'un oracle de danger. La meilleure politique fixe reste une référence, pas une borne supérieure mathématique sur toutes les politiques possibles.

Deux niveaux d'acceptation doivent rester distincts : une micro-tâche démontre que la chaîne apprend ; un benchmark alimentaire sur le monde complet démontre une fonctionnalité utile dans IA_Life. Réussir le premier sans le second est un résultat partiel. Battre une politique optimale programmée n'est pas nécessaire pour établir l'apprentissage ; battre sa propre initialisation et un contrôle comparable sans apprentissage l'est.

Le plan détaillé, les seuils proposés, les budgets bornés et les points d'arrêt figurent dans la [proposition de roadmap](D:/ServOMorph/IA_Life/roadmap_apprentissage_fonctionnel_proposition.md). Les statuts historiques et les critères des anciennes campagnes ne sont pas réécrits par cette analyse.

## 5. Questions expérimentales restantes

| Hypothèse | Expérience qui la tranche | Suite possible |
| --- | --- | --- |
| L'accumulation entre épisodes suffit sur une tâche simple | Table persistante contre même table remise à zéro, mêmes données disponibles et budgets | Conserver la table si elle suffit |
| La classification masque les décisions utiles | Trois situations historiques contre features détaillées, apprentissage et actions comparables | Enrichir l'état avant d'élargir encore les actions |
| L'exploration rencontre trop rarement un repas | Mesurer premiers succès ; comparer entraînement seul à amorçage par démonstrations | BC/DAgger borné, sans multiplier les algorithmes |
| Le besoin principal est la mémoire | Information complète diagnostic, information locale, historique court | Récurrence seulement si l'écart est explicable par l'information |
| La navigation détruit les gains de politique | Exécuter des cibles scriptées avec le même moteur, mesurer arrivées et blocages | Corriger la primitive commune ; ne pas ajuster le learner pour cacher le défaut |
| LLM et mémoire améliorent l'adaptation | Même modèle et outils, mémoire informative contre mémoire absente, budget égal | Conserver uniquement l'effet mesuré |

Le prochain travail concret doit être le contrat d'épisode et la première tâche de cueillette, pas un nouveau balayage de densité de danger ni une nouvelle revue générale de littérature.

## 6. Sources

Sources Web et GitHub consultées le 10 septembre 2026. Dates des articles indiquées ci-dessous ; les documentations et branches GitHub peuvent évoluer. Les licences mentionnées par les dépôts ne dispensent pas d'examiner celles des assets si du contenu est repris.

1. Beeching et al., *Godot Reinforcement Learning Agents*, 2021 : [article](https://arxiv.org/abs/2112.03636), [dépôt MIT](https://github.com/edbeeching/godot_rl_agents), [intégration d'un environnement](https://github.com/edbeeching/godot_rl_agents/blob/main/docs/CUSTOM_ENV.md).
2. DLR-RM, *Stable-Baselines3* : [dépôt MIT](https://github.com/DLR-RM/stable-baselines3), [conseils RL](https://stable-baselines3.readthedocs.io/en/master/guide/rl_tips.html). Implémentations, évaluation séparée et progression depuis un problème simplifié.
3. Farama Foundation, *MiniGrid* : [dépôt](https://github.com/Farama-Foundation/Minigrid). Tâches légères et contraintes de plateforme annoncées.
4. Hafner, *Crafter / Benchmarking the Spectrum of Agent Capabilities*, 2021 : [dépôt MIT](https://github.com/danijar/crafter). Survie et accomplissements comme mesures de capacités.
5. Ni, Eysenbach et Salakhutdinov, *Recurrent Model-Free RL Can Be a Strong Baseline for Many POMDPs*, ICML 2022 : [article](https://proceedings.mlr.press/v162/ni22a.html) ; [SB3-Contrib, MIT](https://github.com/Stable-Baselines-Team/stable-baselines3-contrib).
6. HumanCompatibleAI, *imitation* : [dépôt MIT](https://github.com/HumanCompatibleAI/imitation). Ross, Gordon et Bagnell, *A Reduction of Imitation Learning and Structured Prediction to No-Regret Online Learning*, 2011 : [article DAgger](https://proceedings.mlr.press/v15/ross11a.html).
7. Agarwal et al., *Deep Reinforcement Learning at the Edge of the Statistical Precipice*, 2021 : [article](https://arxiv.org/abs/2108.13264), [rliable, Apache-2.0, archivé](https://github.com/google-research/rliable).
8. Colas, Sigaud et Oudeyer, *How Many Random Seeds? Statistical Power Analysis in Deep Reinforcement Learning Experiments*, 2018 : [article](https://arxiv.org/abs/1806.08295).
9. Wang et al., *Voyager: An Open-Ended Embodied Agent with Large Language Models*, 2023 : [article](https://arxiv.org/abs/2305.16291), [dépôt MIT](https://github.com/MineDojo/Voyager).
10. Shinn et al., *Reflexion: Language Agents with Verbal Reinforcement Learning*, 2023 : [article](https://arxiv.org/abs/2303.11366), [dépôt](https://github.com/noahshinn/reflexion).
11. Farama Foundation, *Gymnasium* : [contrat Env](https://gymnasium.farama.org/api/env/), [terminaison et limites de temps, documentation v0.26.3](https://gymnasium.farama.org/v0.26.3/tutorials/handling_time_limits/). La page ancienne est utilisée pour l'explication, pas pour figer une version logicielle.
12. Ng, Harada et Russell, *Policy Invariance Under Reward Transformations: Theory and Application to Reward Shaping*, 1999 : [article original](https://ai.stanford.edu/~ang/papers/shaping-icml99.pdf).
13. Ollama, *Importing a Model* : [documentation officielle](https://docs.ollama.com/import). Import d'adaptateurs, identité du modèle de base et formats.

## Annexe — Démarche de recherche et contrôles réalisés

1. Lecture des règles locales et de la mémoire projet ; inventaire du code d'apprentissage, des roadmaps et de la documentation pertinente.
2. Analyse du chemin observation → choix → mouvement → récompense → mise à jour → fin d'épisode pour les trois décideurs.
3. Lecture des configurations et résultats M1 v2 et danger v2 ; recalcul des agrégats M1 depuis les summaries. Pas de nouvelle mesure de simulation.
4. Inspection des tests de crédit et du rapport statistique ; calcul exact du cas neuf victoires/trois défaites.
5. Recherches Web/GitHub : `Godot RL Agents GitHub stable baselines reinforcement learning`, `reinforcement learning evaluation few seeds rliable deep reinforcement learning precipice`, `Voyager Minecraft LLM lifelong learning GitHub Reflexion`.
6. Recherches ciblées : `site.gymnasium.farama.org handling time limits terminated truncated bootstrapping`, `site.stable-baselines3.readthedocs.io reinforcement learning tips evaluation separate environment`, `site.proceedings.mlr.press recurrent model free reinforcement learning strong baseline partial observability`.
7. Compléments : `Ng Harada Russell 1999 policy invariance reward transformations potential`, `site.github.com danijar crafter achievements survival reward`, `site.docs.ollama.com import fine tuned adapter safetensors`.
8. Ouverture des dépôts et sources primaires listés ci-dessus ; comparaison des interfaces, de l'usage envisagé, des limitations de plateforme et du statut d'archivage pertinent. Les posts de forums trouvés n'ont pas servi de preuve technique.
9. Traduction en une proposition bornée : hypothèses, ablations, critères de passage, budgets de départ et reprise conditionnelle du danger/LLM.

Restent à effectuer lors de l'implémentation : compatibilité locale, tests moteur de reset/pause/cadence, mesure de débit, entraînements et validation indépendante. Aucun de ces points n'est déclaré réussi dans ce rapport.
