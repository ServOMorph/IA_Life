---
name: analyse-partie
description: Analyse fine d'une session de jeu IA_Life à partir des logs de logs/. Reconstitue la chronologie par personnage (naissance, cueillette, repas, mort), calcule les statistiques de survie, corrèle avec les changements de configuration (vitesse jeu, seuils, sliders perso) et identifie les causes probables des morts ou des comportements observés. À utiliser quand l'utilisateur demande d'analyser une partie/session, de comprendre pourquoi un personnage est mort ou n'a pas mangé, ou l'effet d'un réglage sur la simulation.
tools: Read, Glob, Bash
---

# Analyse d'une partie IA_Life

## Portée
Cette skill est en lecture seule : elle analyse, elle ne modifie ni le code ni les fichiers de log.
Toute modification de mécanique/réglage suggérée à l'issue de l'analyse doit être proposée à
l'utilisateur, jamais appliquée automatiquement dans le cadre de cette skill.

## Étape 1 — Identifier la session à analyser
- Lister `logs/*.log` (`Glob logs/*.log`).
- Par défaut : analyser le fichier le plus récent (nom horodaté `session_AAAA-MM-JJ_HH-MM-SS.log`,
  tri lexicographique = tri chronologique).
- Si l'utilisateur désigne une session précise (date, heure, "l'avant-dernière"...), résoudre
  explicitement le fichier correspondant et le nommer dans la réponse.
- Si plusieurs fichiers existent et que la demande porte sur une comparaison ("compare les deux
  dernières parties"), lire tous les fichiers concernés.

## Étape 2 — Lire le contexte des mécaniques au moment de la session
Avant d'interpréter les logs, lire les fichiers de référence pour connaître les formules et
valeurs par défaut en vigueur (elles évoluent au fil des sessions de dev, ne jamais supposer) :
- `scripts/game_config.gd` — seuils globaux (`max_berries_carried`, `pickup_hunger_threshold`,
  `eat_hunger_threshold`, `full_life_berries`, `ronce_count`, `berries_per_ronce`) et formule
  `pv_per_berry(feeding_capacity)`.
- `scripts/character.gd` — `hunger_depletion_rate` par défaut, formule de déplétion
  (`hunger -= hunger_depletion_rate * aging_factor * scaled_delta`, `scaled_delta` dépend de
  `GameSpeed.time_scale`).

Ces valeurs peuvent avoir été modifiées EN COURS de partie via des lignes `[config]` dans le log
lui-même : elles priment sur les valeurs par défaut du code à partir de leur timestamp.

## Étape 3 — Parser le log
Format de chaque ligne : `[  XX.Xs][catégorie] message`
- `XX.Xs` : secondes réelles écoulées depuis le début de session (PAS le temps simulé — le temps
  simulé dépend de `GameSpeed.time_scale`, lui-même visible via les lignes `[config] Vitesse jeu`).
- Catégories : `session`, `spawn`, `cueillette`, `repas`, `mort`, `config`, `camera`.

Reconstituer, pour analyse interne (pas nécessairement à restituer intégralement à l'utilisateur) :
- **Chronologie globale** : toutes les lignes dans l'ordre.
- **Chronologie par personnage** : filtrer les lignes où le nom du personnage apparaît
  (`spawn`, `cueillette`, `repas`, `mort`, et les `[config]` du type "<Nom> ...").
- **Chronologie de configuration** : toutes les lignes `[config]`, avec leur timestamp — donne
  le contexte de réglage actif à n'importe quel instant de la partie (ex : vitesse de jeu en
  vigueur au moment d'une mort).

## Étape 4 — Calculer les métriques par personnage
Pour chaque personnage apparu dans `[spawn]` :
- Temps de survie réel (timestamp de `[mort]` moins timestamp de `[spawn]`), et signaler s'il a
  survécu jusqu'à la fin du log (pas de ligne `[mort]`).
- Nombre de mûres ramassées / mangées (déjà loggé dans la ligne `[mort]`, ou à défaut cumuler les
  lignes `[cueillette]`/`[repas]`).
- Faim au moment de chaque cueillette/repas (déjà dans le message) — permet de voir si les seuils
  de cueillette/consommation ont été respectés et à quel rythme la faim chutait.
- Écart entre deux événements consécutifs du même personnage — permet d'estimer s'il a erré
  longtemps sans trouver de ronce.

## Étape 5 — Corréler avec la configuration
Point d'attention systématique : la vitesse de jeu (`GameSpeed.time_scale`) multiplie l'écoulement
du temps simulé. Une mort qui semble "instantanée" en temps réel (quelques secondes) peut être
totalement normale si la vitesse de jeu était élevée à ce moment (ex : à x50, une faim pleine se
vide en `100 / (hunger_depletion_rate * 50)` secondes réelles). Toujours vérifier la dernière
valeur `[config] Vitesse jeu` active avant un événement avant de qualifier un comportement
d'anormal.

Autres corrélations à vérifier si pertinentes à la question posée :
- Un personnage mort à 0 mûre ramassée/mangée : a-t-il eu le temps physique (distance x vitesse)
  de croiser une ronce avant expiration de sa faim ?
- Un réglage changé en cours de partie (slider perso ou modale Données du jeu) a-t-il eu un effet
  visible sur le personnage concerné juste après ?

## Étape 6 — Restituer l'analyse
Présenter une synthèse structurée, adaptée à la question posée (ne pas tout ressortir si la
question est ciblée) :
- Résumé global : durée de la session, nombre de survivants/morts, vitesse de jeu en vigueur.
- Par personnage concerné : narratif court (naissance → événements clés → mort ou survie) avec
  timestamps.
- Cause probable identifiée pour chaque anomalie relevée (mort rapide, personnage sans mûre,
  écart entre réglage et comportement observé).
- Si la question implique une modification de mécanique/réglage, formuler une recommandation
  concrète (quel paramètre, quelle valeur, pourquoi) mais ne pas l'appliquer sans confirmation.

Rester disponible pour des questions de suivi sur la même session (le parsing de l'étape 3 sert
de base à toutes les questions ultérieures sans avoir à relire le log à chaque fois, sauf si le
fichier a changé).
