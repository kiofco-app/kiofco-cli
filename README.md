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
KIOFCO_VERSION=v0.1.0 KIOFCO_REPLACE=1 sh ./cli-install.sh
```

```powershell
.\cli-install.ps1
.\cli-install.ps1 -Version v0.1.0 -Replace
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
restent contrôlés par le serveur. Cette première version crée une image par job.
Elle ne propose pas encore de commandes texte, vidéo, audio ou gestion Scribe.
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


Source maintained in a private monorepo. This repository contains distribution files only.
