# IA_Life — voie RL la plus rapide sous Godot 4.5

**Décision visée :** obtenir, en moins d'une journée de développement et d'entraînement, des preuves mesurées qu'une même politique apprise permet à des agents de survivre et de cueillir mieux qu'un comportement aléatoire / le baseline.  
**Date de recherche :** 23 août 2026.  
**Périmètre :** Godot 4.5, GDScript, quatre agents, monde survival/collecte actuel ; aucun changement de code dans cette étude.

## Réponse directe

Le chemin le plus court est un **PPO à politique partagée** : les quatre agents exécutent le *même* réseau et fournissent chacun une transition d'apprentissage. Ce n'est pas encore du MARL centralisé, mais c'est déjà une expérience multi-agent valable où les autres agents font partie de l'environnement. Il supprime le besoin de concevoir quatre politiques, une state globale ou du credit assignment collectif.

Utiliser **Godot RL Agents + Stable-Baselines3** si — et seulement si — un test de compatibilité du plugin avec l'exécutable Godot 4.5 .NET réussit immédiatement. C'est le bridge le plus documenté pour démarrer : il expose les callbacks Godot d'observation, récompense et action, synchronise avec Python par TCP, et fournit un wrapper SB3 Windows. Le projet GDRL indique toutefois que l'entraînement dans l'éditeur et l'inférence ONNX passent par l'édition .NET/Mono : ne pas convertir le projet existant ni remplacer `D:/Godot/godot.exe` sans ce smoke test. [Godot RL Agents — README](https://github.com/edbeeching/godot_rl_agents) ; [custom environment](https://github.com/edbeeching/godot_rl_agents/blob/main/docs/CUSTOM_ENV.md).

