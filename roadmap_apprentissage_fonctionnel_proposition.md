# Roadmap proposée — Apprentissage fonctionnel dans IA_Life

Proposition du 10 septembre 2026. Non adoptée, aucune phase de développement engagée.
Analyse de référence : [diagnostic et recherche Web/GitHub](D:/ServOMorph/IA_Life/_docs/2026-09-10_recherche_apprentissage.md).

Cette proposition remplace, si elle est retenue, le chemin critique « calibration du danger → reprise de l'apprentissage ». Elle conserve les résultats historiques, mais donne la priorité à une preuve d'apprentissage alimentaire entre épisodes. Les dangers deviennent une extension ; un agent LLM utilisant des compétences ou une mémoire d'expérience reste une destination explicite du projet.

## Résultat attendu

Un agent s'améliore grâce à son expérience, conserve ses paramètres entre parties et utilise ces acquis dans une nouvelle partie. Le gain doit être mesuré contre le même agent non entraîné et un contrôle sans apprentissage comparable, sur des cartes non utilisées pour les réglages.

Deux jalons distincts :

- **Première preuve, fin de Phase 2** : une politique initialement neutre apprend une tâche alimentaire courte, puis conserve ce savoir après rechargement. Ce n'est pas encore la validation du monde complet.
- **Fonctionnalité alimentaire livrée, fin de Phase 5** : le modèle retenu réussit le benchmark indépendant et peut piloter un personnage dans le jeu avec ses paramètres sauvegardés.

L'adaptation pendant une vie nouvelle, l'évitement du danger et la mémoire LLM sont mesurés séparément. Une amélioration de la récompense interne, une table qui change ou un personnage qui semble plus habile ne suffisent pas.

## Amendements précis aux plans actuels

| Emplacement actuel | Modification proposée lors de l'adoption |
| --- | --- |
| [Apprentissage v2 — bandeau de suspension](D:/ServOMorph/IA_Life/roadmap_apprentissage_v2.md) | Autoriser une nouvelle expérience alimentaire versionnée, distincte des anciennes campagnes ; conserver leurs verdicts |
| Apprentissage v2 — Phase 4, persistance | Avancer sauvegarde, rechargement et séparation entraînement/évaluation aux Phases 1–2 ci-dessous |
| Apprentissage v2 — Phase 5, protocole | Définir le protocole avant toute nouvelle mesure, dès la Phase 0 |
| Apprentissage v2 — Phase 6, approximation | Rendre le réseau conditionnel à une limite mesurée de la table, de l'observation ou de la généralisation ; pas à la victoire préalable d'un oracle danger |
| [Environnement v3 — condition de déblocage](D:/ServOMorph/IA_Life/roadmap_environnement_apprenable_v3.md) | Supprimer sa portée bloquante sur l'apprentissage alimentaire ; conserver ses conditions si l'on prétend valider l'ancien axe danger |
| Environnement v3 — Phase 3, contournement | Sortir les balayages de danger du chemin critique ; décider du candidat en attente lors de l'adoption, sans le déclarer validé |
| Benchmark historique | Ajouter un nouveau benchmark ; ne pas comparer directement des scores issus d'environnements ou d'actions différents |

Les statuts existants restent inchangés dans cette proposition. Leur mise à jour relève de `/close`. Les anciennes seeds réservées restent protégées ; aucun résultat nouveau ne doit servir à réinterpréter rétrospectivement un ancien gate.

## Contrat expérimental commun

### Ce qui varie et ce qui reste comparable

Dans chaque niveau, tous les bras utilisent le même monde initial, les mêmes observations autorisées, actions disponibles, durées et primitives d'exécution. Un oracle disposant de la carte complète est un diagnostic de solvabilité séparé ; il ne compte pas comme adversaire équitable d'un agent à vision locale.

Le moteur gère les mouvements et contacts. La politique choisit une action. Une macro-action qui rejoint une ressource est annoncée comme une compétence programmée ; l'apprentissage porte alors sur son choix, pas sur sa navigation. Les masques indiquent seulement la validité d'une action, jamais celle qui est optimale.

