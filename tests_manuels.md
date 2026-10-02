# Tests manuels en attente

## DESIGN — Observatoire, phase 1 : lisibilité visuelle

1. Depuis le bureau virtuel Windows « IA_Life », lancer le jeu en mode dev et vérifier la lisibilité des quatre agents, de leurs couleurs et de leurs repères géométriques à distance.
2. Ouvrir les quatre panneaux : contrôler IBM Plex, le fond bleu nuit, les titres associés à chaque agent, le contraste des commandes et la lisibilité de la jauge « RÉSERVE » lorsque la valeur baisse.
3. Vérifier qu'un agent mort affiche « MORT » en gris et que sa jauge ne reste pas visible.
4. Avec au moins une zone dangereuse activée, vérifier le libellé « ZONE DANGEREUSE » pendant l'exposition et son retrait à la sortie, sans masquer le nom ni la couleur de l'agent.
5. Contrôler les panneaux du mode dev et la lecture des valeurs dans l'inspecteur à la résolution de jeu utilisée habituellement.

## Chat LLM et mémoire cartographique de llm_survie

Prérequis : serveur Ollama actif (`gemma3:1b` disponible).

1. Lancer `python run_survie_demo.py` (bureau virtuel « IA_Life »), déplier « Chat LLM » sur un personnage : les échanges (prompt complet, réponse) apparaissent, chaque personnage se plie et se déplie indépendamment.
2. Remonter dans le fil : un nouveau message ne doit pas déplacer la lecture ; replié, le cadre du panneau retrouve sa taille réduite.
3. Dans un prompt, vérifier la section « CARTE MÉMORISÉE » (zones parcourues, bords découverts, exploration par direction) ; après avoir touché un bord, il doit apparaître avec sa distance.

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
