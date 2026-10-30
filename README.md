# Kiofco CLI

`kiofco` pilote la génération depuis un terminal. Les binaires pour macOS,
Windows et Linux (Intel/AMD 64 bits et ARM64) fonctionnent sans Node, Go ni Docker.
Ils utilisent le compte, les crédits et l’API Kiofco existants.

## Installation

Télécharger l’archive correspondant au système depuis les
[releases publiques](https://github.com/kiofco-app/kiofco-cli/releases).
Vérifier son SHA-256 avec `SHA256SUMS`, puis extraire `kiofco` ou `kiofco.exe`
dans un répertoire utilisateur présent dans PATH.

Les releases proposent aussi `cli-install.sh` (macOS/Linux) et
`cli-install.ps1` (Windows). Télécharger le script, le lire, puis l’exécuter :

```sh
sh ./cli-install.sh
# Version précise, installation utilisateur, mise à jour explicite :
KIOFCO_VERSION=v0.2.0 KIOFCO_REPLACE=1 sh ./cli-install.sh
```

```powershell
.\cli-install.ps1
.\cli-install.ps1 -Version v0.2.0 -Replace
```

Les scripts vérifient le checksum avant d’installer. Le SHA-256 contrôle
l’intégrité ; ce n’est pas une signature indépendante du canal de téléchargement.
Ne pas envoyer directement un script téléchargé dans un shell.
Répertoires par défaut : `~/.local/bin` et `%LOCALAPPDATA%\Kiofco\bin`.
Ajouter ce répertoire au PATH utilisateur si nécessaire.
Les premiers binaires ne sont ni signés ni notariés ; le système peut demander
une validation locale. Ne pas désactiver les protections globales du système.

## Connexion

Créer une clé dans [le compte Kiofco](https://www.kiofco.com/account/api-keys),
puis la saisir sans écho dans le terminal :

```sh
kiofco auth login
kiofco auth status
```

`auth login --key-stdin` lit explicitement la clé depuis stdin pour un gestionnaire
de secrets. Ne jamais placer une clé dans une option CLI ou l’historique du shell.
La clé validée est conservée dans le trousseau système (Keychain, Credential
Manager ou Secret Service), jamais dans un fichier en clair.
`KIOFCO_API_KEY` prend priorité sur le trousseau pour les scripts et machines
headless. Sans trousseau accessible, utiliser cette variable sans persistance.
`auth logout` efface seulement la clé locale ; il ne révoque pas la clé distante
et n’efface pas une variable d’environnement. Révoquer dans le compte Kiofco.

## Génération et résultats

```sh
kiofco generate image --adapter vertex-gemini-image --prompt "Un phare dans la brume"
kiofco generate image --adapter vertex-gemini-image --prompt "Un phare" --wait
kiofco jobs get <job-id>
kiofco jobs wait <job-id>
kiofco jobs get <job-id> --json
```

Choisir un adapter disponible sur le compte ; les modèles, crédits et limites
restent contrôlés par le serveur. La requête crée une image par défaut ; si le
fournisseur retourne plusieurs images, toutes restent accessibles dans les résultats.
HTTP 202 confirme la prise en compte : le statut retourné peut déjà être `queued`,
`running`, `done` ou `failed`, notamment lors d’une reprise avec la même clé.
`--wait` observe ce même job et restitue son résultat ou son échec, sans recréer de génération.
Utiliser la CLI **v0.1.1 ou ultérieure** : v0.1.0 ne reconnaît que les accusés `queued`.
Les commandes de génération texte, vidéo et audio ne sont pas encore disponibles ;
les projets Scribe sont accessibles avec les commandes créatives ci-dessous.
Les résultats contiennent des URL temporaires ; demander de nouveau le job pour
obtenir des liens frais. La CLI ne télécharge ni n’ouvre automatiquement ces URL.

Une création utilise une clé d’idempotence unique. En cas de résultat réseau
incertain, reprendre explicitement avec la même `--idempotency-key` au lieu
de créer une seconde génération payante. Aucun POST n’est rejoué automatiquement.
Ctrl-C interrompt l’attente locale, sans annuler le job sur le serveur.
L’attente est bornée à dix minutes par défaut ; reprendre avec `jobs wait`.
Les données JSON vont sur stdout, les diagnostics sur stderr.

| Code de sortie | Sens                                            |
| -------------- | ----------------------------------------------- |
| 0              | Succès                                          |
| 1              | Erreur serveur, transport ou génération échouée |
| 2              | Usage ou configuration invalide                 |
| 3              | Authentification absente ou refusée             |
| 4              | Attente expirée ou interrompue                  |

## Projets créatifs avec Scribe

Depuis la CLI v0.3.0, créer un univers, ses personnages et son histoire avec
l’assistant de son choix, puis proposer ses modifications dans Scribe.
Scribe conserve la version de référence ; les fichiers locaux ne la remplacent
jamais automatiquement.

1. Dans [Scribe](https://scribe.kiofco.com/projects), créer un projet créatif :
   son livre et son univers sont créés ensemble.
2. Après `kiofco auth login`, ouvrir un dossier de travail dédié et récupérer le
   projet. Le terminal propose un sélecteur ; dans un script, utiliser
   `kiofco project list --json`, puis `kiofco project checkout --project <id>`.
3. Installer les entrées pour les assistants utilisés :

```sh
mkdir mon-univers
cd mon-univers
kiofco project checkout
kiofco skills install --hosts claude,codex,chatgpt
kiofco skills list
```

Ouvrir ce dossier dans l’assistant, lui demander de lire le pack installé,
puis travailler sur les documents Markdown en conservant leurs identifiants.
Le pack guide l’univers, les personnages, le plan, les scènes et les références
visuelles. Il utilise seulement les capacités réellement disponibles dans
l’offre de l’assistant, sans basculer automatiquement vers une génération
payante Kiofco.

```sh
kiofco project status
kiofco project diff <document-id>
kiofco project propose <document-id>
```

Relire et approuver la proposition dans Scribe, puis récupérer la référence
avec `kiofco project pull`. Une proposition obsolète demande une réconciliation ;
elle ne fusionne ni n’écrase automatiquement les modifications concurrentes.
`status`, `diff` et les exports restent utilisables hors ligne.

```sh
kiofco project export --format html --output creative/exports/bible.html
```

La synchronisation, les skills et les exports Markdown/HTML/Fountain ne demandent
ni Node ni Python. Ces runtimes servent uniquement aux outils facultatifs,
jamais installés ou exécutés automatiquement. Les commandes `kiofco project --help`,
`kiofco skills --help` et `kiofco tools --help` détaillent les options ;
`--directory <dossier>` sélectionne une autre racine locale.

Source maintained in a private monorepo. This repository contains distribution files only.
