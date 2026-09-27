# Contrat T1 v4 — exploration équilibrée du premier pas

Gelé avant tout entraînement ou lecture de validation T1 v4, le 2026-09-27. Les résultats v2
et v3 gardent leurs verdicts. Le replay v3 a montré que les 27 premières actions hors du secteur
exact étaient adjacentes et rapprochaient l'agent, mais que 11 visaient directement un roncier
vide. L'hypothèse v4 est qu'une exploration insuffisamment équilibrée des huit actions initiales
par secteur a laissé la table contextuelle préférer certaines directions adjacentes.

Le scénario, l'observation, les huit actions, l'horizon, la récompense de résultat et le retour
d'entraînement `r_base + 0,50 × distance_progress` restent ceux de v3. La table Q des actions
suivantes reste identique (`alpha=0,20`, `gamma=0,90`, `epsilon=0,20` à l'entraînement).
La seule modification du candidat est la sélection de la première action pendant
l'entraînement : pour le secteur observé du roncier disponible, choisir l'action dont le nombre
d'essais antérieurs est le plus faible ; résoudre les ex æquo par le plus petit identifiant
d'action. Le compteur `(secteur, action)` augmente une fois après la transition effectivement
exécutée. La valeur contextuelle de ce premier pas continue de recevoir uniquement son retour
physique immédiat, sans bootstrap, avec `alpha=0,20`. En évaluation, le compteur n'est pas lu
pour choisir : la meilleure valeur apprise est sélectionnée, avec ex æquo au plus petit indice.
Compteurs et valeurs sont sauvegardés, rechargés et inclus dans le checksum.

Identifiant et empreinte :

```text
t1_choice_v4|targets=3|available=1|distances=3,6,9|actions=8|ticks=15|horizon=24|alpha=0.20|gamma=0.90|progress=0.50|first_explore=min_count|first_tie=lowest
```

| Usage | Seeds nouvelles |
| --- | --- |
| Cartes d'entraînement | `360000001..360000032` |
| Cartes de validation | `360000101..360000132` |
| Cartes de test final, fermées | `360000201..360000264` |
| Initialisations de développement | `360001001`, `360001002`, `360001003` |
| Initialisations de confirmation | `360001101..360001105` |
| RNG aléatoire | `360002001..360002003`, `360002101..360002102` |

Trois lignées, au plus 1 000 épisodes chacune, 32 cartes d'entraînement parcourues dans l'ordre
cyclique. Checkpoints `0`, `10`, `50`, `200`, `1 000`. Chaque checkpoint est évalué sur les 32
cartes de validation sans mise à jour ; le plus fort taux de consommation gagne, puis la première
direction correcte, puis le palier le plus précoce. Les cinq bras et tous les seuils du contrat
T1 v1 restent inchangés. Le lot attendu contient 1 248 résultats sans absence ni doublon ;
les comparaisons sont appariées par lignée et carte. La recharge doit conserver checksum,
actions et résultats. Le test final de 64 cartes reste fermé tant que le gate de validation
n'est pas atteint. Aucun paramètre ni seuil n'est modifié après la première validation.

Avant la campagne, les tests doivent démontrer un compteur par secteur/action mis à jour une
fois, un écart d'au plus un essai entre actions d'un secteur observé, une évaluation figée et une
sauvegarde/recharge exacte. Probe headless sur carte d'entraînement : un épisode complet doit
prendre moins de 60 s réelles et la mémoire statique rester sous 2 GiB.