Pour les premiers épisodes, un seul agent agit. Les trois agents à politique fixe sont réintroduits au transfert. Les checkpoints d'entraînement conservent paramètres, état de l'optimiseur si utilisé, normalisation, RNG, compteur d'expérience, schéma et empreinte de configuration. Ils ne conservent pas silencieusement le stock des ressources ou les souvenirs de la carte précédente.

### Références obligatoires

| Bras | Rôle |
| --- | --- |
| Candidat entraîné, figé à l'évaluation | Résultat après expérience |
| Même candidat initial, figé | Mesure avant/après à architecture identique |
| Aléatoire sur les actions valides du candidat | Contrôle d'exploration avec le même exécutant et la même cadence |
| Même entraînement avec remise à zéro entre épisodes | Ablation de la persistance pour la table |
| Automate et meilleure politique fixe pertinente | Références de performance ; leur supériorité éventuelle n'invalide pas à elle seule l'existence d'apprentissage |

Pour un réseau, conserver les initialisations correspondant à chaque seed d'entraînement. Pour une politique déjà initialisée par imitation, conserver aussi le checkpoint après imitation afin d'isoler l'effet du RL.

### Échantillonnage et acceptation

Proposition de départ : séparer cartes d'entraînement, 32 cartes de validation et 64 cartes de test final nouvelles. Vérifier l'absence de recouvrement avec les réserves historiques avant d'écrire les listes. Les seeds numériques seront créées et verrouillées en Phase 0, avant de mesurer les tâches nouvelles.

Utiliser trois initialisations d'entraînement pour les expériences de développement, puis cinq pour la confirmation. Ces nombres sont des budgets proposés, pas une garantie de puissance. Un pilote sur validation détermine si ce plan peut détecter l'effet minimal ; augmenter le nombre d'entraînements avant le gel final si nécessaire et compatible avec le budget.

Ne pas traiter les `5 × 64` évaluations comme 320 apprentissages indépendants. Appariement par carte, identifiant d'entraînement et politique ; estimation d'incertitude tenant compte des entraînements et des cartes partagées. Présenter aussi les résultats par entraînement. Égalités, runs manquants et doublons sont explicites ; un lot incomplet ne passe pas.

Pour le monde alimentaire complet, critère proposé :

- gain de survie d'au moins 0,10 contre l'initialisation et contre l'aléatoire comparable ;
- borne inférieure d'un intervalle bilatéral à 95 % du gain strictement positive pour ces deux contrastes, avec correction de multiplicité préenregistrée ;
- survie absolue d'au moins 0,60 et absence de régression alimentaire majeure selon une marge préenregistrée avant entraînement ;
- preuve causale complémentaire : l'ablation des acquis dégrade la performance, et le rechargement conserve les décisions attendues.

Les valeurs sont des exigences proposées pour la nouvelle tâche. Si le pilote montre une tâche saturée ou impossible, redéfinir et versionner le contrat avant l'entraînement comparatif. Ne pas changer ensuite de métrique pour sauver un candidat. Un intervalle trop large donne « indéterminé » ; un résultat sous le seuil donne « critère non atteint », pas « impossible à apprendre ».

### Budgets et limites de recherche

Première preuve tabulaire : checkpoints à 0, 10, 50, 200 et 1 000 épisodes maximum par entraînement. Réseau éventuel : paliers à 100 000, 300 000 et 1 000 000 transitions maximum par entraînement, prolongés seulement si le diagnostic précédent le justifie. Ce sont des plafonds initiaux à préenregistrer ; aucun délai matériel n'est promis.

Mesurer d'abord transitions utiles/seconde, coût des resets et mémoire utilisée. Estimer ensuite `durée = transitions totales / débit observé + évaluations + resets`. Conserver `game_speed = 1` ; revalider séparément toute accélération à pas physique constant pour le nouveau chemin. Au plus deux variantes de représentation et une voie de repli algorithmique après le candidat principal : pas de recherche ouverte de combinaisons.

