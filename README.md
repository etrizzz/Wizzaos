# WizzaOS

WizzaOS est un système desktop personnel pensé pour transformer un ancien PC x86-64 équipé de 6 Go de RAM en machine moderne, familière et réellement utilisable au quotidien.

L'objectif n'est pas de copier Windows ni de simplement renommer une distribution Linux. WizzaOS construit progressivement sa propre expérience : bureau, barre des tâches, recherche, centre de contrôle, outils de maintenance et espaces de travail. Les composants Linux utilisés en profondeur restent une fondation technique et doivent devenir aussi discrets que possible pour l'utilisateur.

## Expérience WizzaOS

WizzaOS vise une prise en main immédiate :

- barre des tâches en bas avec menu Wizza, applications ouvertes et zone système ;
- recherche et lancement rapide d'applications ;
- explorateur de fichiers, bureau, corbeille et périphériques amovibles ;
- Wizza Center pour regrouper progressivement réglages, diagnostic, maintenance et fonctions WizzaOS ;
- Wi-Fi, Bluetooth, audio, imprimantes, stockage USB et mises à jour ;
- Firefox, LibreOffice, PDF, multimédia, photo et numérisation ;
- espace Prismatique et accès aux outils IA web sans services lourds au démarrage ;
- couche gaming optionnelle avec Steam/Proton et Wine/Lutris selon les capacités du matériel.

## Performance avant tout

La machine cible n'a que 6 Go de RAM. Chaque choix doit donc rester raisonnable : faible consommation au repos, ZRAM, démarrage propre, absence de préchargement inutile et composants lourds optionnels. Les effets visuels et optimisations doivent rester adaptés au matériel réel.

## Fondation technique

WizzaOS s'appuie actuellement sur Ubuntu 26.04 LTS, XFCE et l'écosystème Linux pour le noyau, les pilotes et les paquets. Cette fondation n'est pas l'identité du produit : elle sert à obtenir compatibilité matérielle, sécurité et maintenance pendant que l'expérience visible devient progressivement WizzaOS.

## Développement

Le système est construit par améliorations cohérentes et réversibles. `wizza-dev` sert à préparer et vérifier les changements avant qu'une version suffisamment fiable rejoigne `main`.

## État actuel

WizzaOS est en construction active. Le socle desktop et le générateur d'image live existent, mais aucune version stable n'est encore publiée. Une image n'est considérée comme utilisable qu'après validation de sa construction et de son démarrage réel.
