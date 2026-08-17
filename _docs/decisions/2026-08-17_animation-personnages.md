# Levée de la contrainte "personnages sans animation"

**Date :** 2026-08-17
**Statut :** validé

## Décision
- Les personnages, jusqu'ici deux `BoxMesh` statiques (corps + tête) sans animation, auront
  des animations (marche/idle a minima, mort à terme).
- Deux étapes prévues : animation procédurale sur la géométrie actuelle (Phase 3 de
  `DESIGN/roadmap_graphisme.md`), puis personnages riggés avec animation squelettique
  (Phase 5).

## Implémentation
Aucune à ce stade — décision de planification uniquement. Voir `DESIGN/roadmap_graphisme.md`
et `DESIGN/pistes_graphisme.md` (pistes D1/D2).

## Commentaire
Demande explicite de l'utilisateur en session DESIGN du 2026-08-17. Contredisait la
contrainte initiale fixée dans `DESIGN/_contexte/contexte.md` — contexte mis à jour en
conséquence.