## Phase 0 — Fixer la tâche et le protocole [TODO]

**Recherche restante.** Utiliser le diagnostic déjà livré ; ne pas refaire une revue générale. Examiner seulement les points manquants : budget local, compatibilité Python/Godot, disponibilité d'une scène réduite réutilisant les mécaniques alimentaires. Relier chaque choix à une hypothèse mesurable.

**Travail.** Formaliser les observations autorisées, actions, horloge, récompenses, reset et distinction fin de tâche/coupure. Écrire les listes de seeds, les bras, les seuils, le budget, les règles de choix du checkpoint et l'analyse statistique. Séparer les nouveaux fichiers de campagne des références gelées. Prévoir un contrôle omniscient uniquement comme diagnostic, explicitement étiqueté.

**Livrable.** Contrat versionné et matrice des expériences T0–T3 ci-dessous, avec les valeurs exactes avant leur utilisation. Les sources pertinentes sont Gymnasium, SB3, MiniGrid et la recherche sur l'évaluation référencées dans l'analyse.

**Gate.** Chaque résultat annoncé correspond à une mesure définie ; aucun état de carte n'est confondu avec une seed d'entraînement. Une expérience supplémentaire doit répondre à une hypothèse écrite et entrer dans le budget.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 1 — Fiabiliser les transitions et conserver l'expérience [TODO]

**Recherche ciblée.** Trancher le statut de la sortie de faim, de la mort et de l'arrêt au temps limite. Choisir une cadence fixe pour les expériences neuves, ou un traitement explicite de la durée des engagements ; ne pas mélanger ces conventions.

**Développement.** Ajouter au chemin expérimental tabulaire la sauvegarde/recharge et un mode d'évaluation qui ne modifie pas la table. Distinguer réinitialisation du monde, réinitialisation de l'état transitoire du décideur et remise à zéro volontaire de ses paramètres. Garantir un crédit unique de la dernière transition, y compris récompense suivie immédiatement d'une mort ou d'une coupure. Garder les schémas historiques lisibles sans leur appliquer les nouvelles sémantiques.

Les campagnes tabulaires peuvent d'abord utiliser un processus Godot frais par épisode, avec passage explicite de la table ; cela évite de rendre la migration du bridge préalable à la première preuve. Adapter le rapport pour refuser les lots incomplets et préserver les identifiants de répétition/entraînement.

**Tests créés et exécutés.** Sauvegarde/recharge identique ; rejet de schéma incompatible ; aucune mise à jour en évaluation ; fin terminale sans bootstrap ; coupure avec sémantique correcte ; récompense finale non perdue/non doublée ; reprise d'une lignée sans contamination d'une autre. Tester aussi les ex æquo de scores : le premier élément de la liste ne doit pas passer pour un acquis.

**Gate.** Une reprise reproduit la suite attendue ; le checksum des paramètres reste constant pendant une évaluation ; toutes les transitions du scénario verrouillé sont comptées une fois. Aucun gain de jeu n'est encore revendiqué.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 2 — Première preuve alimentaire entre épisodes [TODO]

**Recherche ciblée.** Définir un exercice où la bonne réponse dépend d'une observation et où le moteur sait exécuter toutes les options. S'inspirer des tâches élémentaires MiniGrid sans importer sa simulation à la place de Godot.

**Tâche T0.** Petite arène, un personnage, une ressource visible à position variable, sans danger ni concurrence. Actions directionnelles symétriques et cadence bornée ; la cueillette réelle dans Godot constitue le succès. La table reçoit notamment le secteur relatif de la ressource. L'aide moteur est identique pour le candidat et ses contrôles ; aucune action « réussir automatiquement ».

**Développement.** Ajouter le scénario déterministe, une petite représentation tabulaire explicitement distincte des trois situations historiques, la lignée d'entraînement et le gel de politique. Réutiliser les contacts et règles alimentaires, avec seuils initiaux choisis pour que la cueillette soit possible. Ne pas créditer seulement une distance géométrique comme si une mûre avait été récoltée.

