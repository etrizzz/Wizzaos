# Architecture WizzaOS

## Objectif
WizzaOS vise un PC x86-64 ancien doté de 6 Go de RAM. La priorité n'est pas de battre des benchmarks mais de rendre la machine agréable et fiable pendant plusieurs années pour Prismatique, le web, les IA en ligne, la bureautique, le multimédia et le jeu compatible.

## Fondation
- Ubuntu 26.04 LTS comme base de maintenance longue durée
- XFCE pour limiter l'empreinte mémoire du bureau
- PipeWire pour l'audio
- NetworkManager pour réseau et Wi-Fi
- Flatpak pour les applications desktop additionnelles
- Steam/Proton et Wine/Lutris comme composants optionnels

## Règles
1. Le bureau doit rester léger au repos.
2. Les applications lourdes ne sont pas préchargées au démarrage.
3. Les effets visuels s'adaptent au GPU.
4. Les fonctions gaming sont installables sans être nécessaires au poste Prismatique.
5. Toute optimisation doit pouvoir être annulée.
6. `main` reste stable ; le développement se fait sur `wizza-dev`.

## Profils
### Prismatique
Navigation, IA web, documents, PDF, impression, retouche légère, fichiers, communication.

### Quotidien
Streaming, musique, photos, Bluetooth, messagerie et applications web.

### Gaming
Steam, Proton, GameMode et MangoHud lorsque le matériel les supporte.
