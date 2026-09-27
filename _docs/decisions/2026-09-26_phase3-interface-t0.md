# Phase 3 — gate technique de l'interface d'entraînement atteint

Date : 2026-09-26. Statut : validé. Commentaire : les contrats techniques, les 12 tests d'intégration et la conservation de la réussite T0 via l'adaptateur satisfont le gate Phase 3. Statut de roadmap mis à jour par `/close` le 2026-09-27.

## Transport et exécution

Le transport retenu pour le nouveau chemin est le bridge TCP/JSONL local, avec deux adaptateurs Gymnasium : T0 et monde alimentaire. Le serveur commun `tools/food_gym_server.gd` conserve la connexion pendant que chaque `reset(seed)` détruit et reconstruit la scène Godot. Chaque `step(action)` exécute exactement 15 ticks physiques, puis désactive les traitements de la scène jusqu'à la commande suivante. Le dernier tick est traité avant l'envoi de l'observation et de la récompense.

Le mode monde recrée les quatre personnages et les 24 ronciers depuis la seed. Rouge reçoit huit actions directionnelles symétriques ; les trois autres personnages utilisent une politique fixe. Le danger est désactivé. Le succès est une consommation réelle, la mort est terminale, et l'horizon de 120 actions est une troncature. L'observation porte faim, inventaire, trois cibles effectivement perçues avec directions et distances relatives, trois souvenirs réellement connus, collision latérale, déplacement vers une cible visible au début de l'action et action précédente. Les coordonnées absolues et les ressources cachées ne figurent pas dans l'observation. Un diagnostic donnant l'état complet n'est accessible que si le processus de test reçoit explicitement `IA_LIFE_GYM_DIAGNOSTICS=1` ; les adaptateurs ordinaires ne l'activent pas.

Le mode T0 conserve l'observation et les huit actions du contrat T0 v4. Les deux modes refusent les pas périmés, invalides, avant reset ou après fin. Le port est configurable ; le client fixe un délai d'attente et ferme le processus. Les dépendances testées localement sont épinglées : Python 3.13, Godot 4.5, `gymnasium==1.3.0`, `stable-baselines3==2.9.0`.

Le choix du bridge local suit la comparaison de compatibilité documentée le 2026-09-18. [Godot RL Agents](https://github.com/edbeeching/godot_rl_agents) fournit des wrappers SB3, mais son intégration demanderait un add-on tiers et son guide de formation interactive demande Godot .NET. Le contrat d'API suit [Gymnasium](https://gymnasium.farama.org/main/api/env/) et le vérificateur [SB3](https://stable-baselines3.readthedocs.io/en/master/common/env_checker.html). Le mode RL ancien dans la scène principale reste distinct de ce nouveau transport.

## Vérifications et portée du gate

- `check_env` SB3 passe sur les deux adaptateurs. Douze tests d'intégration passent : T0 (6) et monde (6).
- T0 : les trois checkpoints v4 retenus réussissent chacun les huit secteurs via l'adaptateur (24/24). Deux workers donnent les mêmes résultats ; la latence client ne change pas la trace. Un contact provoqué exactement au quinzième tick est crédité dans la réponse de ce pas.
- Monde : deux resets avec la même seed reconstruisent les positions des quatre personnages et les stocks des 24 ronciers, même après des trajectoires différentes ; une autre seed change le placement. Une cueillette réelle vide un stock, qui est restauré au reset. L'état ne mute pas pendant une pause après contact. Changer le stock d'un roncier devenu invisible ne change pas l'observation. La collision latérale avec le mur est observée sans compter le contact avec le sol. Les deux workers sont isolés ; l'horizon, le refus d'un pas après fin et la reprise après interruption du processus passent.
- Les régressions Godot du scénario T0, des transitions/persistance et du protocole RL passent.
- Probe local sur un processus : médiane de reset monde 0,2181 s (10 resets), 44,7 actions monde/s (100 actions), 64 224 898 octets de mémoire statique Godot. Le probe T0 antérieur donnait 537 actions/s (100 actions). Ces débits ponctuels orientent le budget de la Phase 4 ; ils ne garantissent pas une campagne longue ou parallèle.

Le gate de la Phase 3 est atteint pour l'interface technique. Cette conclusion ne valide pas T1–T3 ni un apprentissage dans le monde complet. Le chemin T0 direct et le bridge n'ont pas toujours le même nombre d'actions avant cueillette : le premier enchaîne les appels dans la même frame, le second donne exactement 15 ticks à chaque action. La réussite des checkpoints est conservée sur les huit placements, sans identité bit à bit des traces. Une future campagne doit comparer ses bras sur le même adaptateur et figer sa configuration avant mesure.

À la date de cette décision, le travail T1 préparé antérieurement n'avait pas été modifié et la Phase 4 attendait le checkpoint `/compact` et la réponse écrite de l'utilisateur. Les seeds de test final T1 restent fermées.