**Expériences.** Contrôle scripté pour chaque placement ; candidat neutre → entraîné ; aléatoire comparable ; remise à zéro entre épisodes. Rotation des positions, apprentissages indépendants, checkpoints selon le budget commun. La politique scriptée prouve la solvabilité ; elle ne fournit pas de démonstrations au candidat principal.

**Tests créés et exécutés.** Contact et stock réels, ressource hors contact sans récompense, symétrie des actions, reproductibilité, absence de réponse préchargée, sauvegarde/recharge et évaluation figée.

**Gate proposé.** Sur validation, au moins 0,90 de réussite, gain d'au moins 0,30 sur l'initialisation et l'aléatoire comparable, gain positif pour chaque entraînement de développement. Confirmer la conservation après recharge. Ce gate est un jalon d'ingénierie, pas la preuve finale sur le monde complet.

**Échec.** Si le contrôle scripté échoue, corriger le scénario/moteur. Si lui seul réussit, examiner observations, transitions et fréquence des premiers succès avant tout nouvel algorithme. À budget épuisé, publier la cause établie ou l'incertitude ; ne pas relancer une grille de danger.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 3 — Interface d'entraînement extensible [TODO]

**Recherche ciblée.** Comparer le bridge local à Godot RL Agents sur le même T0 : compatibilité Windows/Godot, cadence, reset, observation finale, headless et isolation de processus. Choisir un seul transport pour le nouveau chemin ; conserver une table persistante comme candidat si elle suffit.

**Développement.** Exposer un environnement Gymnasium avec reset complet du monde. Déplacer la frontière d'action sur un nombre exact de ticks physiques ; geler toutes les mutations entre actions, y compris cueillette et agents tiers. Ajouter identifiants épisode/pas, port configurable, délais d'attente et arrêt propre. Une nouvelle seed doit réellement reconstruire les positions et stocks concernés. Distinguer mort, réussite et troncature selon le contrat.

Unifier les observations alimentaires structurées : faim, inventaire, cibles perçues relatives, distances, souvenirs explicitement connus, collision/progression et action précédente. Les coordonnées absolues et l'accès aux objets cachés ne doivent pas constituer une fuite involontaire de carte. Les masques n'exposent que les actions réellement exécutables.

**Tests créés et exécutés.** Vérificateur Gymnasium/SB3 ; deux resets identiques après trajectoires différentes ; reset avec nouvelle seed ; stocks et autres personnages restaurés ; pause prolongée au contact sans mutation ; traces identiques malgré latence client ; pas supplémentaire après fin refusé ; deux workers isolés ; reprise après interruption. Vérifier que l'ordre physique crédite les événements du dernier tick avant l'observation renvoyée.

**Gate.** Le candidat tabulaire conserve sa performance T0 via l'adaptateur. Les contrats passent et le débit permet le budget suivant. Les dépendances sont épinglées après essai local. Une exportation ONNX ou une migration .NET ne fait pas partie du préalable.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 4 — Apprendre une politique alimentaire dans un monde progressif [TODO]

**Recherche ciblée.** Distinguer limite de représentation, exploration et mémoire. La table persistante est le premier contrôle ; un petit réseau PPO/SB3 est le candidat si elle ne représente plus correctement les choix. Utiliser observations structurées et cadences communes, sans vision par pixels à ce stade.

**Curriculum.** Chaque niveau possède une configuration versionnée et un contrôle de solvabilité avant entraînement :

- **T1 — Choix de ressource.** Plusieurs cibles perçues, distances et disponibilités variables. La politique choisit parmi les cibles, sans qu'un tri par « meilleure ressource » donne implicitement la solution. Mesurer collecte et consommation, pas seulement approche.
- **T2 — Retrouver une ressource.** Vision locale et mémoire de la dernière perception ; ressources hors champ. Comparer mémoire explicite/historique court à observation seule. Une référence à information complète sert uniquement à localiser le défaut.
- **T3 — Survie alimentaire.** Monde procédural du projet, puis concurrence des trois agents fixes, avec danger désactivé. Réintroduire relief, obstacles et concurrence séparément pour localiser les régressions.

