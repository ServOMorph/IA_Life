# Roadmap — Dangers sur approche de ressources

Créée le : 2026-09-09
Statut : **[EN COURS]**

## Objectif

Remplacer le placement aléatoire des zones dangereuses, qui ne sépare pas `eviter` de
`aleatoire`, par un placement déterministe sur l'approche entre un spawn et des ronciers. Le
comportement doit rester local : aucun pathfinding ni modification du bras `aleatoire`.

## Phase 1 — Contrat, placement et tests [FAIT — 2026-09-09]

- Ajouter un mode de placement `approche_roncier`, désactivé par défaut afin de préserver les
  anciennes expériences.
- Pour chaque roncier retenu de manière déterministe, placer une zone sur le segment entre le
  spawn choisi et ce roncier, à une marge configurable hors du roncier.
- Journaliser le mode, le spawn et le roncier source pour rendre la géométrie contrôlable.
- Couvrir validation, déterminisme, géométrie de placement, compatibilité du mode historique et
  un smoke headless.

**Gate** : le smoke produit uniquement des zones `approche_roncier` à la marge attendue ; les
anciens JSON gardent le placement aléatoire ; les tests pertinents sont verts.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 2 — Calibration sur seeds d'entraînement [FAIT — 2026-09-10]

- Écrire une campagne versionnée : nombre de ronciers gardés × marge de placement.
- Exécuter les quatre bras sur les 12 seeds de calibration et appliquer le gate causal existant.
- Ne pas ouvrir les seeds réservés.

**Gate** : un point passe les quatre critères causaux de la Phase 3 de
`roadmap_environnement_apprenable_v3.md`, ou la limite du nouveau placement est documentée
avant toute décision sur l'axe.

**Résultat** : 192 runs à 6/12 zones × marges 1/3, puis 144 runs à portées 10/12/15 m. Aucun
point ne passe le gate. Le placement est complet (1 728/1 728 zones) ; la limite est la fuite
rectiligne, pas la géométrie. Les seeds réservés restent fermés.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.
