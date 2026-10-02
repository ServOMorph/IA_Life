# Direction visuelle Observatoire et décor de l'arène

**Date :** 2026-10-02
**Statut :** validé pour la direction et la densité des arbres ; contrôles visuels des phases 1-2 en attente

## Décision
- Retenir « Observatoire » : interface bleu nuit, IBM Plex, couleurs et repères propres aux quatre agents ; faim, mort et danger explicités autrement que par la seule couleur.
- Employer un sous-ensemble CC0 du Nature Kit de Kenney pour les arbres, rochers et ronciers. La densité de 108 arbres a été confirmée par l'utilisateur.
- Désactiver les collisions physiques des arbres à la demande de l'utilisateur, en conservant leurs formes pour une réactivation ultérieure.
- Remplacer le relief à bruit unique et les quatre cuvettes symétriques par un relief multi-échelle, avec zones de départ et bordures adoucies. Le terrain reste généré par code, conformément à la décision du 2026-08-17.

## Vérification et limites
- Tests ciblés Godot : identité, décor, relief et exécution headless. Le maillage et la collision du sol partagent les mêmes hauteurs.
- Les contrôles visuels et les déplacements sur les zones accidentées restent dans `tests_manuels.md` ; les phases 1-2 ne sont pas closes.
- Le nouveau relief peut changer les parcours et les observations des agents : les résultats expérimentaux anciens ne sont pas directement comparables.
