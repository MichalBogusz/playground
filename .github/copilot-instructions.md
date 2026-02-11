# Copilot Instructions — Traefik + Keycloak Workshop

## Project Overview

A learning-oriented workshop project building a **Workflow application** with **Traefik** (reverse proxy/API gateway) and **Keycloak** (identity provider). The project is structured as 9 incremental stages — each stage adds infrastructure and application layers on top of the previous one.

## Architecture

- **Traefik v3** — gateway, all services exposed under `*.localhost` subdomains
- **Keycloak 24+** — OIDC/OAuth2 identity provider, RBAC with roles: `creator`, `approver`, `viewer`
- **FastAPI (Python)** — backend REST API at `api.localhost`
- **React (Vite + TypeScript)** — frontend SPA at `app.localhost`
- **Notification Service (FastAPI)** — internal service, service-to-service auth via Client Credentials Grant
- **PostgreSQL 16** — database for app data and Keycloak
- **Docker Compose** — orchestration, multi-network isolation

## Key Patterns & Conventions

### Language Rules
- **All Markdown (`.md`) files must be written in English.** This includes README files, documentation, comments in markdown, and any prose content in `.md` format.
- Code comments in Python/TypeScript may be in English or Polish depending on context, but prefer English.

### Project Structure
```
traefik-keycloak-workshop/
├── docker-compose.yml          # single compose file, all services
├── .env                        # environment variables (secrets, ports)
├── traefik/traefik.yml         # Traefik static config
├── traefik/dynamic/            # Traefik dynamic config (middlewares, TLS)
├── keycloak/realm-export.json  # Keycloak realm config (importable)
├── backend/app/                # FastAPI app (main API)
├── notification-service/app/   # FastAPI app (internal service)
├── frontend/src/               # React + Vite app
└── certs/                      # mTLS certificates (generated, not committed)
```

### Docker Compose Conventions
- All services are defined in a single `docker-compose.yml` at the project root
- Traefik routing is configured via Docker labels on each service (auto-discovery)
- Use separate Docker networks for isolation: `frontend-net`, `backend-net`, `db-net`
- Environment variables go in `.env`, referenced in compose via `${VAR_NAME}`

### Traefik Configuration
- Static config: `traefik/traefik.yml` (entrypoints, providers, dashboard)
- Dynamic config: `traefik/dynamic/*.yml` (middlewares, TLS options)
- Routing rules use `Host()` matchers: `traefik.localhost`, `auth.localhost`, `api.localhost`, `app.localhost`
- Labels pattern: `traefik.http.routers.<name>.rule=Host(\`<subdomain>.localhost\`)`

### Authentication & Authorization
- JWT tokens issued by Keycloak, validated in backend via JWKS endpoint
- Roles mapped in Keycloak realm: `creator`, `approver`, `viewer`
- Backend uses dependency injection for auth: `auth.py` provides `get_current_user` dependency
- Service-to-service auth uses **Client Credentials Grant** (Keycloak service accounts)
- mTLS for transport-level trust between internal services

### Backend (FastAPI) Patterns
- Entry point: `backend/app/main.py`
- Auth logic: `backend/app/auth.py` — JWT validation against Keycloak JWKS
- DB models: `backend/app/models.py` (SQLAlchemy/SQLModel)
- API schemas: `backend/app/schemas.py` (Pydantic)
- Routers: `backend/app/routers/` — one file per resource domain
- RBAC enforced at endpoint level via FastAPI dependencies

### Workflow Domain Model
- Statuses: `draft` → `submitted` → `approved` | `rejected`
- Only `creator` role can create/edit/submit workflows
- Only `approver` role can approve/reject workflows
- `viewer` role has read-only access to all workflows

## Development Workflow

```bash
docker compose up -d            # start all services
docker compose logs -f <svc>    # follow logs for a service
docker compose down             # stop everything
docker compose build <svc>      # rebuild specific service
```

## Important Notes
- This is a **learning project** — each stage builds incrementally. Do not jump ahead or add features from later stages prematurely.
- The `certs/` directory contains generated certificates — do not commit private keys.
- Keycloak admin console is at `auth.localhost` — default dev credentials are in `.env`.
