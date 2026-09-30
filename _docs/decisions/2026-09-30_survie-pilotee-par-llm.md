# Survie pilotée par LLM (Rouge, Bleu, Vert, Jaune)

**Date :** 2026-09-30
**Statut :** proposé

## Décision
Les quatre personnages autonomes sont pilotés chacun par un LLM local (`gemma3:1b`, Ollama). Le
personnage « Test » (piloté par le développeur) n'est pas modifié. L'axe apprentissage par
renforcement (T0-T3) est mis en pause, y compris la suite de la confirmation T3 v3. Roadmap :
`roadmap_survie_llm.md`.

- Le LLM choisit une cible (identifiant de roncier) ; le moteur calcule la trajectoire. Sans cible
  utile, le LLM choisit une direction parmi 8.
- Ramasser et manger deviennent des actions explicites du LLM : ramassage possible à tout moment
  (contact, inventaire < 3), repas refusé au-dessus de `eat_hunger_threshold`. Les automatismes
  ne sont désactivés que pour ce décideur.
- Mémoire : coordonnées de chaque roncier vu ou touché, sans limite ni oubli. Mûres restantes
  estimées (dernière vue, décrémentée des cueillettes propres, corrigée à la vue suivante).
- Monde : pas de repousse, zones dangereuses désactivées.
- Temps : pas de pause. Pendant l'attente d'une réponse, l'agent poursuit son action en cours ; la
  simulation continue. La latence devient un coût de survie, journalisé par agent.
- Mesure : `game_speed = 1.0`, `--jobs 1`, résultats dépendants du matériel (assumé). Critère de
  succès à écrire avant toute mesure.

## Compromis assumés
- Un run avec le vrai LLM n'est pas rejouable ; la reproductibilité se teste avec un mock.
- La comparaison à l'automate (décision instantanée) est inéquitable ; la faim perdue en attente
  est reportée à côté de la survie.
- Option écartée : gel de la seule horloge de l'agent qui attend (indépendant du GPU) ; retenue
  seulement si la dépendance au matériel invalide la Phase 5.
- Stock fini : 24 ronciers × 3 mûres ; la durée de vie est plafonnée par la carte.

## Commentaire
2026-09-30 : décision de périmètre, aucune implémentation. Ollama ne répondait pas sur
`127.0.0.1:11434` en fin de session ; à rétablir avant la Phase 4.