**Développement et expériences.** Entraîner avec plusieurs épisodes et checkpoints, puis choisir sur validation. Conserver un mélange de niveaux déjà maîtrisés pour mesurer et limiter l'oubli. Comparer table, représentation détaillée et candidat neuronal avec les mêmes primitives au niveau considéré. Ne pas comparer directement leurs scores T0 et T3.

Si les premiers repas sont trop rares, activer une seule branche d'imitation : démonstrations d'un contrôleur dont le taux de succès a été mesuré, clonage comportemental, puis éventuellement DAgger. Comptabiliser données expertes et appels. Comparer après imitation et après RL. Si T1 passe mais T2 échoue avec un diagnostic d'information partielle, comparer un historique court puis RecurrentPPO ; ne pas lancer les deux branches sans cause identifiée.

**Tests créés et exécutés.** Observations sans information cachée ; masques identiques ; ressources vidées ou devenues inaccessibles ; absence de prime répétée sans événement ; comptage cueillette/consommation/mort ; politique figée ; mémoire récurrente remise à zéro ; régressions T0–T2 ; même contrat en headless et en jeu.

**Gate.** Atteindre les seuils de validation prédéfinis pour chaque niveau, puis les exigences alimentaires T3 du contrat commun. Le gain doit survivre au retrait des aides d'entraînement éventuelles. Documenter si la solution apprend le choix de compétences ou le mouvement lui-même. Geler ensuite le candidat et l'analyse pour la confirmation.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 5 — Confirmation indépendante et livraison dans le jeu [TODO]

**Recherche restante.** Aucune nouvelle recherche d'algorithme après ouverture du test. Vérifier seulement que le plan statistique gelé correspond à la structure effective des données.

**Développement.** Charger le checkpoint retenu dans un décideur interchangeable. Ajouter un mode figé, le modèle/version dans la télémétrie et un repli explicite en cas d'indisponibilité de l'inférence. Tout recours au repli est compté ; une bonne survie obtenue par l'automate de secours ne valide pas le modèle.

**Confirmation.** Exécuter le lot final préenregistré avec les entraînements indépendants et les 64 cartes nouvelles. Comparer aux contrôles appariés, publier survie, nourriture, incertitude, coût de calcul, erreurs et blocages. Le candidat est choisi sur validation, jamais par le meilleur score final. Les anciennes références réservées ne sont pas ouvertes pour cette confirmation nouvelle.

**Tests créés et exécutés.** Rechargement du modèle, schéma incompatible, perte de connexion, absence de mise à jour en mode figé, contrôle manuel prioritaire, équivalence d'actions entre le chemin évalué et le chemin livré. Démonstration fenêtrée sur le bureau IA_Life ; toute validation manuelle en attente rejoint la [file de tests](D:/ServOMorph/IA_Life/tests_manuels.md), puis est retirée après réalisation.

**Gate.** Critères statistiques et seuils alimentaires du contrat commun atteints, contrôles techniques passés et démonstration réalisée. Sinon, déclarer résultat partiel/indéterminé/critère non atteint. Un échec final nécessite une nouvelle version et de nouvelles réserves avant tout nouveau réglage ; ne pas réutiliser le test pour choisir un correctif.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 6 — Extension conditionnelle : danger et adaptation [TODO]

**Condition d'entrée.** Fonctionnalité alimentaire livrée. Cette extension ne bloque pas son acceptation.

**Recherche.** Comparer une micro-tâche à deux routes, l'une courte et coûteuse, l'autre plus longue et sûre. Rendre le coût et l'accessibilité observables. Un détour fixe imposé partout ne teste pas le choix stratégique ; prévoir des situations où les compromis diffèrent.

**Développement.** Réutiliser la mécanique de danger, l'intégrer aux observations et au retour d'expérience de façon versionnée. Tester la navigation seule sur les trajets avant entraînement. Prévoir des variantes sans danger pour mesurer l'oubli de l'alimentation. Si l'ancien contournement est réutilisé, son comportement reste à mesurer ; le nouveau protocole n'efface pas son échec historique.

