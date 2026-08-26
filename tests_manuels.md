# Tests manuels en attente

## Affichage du type de décideur dans l'Inspecteur (Phase 7)
Lancer le jeu en mode dev (`python run_dev.py`), ouvrir l'Inspecteur, sélectionner un agent,
catégorie "décision". Vérifier que `decider_type` s'affiche comme texte (`automate`), pas
comme `"0.00"`, et que `llm_model`/`llm_decision_interval_seconds`/`llm_timeout_seconds`
s'affichent correctement. Vérifier aussi que la note en bas de l'Inspecteur mentionne
désormais "tant qu'aucun agent n'utilise un décideur LLM" (et non plus l'ancien texte).

## Reconnexion WebSocket ROBERTO après verrouillage écran (iPhone)
Correctif appliqué : `ensureConnected()` sur `visibilitychange`/`pageshow` dans
`ROBERTO/com_telephone/voice-code-bridge/mobile/app.js` (avant : reconnexion uniquement via
`ws.onclose`, qui ne se déclenche pas de façon fiable quand iOS Safari suspend le JS en
arrière-plan). Sur iPhone : ouvrir l'appli, envoyer un message, verrouiller l'écran ~30s,
déverrouiller, vérifier que le point de connexion repasse à "Connecté" sans rechargement manuel,
puis envoyer un nouveau message via `POST /send` côté PC et vérifier qu'il arrive bien sur le
téléphone (`sent:1` dans la réponse).

## Re-abonnement push ROBERTO après correction de la clé VAPID
Cause racine trouvée le 2026-08-26 (après deux fausses pistes : purge de souscription obsolète,
puis comparaison `sub.options.applicationServerKey` — inopérante, Safari n'expose pas cette
API sur cette version) : la constante `VAPID_PUBLIC_KEY` codée en dur dans `app.js` ne
correspondait pas à `VAPID_PUBLIC` de `.env` côté serveur. Toute souscription créée par le
téléphone, même fraîche, échouait donc systématiquement (`VapidPkHashMismatch`). Corrigé :
`VAPID_PUBLIC_KEY` dans `app.js` alignée sur `.env`, et `enablePushNotifications` désinscrit
toujours l'ancienne souscription avant d'en recréer une. Sur iPhone : recharger complètement la
page (fermer/rouvrir l'appli ou tirer pour rafraîchir), vérifier qu'une nouvelle entrée apparaît
dans `push_subs.json` et que `curl -X POST http://127.0.0.1:5000/push/test` répond sans
`VapidPkHashMismatch`. Puis verrouiller l'écran, envoyer un message via `POST /send` côté PC, et
vérifier qu'une notification push arrive malgré le WebSocket fermé.
