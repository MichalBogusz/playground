# AI Agent Instructions — Playground Monorepo

## Overview

This is a **learning monorepo** for exploring various technologies and architectural patterns. Each subdirectory is an independent project with its own setup, dependencies, and documentation.

## Repository Structure

```
playground/
├── traefik-keycloak-workshop/    # Traefik + Keycloak + FastAPI + React
│   └── AGENTS.md                  # project-specific AI instructions
└── ...                            # future learning projects
```

## General Conventions

### Language Policy
- **All Markdown (`.md`) files must be written in English.**
- Code comments may be in English or Polish, but English is preferred for broader accessibility.

### Project Independence
- Each project is self-contained with its own dependencies, configuration, and tooling
- Always check for project-specific `AGENTS.md` or `README.md` before making assumptions
- Do not assume patterns from one project apply to another

### Documentation Standards
- Each project must have a `README.md` with setup instructions
- Use `AGENTS.md` in project directories for AI-specific guidance
- Document architectural decisions and learning goals

## Active Projects

### traefik-keycloak-workshop
**Goal:** Learn Traefik (API gateway), Keycloak (identity provider), and secure microservice communication  
**Stack:** Traefik v3, Keycloak 24+, FastAPI, React, PostgreSQL, Docker Compose  
**Status:** Active development (9-stage learning path)  
📄 See [traefik-keycloak-workshop/AGENTS.md](traefik-keycloak-workshop/AGENTS.md) for details

## Adding New Projects

When adding a new learning project:
1. Create a dedicated subdirectory: `playground/<project-name>/`
2. Add a `README.md` with project goals and setup instructions
3. Add `AGENTS.md` if the project has AI-relevant patterns or conventions
4. Update this file's "Active Projects" section

## Workspace Guidelines

- Use workspace-relative imports and paths where possible
- Each project may use different languages, frameworks, and tools
- Document learning outcomes and key takeaways in project READMEs
- Prefer incremental learning stages over big-bang implementations
