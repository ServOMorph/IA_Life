# Phase 6 — Mécaniques sociales avancées (communication, coopération, agressivité)

Date : 2026-08-25
Statut : validé

## Décision

Trois nouveaux traits probabilistes, individuels, catégorie `social` (même famille que
`follow_probability`/`avoid_probability`) :

- **Communication** (`communication_probability`) : lors d'une rencontre, un agent partage une
  position de roncier qu'il a mémorisée et que l'autre ne connaît pas encore, sans condition.
- **Coopération** (`cooperation_probability`) : lors d'une rencontre, un agent qui porte au
  moins une mûre en cède une à l'agent rencontré si la faim de ce dernier est sous le seuil de
  consommation (`GameConfig.eat_hunger_threshold`).
- **Agressivité** (`aggression_probability`) : lors d'une rencontre, un agent force l'agent
  rencontré à s'éloigner, indépendamment du choix de ce dernier (répulsion imposée).

Les trois options ont été choisies par l'utilisateur via le nouveau système de choix rapide
de l'appli ROBERTO, en écartant à chaque fois une alternative plus complexe (partage
conditionné, définition alternative) au profit de l'option la plus simple et cohérente avec
les traits déjà en place.

## Commentaire

Communication et agressivité se déclenchent de façon fiable et rapide dans un scénario de
simulation court (`experiments/social_communication_smoke_v1.json`,
`social_aggression_smoke_v1.json`). Coopération fonctionne (`social_cooperation_smoke_v1.json`)
mais ne s'est observée que dans une configuration généreuse (100 ronciers, rayon social 90,
400 s simulées) : le déclenchement dépend d'une coïncidence spatio-temporelle (un agent en
surplus de nourriture croisant un agent en faim critique) plus rare que pour les deux autres
mécaniques. Aucune campagne multi-seeds n'a été menée à ce stade pour en démontrer l'effet de
façon statistique, contrairement à suivi/évitement (Phase 6, action sociale précédente).
