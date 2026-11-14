---
description: Exécute un agent de code dans un conteneur Docker isolé, en partageant ses sessions avec l'hôte.
---

# claude-code-container

Conteneur Docker pour exécuter Claude Code dans un environnement isolé, dérivé du [devcontainer de
référence d'Anthropic](https://github.com/anthropics/claude-code/tree/main/.devcontainer).

## Pourquoi exécuter Claude Code dans un conteneur ?

Anthropic recommande d'exécuter Claude Code dans un conteneur quand on utilise
`--dangerously-skip-permissions` en fonctionnement non surveillé. Le conteneur apporte une isolation
du système de fichiers et des restrictions réseau (pare-feu) qui limitent ce à quoi Claude peut
accéder en cas d'incident. Voir la
[documentation officielle](https://code.claude.com/docs/en/devcontainer).

Ce dépôt retire le `devcontainer.json` (intégration VS Code) et fournit un simple script shell pour
lancer le conteneur directement avec Docker.

## Contenu

- `Dockerfile` — image basée sur Node.js 20 avec Claude Code, ZSH, git-delta et le pare-feu ;
- `init-firewall.sh` — règles iptables/ipset restrictives (liste blanche sortante uniquement) ;
- `claude-code-container.sh` — script d'enveloppe pour lancer le conteneur.

## Prérequis

- Docker ;
- un compte Claude (claude.ai) ;
- `libnotify` sur l'hôte (facultatif, pour les notifications de bureau).

## Installation

```bash
docker build -t claude-code:latest .
```

## Utilisation

Depuis le dossier du projet :

```bash
cd ~/mon-projet
./claude-code-container.sh
```

Puis, dans le conteneur :

```bash
claude
```

## Fonctionnement

### Historique de sessions partagé

Claude Code range l'historique de sessions sur le chemin absolu du projet. Le devcontainer d'origine
monte tout sous `/workspace` : les sessions créées dans le conteneur ne sont donc pas visibles quand
on lance Claude Code directement sur l'hôte, et inversement.

Pour corriger cela, `claude-code-container.sh` monte le dossier du projet au **même chemin absolu**
dans le conteneur (`-v "$PROJECT_DIR:$PROJECT_DIR"` et `-w "$PROJECT_DIR"`). Claude Code voit ainsi
exactement le même chemin des deux côtés, et l'historique de sessions est partagé sans couture entre
l'hôte et le conteneur.

Sans le montage du dossier de sessions, `docker run --rm` efface les sessions à la fin du conteneur :
`~/.claude` et `~/.claude.json` sont montés depuis l'hôte pour qu'elles persistent et restent
visibles des deux côtés.

### Montages

| Hôte | Conteneur | Rôle |
|------|-----------|------|
| `$(pwd)` | `$(pwd)` | Projet (même chemin = historique de sessions partagé) |
| `~/.claude.json` | `/home/node/.claude.json` | Authentification Claude |
| `~/.claude` | `/home/node/.claude` | Configuration et sessions de Claude Code |
| `/run/user/$UID/bus` | `/run/user/1000/bus` | Socket D-Bus (notifications) |

### Limites d'isolation

Cette configuration échange une partie de l'isolation contre de la commodité. Deux points
affaiblissent la frontière du conteneur par rapport à un devcontainer pleinement isolé :

- **la configuration et les identifiants de Claude** (`~/.claude`, `~/.claude.json`) sont partagés
  depuis l'hôte : un processus malveillant dans le conteneur peut les lire ou les exfiltrer ;
- **la socket D-Bus** est montée pour les notifications de bureau. Elle expose le bus de session de
  l'hôte, ce qui permet en théorie d'interagir avec d'autres services (gestionnaire de fichiers,
  gestionnaire de secrets…), et pas seulement avec les notifications. Pour n'exposer que les
  notifications, utiliser `xdg-dbus-proxy` avec un filtre sur `org.freedesktop.Notifications`.

Pour des dépôts de confiance, le compromis est raisonnable. Pour du code non fiable, envisager de
retirer le montage D-Bus et d'utiliser des identifiants isolés.

### Pare-feu

Le conteneur embarque un script de pare-feu (`init-firewall.sh`) en politique de refus par défaut,
n'autorisant que les domaines nécessaires : registre npm, GitHub, API Anthropic, Sentry, Statsig,
place de marché VS Code.

Pour l'activer dans le conteneur :

```bash
sudo /usr/local/bin/init-firewall.sh
```

> **Note** : le pare-feu exige `--cap-add=NET_ADMIN --cap-add=NET_RAW` au lancement du conteneur.
> Ajouter ces options à `claude-code-container.sh` si besoin.

## Personnalisation

### Ajouter des domaines au pare-feu

Éditer la boucle `for domain in ...` de `init-firewall.sh`.

## Annexe — WebSocket manquant avec le SDK Caido sous Node < 21

### Erreur

```
Error: WebSocket implementation missing; on Node you can `import WebSocket from 'ws';`
and pass `webSocketImpl: WebSocket` to `createClient`
```

### Cause

Node < 21 n'expose pas de `WebSocket` global. Le SDK Caido (`@caido/sdk-client`) utilise
`graphql-ws` en dessous, qui attend `globalThis.WebSocket`.

### Correctif

Ajouter en tête de `lib/client.ts`, **avant** l'import du SDK :

```typescript
import WebSocket from "ws";
(globalThis as any).WebSocket = WebSocket;
```

S'assurer que `ws` est installé :

```bash
npm install ws
```

### Contexte typique

Se produit en exécutant le client dans un conteneur ou tout autre environnement Node 20 où `ws` est
présent dans `node_modules` mais n'est pas exposé globalement.
