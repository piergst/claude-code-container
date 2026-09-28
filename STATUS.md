---
state: paused
next: reprendre comme référence de déploiement d'agents en conteneur
---

## Fait

- Image Docker fonctionnelle : Claude Code, zsh, git-delta, firewall.
- Script de lancement `claude-code-container.sh`.
- Sessions partagées hôte/conteneur via le montage de `~/.claude` et le montage du projet au même chemin absolu.

## Reste

- Rien d'engagé : dépôt en pause.

## Principe

Le principe est solide et peut servir de référence pour déployer facilement des agents en conteneur, tout type d'agent.
