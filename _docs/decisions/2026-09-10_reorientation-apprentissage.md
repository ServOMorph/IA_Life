# Réorientation de l'apprentissage

Date : 2026-09-10. Statut : validé.

## Décision

La roadmap `roadmap_apprentissage_fonctionnel_proposition.md` devient le chemin critique de l'apprentissage. Sa Phase 0 est engagée : formaliser le contrat d'épisode, les seeds, les bras, les critères et le budget avant toute mesure nouvelle.

La première preuve vise une tâche alimentaire contrôlée avec conservation des acquis entre épisodes. L'interface Gymnasium/PPO ne sera envisagée qu'après ce jalon ; l'agent LLM apprenant reste une extension conditionnelle.

## Conséquences

Les Phases 4 à 6 de `roadmap_apprentissage_v2.md` et la dépendance historique au gate danger v3 ne constituent plus le plan d'exécution. Leurs résultats restent archivés et leurs campagnes ne sont pas relancées.

`roadmap_environnement_apprenable_v3.md` passe en pause : son axe danger n'est pas abandonné, mais devient une extension conditionnelle après la preuve alimentaire. Aucun candidat de contournement n'est validé et aucune seed réservée n'est ouverte.

## Justification

L'analyse du 2026-09-10 montre que le chemin RL doit encore fixer le reset, l'observation des ressources et le retour événementiel. Une preuve alimentaire progressive isole ces prérequis avant d'attribuer un résultat à la navigation de danger ou à un LLM.
