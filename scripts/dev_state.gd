extends Node

## État dev partagé, persistant à travers reload_current_scene().
## seed_override < 0 : utiliser la seed de la config. current_seed : seed effective
## du run courant, exposée à l'UI.

var seed_override: int = -1
var current_seed: int = 0
var danger_zone_count_override: int = -1
var current_danger_zone_count: int = 0
