# Contrat v3 — zones dangereuses

Statut : Phase 0 spécifiée ; aucune mécanique n'est encore exécutée.

## Configuration

Les clés de `environment.game_config` sont `danger_zone_count`, `danger_zone_radius`,
`danger_hunger_cost_rate`, `danger_zone_visible` et `danger_zone_safety_radius`. Si
`danger_zone_count` vaut `0` (valeur par défaut), aucune zone n'est créée, aucun coût ni
événement n'est produit et le déroulement d'une expérience historique est strictement inchangé.

Le placement de Phase 1 utilisera un RNG dédié dérivé de la seed de l'expérience et au plus 64
tentatives par zone. Une zone ne peut être retenue que si son disque, augmenté de
`danger_zone_safety_radius`, ne recouvre ni spawn, ni mur, ni roncier. Un échec de placement est
journalisé ; il ne déclenche jamais un placement alternatif non déterministe.

## Schéma de télémétrie Phase 1

Chaque événement porte une `category` égale à son nom (`danger_placement`, `danger_enter`,
`danger_exposure`, `danger_exit`) et conserve l'enveloppe JSONL existante (`schema_version`,
`session_id`, `elapsed_seconds`, `message`, `data`). Les champs de `data` sont :

| Événement | Champs obligatoires |
| --- | --- |
| `danger_placement` | `zone_id`, `position`, `radius`, `seed`, `placement_attempt` |
| `danger_enter` | `agent`, `zone_id`, `position`, `exposure_seconds_total`, `hunger_cost_total` |
| `danger_exposure` | `agent`, `zone_ids`, `delta_seconds`, `cost_rate`, `hunger_cost_delta`, `exposure_seconds_total`, `hunger_cost_total` |
| `danger_exit` | `agent`, `zone_id`, `position`, `exposure_seconds_total`, `hunger_cost_total` |

Une exposition recouvrant plusieurs zones utilise le coût maximal : `cost_rate` n'est jamais une
somme. Le résumé de run exposera, par agent, `danger_entries_total`, `danger_exits_total`,
`danger_exposure_seconds` et `danger_hunger_cost_total`.

## Cas de contrat à automatiser en Phase 1

- zéro zone : aucune entité, aucun événement danger et même trace de référence v2 ;
- exposition à une zone : coût mesuré = `danger_hunger_cost_rate × durée simulée` ;
- chevauchement : le coût mesuré est le maximum des deux taux, jamais leur somme ;
- sortie : l'exposition et le coût cessent à la frame de sortie, puis `danger_exit` est unique.

Le calcul pur (zéro zone, exposition simple, chevauchement et sortie) est testé dès la Phase 0
par `DangerZoneContract`; les tests d'intégration Area3D et de journaux seront ajoutés en Phase 1.
