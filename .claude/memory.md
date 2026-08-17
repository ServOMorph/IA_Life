# Mémoire projet
<!-- Fichier géré via /create_memory. Ne pas modifier manuellement sauf pour supprimer des entrées. -->

## 2026-08-17 — Vitesse de jeu = accélérateur de temps pur
`GameSpeed.time_scale` est un pur accélérateur de temps, destiné à rejouer une partie plus vite en
vue d'analyse. La partie doit se dérouler EXACTEMENT comme à x1, juste compressée en temps réel —
jamais changer l'issue ou l'équilibrage.

Conséquence :
- Toute grandeur qui varie avec le temps (faim, déplacement, gravité, minuteur de changement de
  direction) doit être multipliée par `time_scale`.
- Toute grandeur événementielle/fixe (PV gagnés par mûre, seuils de faim, compteurs, nombre de
  ronces) ne doit JAMAIS être indexée sur `time_scale`.

Exceptions volontaires déjà correctes, à ne pas "corriger" : déplacement de la caméra libre ZQSD
(sinon injouable à haute vitesse), timeout de sécurité du mode headless, horodatages des logs
(`GameLogger`) — ces trois-là restent en temps réel par design.

## 2026-08-17 — Autorisation lecture/écriture hors DESIGN/
L'agent design est autorisé à lire et modifier des fichiers en dehors de son dossier DESIGN/
(racine du projet, dossiers de code applicatif) dès lors que la modification concerne le design
du jeu. Cette autorisation prévaut sur l'invariant par défaut d'`agent_role.md` limitant l'agent
à DESIGN/.

## 2026-08-17 — Collision physique par défaut sur les objets de scène
Tout objet ajouté dans une scène Godot doit recevoir une collision physique (StaticBody3D/
CollisionShape3D ou équivalent selon le type d'objet), sauf demande explicite contraire de
l'utilisateur. Une Area3D de détection ne suffit pas à elle seule si une collision physique
bloquante est aussi pertinente pour l'objet — les deux ne sont pas interchangeables (ex: les
ronces n'avaient qu'une Area3D de cueillette, sans bloquer physiquement les personnages).
