# Tests manuels en attente

## ROBERTO multi-projet — sélecteur de projet dans la PWA (phase 3)

À faire depuis le téléphone (iPhone/Safari), le pont actif (`com_manager.py status` = 3 OK)
et une session Claude Code par projet avec Monitor actif sur son log.

1. **Barre de projets visible** : ouvrir l'appli, vérifier la présence de deux boutons
   `IA_Life` et `TSA` sous le bandeau de connexion. Le bouton du projet courant est encadré
   en bleu.
1b. **Mise en page** : le bandeau du haut (`Connecté` / état / `Reset`) et la barre de projets
   restent visibles sans avoir à faire défiler la page ; seul le fil de messages défile.
2. **Envoi routé** : sur `IA_Life`, envoyer un message texte → il n'apparaît que dans la
   session Claude IA_Life (`logs/messages_ia_life.log`), pas dans celle de TSA. Basculer sur
   `TSA`, envoyer un message → il n'arrive que côté TSA.
3. **Historique séparé** : après avoir échangé sur les deux projets, basculer d'un projet à
   l'autre → le fil affiché change et correspond au seul historique du projet sélectionné.
4. **Réception projet inactif** : rester sur `IA_Life`, faire répondre la session TSA via
   `POST /send` (`project: "tsa"`) → le message ne s'injecte pas dans le fil affiché, une
   pastille bleue apparaît sur le bouton `TSA`, et la notification push est titrée `TSA · Assistant`.
   Basculer sur `TSA` → le message est là (rangé dans son historique), la pastille disparaît.
5. **Audio non joué pour projet inactif** : même scénario qu'au point 4 avec réponse vocale →
   aucun son ne se déclenche tant qu'on n'a pas basculé sur `TSA`.
6. **Reset ciblé** : bouton `Reset` sur `IA_Life` → vide uniquement l'historique `IA_Life`,
   celui de `TSA` est intact après bascule.
7. **Persistance du choix** : fermer puis rouvrir l'appli → le projet sélectionné est celui
   quitté (pas de retour systématique à `IA_Life`).

## ROBERTO multi-projet — raccordement TSA (phase 4)

Prérequis : les 3 process partagés tournent (démarrés côté IA_Life), l'appli rechargée.

8. **Session TSA en écoute** : ouvrir une session Claude Code dans
   `D:\ServOMorph\Appli_TSA_SDI_TDAH`, lancer `/roberto` → il rapporte le statut des 3 process,
   arrête l'éventuel ancien Monitor, en relance un sur `messages_tsa.log`, écrit
   `monitor_tsa.lock`.
9. **Aller-retour TSA** : depuis le téléphone, sélectionner `TSA`, envoyer un message vocal →
   il apparaît dans la session TSA (pas IA_Life), la réponse `POST /send` (`project: "tsa"`)
   revient dans le fil `TSA` de l'appli et est lue.
10. **Isolation des sessions** : avec les deux sessions actives (IA_Life + TSA), envoyer un
    message sur chaque projet → chaque session ne voit que ses propres messages, aucune fuite.
11. **`!close` routé** : depuis le téléphone sur `TSA`, envoyer `!close` → c'est la session TSA
    qui exécute son `/close` (commit sur le dépôt TSA), bilan renvoyé sur le téléphone.
