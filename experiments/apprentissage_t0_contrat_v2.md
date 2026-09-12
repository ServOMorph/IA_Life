# Contrat expérimental T0 — apprentissage alimentaire persistant v2

Statut : remplacement préenregistré de `apprentissage_t0_contrat_v1.md`, avant toute campagne
T0. La version v1 reste conservée comme trace et ne produit aucun résultat.

## Modification motivée

La récompense T0 reste exclusivement `+1` lors de la cueillette réelle par
`try_pick_berry_from_ronce`. À 8 m, une table Q nulle devrait découvrir une longue séquence de
directions avant de recevoir son premier signal, ce qui rend le budget de 1 000 épisodes inadapté
à une première preuve d'ingénierie. La v2 ne rajoute ni récompense de distance, ni macro-action,
ni information supplémentaire.

| Élément | v1 | v2 verrouillée |
| --- | --- | --- |
| Distance Rouge–ronce | 8 m | 2 m |
| Empreinte de configuration | `t0_contract_v1` | `t0_contract_v2|resource_distance=2.0|actions=8|ticks=15|horizon=48|alpha=0.20|gamma=0.90` |
| Identifiant d'expérience | `t0_contract_v1` | `t0_contract_v2` |

Toutes les autres clauses de `apprentissage_t0_contrat_v1.md` sont reprises sans changement :
arène de 24 m, Rouge à l'origine, huit secteurs et directions, 15 ticks physiques à 1/60 s,
horizon de 48 actions, `game_speed = 1`, observation, actions, seeds, bras, Q-learning,
checkpoints, validations, critères de gate, règles de persistance et refus des lots incomplets.

La nouvelle distance conserve un choix directionnel : une action dure 0,25 s à la vitesse du
personnage, et le bras doit encore sélectionner une direction cohérente avec le secteur pour
atteindre la zone de contact. Le contrôle scripté demeure le diagnostic de solvabilité ; il ne
fournit aucune démonstration au candidat.

Le premier entraînement T0 doit employer exclusivement cette version. Toute modification ultérieure
exige une nouvelle version, de nouvelles réserves et ne peut pas être comparée directement à v1.