**Expérience d'adaptation.** Mesurer d'abord la politique figée sur un changement préenregistré du monde, puis lui accorder un nombre fixé d'épisodes d'adaptation sur un lot dédié. Comparer à la politique toujours figée et à une réinitialisation complète, avec mêmes observations et budget. Évaluer ensuite sur d'autres cartes du régime changé.

**Tests créés et exécutés.** Coût proportionnel au temps réellement exposé, aucune récompense de fuite sans progrès utile, mémoire/récompense cohérentes, chemins accessibles, non-régression alimentaire. Utiliser de nouvelles réserves pour le nouveau contrat ; l'ancien gate garde ses réserves et sa portée propres.

**Gate.** Gain de résultat avec maîtrise du coût et de la rétention, selon seuils fixés avant l'expérience. Distinguer généralisation d'une politique figée et apprentissage après changement. Si le danger n'apporte rien, conserver le système alimentaire fonctionnel.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 7 — Extension conditionnelle : agent LLM apprenant [TODO]

**Condition d'entrée.** Phase 5 réussie ; la Phase 6 n'est pas un préalable obligatoire. Cette branche vise l'objectif d'agents pilotés par LLM.

**Recherche.** Adapter les idées de Voyager et Reflexion : catalogue de compétences exécutables, bilan d'épisode et mémoire sélectionnée. Tester d'abord le modèle local disponible avec cette interface. Mesurer qualité des choix et coût réel avant de décider d'un affinage.

**Développement.** Ollama choisit un objectif dans un schéma borné ; la compétence exécute les mouvements. Enregistrer observation, objectif, résultat réel et enseignement retenu, sans accepter une affirmation du modèle comme preuve de réussite. Synchroniser les décisions pour les expériences ou rejouer un journal de réponses, afin que la latence ne change pas la quantité d'expérience.

**Comparaisons.** Même modèle sans mémoire, avec mémoire factuelle et, si utile, mémoire témoin non pertinente ; mêmes compétences, observations, nombre d'appels et budget. Mesurer l'effet propre de la mémoire, les invalidités, les replis et la rétention. Comparer séparément au décideur compact sur les mêmes tâches.

**Affinage des poids, seulement si justifié.** Constituer un jeu de trajectoires réussies et échouées annotées par les résultats du moteur ; séparation par cartes et tâches avant génération des exemples. Comparer modèle de base, modèle avec contexte et modèle affiné. Tester architecture exacte, VRAM, framework d'entraînement, licence, export et import Ollama sur un petit lot avant campagne. Les poids sont entraînés avec l'outil approprié puis servis par Ollama ; l'import seul n'entraîne rien.

**Tests créés et exécutés.** Réponses invalides, mémoire contradictoire, cible périmée, repli, reprise, absence de fuite des données de test, mêmes outils et informations pour les bras. Vérifier qu'une compétence programmée n'est pas comptée comme une compétence apprise par le LLM.

**Gate.** Amélioration mesurable sur nouvelles tâches contre le même modèle privé de l'acquis étudié, avec coût et taux d'échec publiés. Nommer précisément le résultat : apprentissage des poids, adaptation par mémoire ou accumulation de compétences. Aucun de ces résultats n'est présumé par la présente roadmap.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Règles de conduite

Les recherches initiales sont consignées dans l'analyse liée ; chaque phase complète uniquement la question nécessaire à sa réalisation. Insérer une phase de refactorisation dédiée seulement si une dette observée rend la suite difficile, et en expliciter le motif. Ne pas modifier les statuts pendant le développement : les preuves sont consignées, `/close` prononce la clôture.

La rédaction de ce plan ne lance aucune de ses phases et ne déclenche pas les checkpoints. Ceux-ci s'appliquent lors de l'exécution future, entre phases. Le premier chantier à engager après adoption est le contrat d'épisode, suivi de la conservation des acquis et de T0.
