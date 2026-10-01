# Tests manuels en attente

## Phase 5 — démonstration fenêtrée du modèle T3 v3 appliqué

Prérequis : lot final de confirmation exécuté (le checkpoint `experiments/t3_confirmation_final_workers/trained_410001101.jsonl.410001101.200.checkpoint.json` doit exister).

1. Lancer `python run_applied_demo.py` ; la fenêtre Godot doit s'ouvrir sur le bureau virtuel Windows « IA_Life ».
2. Vérifier que Rouge (rouge) se déplace vers les ronciers et se nourrit ; Bleu, Vert et Jaune jouent la politique fixe.
3. Dans les logs de session (`logs/`), vérifier l'événement `modele_charge` puis, en fin de session, `modele_bilan` avec `fallback_cycles_total` à 0 et `table_unchanged` à `true`.
4. Changer la vitesse de jeu (curseur, autre que x1) : le modèle doit se replier sur l'automate, événement `modele_repli` (raison `vitesse_jeu`) et `fallback_cycles_total` non nul.

## Phase 4 — démonstration fenêtrée de la survie pilotée par LLM

Prérequis : serveur Ollama actif (`ollama list` répond, `gemma3:1b` disponible).

1. Lancer `python run_survie_demo.py` ; la fenêtre Godot doit s'ouvrir sur le bureau virtuel Windows « IA_Life ».
2. Vérifier que Rouge, Bleu, Vert et Jaune se déplacent, s'arrêtent parfois (attente de réponse) puis repartent, et que l'agent ramasse puis mange lorsqu'il atteint un roncier.
3. Vérifier que « Test » reste pilotable et n'est jamais figé pendant les attentes des autres agents.
4. Dans les logs de session (`logs/`), vérifier la présence des événements `llm_survie_tour`, `llm_survie_attente_debut`, `llm_survie_attente_fin` et l'absence de `llm_survie_repli` répétés.
5. Changer la vitesse de jeu (curseur, autre que x1) : la simulation reste stable (aucune erreur), sachant que la mesure de survie n'est valide qu'à x1.
