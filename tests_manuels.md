# Tests manuels en attente

## Affichage du type de décideur dans l'Inspecteur (Phase 7)
Lancer le jeu en mode dev (`python run_dev.py`), ouvrir l'Inspecteur, sélectionner un agent,
catégorie "décision". Vérifier que `decider_type` s'affiche comme texte (`automate`), pas
comme `"0.00"`, et que `llm_model`/`llm_decision_interval_seconds`/`llm_timeout_seconds`
s'affichent correctement. Vérifier aussi que la note en bas de l'Inspecteur mentionne
désormais "tant qu'aucun agent n'utilise un décideur LLM" (et non plus l'ancien texte).