Pour le premier résultat, **ne pas commencer par RLlib, PettingZoo, QMIX/MAPPO, LSTM, image observations, ONNX, ni par l'agent riggé**. Ces éléments sont des extensions de phase 2. RLlib est l'option à garder lorsque l'objectif devient explicitement l'étude de coopération/compétition avec plusieurs politiques ou entraînement centralisé : son API est adaptée au MARL, mais son propre guide indique que les environnements multi-agent ne sont pas encore vectorisés comme les environnements single-agent. [RLlib multi-agent](https://docs.ray.io/en/master/rllib/multi-agent-envs.html) ; [guide de passage à l'échelle](https://docs.ray.io/en/latest/rllib/scaling-guide.html).

## État réellement disponible dans IA_Life

L'examen demandé du code montre que l'interface expérimentale existe déjà, mais pas encore une interface pas-à-pas pour un entraîneur RL.

| Élément | État constaté | Réemploi RL |
| --- | --- | --- |
| `scripts/character.gd` | Simulation physique `CharacterBody3D`, faim, mort, déplacement, cueillette, mémoire, social et compteurs par agent. La décision est aujourd'hui déléguée à `baseline_decider.gd`. | Extraire une façade contrôleur : le RL fixe direction/action ; le personnage garde terrain, collision, faim, cueillette et métriques. |
| `scripts/game_config.gd` | Sept variables globales, dont nombre de ronces et baies par ronce. | Les conserver comme paramètres de scénario/curriculum ; éviter de les modifier pendant un épisode. |
| `run_headless.py` | Lance Godot headless, transmet une configuration JSON temporaire et la révision Git ; timeout Python. | À conserver pour l'évaluation reproductible et les campagnes. Ce lanceur n'est pas une boucle `reset/step` : seul, il ne permettrait qu'un épisode par processus, trop lent pour PPO. |
| `scripts/game_logger.gd` | Journal lisible, JSONL structuré, session et `summary.json`. | Garder comme trace canonique de chaque évaluation et ajouter `episode_id`, seed, policy checkpoint, retour et cause de fin dans les données RL. |

Le projet est confirmé en **Godot 4.5 stable Forward+**. La décision de bridge doit donc explicitement tester cette version, non s'appuyer sur une compatibilité Godot 4 générique.

## Options réalistes comparées

| Option | Ce qu'elle apporte | Frein pour < 1 jour | Verdict |
| --- | --- | --- | --- |
| **GDRL + SB3 PPO, politique partagée** | Bridge Godot↔Python existant ; PPO multi-process ; quickstart Windows ; API à quatre callbacks. GDRL annonce SB3, CleanRL, Sample Factory et RLlib. | Plugin historiquement .NET/C# ; valider l'édition/export .NET 4.5 sur cette machine avant toute intégration. SB3 n'est pas un framework MARL natif. | **Choix recommandé**, à condition que le smoke test prenne moins d'une heure. |
| **GDRL + RLlib** | Multi-policy, mapping agent→policy, API MARL ; exemple GDRL « MultiAgent Simple ». | Dépendances plus lourdes, incompatibilité de venv indiquée par GDRL avec SB3/Gymnasium, orchestration et coût de debug plus élevés. | Phase 2 seulement. |
| **Bridge TCP/JSON sur mesure + Gymnasium/SB3** | Pas de dépendance .NET ; réutilise directement le Godot standard et peut adapter exactement le protocole IA_Life. | Il faut écrire, déboguer et tester `reset/step`, synchronisation, action batching et arrêt propre : risque élevé de dépasser la journée. | Plan B si GDRL .NET échoue ; ne pas l'écrire avant l'échec confirmé. |
| **`godot-native-rl` + backend Python** | Addon récent pour Godot 4.5+, GDScript/C++ natif sans .NET ; annonce compatibilité `godot_rl` 0.8.2 et interop PettingZoo. | Projet récent, surface fonctionnelle très large et confiance opérationnelle plus faible que GDRL ; dépendance native supplémentaire. | Alternative technique intéressante si éviter .NET est non négociable, mais pas le choix « premiers résultats » sans essai préalable. [Dépôt](https://github.com/minigraphx/godot-native-rl). |
| Lancer `run_headless.py` par épisode | Réemploie tout de suite les fichiers existants. | Aucun échange de pas/action pendant une partie, démarrage Godot à chaque épisode : collecte beaucoup trop lente. | Évaluation uniquement. |
| RL maison GDScript / évolution génétique | Aucun bridge Python obligatoire. | Pas de bibliothèque de PPO prête ni métriques comparables immédiates ; détourne du but RL/MARL. | Hors périmètre du sprint. |

### Pourquoi PPO partagé, pas MARL complet d'emblée

Les quatre agents ont le même corps, le même espace d'actions et le même objectif local de survie. Une politique partagée fait donc converger quatre fois plus de transitions dans un même modèle, tout en permettant les évaluations par agent. Le partage ne suppose pas que les agents soient identiques : l'observation inclut leur faim, inventaire et voisins.

Le cadre devient du MARL au sens interactionnel dès lors que les agents se perçoivent ; il reste **independent learning with parameter sharing**. Ce choix est délibéré : il répond à « apprennent à survivre/cueillir » sans prétendre démontrer la coopération. Pour tester la coopération ensuite, le contrat naturel est `ParallelEnv`/RLlib : chaque pas reçoit les actions de tous les agents et renvoie observations, récompenses, `terminated`, `truncated` et informations par identifiant. [PettingZoo Parallel API](https://pettingzoo.farama.org/api/parallel/).

## Architecture proposée — MVP entraînable

```text
4 × Character.gd  ── obs/reward/action ──> RLController (un par agent)
       │                                           │
       ├── faim, ronces, mémoire, social, terrain  ├── AIController3D GDRL
       └── GameLogger JSONL / summary              └── Sync TCP
                                                        │
                                  Stable-Baselines3 PPO, 1 politique partagée
                                                        │
                           checkpoints / TensorBoard / évaluations headless réutilisant logs
```

### Contrat de pas

- **Décision à 4 Hz** : une action RL est maintenue pendant 0,25 s de **temps simulé**, jamais de temps réel. Le delta de simulation reste piloté par `GameSpeed.time_scale` (`scaled_delta = delta * GameSpeed.time_scale`) ; augmenter cette vitesse réduit le temps mural sans changer la durée simulée ni le contrat de décision. La physique continue à 60 Hz. Ce contrôle est suffisamment fin pour tourner et suffisamment grossier pour apprendre vite.
- **Épisode** : 2 400 décisions (10 minutes simulées à 4 Hz) ; `terminated` si mort ; `truncated` au time-limit. Ne pas confondre ces deux fins, conformément à l'API Gymnasium et aux recommandations SB3. [Gymnasium Env API](https://gymnasium.farama.org/api/env/) ; [conseils SB3](https://stable-baselines3.readthedocs.io/en/master/guide/rl_tips.html).
- **Reset** : seed explicite, positions de spawn déterministes, ronces et nombre de baies issus d'`ExperimentConfig`, remise à zéro de tous les compteurs. Une seed est réservée à l'entraînement, une autre au test.
- **Politique** : MLP PPO (`MlpPolicy`) ; `VecNormalize` sur les observations puis gelé à l'évaluation. PPO est le choix rapide lorsque la collecte parallèle réduit le temps mural ; SB3 recommande des observations normalisées, un reward façonné et un environnement simplifié au démarrage. [PPO SB3](https://stable-baselines3.readthedocs.io/en/master/modules/ppo.html) ; [tips SB3](https://stable-baselines3.readthedocs.io/en/master/guide/rl_tips.html).

### Observations vectorielles v1 (27 floats, pas de caméra)

Toutes les distances sont divisées par la diagonale de la carte ; les directions sont dans le repère local de l'agent ; les compteurs sont bornés à `[0,1]`.

| Groupe | Dimensions | Contenu |
| --- | ---: | --- |
| État interne | 4 | faim, baies portées / capacité, taille mémoire / capacité, temps restant / durée épisode |
| Cinématique | 4 | position `x,z`, direction actuelle `x,z` |
| Ressource visible/mémorisée | 6 | direction et distance de la ronce connue la plus proche, quantité normalisée ; même triplet pour la ronce visible la plus proche. Valeurs zéro + masque implicite si absente. |
| Proximité de carte | 4 | distances normalisées nord, sud, est, ouest |
| Social | 9 | pour les trois voisins les plus proches : direction `x,z` + distance ; zéro s'il n'existe pas |

Ne pas exposer la liste globale de toutes les ronces ou positions exactes de tous les agents : cela court-circuiterait perception et mémoire. Pour v1, une requête de proximité simple est préférable aux raycasts/image sensors ; l'objectif est un signal d'apprentissage, non un benchmark de vision.

### Actions v1

`Discrete(7)` : avancer, avancer-gauche, gauche, arrière-gauche, arrière, arrière-droite, droite. Chaque action devient un `Vector3` normalisé appliqué comme direction pendant le pas RL. La cueillette et la consommation restent automatiques **au premier entraînement** : l'agent apprend localisation et déplacement, non la gestion d'un bouton. Le contrôle explicite de `PICKUP`/`EAT` est une expérience v2 après preuve que le déplacement apprend.

> Si après 100–150 k steps l'agent n'arrive pas à tourner efficacement, passer en action continue `Box([-1,1], shape=(2,))`.

Cette action discrète évite les problèmes de mise à l'échelle d'une action continue et donne un diagnostic immédiatement lisible. Si une action continue est adoptée ensuite, elle doit être symétrique `[-1,1]` puis remise à l'échelle dans le jeu. [conseils SB3](https://stable-baselines3.readthedocs.io/en/master/guide/rl_tips.html).

### Reward v1 : dense, borné, orienté survie

| Événement par pas | Récompense | Justification |
| --- | ---: | --- |
| Chaque seconde vivante | +0,005 | Signal minimal de survie. |
| Une baie cueillie | +0,30 | Apprendre à atteindre une ressource. |
| Une baie consommée | +1,00 | Objectif instrumental : restaurer la faim. |
| Mort | -2,00 | Évite les politiques qui collectent sans survivre. |
| Temps / pas | -0,001 | Encourage l'efficience sans écraser les récompenses alimentaires. |
| Première zone visitée | +0,02, plafond 20/épisode | Démarre l'exploration ; plafond pour ne pas apprendre l'errance. |

Pas de récompense sociale en v1 : elle masquerait le résultat survival. Après une baseline fiable, une condition expérimentale peut ajouter une récompense coopérative explicite et comparer à la condition individuelle.

## Plan exécutable, avec coupe-circuit d'une journée

| Temps | Étape et critère de sortie |
| ---: | --- |
| 0:00–0:30 | Créer une scène RL minimale, séparée de la scène visuelle/dev. Installer GDRL dans une copie/branche et vérifier chargement dans Godot 4.5 .NET, puis une connexion Python↔Godot. **Stop** : si l'addon ne charge pas ou le bridge ne répond pas en 30 min, basculer vers l'essai `godot-native-rl`; si lui aussi échoue, arrêter avant tout développement de MARL et choisir explicitement le bridge TCP sur mesure. |
| 0:30–2:00 | Ajouter `RLController` : `get_obs`, `get_reward`, `get_action_space`, `set_action`; action directionnelle remplace seulement `_decider.decide` quand le mode RL est actif. Ajouter reset déterministe et fin d'épisode. |
| 2:00–2:30 | Tests à actions aléatoires : bornes, aucune valeur NaN, reset identique à seed fixe, morte/timeout correctement séparés, 4 agents connectés. Exécuter `check_env` côté Python quand l'API le permet. |
| 2:30–3:00 | Smoke train court PPO (10–20 k décisions) : la récompense moyenne doit bouger et un checkpoint se charge. Corriger reward/obs avant de lancer longtemps. |
| 3:00–6:00 | Entraînement PPO : 4 agents × plusieurs mondes/processus si le bridge le permet, checkpoints toutes les 25 k décisions, évaluation toutes les 10 k. Commencer par 100–300 k décisions, pas par plusieurs millions. |
| 6:00–7:00 | Évaluer sur 20 épisodes × 5 seeds de test, politique déterministe, puis baseline actuel et actions aléatoires sur les mêmes configs. Produire tableau, courbes et exports JSONL/summary existants. |

Un résultat en moins d'un jour signifie **signe de vie mesuré** (survie/cueillette au-dessus des contrôles), pas robustesse scientifique définitive. SB3 souligne que le RL model-free est souvent peu efficient en échantillons et doit être évalué sur plusieurs seeds ; l'étude doit donc signaler clairement le nombre de seeds et intervalles de confiance. [conseils SB3](https://stable-baselines3.readthedocs.io/en/master/guide/rl_tips.html).

## Configuration de départ exacte

```python
# principe ; adapter au wrapper GDRL effectivement validé
PPO(
    "MlpPolicy", env,
    learning_rate=3e-4,
    n_steps=1024,
    batch_size=256,
    n_epochs=10,
    gamma=0.995,
    gae_lambda=0.95,
    clip_range=0.2,
    ent_coef=0.01,
    vf_coef=0.5,
    max_grad_norm=0.5,
    tensorboard_log="logs/rl/tensorboard",
)
```

À conserver dans le manifeste de chaque run : version Godot, commit Git, version `godot-rl`, version SB3/PyTorch, configuration JSON complète, seed d'environnement, seed Python/Numpy/Torch, nombre d'agents, fréquence de décision, espace obs/actions, reward version et hash de checkpoint. Le projet logge déjà une partie de ces données : il faut les unifier, non créer un deuxième système.

## Évaluation : ce qui prouvera un apprentissage utile

Rapporter la médiane, moyenne et intervalle bootstrap 95 % par seed et par agent ; ne jamais se contenter d'une vidéo ou de la reward d'entraînement.

| Famille | Mesure primaire | Mesures de diagnostic |
| --- | --- | --- |
| Survie | taux de survie au time-limit ; durée de vie | temps jusqu'à première mort, distribution de faim terminale |
| Nourriture | baies consommées / épisode | baies cueillies, rendement cueillies→consommées, inventaire perdu à la mort |
| Efficience | distance par baie consommée | distance totale, temps entre découvertes et consommation |
| Exploration/mémoire | zones découvertes et revisites | succès vers ronce mémorisée, taux de mémoire à pleine capacité |
| Stabilité | score sur 5 seeds de test non vues | variance entre agents, AUC de la courbe d'évaluation, taux d'épisodes invalides |
| Social (sans reward v1) | distance/contacts par agent | rencontres, secondes de regroupement, suivis/évitements : observer sans récompenser |

Contrôles obligatoires : (1) actions aléatoires, (2) `BaselineDecider`, (3) PPO appris. Même cartes, mêmes seeds de test, même time-limit, aucune intervention manuelle. Une politique PPO est déclarée meilleure seulement si elle dépasse les deux contrôles sur la métrique primaire et qu'elle ne dégrade pas massivement la survie.

## Après le MVP : chemin MARL sans réécriture

1. Garder l'identifiant stable de chaque agent et produire obs/actions/rewards/terminaisons sous forme de dictionnaires simultanés.
2. Introduire une condition de ressources rares où les autres agents affectent réellement la récompense.
3. Porter ce contrat vers `PettingZoo ParallelEnv`, puis RLlib `MultiAgentEnv` si des politiques distinctes ou un entraînement centralisé sont nécessaires. PettingZoo est particulièrement adapté au pas simultané ; son `state()` est précisément prévu pour les méthodes CTDE telles que QMIX. [PettingZoo](https://pettingzoo.farama.org/api/parallel/).
4. Comparer trois politiques : partagée indépendante, deux profils partagés (explorateur/prudent), puis MAPPO/QMIX. Ne pas attribuer un comportement social à l'algorithme sans le comparer à une condition reward/observation identique.

## Limites et risques vérifiés

- **Compatibilité GDRL / Godot 4.5 :** la documentation officielle GDRL parle de Godot 4 et demande le build .NET pour l'entraînement en éditeur ; elle ne garantit pas explicitement le couple local `4.5.stable + Godot standard actuel`. Le smoke test est donc un prérequis, pas une formalité.
- **Débit :** la performance publiée par GDRL (12 k interactions/s sur 4 cœurs) est un benchmark de leur environnement Jumper sur un portable donné en 2021 ; ce n'est pas une prévision pour IA_Life. Mesurer `steps/s` localement avant de choisir le nombre de mondes. [article GDRL](https://arxiv.org/abs/2112.03636).
- **Ressources rares :** elles peuvent rendre le reward de consommation trop sparse. Débuter avec plus de ronces/baies, puis réduire par curriculum après succès.
- **Récompense façonnée :** elle peut apprendre des comportements opportunistes. Les métriques primaires, les contrôles et des évaluations sans bonus d'exploration sont les garde-fous.
- **Déterminisme :** le jeu a déjà seeds/configurations ; traiter l'ordre d'itération des agents, la génération de ronces et les resets comme des éléments testables avant d'interpréter un gain RL.

## Sources et registre des affirmations

| Source | Éditeur / date consultée | Éléments utilisés |
| --- | --- | --- |
| [Godot RL Agents README](https://github.com/edbeeching/godot_rl_agents) | edbeeching, consulté le 2026-08-23 | bridge Python, backends, support Windows SB3, ONNX expérimental, nécessité .NET mentionnée. |
| [GDRL — custom environment](https://github.com/edbeeching/godot_rl_agents/blob/main/docs/CUSTOM_ENV.md) | edbeeching, consulté le 2026-08-23 | callbacks obs/reward/action, TCP Sync, accélération, contrôleur 3D. |
| [GDRL examples](https://github.com/edbeeching/godot_rl_agents_examples) | edbeeching, consulté le 2026-08-23 | exemple multi-agent RLlib. |
| [Godot RL Agents paper](https://arxiv.org/abs/2112.03636) | Beeching et al., 2021, consulté le 2026-08-23 | architecture et benchmark historique, accès aux algorithmes. |
| [RLlib multi-agent environments](https://docs.ray.io/en/master/rllib/multi-agent-envs.html) | Ray, consulté le 2026-08-23 | politiques multiples, mapping, API dict par agent. |
| [RLlib scaling guide](https://docs.ray.io/en/latest/rllib/scaling-guide.html) | Ray, consulté le 2026-08-23 | limite actuelle de vectorisation MARL. |
| [PettingZoo Parallel API](https://pettingzoo.farama.org/api/parallel/) | Farama Foundation, consulté le 2026-08-23 | contrat simultané et `state()` pour CTDE. |
| [SB3 PPO](https://stable-baselines3.readthedocs.io/en/master/modules/ppo.html) et [tips](https://stable-baselines3.readthedocs.io/en/master/guide/rl_tips.html) | Stable-Baselines3, consulté le 2026-08-23 | PPO, parallèle, normalisation, reward shaping, tests multi-seeds et limites. |
| [Godot Native RL](https://github.com/minigraphx/godot-native-rl) | minigraphx, consulté le 2026-08-23 | alternative Godot 4.5+ sans .NET, protocole `godot-rl`, PettingZoo annoncé. |

### Arrêt de recherche

La recherche s'arrête ici : les sources primaires couvrent le bridge recommandé, son risque de compatibilité, le framework de premier entraînement et l'option MARL future. Les projets de démo survival trouvés n'apportent pas de contrat plus fiable que les APIs et dépôts cités ; les reproduire ou les privilégier augmenterait le risque sans accélérer le MVP.
