---
description: Exécute un agent de code dans un conteneur Docker isolé, en partageant ses sessions avec l'hôte.
---

# claude-code-container

## Installation

```bash
docker build -t claude-code:latest .
```

## Utilisation

Lancer le conteneur depuis le dossier du projet :

```bash
cd ~/mon-projet
./claude-code-container.sh
```

Puis, dans le conteneur :

```bash
claude
```

### Binding du dossier de sessions

Le script monte le dossier de sessions de l'agent depuis l'hôte :

```bash
-v ~/.claude:/home/node/.claude
-v ~/.claude.json:/home/node/.claude.json
```

Sans ce montage, `docker run --rm` efface les sessions à la fin du conteneur. Avec lui, elles persistent côté hôte et restent visibles depuis l'hôte comme depuis le conteneur.

Le projet est monté au même chemin absolu (`-v "$PWD:$PWD"` et `-w "$PWD"`). Claude Code indexe ses sessions par chemin absolu : monter à l'identique garantit que la même clé de session est retrouvée des deux côtés.
