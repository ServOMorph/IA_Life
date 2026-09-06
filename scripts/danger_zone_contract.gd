class_name DangerZoneContract
extends RefCounted

## Contrat numérique v3, volontairement indépendant de la scène.
## La Phase 1 raccordera ces règles aux Area3D et au temps simulé de Character.

const EVENT_PLACEMENT := "danger_placement"
const EVENT_ENTER := "danger_enter"
const EVENT_EXPOSURE := "danger_exposure"
const EVENT_EXIT := "danger_exit"

static func effective_cost_rate(active_cost_rates: Array) -> float:
	var result := 0.0
	for value in active_cost_rates:
		result = maxf(result, float(value))
	return result

static func hunger_cost(active_cost_rates: Array, simulated_delta: float) -> float:
	return effective_cost_rate(active_cost_rates) * maxf(simulated_delta, 0.0)
